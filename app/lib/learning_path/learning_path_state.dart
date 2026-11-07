import '../models.dart';

enum PathTrigger { none, unlock, completeNode, completeCheckpoint }

class LearningUnit {
  final String id, title, outcome;
  final int index, paletteIndex;
  final List<Milestone> nodes;
  LearningUnit({
    required this.id,
    required this.title,
    required this.outcome,
    required this.index,
    required this.paletteIndex,
    required List<Milestone> nodes,
    this.guide = const {},
  }) : nodes = List.unmodifiable(nodes);

  /// The unit's guide content from `units[].guide` (PTH-11), when authored.
  final Json guide;

  /// ARC-04 / plan 1.12: units come from `units[]` in the content data. Older
  /// content without units falls back to groups of three nodes.
  static List<LearningUnit> forCatalog(Catalog c) {
    if (c.milestones.isEmpty) {
      return [
        LearningUnit(
          id: '${c.id}:unit:0',
          title: c.title,
          outcome: c.description,
          index: 0,
          paletteIndex: 0,
          nodes: const [],
        ),
      ];
    }
    if (c.units.isNotEmpty) {
      final units = <LearningUnit>[];
      for (var i = 0; i < c.units.length; i++) {
        final u = c.units[i];
        final id = u['id'] as String? ?? '${c.id}:unit:$i';
        final nodes = c.milestones.where((m) => m.unitId == id).toList();
        if (nodes.isEmpty) continue;
        units.add(
          LearningUnit(
            id: id,
            index: units.length,
            title: u['title'] as String? ?? nodes.first.title,
            outcome: u['outcome'] as String? ?? nodes.last.deliverable,
            paletteIndex: ((u['palette'] as int?) ?? i) % 3,
            nodes: nodes,
            guide: u['guide'] is Map ? Json.from(u['guide']) : const {},
          ),
        );
      }
      // Nodes without a known unit are never dropped from the path.
      final placed = units.expand((u) => u.nodes).map((m) => m.id).toSet();
      final orphans = c.milestones.where((m) => !placed.contains(m.id));
      if (orphans.isNotEmpty) {
        units.add(
          LearningUnit(
            id: '${c.id}:unit:${units.length}',
            index: units.length,
            title: orphans.first.title,
            outcome: orphans.last.deliverable,
            paletteIndex: units.length % 3,
            nodes: orphans.toList(),
          ),
        );
      }
      if (units.isNotEmpty) return units;
    }
    return [
      for (var i = 0; i < c.milestones.length; i += 3)
        LearningUnit(
          id: '${c.id}:unit:${i ~/ 3}',
          index: i ~/ 3,
          title: c.milestones[i].title,
          outcome: c
              .milestones[(i + 2).clamp(0, c.milestones.length - 1)]
              .deliverable,
          paletteIndex: (i ~/ 3) % 3,
          nodes: c.milestones.skip(i).take(3).toList(),
        ),
    ];
  }
}

class PathNodePresentationState {
  final NodeState stableState;
  final bool isActive,
      isPressed,
      isCompleted,
      isMastered,
      showProgressRing,
      showCheckpointCrown,
      showBoostEffect,
      animateArrows,
      runCompletionCombo,
      animateIcon;
  final int paletteIndex, fromIconIndex, toIconIndex, starFlipMode;
  final PathTrigger pendingTrigger;
  final String? eventId;
  final double progress;
  const PathNodePresentationState({
    required this.stableState,
    this.isActive = false,
    this.isPressed = false,
    this.isCompleted = false,
    this.isMastered = false,
    this.showProgressRing = false,
    this.showCheckpointCrown = false,
    this.showBoostEffect = false,
    this.animateArrows = false,
    this.runCompletionCombo = false,
    this.animateIcon = false,
    this.paletteIndex = 0,
    this.fromIconIndex = 0,
    this.toIconIndex = 0,
    this.starFlipMode = 0,
    this.pendingTrigger = PathTrigger.none,
    this.eventId,
    this.progress = 0,
  });
}
