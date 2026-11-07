import 'dart:async';
import 'package:llamadart/llamadart.dart';

/// Runs a local file through a native engine. No network sources are accepted.
class PhoneInferenceRunner {
  LlamaEngine? _engine;
  bool _cancelled = false;
  void cancel() {
    _cancelled = true;
    _engine?.cancelGeneration();
  }

  Future<String> generate({
    required String filePath,
    required String prompt,
    String? sha256,
    bool thinking = false,
    void Function(String)? onText,
  }) async {
    _cancelled = false;
    final timer = Timer(const Duration(minutes: 3), cancel);
    try {
      _engine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(filePath)),
        download: ModelLoadOptions(sha256: sha256),
        params: const LlamaCppModelParams(
          contextSize: 2048,
          device: ComputeDevice.cpu,
          gpuLayers: 0,
          numberOfThreads: 3,
          numberOfThreadsBatch: 3,
          batchSize: 256,
          microBatchSize: 128,
        ),
      );
      if (_cancelled) throw StateError('Generation cancelled.');
      var text = '';
      await for (final chunk in _engine!.create(
        [
          LlamaChatMessage.fromText(
            role: LlamaChatRole.system,
            text:
                'You are Sumi, a concise learning coach. Give plain-text guidance grounded in the supplied exercise. Acknowledge uncertainty.',
          ),
          LlamaChatMessage.fromText(role: LlamaChatRole.user, text: prompt),
        ],
        enableThinking: thinking,
        params: GenerationParams(
          maxTokens: thinking ? 320 : 160,
          temp: .6,
          topP: .9,
        ),
      )) {
        if (_cancelled) {
          _engine!.cancelGeneration();
          break;
        }
        text += chunk.text;
        onText?.call(text);
      }
      if (_cancelled) throw StateError('Generation cancelled or timed out.');
      if (text.trim().isEmpty) {
        throw StateError(
          'The model produced no visible answer. Try a smaller Qwen model.',
        );
      }
      return text.trim();
    } finally {
      timer.cancel();
      await _engine?.dispose();
      _engine = null;
    }
  }
}
