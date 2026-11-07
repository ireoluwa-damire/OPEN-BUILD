import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../theme.dart';
import '../graphics/sumi_graphics.dart';

/// SHL-05 (DC §8.1): boot screen. Copy appears only after one second.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  bool _slow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: SumiColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SumiWordmark(width: 144),
            const SizedBox(height: 24),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 8,
                color: SumiColors.primary,
                backgroundColor: SumiColors.disabled,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            if (_slow) ...[
              const SizedBox(height: 16),
              Text('Opening your learning space…', style: t.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// SHL-05 recovery: saved data is never silently reset.
class RecoveryScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onExport;
  final VoidCallback onStartFresh;
  const RecoveryScreen({
    super.key,
    required this.onRetry,
    required this.onStartFresh,
    this.onExport,
  });

  Future<void> _confirmFresh(BuildContext context) async {
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
              Text(
                'Start a fresh profile?',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your unreadable data stays stored on this device, but Sumi will start from the beginning for this discipline.',
                style: Theme.of(c).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TactileButton(
                'KEEP MY DATA',
                variant: TactileVariant.secondary,
                onPressed: () => Navigator.pop(c, false),
              ),
              const SizedBox(height: 8),
              TactileButton(
                'START FRESH',
                variant: TactileVariant.text,
                errorTone: true,
                onPressed: () => Navigator.pop(c, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) onStartFresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                icon: Icons.inventory_2_outlined,
                heading: 'We couldn’t open your progress',
                body: 'Your saved data is untouched.',
              ),
              TactileButton('TRY AGAIN', onPressed: onRetry),
              if (onExport != null) ...[
                const SizedBox(height: 12),
                TactileButton(
                  'EXPORT RECOVERY FILE',
                  variant: TactileVariant.outline,
                  onPressed: onExport,
                ),
              ],
              const SizedBox(height: 8),
              TactileButton(
                'START A FRESH PROFILE',
                variant: TactileVariant.text,
                onPressed: () => _confirmFresh(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
