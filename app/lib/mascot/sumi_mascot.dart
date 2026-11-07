import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../theme.dart';
import 'reference_slots_debug.dart';
import 'sumi_rig.dart';

export 'sumi_rig.dart' show SumiAnim, SumiAnimGroup, SumiSkin;

/// Plays one [SumiAnim].
///
/// Looping animations run until the widget is removed (and pause with
/// [TickerMode]); one-shots play once, hold their last frame and call
/// [onFinished]. With [reducedMotion] the poster pose is painted and no ticker
/// runs, so screens still settle in tests and for motion-sensitive learners.
class SumiMascot extends StatefulWidget {
  final SumiAnim anim;
  final double size;
  final SumiSkin skin;
  final bool reducedMotion, darkMode, rtl;
  final String? semanticLabel;
  final VoidCallback? onFinished;

  /// Changing this replays a one-shot even if [anim] is unchanged.
  final Object? replayKey;
  const SumiMascot({
    super.key,
    required this.anim,
    this.size = 120,
    this.skin = SumiSkin.standard,
    this.reducedMotion = false,
    this.darkMode = false,
    this.rtl = false,
    this.semanticLabel,
    this.onFinished,
    this.replayKey,
  });
  @override
  State<SumiMascot> createState() => _SumiMascotState();
}

class _SumiMascotState extends State<SumiMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _elapsed = Duration.zero;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant SumiMascot old) {
    super.didUpdateWidget(old);
    if (old.anim != widget.anim ||
        old.replayKey != widget.replayKey ||
        old.reducedMotion != widget.reducedMotion) {
      _start();
    }
  }

  void _start() {
    _ticker.stop();
    _elapsed = Duration.zero;
    _done = false;
    if (!widget.reducedMotion) _ticker.start();
  }

  void _tick(Duration elapsed) {
    setState(() => _elapsed = elapsed);
    if (!widget.anim.loops &&
        elapsed.inMilliseconds >= widget.anim.durationMs &&
        !_done) {
      _done = true;
      _ticker.stop();
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anim;
    final ms = _elapsed.inMilliseconds;
    double progress, time;
    if (widget.reducedMotion) {
      progress = a.posterProgress;
      time = progress * a.durationMs / 1000;
    } else if (a.loops) {
      progress = (ms % a.durationMs) / a.durationMs;
      time = ms / 1000;
    } else {
      progress = (ms / a.durationMs).clamp(0.0, 1.0);
      time = ms / 1000;
    }
    final paint = CustomPaint(
      size: Size.square(widget.size),
      painter: SumiPainter(
        anim: a,
        progress: progress,
        time: time,
        skin: widget.skin,
        darkMode: widget.darkMode,
        rtl: widget.rtl,
      ),
    );
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(
            image: true,
            label: widget.semanticLabel,
            child: ExcludeSemantics(child: paint),
          );
  }
}

/// Developer gallery of every Sumi animation. Reachable in debug builds only.
class SumiGalleryScreen extends StatefulWidget {
  final bool reducedMotion;
  const SumiGalleryScreen({super.key, this.reducedMotion = false});
  @override
  State<SumiGalleryScreen> createState() => _SumiGalleryScreenState();
}

class _SumiGalleryScreenState extends State<SumiGalleryScreen> {
  SumiSkin skin = SumiSkin.standard;
  bool dark = false, rtl = false;
  final Map<SumiAnim, int> replays = {};

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF131629) : SumiColors.surfaceSoft;
    return Scaffold(
      appBar: AppBar(title: const Text('Sumi animation library')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${SumiAnim.values.length} original animations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SumiSkin.values)
                ChoiceChip(
                  label: Text(s.name),
                  selected: skin == s,
                  onSelected: (_) => setState(() => skin = s),
                ),
              FilterChip(
                label: const Text('dark'),
                selected: dark,
                onSelected: (v) => setState(() => dark = v),
              ),
              FilterChip(
                label: const Text('right-to-left'),
                selected: rtl,
                onSelected: (v) => setState(() => rtl = v),
              ),
            ],
          ),
          for (final g in SumiAnimGroup.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                g.label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final a in SumiAnim.values.where((a) => a.group == g))
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(
                    () => replays[a] = (replays[a] ?? 0) + 1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        color: bg,
                        child: SumiMascot(
                          anim: a,
                          size: 104,
                          skin: skin,
                          darkMode: dark,
                          rtl: rtl,
                          reducedMotion: widget.reducedMotion,
                          replayKey: replays[a],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(a.role),
                            if (kDebugMode)
                              Text(
                                'Research ref: ${debugReferenceSlots[a.name] ?? '-'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              '${a.loops ? 'Loops' : 'Plays once · tap to replay'} · ${a.durationMs} ms',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
