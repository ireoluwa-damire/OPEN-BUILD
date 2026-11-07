import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'phone_model_types.dart';
import 'phone_runtime.dart';
import 'effects/effects_service.dart';

class PhoneModelController extends ChangeNotifier {
  bool get supported => Platform.isAndroid || Platform.isIOS;
  bool busy = false, initialized = false;
  String status = 'Download once. Run the coach on this device.';
  double? progress;
  String? workingId, activeId;
  List<PhoneModelChoice> choices = [];
  List<Json> installed = [];
  Json device = {};
  String? get activeName =>
      installed.where((m) => m['id'] == activeId).firstOrNull?['name'];
  late Directory _directory;
  late DefaultModelDownloadManager _downloads;
  Future<void>? _initializing;
  ModelDownloadCancelToken? _cancelToken;
  PhoneInferenceRunner? _runner;
  bool get generating => _runner != null;
  bool _cancelled = false;

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    try {
      choices =
          (jsonDecode(
                    await rootBundle.loadString('assets/model_catalog.json'),
                  )['models']
                  as List)
              .map((j) => PhoneModelChoice(Json.from(j)))
              .toList();
      final support = await getApplicationSupportDirectory();
      _directory = Directory('${support.path}/phone-models');
      await _directory.create(recursive: true);
      _downloads = DefaultModelDownloadManager(
        defaultCacheDirectory: '${_directory.path}/downloads',
      );
      final index = File('${_directory.path}/index.json');
      if (await index.exists()) {
        final value = Json.from(jsonDecode(await index.readAsString()));
        activeId = value['active_id'];
        for (final item in (value['installed'] ?? []) as List) {
          final entry = Json.from(item);
          final file = File(entry['path']);
          if (await file.exists() && await file.length() == entry['bytes']) {
            installed.add(entry);
          }
        }
        if (!installed.any((m) => m['id'] == activeId)) activeId = null;
      }
      await _deviceInfo();
      initialized = true;
      notifyListeners();
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _deviceInfo() async {
    if (!Platform.isAndroid) return;
    try {
      final value = await const MethodChannel(
        'sumi/device',
      ).invokeMapMethod<String, dynamic>('capabilities');
      device = value ?? {};
    } on MissingPluginException {
      device = {};
    }
  }

  Future<void> _save() async {
    final temporary = File('${_directory.path}/index.json.tmp');
    await temporary.writeAsString(
      jsonEncode({'active_id': activeId, 'installed': installed}),
      flush: true,
    );
    await temporary.rename('${_directory.path}/index.json');
  }

  void _begin(String id, String message) {
    if (busy) throw StateError('Another model operation is running.');
    busy = true;
    workingId = id;
    status = message;
    progress = null;
    _cancelled = false;
    notifyListeners();
  }

  void _end() {
    busy = false;
    workingId = null;
    progress = null;
    _cancelToken = null;
    notifyListeners();
  }

  Future<void> _space(int bytes) async {
    await _deviceInfo();
    final free = device['storage_free_bytes'] as int?;
    if (free != null && free < bytes + 268435456) {
      throw StateError(
        'Free more storage before downloading or importing this model.',
      );
    }
  }

  Future<void> download(PhoneModelChoice choice) async {
    await initialize();
    await _space(choice.bytes);
    _begin(choice.id, 'Downloading ${choice.name}. Keep Sumi open.');
    _cancelToken = ModelDownloadCancelToken();
    final before = List<Json>.of(installed);
    final oldActive = activeId;
    final progressClock = Stopwatch()..start();
    try {
      final entry = await _downloads.ensureModel(
        ModelSource.huggingFace(
          repoId: choice.repo,
          filePath: choice.file,
          revision: choice.revision,
        ),
        options: ModelLoadOptions(
          sha256: choice.sha256,
          resume: true,
          cancelToken: _cancelToken,
        ),
        onProgress: (value) {
          if (progressClock.elapsedMilliseconds < 120 && value.fraction != 1) {
            return;
          }
          progressClock.reset();
          progress = value.fraction;
          status =
              '${choice.name}: ${(value.receivedBytes / 1000000).round()} / ${(choice.bytes / 1000000).round()} MB. Verifying before use.';
          notifyListeners();
        },
      );
      if (_cancelled) throw StateError('Download paused.');
      installed.removeWhere((m) => m['id'] == choice.id);
      installed.add({
        'id': choice.id,
        'name': choice.name,
        'path': entry.filePath,
        'bytes': entry.bytes ?? choice.bytes,
        'sha256': choice.sha256,
        'cache_key': entry.cacheKey,
        'verified': true,
      });
      activeId = choice.id;
      await _save();
      status =
          '${choice.name} is stored on this device. Publisher checksum verified.';
      EffectsService.instance.sound(SumiSound.modelReady);
    } catch (_) {
      installed = before;
      activeId = oldActive;
      status = _cancelled
          ? 'Download paused. Use Download / resume to continue.'
          : 'Download failed or the file could not be verified. Retry to resume.';
      rethrow;
    } finally {
      _end();
    }
  }

  void cancel() {
    _cancelled = true;
    _cancelToken?.cancel();
    _runner?.cancel();
    status = 'Stopping… partial downloads can be resumed.';
    notifyListeners();
  }

  Future<void> select(String id) async {
    if (busy) throw StateError('Finish the current model operation first.');
    if (!installed.any((m) => m['id'] == id)) {
      throw StateError('Download this model first.');
    }
    activeId = id;
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (busy) throw StateError('Finish the current model operation first.');
    final model = installed.firstWhere((m) => m['id'] == id);
    if (model['cache_key'] != null) {
      await _downloads.remove(model['cache_key']);
    } else {
      await File(model['path']).delete();
    }
    installed.removeWhere((m) => m['id'] == id);
    if (activeId == id) activeId = installed.firstOrNull?['id'];
    await _save();
    status = 'Model removed from this device.';
    notifyListeners();
  }

  Future<void> importModel() async {
    await initialize();
    if (busy) return;
    final selected = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'GGUF model', extensions: ['gguf']),
      ],
    );
    if (selected == null) return;
    final size = await selected.length();
    if (size > 4294967296) {
      throw StateError('This demo supports single GGUF files up to 4 GB.');
    }
    await _space(size);
    _begin('import', 'Copying the selected model into Sumi storage…');
    File? target;
    final before = List<Json>.of(installed);
    final oldActive = activeId;
    try {
      final id = 'import-${DateTime.now().microsecondsSinceEpoch}';
      target = File('${_directory.path}/$id.gguf');
      await selected.saveTo(target.path);
      final handle = await target.open();
      final header = await handle.read(4);
      await handle.close();
      if (!listEquals(header, [71, 71, 85, 70])) {
        throw const FormatException('This is not a GGUF file.');
      }
      final digest = await sha256.bind(target.openRead()).first;
      installed.add({
        'id': id,
        'name': selected.name,
        'path': target.path,
        'bytes': size,
        'sha256': digest.toString(),
        'verified': false,
      });
      activeId = id;
      await _save();
      status =
          'Model imported. Its architecture will be checked when loaded; publisher identity is unverified.';
    } catch (_) {
      installed = before;
      activeId = oldActive;
      if (target != null && await target.exists()) await target.delete();
      rethrow;
    } finally {
      _end();
    }
  }

  Future<String> reply(String prompt, {void Function(String)? onText}) async {
    if (!supported) {
      throw UnsupportedError(
        'On-device inference is enabled in the mobile build.',
      );
    }
    await initialize();
    final model = installed.where((m) => m['id'] == activeId).firstOrNull;
    if (model == null) throw StateError('Download or import a model first.');
    _begin(model['id'], 'Loading ${model['name']} on this device…');
    _runner = PhoneInferenceRunner();
    final stopwatch = Stopwatch()..start();
    try {
      final text = await _runner!.generate(
        filePath: model['path'],
        sha256: model['sha256'],
        prompt: prompt,
        thinking: !model['id'].toString().startsWith('qwen3'),
        onText: (text) {
          status = 'Generating on this device · CPU';
          onText?.call(text);
          notifyListeners();
        },
      );
      status =
          'Generated on this device in ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} s. Model unloaded to free memory.';
      return text;
    } catch (_) {
      status = _cancelled
          ? 'Generation stopped. Your learning route is unchanged.'
          : 'The model could not complete this request. Try the small Qwen model.';
      rethrow;
    } finally {
      _runner = null;
      _end();
    }
  }
}
