import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../motion/celebration.dart';
import '../unit_guide_screen.dart';
import 'learning_path_state.dart';
import 'learning_path_controller.dart';
import '../effects/effects_service.dart';
import '../graphics/sumi_graphics.dart';
import '../engagement/points_policy.dart';
import '../engagement/quest_card.dart';
import '../engagement/quests.dart';
import '../learning_session/challenge_definition.dart';

class PathScreen extends StatefulWidget {
  final Catalog catalog;
  final LearningState learning;
  final LocalStore store;
  /// Resolves to true when the learner chose CONTINUE on the result screen.
  final Future<bool?> Function(Milestone) onOpenMilestone;
  final Future<void> Function(Resource) onOpenResource;
  final VoidCallback onAssess, onAskTutor;
  const PathScreen({
    super.key,
    required this.catalog,
    required this.learning,
    required this.store,
    required this.onOpenMilestone,
    required this.onOpenResource,
    required this.onAssess,
    required this.onAskTutor,
  });
  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> with WidgetsBindingObserver {
  late final controller = LearningPathController(
    catalog: widget.catalog,
    learning: widget.learning,
    store: widget.store,
  );
  late final scroll = ScrollController(
    initialScrollOffset: controller.scrollOffset,
  );
  final stackKey = GlobalKey();
  final nodeKeys = <String, GlobalKey>{};
  Rect? anchor;
  bool launching = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(() {
      controller.scrollTo(scroll.offset);
      if (anchor != null) {
        anchor = null;
        controller.dismiss();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.playPending(
        reducedMotion:
            widget.learning.reducedMotion ||
            MediaQuery.disableAnimationsOf(context),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.persistContext();
    }
  }

  Future<void> start(Milestone node) async {
    if (launching) return;
    setState(() => launching = true);
    if (!await controller.persistContext()) {
      if (mounted) setState(() => launching = false);
      return;
    }
    final openNext = await widget.onOpenMilestone(node) == true;
    if (!mounted) return;
    setState(() {
      launching = false;
      anchor = null;
    });
    controller.dismiss();
    controller.refresh();
    await controller.playPending(
      reducedMotion:
          widget.learning.reducedMotion ||
          MediaQuery.disableAnimationsOf(context),
    );
    // RES-04: after the events, open the anchored card on the new current
    // node. RETURN TO PATH skips this.
    if (!openNext || !mounted) return;
    final next = widget.learning.current(widget.catalog);
    if (next == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) select(next);
    });
  }

  void select(Milestone node) {
    final box =
        nodeKeys[node.id]?.currentContext?.findRenderObject() as RenderBox?;
    final stack = stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null) return;
    anchor = stack.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
    controller.select(node.id);
  }

  Future<void> sections() async {
    if (!await controller.persistContext() || !mounted) return;
    final unitId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SectionOverviewScreen(controller: controller),
      ),
    );
    if (unitId != null && mounted && await controller.selectUnit(unitId)) {
      anchor = null;
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  Future<void> guide() async {
    if (!await controller.persistContext() || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => UnitGuideScreen(
          catalog: widget.catalog,
          learning: widget.learning,
          unit: controller.unit,
          onOpenResource: widget.onOpenResource,
          onAskTutor: widget.onAskTutor,
          onStartPractice: () {
            final node = controller.unit.nodes
                .where(
                  (n) =>
                      n.prerequisites.every(widget.learning.completed.contains),
                )
                .firstOrNull;
            if (node != null) start(node);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final node = controller.selectedNode;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.catalog.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // PTH-02: streak and points (Focus is lesson-only, CF-15). The
          // tutor is reached from the guide and lessons, not the path (TUT-01).
          actions: [
            PathStatusRow(engagement: widget.learning.engagement),
            IconButton(
              tooltip: 'Sections',
              onPressed: sections,
              icon: const Icon(Icons.view_list_rounded),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, bounds) {
            final width = math.min(340.0, bounds.maxWidth - 24);
            final height = math.min(
              MediaQuery.textScalerOf(context).scale(1) > 1.4 ? 310.0 : 220.0,
              bounds.maxHeight - 24,
            );
            final selectedAnchor = anchor;
            final left = selectedAnchor == null
                ? 12.0
                : (selectedAnchor.center.dx - width / 2).clamp(
                    12.0,
                    bounds.maxWidth - width - 12,
                  );
            final below =
                selectedAnchor == null || selectedAnchor.top < height + 12;
            final top = selectedAnchor == null
                ? 12.0
                : (below
                          ? selectedAnchor.bottom + 8
                          : selectedAnchor.top - height - 8)
                      .clamp(
                        12.0,
                        math.max(12.0, bounds.maxHeight - height - 12),
                      )
                      .toDouble();
            return Stack(
              key: stackKey,
              children: [
                ListView(
                  controller: scroll,
                  key: PageStorageKey('path:${widget.catalog.id}'),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                  children: [
                    QuestCard(
                      quests: DailyQuests.of(
                        widget.learning,
                        EngagementState.clock(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    UnitHeaderCard(
                      unit: controller.unit,
                      learning: widget.learning,
                      onOpenGuidebook: guide,
                      onOpenSections: sections,
                    ),
                    if (controller.error != null)
                      TextButton(
                        onPressed: controller.persistContext,
                        child: Text(controller.error!),
                      ),
                    if (!widget.learning.baselineDone(widget.catalog))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: widget.onAssess,
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Find your starting point'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Learning Path',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SerpentinePath(
                      controller: controller,
                      nodeKeys: nodeKeys,
                      onSelectNode: select,
                    ),
                    if (controller.units.length > 1)
                      TextButton(
                        onPressed: sections,
                        child: const Text('Explore all units'),
                      ),
                  ],
                ),
                if (node != null && selectedAnchor != null)
                  Positioned(
                    left: (selectedAnchor.center.dx - 8).clamp(
                      left + 16,
                      left + width - 32,
                    ),
                    top: below ? top - 7 : top + height - 9,
                    width: 16,
                    height: 16,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
                if (node != null && selectedAnchor != null)
                  Positioned(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    child: TapRegion(
                      groupId: controller,
                      onTapOutside: (_) {
                        anchor = null;
                        controller.dismiss();
                      },
                      child: NodeActionOverlay(
                        milestone: node,
                        state: controller.presentation(node),
                        reason: widget.learning.reason(node, widget.catalog),
                        busy: launching,
                        baseReward: PointsPolicy.baseReward(
                          node,
                          challengesFor(widget.catalog, node).length,
                        ),
                        prerequisite: widget.catalog.milestones
                            .where(
                              (m) =>
                                  node.prerequisites.contains(m.id) &&
                                  !widget.learning.completed.contains(m.id),
                            )
                            .firstOrNull,
                        onGoTo: (prereq) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) select(prereq);
                          });
                        },
                        onStart: () => start(node),
                        onClose: () {
                          anchor = null;
                          controller.dismiss();
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

// CF-13: unit hues are design tokens.
const _palettes = [SumiColors.unitTeal, SumiColors.unitPlum, SumiColors.unitOlive];

/// PTH-02 (DC §7.13): streak and points pills. Tapping points shows the
/// weekly total and what points mean (DC §7.26).
class PathStatusRow extends StatelessWidget {
  final EngagementState engagement;
  const PathStatusRow({super.key, required this.engagement});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget pill(SumiGlyphKind icon, Color color, String value, String label, {VoidCallback? onTap}) =>
        Semantics(
          button: onTap != null,
          label: '$value $label',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SumiRadius.pill),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SumiGlyph(icon, size: 20, color: color),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: t.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(
          SumiGlyphKind.flame,
          SumiColors.warningInk,
          '${engagement.streakDays}',
          'day streak',
        ),
        pill(
          SumiGlyphKind.points,
          SumiColors.successInk,
          '${engagement.pointsTotal}',
          'points',
          onTap: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              content: Text(
                '${engagement.pointsWeek} points this week · Points measure practice, not mastery.',
                style: t.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UnitHeaderCard extends StatelessWidget {
  final LearningUnit unit;
  final LearningState learning;
  final VoidCallback onOpenGuidebook, onOpenSections;
  const UnitHeaderCard({
    super.key,
    required this.unit,
    required this.learning,
    required this.onOpenGuidebook,
    required this.onOpenSections,
  });
  @override
  Widget build(BuildContext context) {
    final completed = unit.nodes
        .where((n) => learning.completed.contains(n.id))
        .length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _palettes[unit.paletteIndex],
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'UNIT ${unit.index + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Unit Guidebook',
                onPressed: onOpenGuidebook,
                icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
            ],
          ),
          Text(
            unit.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(unit.outcome, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: unit.nodes.isEmpty ? 0 : completed / unit.nodes.length,
            color: Colors.white,
            backgroundColor: Colors.white24,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed / ${unit.nodes.length} steps',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class SerpentinePath extends StatelessWidget {
  final LearningPathController controller;
  final Map<String, GlobalKey> nodeKeys;
  final void Function(Milestone) onSelectNode;
  const SerpentinePath({
    super.key,
    required this.controller,
    required this.nodeKeys,
    required this.onSelectNode,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < controller.unit.nodes.length; i++)
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (i == 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ExcludeSemantics(
                    child: DisciplineScene(
                      scene: controller.catalog.scene,
                      size: 120,
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(math.sin(i * math.pi / 2) * 68, 0),
                child: TapRegion(
                  groupId: controller,
                  child: PathNodeWidget(
                    key: nodeKeys.putIfAbsent(
                      controller.unit.nodes[i].id,
                      () => GlobalKey(),
                    ),
                    milestone: controller.unit.nodes[i],
                    state: controller.presentation(controller.unit.nodes[i]),
                    reducedMotion:
                        controller.learning.reducedMotion ||
                        MediaQuery.disableAnimationsOf(context),
                    onPress: (down) => controller.press(
                      down ? controller.unit.nodes[i].id : null,
                    ),
                    onTap: () => onSelectNode(controller.unit.nodes[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class PathNodeWidget extends StatefulWidget {
  final Milestone milestone;
  final PathNodePresentationState state;
  final bool reducedMotion;
  final VoidCallback onTap;
  final void Function(bool) onPress;
  const PathNodeWidget({
    super.key,
    required this.milestone,
    required this.state,
    required this.onTap,
    required this.onPress,
    required this.reducedMotion,
  });
  @override
  State<PathNodeWidget> createState() => _PathNodeWidgetState();
}

/// Plays one original animation per persisted path event (unlock, complete,
/// checkpoint). The event id guards against replays on rebuild; the animation
/// keeps running after the controller clears the event so it never cuts off.
class _PathNodeWidgetState extends State<PathNodeWidget>
    with SingleTickerProviderStateMixin {
  static const duration = Duration(milliseconds: 800);
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: duration,
  );
  String? playedEventId;
  PathTrigger playing = PathTrigger.none;

  @override
  void initState() {
    super.initState();
    _maybePlay();
  }

  @override
  void didUpdateWidget(covariant PathNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    final s = widget.state;
    if (s.eventId == null ||
        s.pendingTrigger == PathTrigger.none ||
        s.eventId == playedEventId) {
      return;
    }
    playedEventId = s.eventId;
    playing = s.pendingTrigger;
    if (widget.reducedMotion) {
      motion.value = 1;
      return;
    }
    // SND-01/02: event sound and haptic, gated by the learner's settings.
    EffectsService.instance.feedback(
      s.pendingTrigger == PathTrigger.unlock
          ? SumiSound.nodeUnlock
          : SumiSound.nodeComplete,
      SumiHaptic.light,
    );
    motion.forward(from: 0);
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  double _scale(double t) {
    if (!motion.isAnimating) return 1;
    return switch (playing) {
      PathTrigger.unlock => TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: .78, end: .78),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween(begin: .78, end: 1.18)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40,
        ),
      ]).transform(t),
      PathTrigger.completeNode || PathTrigger.completeCheckpoint =>
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: .9)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 15,
          ),
          TweenSequenceItem(
            tween: Tween(begin: .9, end: 1.16)
                .chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 1.16, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).transform(t),
      PathTrigger.none => 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final milestone = widget.milestone;
    final locked = state.stableState == NodeState.locked;
    final base = locked ? SumiColors.disabled : _palettes[state.paletteIndex];
    final checkpointDone = state.showCheckpointCrown;
    // Phase 9: original node glyphs (DC §5), not Material icons.
    final typeIcon = locked
        ? SumiGlyphKind.lock
        : glyphForNode(milestone.type);
    final settledIcon = checkpointDone
        ? SumiGlyphKind.checkpoint
        : state.fromIconIndex == 99
        ? SumiGlyphKind.check
        : typeIcon;
    return Semantics(
      button: true,
      label: '${milestone.title}, ${state.stableState.name}',
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, _) {
          final t = motion.value;
          final animating = motion.isAnimating;
          var color = checkpointDone ? SumiColors.amber : base;
          var icon = settledIcon;
          var iconTurn = 0.0;
          var iconShake = 0.0;
          if (animating && playing == PathTrigger.unlock) {
            // Grey + shaking lock, then colour floods in and the icon pops.
            final flood = ((t - .3) / .25).clamp(0.0, 1.0);
            color = Color.lerp(SumiColors.disabled, base, flood)!;
            if (t < .32) {
              icon = SumiGlyphKind.lock;
              iconShake = math.sin(t / .32 * math.pi * 4) * .22;
            }
          } else if (animating &&
              (playing == PathTrigger.completeNode ||
                  playing == PathTrigger.completeCheckpoint)) {
            // Icon flips edge-on and lands on the completed face.
            final flip = (t / .5).clamp(0.0, 1.0);
            iconTurn = math.sin(flip * math.pi) * (math.pi / 2);
            if (flip < .5) icon = typeIcon;
            if (playing == PathTrigger.completeCheckpoint) {
              color = Color.lerp(base, SumiColors.amber, flip)!;
            }
          }
          final depth = locked
              ? SumiColors.borderShadow
              : Color.lerp(color, Colors.black, .25)!;
          final burstColor = playing == PathTrigger.completeCheckpoint
              ? SumiColors.amber
              : playing == PathTrigger.unlock
              ? base
              : SumiColors.primary;
          return SizedBox(
            width: 100,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (animating)
                  Positioned(
                    left: -20,
                    top: -16,
                    width: 140,
                    height: 140,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: SparkBurstPainter(
                          t: t,
                          color: burstColor,
                          rays: playing == PathTrigger.completeCheckpoint
                              ? 12
                              : 8,
                          stars: playing != PathTrigger.unlock,
                        ),
                      ),
                    ),
                  ),
                if (state.isActive || state.showProgressRing)
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      value: state.showProgressRing ? state.progress : 1,
                      strokeWidth: 5,
                      color: base.withValues(alpha: .35),
                      backgroundColor: SumiColors.surfaceSoft,
                    ),
                  ),
                if (state.animateArrows)
                  Positioned(
                    top: -30,
                    child: IgnorePointer(
                      child: _StartBubble(
                        color: base,
                        label: state.showProgressRing ? 'CONTINUE' : 'START',
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: _scale(t),
                  child: Container(
                    width: 76,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: depth,
                    ),
                    child: AnimatedAlign(
                      duration: Duration(
                        milliseconds: widget.reducedMotion ? 0 : 90,
                      ),
                      alignment: state.isPressed
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: SizedBox(
                        width: 76,
                        height: 74,
                        child: Material(
                          color: color,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onTap,
                            onHighlightChanged: widget.onPress,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft top highlight gives the tactile look.
                                if (!locked)
                                  Positioned(
                                    top: 10,
                                    child: Container(
                                      width: 34,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .28,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(iconTurn)
                                    ..rotateZ(iconShake),
                                  child: SumiGlyph(
                                    icon,
                                    color: locked && !animating
                                        ? SumiColors.disabledText
                                        : Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StartBubble extends StatelessWidget {
  final Color color;
  final String label;
  const _StartBubble({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SumiColors.border, width: 2),
          ),
          child: Text(
            label,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: .6,
            ),
          ),
        ),
        CustomPaint(size: const Size(14, 7), painter: _TailPainter()),
      ],
    ),
  );
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = SumiColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NodeActionOverlay extends StatelessWidget {
  final Milestone milestone;
  final PathNodePresentationState state;
  final String reason;
  final bool busy;
  final VoidCallback onStart, onClose;

  /// AMB-02: points guaranteed on first completion.
  final int baseReward;

  /// PTH-09: the first unfinished prerequisite of a locked node.
  final Milestone? prerequisite;
  final void Function(Milestone prerequisite)? onGoTo;
  const NodeActionOverlay({
    super.key,
    required this.milestone,
    required this.state,
    required this.reason,
    required this.onStart,
    required this.onClose,
    this.busy = false,
    this.baseReward = 0,
    this.prerequisite,
    this.onGoTo,
  });

  static String typeLabel(NodeType t) => switch (t) {
    NodeType.microLesson => 'LESSON',
    NodeType.guidedPractice => 'PRACTICE',
    NodeType.videoResource => 'VIDEO',
    NodeType.recallReview => 'REVIEW',
    NodeType.projectStep => 'PROJECT',
    NodeType.checkpoint => 'CHECKPOINT',
    NodeType.rewardUnlock => 'REWARD',
  };

  /// DC §11.2 node CTAs.
  String get ctaLabel {
    if (busy) return 'OPENING…';
    if (state.isCompleted) return 'PRACTISE AGAIN';
    return switch (milestone.type) {
      NodeType.checkpoint => 'START CHECKPOINT',
      NodeType.recallReview => 'REVIEW +$baseReward POINTS',
      _ => 'START +$baseReward POINTS',
    };
  }
  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(20),
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.stableState == NodeState.locked
                      ? 'LOCKED'
                      : '${typeLabel(milestone.type)} · ${milestone.minutes} MIN',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close node card',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.stableState == NodeState.locked
                        ? prerequisite == null
                              ? 'Finish the earlier steps to unlock this step.'
                              : 'Finish “${prerequisite!.title}” to unlock this step.'
                        : reason,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.stableState == NodeState.locked)
            FilledButton(
              onPressed: prerequisite == null || onGoTo == null
                  ? null
                  : () => onGoTo!(prerequisite!),
              child: Text(
                prerequisite == null
                    ? 'LOCKED'
                    : 'GO TO ${prerequisite!.title.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            FilledButton(
              onPressed: busy ? null : onStart,
              child: Text(ctaLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    ),
  );
}

class SectionOverviewScreen extends StatelessWidget {
  final LearningPathController controller;
  const SectionOverviewScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sections & units')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          controller.catalog.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        for (final unit in controller.units)
          Card(
            child: ListTile(
              title: Text('Unit ${unit.index + 1} · ${unit.title}'),
              subtitle: Text(unit.outcome),
              trailing: Text(
                '${unit.nodes.where((n) => controller.learning.completed.contains(n.id)).length}/${unit.nodes.length}',
              ),
              onTap: () => Navigator.pop(context, unit.id),
            ),
          ),
      ],
    ),
  );
}


