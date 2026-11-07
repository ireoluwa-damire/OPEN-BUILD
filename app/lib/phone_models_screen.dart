import 'package:flutter/material.dart';
import 'on_device.dart';
import 'phone_model_types.dart';
import 'theme.dart';
import 'widgets.dart';

class PhoneModelsScreen extends StatefulWidget {
  final PhoneModelController controller;
  const PhoneModelsScreen({super.key, required this.controller});
  @override
  State<PhoneModelsScreen> createState() => _PhoneModelsScreenState();
}

class _PhoneModelsScreenState extends State<PhoneModelsScreen> {
  String? error;
  String testReply = '';
  PhoneModelController get coach => widget.controller;
  @override
  void initState() {
    super.initState();
    coach.initialize().catchError((Object e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : 'Model storage could not be opened. Try reopening this screen.',
        );
      }
    });
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() => error = null);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              coach.status.startsWith('Download') ||
                  coach.status.startsWith('The model')
              ? coach.status
              : 'That operation could not finish. Check storage, the model file, and your connection for downloads.',
        );
      }
    }
  }

  Future<void> download(PhoneModelChoice model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.name}?'),
        content: Text(
          '${model.sizeLabel} from ${model.repo} on Hugging Face. Wi-Fi is recommended. '
          'Keep Sumi open; interrupted downloads can resume. '
          'RAM guidance: about ${model.suggestedRamGb} GB total device RAM, not a guarantee. '
          'Inference stays on this device after download.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await run(() => coach.download(model));
  }

  Future<void> remove(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove this model?'),
        content: Text(
          'This frees its storage. Your learning progress stays saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep model'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await run(() => coach.remove(id));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: coach,
    builder: (context, _) {
      final t = Theme.of(context).textTheme;
      final ram = coach.device['ram_total_bytes'] as int?;
      final free = coach.device['storage_free_bytes'] as int?;
      return Scaffold(
        appBar: AppBar(title: Text('Models on this device')),
        body: ListView(
          padding: EdgeInsets.all(24),
          children: [
            Tag('DOWNLOAD ONCE · USE OFFLINE'),
            SizedBox(height: 16),
            Text('Your coach.\nOn your phone.', style: t.headlineLarge),
            SizedBox(height: 12),
            Text(
              'Hugging Face supplies the download files. Once stored, the model runs here through llama.cpp; no inference server is used.',
            ),
            SizedBox(height: 16),
            if (!coach.supported) Surface(child: Text(coach.status)),
            if (ram != null || free != null)
              Surface(
                child: Text(
                  [
                    if (ram != null)
                      '${(ram / 1073741824).toStringAsFixed(1)} GB device RAM',
                    if (free != null)
                      '${(free / 1073741824).toStringAsFixed(1)} GB storage free',
                  ].join(' · '),
                ),
              ),
            SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(coach.status, style: t.bodySmall),
            ),
            if (coach.busy) ...[
              SizedBox(height: 12),
              LinearProgressIndicator(value: coach.progress),
              TextButton(onPressed: coach.cancel, child: Text('Stop / pause')),
            ],
            if (error != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(error!, style: TextStyle(color: SumiColors.coral)),
              ),
            SizedBox(height: 24),
            for (final model in coach.choices)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name, style: t.titleMedium),
                      SizedBox(height: 8),
                      Text(
                        '${model.sizeLabel} · ${model.quantization} · ${model.license}',
                        style: t.bodySmall,
                      ),
                      SizedBox(height: 8),
                      Text(model.note),
                      SizedBox(height: 12),
                      if (coach.installed.any((m) => m['id'] == model.id))
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: coach.busy
                                  ? null
                                  : () => run(() => coach.select(model.id)),
                              icon: Icon(
                                coach.activeId == model.id
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                              ),
                              label: Text(
                                coach.activeId == model.id
                                    ? 'Selected · verified'
                                    : 'Use this model',
                              ),
                            ),
                            TextButton(
                              onPressed: coach.busy
                                  ? null
                                  : () => remove(model.id),
                              child: Text('Remove'),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: coach.busy ? null : () => download(model),
                          icon: Icon(Icons.download_rounded),
                          label: Text('Download / resume'),
                        ),
                    ],
                  ),
                ),
              ),
            for (final model in coach.installed.where(
              (m) => m['verified'] != true,
            ))
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model['name'], style: t.titleMedium),
                      Text(
                        'Imported GGUF · publisher unverified',
                        style: t.bodySmall,
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: coach.busy
                                ? null
                                : () => run(() => coach.select(model['id'])),
                            child: Text(
                              coach.activeId == model['id']
                                  ? 'Selected'
                                  : 'Use model',
                            ),
                          ),
                          TextButton(
                            onPressed: coach.busy
                                ? null
                                : () => remove(model['id']),
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: !coach.supported || coach.busy
                  ? null
                  : () => run(coach.importModel),
              icon: Icon(Icons.folder_open_rounded),
              label: Text('Import another GGUF file'),
            ),
            SizedBox(height: 12),
            Text(
              'Single-file, compatible GGUF only (up to 4 GB in this demo). Unsupported architectures may fail to load. Imported files are copied into Sumi storage.',
              style: t.bodySmall,
            ),
            SizedBox(height: 18),
            Text(
              'DeepSeek V4.1 is a much larger model, not a phone option here. The small DeepSeek option above is a distinct distilled model.',
              style: t.bodySmall,
            ),
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: coach.activeId == null || coach.busy
                  ? null
                  : () => run(() async {
                      setState(() => testReply = '');
                      final text = await coach.reply(
                        'Give one short practical tip for practising a new skill. No more than two sentences.',
                        onText: (text) {
                          if (mounted) setState(() => testReply = text);
                        },
                      );
                      if (mounted) setState(() => testReply = text);
                    }),
              icon: Icon(Icons.offline_bolt_rounded),
              label: Text('Test local inference'),
            ),
            if (testReply.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Surface(child: SelectableText(testReply)),
              ),
            SizedBox(height: 16),
            Text(
              'Offline test: after downloading, turn off Wi-Fi and mobile data yourself, then run this test again. AI advice can be wrong; compare it with your learning references.',
              style: t.bodySmall,
            ),
          ],
        ),
      );
    },
  );
}
