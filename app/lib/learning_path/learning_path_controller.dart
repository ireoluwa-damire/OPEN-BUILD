import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services.dart';
import 'learning_path_state.dart';

class LearningPathController extends ChangeNotifier {
  final Catalog catalog;
  final LearningState learning;
  final LocalStore store;
  late final List<LearningUnit> units = LearningUnit.forCatalog(catalog);
  late String selectedUnitId;
  String? selectedNodeId, pressedNodeId, error;
  double scrollOffset = 0;
  Json? _event;
  bool _processing = false, _disposed = false;
  Timer? _scrollTimer;
  final Set<String> _pendingUnlocks = {};
  final Set<String> _pendingCompletions = {};
  LearningPathController({
    required this.catalog,
    required this.learning,
    required this.store,
  }) {
    selectedUnitId =
        learning.pathContext['unitId'] as String? ?? units.first.id;
    if (!units.any((u) => u.id == selectedUnitId)) {
      selectedUnitId = units.first.id;
    }
    selectedNodeId = learning.pathContext['nodeId'];
    scrollOffset = (learning.pathContext['offset'] as num? ?? 0).toDouble();
    refresh();
  }
  LearningUnit get unit => units.firstWhere((u) => u.id == selectedUnitId);
  Milestone? get selectedNode =>
      catalog.milestones.where((n) => n.id == selectedNodeId).firstOrNull;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void refresh() {
    _pendingCompletions.addAll(
      learning.pathEvents
          .where((e) => e['trigger'] == 'completeNode')
          .map((e) => e['nodeId'] as String),
    );
    _pendingUnlocks.addAll(
      learning.pathEvents
          .where((e) => e['trigger'] == 'unlock')
          .map((e) => e['nodeId'] as String),
    );
    _notify();
  }

  PathNodePresentationState presentation(Milestone node) {
    final complete = learning.completed.contains(node.id);
    final available = node.prerequisites.every(learning.completed.contains);
    final current =
        catalog.milestones
            .where(
              (n) =>
                  !learning.completed.contains(n.id) &&
                  n.prerequisites.every(learning.completed.contains),
            )
            .firstOrNull
            ?.id ==
        node.id;
    final activeSession = learning.sessions.values
        .where((s) => s['nodeId'] == node.id && s['result'] == null)
        .lastOrNull;
    final inProgress = activeSession != null;
    final progress = activeSession == null
        ? 0.0
        : (activeSession['attempts'] as List)
                  .where((a) => a['outcome'] == 'correct')
                  .map((a) => a['challengeId'])
                  .toSet()
                  .length /
              (activeSession['challenges'] as List).length;
    final unlocking = _pendingUnlocks.contains(node.id);
    final trigger = _event?['nodeId'] == node.id
        ? PathTrigger.values.byName(_event!['trigger'])
        : PathTrigger.none;
    final stable = complete
        ? NodeState.complete
        : !available
        ? NodeState.locked
        : unlocking
        // Look locked until this node's own unlock animation plays.
        ? (trigger == PathTrigger.unlock ? NodeState.available : NodeState.locked)
        : inProgress
        ? NodeState.inProgress
        : current
        ? NodeState.current
        : NodeState.available;
    final icon = node.type.index;
    return PathNodePresentationState(
      stableState: stable,
      isActive: (current || inProgress) && !unlocking && !complete,
      isPressed: pressedNodeId == node.id,
      isCompleted: complete,
      showProgressRing: inProgress && !complete,
      progress: progress,
      showCheckpointCrown: complete && node.type == NodeType.checkpoint,
      animateArrows: current && !unlocking,
      runCompletionCombo: trigger == PathTrigger.completeNode,
      animateIcon: trigger != PathTrigger.none,
      paletteIndex: unit.paletteIndex,
      fromIconIndex: complete && !_pendingCompletions.contains(node.id)
          ? 99
          : icon,
      toIconIndex: complete ? 99 : icon,
      starFlipMode: trigger == PathTrigger.completeCheckpoint ? 1 : 0,
      pendingTrigger: trigger,
      eventId: trigger == PathTrigger.none ? null : _event!['id'],
    );
  }

  void press(String? id) {
    pressedNodeId = id;
    _notify();
  }

  void select(String? id) {
    selectedNodeId = id == selectedNodeId ? null : id;
    _notify();
  }

  void dismiss() {
    selectedNodeId = null;
    _notify();
  }

  void scrollTo(double offset) {
    scrollOffset = offset;
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 200), () {
      persistContext();
    });
  }

  Future<bool> persistContext() async {
    _scrollTimer?.cancel();
    final context = {
      'unitId': selectedUnitId,
      'nodeId': selectedNodeId,
      'offset': scrollOffset,
    };
    try {
      await store.transaction(learning, (s) async {
        s.pathContext = context;
      });
      error = null;
      return true;
    } catch (_) {
      error = 'Couldn’t save your path position. Try again.';
      _notify();
      return false;
    }
  }

  Future<bool> selectUnit(String id) async {
    if (!units.any((u) => u.id == id)) return false;
    final old = selectedUnitId;
    final oldOffset = scrollOffset;
    selectedUnitId = id;
    scrollOffset = 0;
    selectedNodeId = null;
    if (!await persistContext()) {
      selectedUnitId = old;
      scrollOffset = oldOffset;
      return false;
    }
    _notify();
    return true;
  }

  /// Claim each persisted event before playing it. Rebuilds cannot replay it;
  /// a process kill during animation restores the already-persisted stable state.
  Future<void> playPending({required bool reducedMotion}) async {
    if (_processing) return;
    _processing = true;
    refresh();
    try {
      while (!_disposed && learning.pathEvents.isNotEmpty) {
        final next = Json.from(learning.pathEvents.first);
        final awaitingResult = learning.sessions.values.any(
          (s) =>
              s['result'] != null &&
              s['resultAcknowledged'] != true &&
              (next['id'] as String).startsWith('${s['sessionId']}:'),
        );
        if (awaitingResult) break;
        try {
          await store.transaction(learning, (s) async {
            s.pathEvents.removeWhere((e) => e['id'] == next['id']);
          });
        } catch (_) {
          error = 'Animation is waiting for a saved path update.';
          _notify();
          break;
        }
        if (_disposed) break;
        _event = next;
        _notify();
        if (!reducedMotion) {
          // Matches PathNodeWidget's 800 ms one-shot so events play in turn.
          await Future<void>.delayed(const Duration(milliseconds: 720));
        }
        _pendingUnlocks.remove(next['nodeId']);
        if (next['trigger'] == 'completeNode') {
          _pendingCompletions.remove(next['nodeId']);
        }
        _event = null;
        _notify();
      }
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollTimer?.cancel();
    super.dispose();
  }
}
