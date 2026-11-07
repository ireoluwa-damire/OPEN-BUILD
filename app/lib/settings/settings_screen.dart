import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../build_info.dart';
import '../design_system/components.dart';
import '../design_system/routes.dart';
import '../mascot/sumi_mascot.dart';
import '../models.dart';
import '../on_device.dart';
import '../phone_models_screen.dart';
import '../services.dart';
import '../theme.dart';

/// Settings subtitles derived from state only (SET-02, DC §11.5). Tests call
/// these directly and compare them with the rendered rows.
abstract final class SettingsCopy {
  static const guest = 'Guest · progress stays on this device';
  static const reminders =
      'Not set up yet — Sumi can’t send notifications in this build.';
  static const cloud = 'Not configured';
  static const licences = 'Open-source, model and content licences';

  static String dailyGoal(LearningState l) => '${l.dailyMinutes} min/day';

  static String goal(LearningState l) {
    final deadline = l.goalRecord?.deadline;
    final d = deadline == null || deadline.isEmpty || deadline == 'None'
        ? 'No deadline'
        : deadline;
    final outcome = l.goal.isEmpty ? 'No goal set' : l.goal;
    return '$outcome · $d';
  }

  static String exerciseMix(LearningState l) => switch (l.settings.exerciseMix) {
    'practice' => 'More practice',
    'reading' => 'More reading',
    _ => 'Balanced',
  };

  static String accessibility(LearnerSettings s) => [
    'Reduced motion ${s.reducedMotion ? 'on' : 'off'}',
    'High contrast ${s.highContrast ? 'on' : 'off'}',
    'Text: ${s.textMode == 'system' ? 'system' : s.textMode}',
  ].join(' · ');

  static String model(PhoneModelController c) {
    if (!c.supported) return 'Runs in the installed mobile app';
    if (c.workingId != null && c.progress != null) {
      return 'Downloading ${(c.progress! * 100).round()}%';
    }
    if (c.activeName != null) return '${c.activeName} ready';
    return 'No model installed';
  }

  static String storage(int bytes) =>
      'Stored on this device (not encrypted) · ${formatBytes(bytes)}';

  static String about() => 'Sumi ${BuildInfo.version} (${BuildInfo.build})';

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// SET-01 to SET-07 (DC §8.14). Every change goes through [onUpdate], a
/// single transaction per change (ARC-01).
class SettingsScreen extends StatefulWidget {
  final List<Catalog> disciplines;
  final Catalog catalog;
  final LearningState learning;
  final LocalStore store;
  final PhoneModelController phoneCoach;
  final Future<void> Function(void Function(LearningState s) change) onUpdate;
  final Future<void> Function(Catalog) onSwitchDiscipline;

  /// Called after a discipline's data was cleared or imported, so the shell
  /// reloads it from storage.
  final Future<void> Function(String trackId) onDataReplaced;

  const SettingsScreen({
    super.key,
    required this.disciplines,
    required this.catalog,
    required this.learning,
    required this.store,
    required this.phoneCoach,
    required this.onUpdate,
    required this.onSwitchDiscipline,
    required this.onDataReplaced,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _bytes;
  String? _error;

  LearningState get l => widget.learning;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    var total = 0;
    for (final d in widget.disciplines) {
      final records = await widget.store.rawRecords(d.id);
      for (final v in records.values) {
        total += utf8.encode(v).length;
      }
    }
    if (mounted) setState(() => _bytes = total);
  }

  Future<void> _update(void Function(LearningState s) change) async {
    try {
      await widget.onUpdate(change);
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t save that change. Try again.');
      }
    }
  }

  Future<void> _pickMinutes() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in OnboardingState.minuteOptions) ...[
                ChoiceRow(
                  label: '$m min/day',
                  state: l.dailyMinutes == m
                      ? ChoiceState.selected
                      : ChoiceState.idle,
                  onTap: () => Navigator.pop(c, m),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _update((s) => s.dailyMinutes = picked);
  }

  Future<void> _pickMix() async {
    const options = {
      'balanced': 'Balanced',
      'practice': 'More practice',
      'reading': 'More reading',
    };
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in options.entries) ...[
                ChoiceRow(
                  label: e.value,
                  state: l.settings.exerciseMix == e.key
                      ? ChoiceState.selected
                      : ChoiceState.idle,
                  onTap: () => Navigator.pop(c, e.key),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) await _update((s) => s.settings.exerciseMix = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: t.titleMedium)),
      body: ListenableBuilder(
        listenable: widget.phoneCoach,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InlineError(_error!),
              ),
            const SettingsSectionLabel('Profile on this device'),
            const SettingsRow(
              icon: Icons.person_rounded,
              title: 'Guest profile',
              subtitle: SettingsCopy.guest,
            ),
            const SettingsSectionLabel('Learning preferences'),
            SettingsRow(
              icon: Icons.timer_rounded,
              title: 'Daily goal',
              subtitle: SettingsCopy.dailyGoal(l),
              onTap: _pickMinutes,
            ),
            SettingsRow(
              icon: Icons.flag_rounded,
              title: 'Goal and deadline',
              subtitle: SettingsCopy.goal(l),
            ),
            SettingsRow(
              icon: Icons.shuffle_rounded,
              title: 'Exercise mix',
              subtitle: SettingsCopy.exerciseMix(l),
              onTap: _pickMix,
            ),
            SettingsRow(
              icon: Icons.volume_up_rounded,
              title: 'Sound effects',
              subtitle: l.soundEffectsEnabled ? 'On' : 'Off',
              switchValue: l.soundEffectsEnabled,
              onSwitch: (v) => _update((s) => s.soundEffectsEnabled = v),
            ),
            SettingsRow(
              icon: Icons.vibration_rounded,
              title: 'Haptics',
              subtitle: l.hapticsEnabled ? 'On' : 'Off',
              switchValue: l.hapticsEnabled,
              onSwitch: (v) => _update((s) => s.hapticsEnabled = v),
            ),
            SettingsRow(
              icon: Icons.school_rounded,
              title: 'Disciplines',
              subtitle:
                  '${widget.disciplines.where((d) => !d.isCustom).length} available · ${widget.catalog.title} active',
              onTap: () => _showDisciplines(context),
            ),
            const SettingsSectionLabel('Notifications and reminders'),
            const SettingsRow(
              icon: Icons.notifications_off_rounded,
              title: 'Practice reminders',
              subtitle: SettingsCopy.reminders,
              switchValue: false,
              enabled: false,
            ),
            const SettingsSectionLabel('Accessibility'),
            SettingsRow(
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility',
              subtitle: SettingsCopy.accessibility(l.settings),
              onTap: () async {
                await Navigator.of(context).push(
                  slideRoute<void>(
                    (_) => AccessibilitySettingsScreen(
                      learning: l,
                      onUpdate: widget.onUpdate,
                    ),
                    reducedMotion: l.reducedMotion,
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
            const SettingsSectionLabel('Offline AI models'),
            SettingsRow(
              icon: Icons.offline_bolt_rounded,
              title: 'Offline AI models',
              subtitle: SettingsCopy.model(widget.phoneCoach),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PhoneModelsScreen(controller: widget.phoneCoach),
                ),
              ),
            ),
            const SettingsSectionLabel('Cloud AI'),
            const SettingsRow(
              icon: Icons.cloud_off_rounded,
              title: 'Cloud AI',
              subtitle: SettingsCopy.cloud,
            ),
            const SettingsSectionLabel('Storage and privacy'),
            SettingsRow(
              icon: Icons.storage_rounded,
              title: 'Storage and privacy',
              subtitle: _bytes == null
                  ? 'Stored on this device (not encrypted)'
                  : SettingsCopy.storage(_bytes!),
              onTap: () async {
                await Navigator.of(context).push(
                  slideRoute<void>(
                    (_) => StoragePrivacyScreen(
                      disciplines: widget.disciplines,
                      store: widget.store,
                      learning: l,
                      onUpdate: widget.onUpdate,
                      onDataReplaced: widget.onDataReplaced,
                    ),
                    reducedMotion: l.reducedMotion,
                  ),
                );
                await _measure();
              },
            ),
            const SettingsSectionLabel('About and licences'),
            SettingsRow(
              icon: Icons.info_rounded,
              title: 'About Sumi',
              subtitle: SettingsCopy.about(),
              onTap: () => Navigator.of(context).push(
                slideRoute<void>(
                  (_) => const AboutScreen(),
                  reducedMotion: l.reducedMotion,
                ),
              ),
            ),
            SettingsRow(
              icon: Icons.gavel_rounded,
              title: 'Licences',
              subtitle: SettingsCopy.licences,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Sumi',
                applicationVersion: SettingsCopy.about(),
              ),
            ),
            // GOV-05: the animation gallery is a developer tool only.
            if (kDebugMode)
              SettingsRow(
                icon: Icons.bug_report_rounded,
                title: 'Mascot gallery (debug)',
                subtitle: 'Developer preview of every animation',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        SumiGalleryScreen(reducedMotion: l.reducedMotion),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDisciplines(BuildContext context) async {
    final picked = await showModalBottomSheet<Catalog>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in widget.disciplines.where((d) => !d.isCustom)) ...[
                ChoiceRow(
                  label: d.title,
                  state: d.id == widget.catalog.id
                      ? ChoiceState.selected
                      : ChoiceState.idle,
                  onTap: () => Navigator.pop(c, d),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked.id != widget.catalog.id) {
      await widget.onSwitchDiscipline(picked);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

/// SET-05: accessibility settings. Changes apply at once and persist.
class AccessibilitySettingsScreen extends StatefulWidget {
  final LearningState learning;
  final Future<void> Function(void Function(LearningState s) change) onUpdate;
  const AccessibilitySettingsScreen({
    super.key,
    required this.learning,
    required this.onUpdate,
  });

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  String? _error;
  LearnerSettings get s => widget.learning.settings;

  Future<void> _update(void Function(LearnerSettings s) change) async {
    try {
      await widget.onUpdate((l) => change(l.settings));
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t save that change. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Accessibility', style: t.titleMedium)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: InlineError(_error!)),
          const SettingsSectionLabel('Text'),
          for (final mode in LearnerSettings.textModes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ChoiceRow(
                label: switch (mode) {
                  'large' => 'Larger (×1.15)',
                  'larger' => 'Largest (×1.3)',
                  _ => 'System',
                },
                subtitle: mode == 'system'
                    ? 'Follows your device text size'
                    : 'On top of your device text size',
                state: s.textMode == mode ? ChoiceState.selected : ChoiceState.idle,
                onTap: () => _update((s) => s.textMode = mode),
              ),
            ),
          const SettingsSectionLabel('Display and motion'),
          SettingsRow(
            icon: Icons.contrast_rounded,
            title: 'High contrast',
            subtitle: s.highContrast ? 'On' : 'Off',
            switchValue: s.highContrast,
            onSwitch: (v) => _update((s) => s.highContrast = v),
          ),
          SettingsRow(
            icon: Icons.motion_photos_off_rounded,
            title: 'Reduced motion',
            subtitle: s.reducedMotion
                ? 'On · animations are replaced with still frames'
                : 'Off',
            switchValue: s.reducedMotion,
            onSwitch: (v) => _update((s) => s.reducedMotion = v),
          ),
          const SettingsSectionLabel('Sound, touch and media'),
          SettingsRow(
            icon: Icons.volume_up_rounded,
            title: 'Sound effects',
            subtitle: s.soundEffects ? 'On' : 'Off',
            switchValue: s.soundEffects,
            onSwitch: (v) => _update((s) => s.soundEffects = v),
          ),
          SettingsRow(
            icon: Icons.vibration_rounded,
            title: 'Haptics',
            subtitle: s.haptics ? 'On' : 'Off',
            switchValue: s.haptics,
            onSwitch: (v) => _update((s) => s.haptics = v),
          ),
          SettingsRow(
            icon: Icons.closed_caption_rounded,
            title: 'Prefer captioned videos',
            subtitle: s.captions
                ? 'On · resources with captions are ranked first'
                : 'Off',
            switchValue: s.captions,
            onSwitch: (v) => _update((s) => s.captions = v),
          ),
          const SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Colour-independent feedback',
            subtitle: 'Always on · every state uses an icon and text as well as colour',
          ),
          SettingsRow(
            icon: Icons.record_voice_over_rounded,
            title: 'Tutor explanation length',
            subtitle: s.explanationLength == 'detailed' ? 'Detailed' : 'Short',
            onTap: () => _update(
              (s) => s.explanationLength =
                  s.explanationLength == 'detailed' ? 'short' : 'detailed',
            ),
          ),
        ],
      ),
    );
  }
}

/// SET-06: storage summary, export, import and scoped deletion. Offline model
/// files are stored separately and are never touched here.
class StoragePrivacyScreen extends StatefulWidget {
  final List<Catalog> disciplines;
  final LocalStore store;
  final LearningState learning;
  final Future<void> Function(void Function(LearningState s) change) onUpdate;
  final Future<void> Function(String trackId) onDataReplaced;
  const StoragePrivacyScreen({
    super.key,
    required this.disciplines,
    required this.store,
    required this.learning,
    required this.onUpdate,
    required this.onDataReplaced,
  });

  @override
  State<StoragePrivacyScreen> createState() => _StoragePrivacyScreenState();
}

class _StoragePrivacyScreenState extends State<StoragePrivacyScreen> {
  Map<String, int> _sizes = {};
  String? _message, _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sizes = <String, int>{};
    for (final d in widget.disciplines) {
      final records = await widget.store.rawRecords(d.id);
      sizes[d.id] = records.values.fold(0, (n, v) => n + utf8.encode(v).length);
    }
    if (mounted) setState(() => _sizes = sizes);
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body, style: Theme.of(c).textTheme.bodyLarge),
              const SizedBox(height: 24),
              TactileButton(
                'KEEP MY DATA',
                variant: TactileVariant.secondary,
                onPressed: () => Navigator.pop(c, false),
              ),
              const SizedBox(height: 8),
              TactileButton(
                action,
                variant: TactileVariant.text,
                errorTone: true,
                onPressed: () => Navigator.pop(c, true),
              ),
            ],
          ),
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _export() async {
    final records = await widget.store.rawRecords(widget.learning.trackId);
    final current = records['sumi.learning.v${LearningState.schemaVersion}.${widget.learning.trackId}'];
    if (current == null) {
      setState(() => _error = 'There is no saved progress to export yet.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: current));
    if (mounted) {
      setState(() {
        _error = null;
        _message = 'Progress for this discipline was copied as JSON. Paste it somewhere safe.';
      });
    }
  }

  Future<void> _import() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json', 'txt']),
        ],
      );
      if (file == null) return;
      final raw = await file.readAsString();
      final trackId = widget.learning.trackId;
      if (!await _confirm(
        'Replace this discipline’s progress?',
        'The imported file replaces the progress saved for this discipline on this device.',
        'REPLACE PROGRESS',
      )) {
        return;
      }
      await widget.store.importRecord(trackId, raw);
      await widget.onDataReplaced(trackId);
      await _load();
      if (mounted) {
        setState(() {
          _error = null;
          _message = 'Progress imported.';
        });
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'That file isn’t a compatible Sumi export. Nothing was changed.',
        );
      }
    }
  }

  Future<void> _clear(List<Catalog> tracks, String label) async {
    if (!await _confirm(
      'Clear progress for $label?',
      'This deletes the saved progress for $label on this device. Offline AI models are not removed. This can’t be undone.',
      'CLEAR PROGRESS',
    )) {
      return;
    }
    try {
      for (final d in tracks) {
        await widget.store.clearTrack(d.id);
        await widget.onDataReplaced(d.id);
      }
      await _load();
      if (mounted) {
        setState(() {
          _error = null;
          _message = 'Progress cleared for $label.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t clear progress. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tracks = widget.disciplines.where((d) => !d.isCustom).toList();
    final total = _sizes.values.fold(0, (n, v) => n + v);
    final active = widget.disciplines
        .where((d) => d.id == widget.learning.trackId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text('Storage and privacy', style: t.titleMedium)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: InlineError(_error!)),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(liveRegion: true, child: Text(_message!, style: t.bodyLarge)),
            ),
          const SettingsSectionLabel('On this device'),
          SettingsRow(
            icon: Icons.storage_rounded,
            title: 'Learning progress',
            subtitle: SettingsCopy.storage(total),
          ),
          for (final d in tracks)
            SettingsRow(
              icon: Icons.folder_rounded,
              title: d.title,
              subtitle: SettingsCopy.formatBytes(_sizes[d.id] ?? 0),
            ),
          const SettingsRow(
            icon: Icons.offline_bolt_rounded,
            title: 'Offline AI models',
            subtitle: 'Stored separately. Manage them in Offline AI models.',
          ),
          const SettingsSectionLabel('Your data'),
          SettingsRow(
            icon: Icons.copy_all_rounded,
            title: 'Copy progress as JSON',
            subtitle: active == null
                ? 'Current discipline'
                : 'Current discipline: ${active.title}',
            onTap: _export,
          ),
          SettingsRow(
            icon: Icons.file_open_rounded,
            title: 'Import progress',
            subtitle: 'From a Sumi JSON export for this discipline',
            onTap: _import,
          ),
          if (active != null)
            SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: 'Clear ${active.title} progress',
              subtitle: 'Other disciplines and models are kept',
              onTap: () => _clear([active], active.title),
            ),
          SettingsRow(
            icon: Icons.delete_forever_rounded,
            title: 'Clear all progress',
            subtitle: 'Every discipline on this device · models are kept',
            onTap: () => _clear(tracks, 'every discipline'),
          ),
          SettingsRow(
            icon: Icons.restart_alt_rounded,
            title: 'Reset what Sumi has inferred',
            subtitle: 'Keeps progress and your explicit preferences',
            onTap: () async {
              await widget.onUpdate(
                (s) => s.adaptationProfile.resetInferredPreferences(),
              );
              if (mounted) {
                setState(() => _message = 'Inferred observations were reset.');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// SET-07: build metadata, licences and the AI-assistance disclosure.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: Text('About Sumi', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
        children: [
          Text(SettingsCopy.about(), style: t.titleLarge),
          const SizedBox(height: 4),
          Text('Application ID: ${BuildInfo.applicationId}', style: t.bodyMedium),
          const SizedBox(height: 20),
          Text('How Sumi works', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Sumi is offline-first. Your progress is stored on this device and is not encrypted. There is no account and no cloud sync.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Offline AI models', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Optional on-device models are open-weight Qwen GGUF files from their publishers, downloaded only when you choose and checked against a pinned SHA-256 hash. Each model keeps its own licence, shown on its card.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Lesson content', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Music and Fashion lesson text is original and was drafted with AI assistance. It has not been reviewed by a subject expert. Reviewed resources link to their original publishers.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Font', style: t.titleMedium),
          const SizedBox(height: 6),
          Text('Nunito, SIL Open Font License 1.1.', style: t.bodyLarge),
          const SizedBox(height: 24),
          TactileButton(
            'VIEW LICENCES',
            variant: TactileVariant.outline,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Sumi',
              applicationVersion: SettingsCopy.about(),
            ),
          ),
        ],
      ),
    );
  }
}
