import '../models.dart' show Json;

/// One capability's review schedule (EVD-03). Stored per node in
/// `LearningState.reviewSchedule`.
class ReviewItem {
  final String nodeId;
  final DateTime dueAt;

  /// The outcome that set this schedule: `incorrect`, `hinted`,
  /// `independent`, `recalled` or `transferred`.
  final String outcome;

  /// Human reason shown wherever the item is due. Never empty.
  final String reason;
  final DateTime updatedAt;

  const ReviewItem({
    required this.nodeId,
    required this.dueAt,
    required this.outcome,
    required this.reason,
    required this.updatedAt,
  });

  bool due(DateTime now) => !now.isBefore(dueAt);

  Json toJson() => {
    'node_id': nodeId,
    'due_at': dueAt.toIso8601String(),
    'outcome': outcome,
    'reason': reason,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ReviewItem.fromJson(Json j) => ReviewItem(
    nodeId: j['node_id'] ?? '',
    dueAt: DateTime.tryParse(j['due_at'] ?? '') ?? DateTime.now(),
    outcome: j['outcome'] ?? 'independent',
    reason: (j['reason'] as String?)?.isNotEmpty == true
        ? j['reason']
        : 'Time to bring this back.',
    updatedAt: DateTime.tryParse(j['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// S1 §12.4 review rules (EVD-03).
///
/// | Outcome       | Next review                       |
/// |---------------|-----------------------------------|
/// | Incorrect     | repair in-lesson, plus next day   |
/// | Hinted        | +1 day                            |
/// | Independent   | +2 days                           |
/// | Recalled      | +5 days                           |
/// | Transferred   | +10 days                          |
/// | New failure   | pull forward; keep earlier evidence |
abstract final class ReviewScheduler {
  static const intervals = {
    'incorrect': 1,
    'hinted': 1,
    'independent': 2,
    'recalled': 5,
    'transferred': 10,
  };

  static const _reasons = {
    'incorrect': 'You had a tricky moment here. A short repair helps it stick.',
    'hinted': 'You used a hint last time. Try it on your own now.',
    'independent': 'You got this right. Recall it after a short gap.',
    'recalled': 'You recalled this. A longer gap keeps it strong.',
    'transferred':
        'You used this in a new context. A final check keeps it fresh.',
  };

  /// Local midnight [days] after [now], so a review becomes due at the start
  /// of a calendar day rather than at an arbitrary hour.
  static DateTime _dayStart(DateTime now, int days) {
    final local = now.toLocal();
    return DateTime(local.year, local.month, local.day + days);
  }

  /// The next schedule after [outcome] on [nodeId]. A new failure pulls an
  /// existing, later review forward to the next day; it never pushes an
  /// earlier review back. Earlier evidence is not changed here.
  static ReviewItem schedule({
    required String nodeId,
    required String outcome,
    required DateTime now,
    ReviewItem? previous,
  }) {
    final days = intervals[outcome] ?? 2;
    var dueAt = _dayStart(now, days);
    final failure = outcome == 'incorrect';
    if (failure && previous != null && previous.dueAt.isBefore(dueAt)) {
      dueAt = previous.dueAt;
    }
    return ReviewItem(
      nodeId: nodeId,
      dueAt: dueAt,
      outcome: outcome,
      reason: _reasons[outcome] ?? 'Time to bring this back.',
      updatedAt: now,
    );
  }

  /// Items due at [now], earliest first.
  static List<ReviewItem> dueItems(
    Map<String, ReviewItem> schedule,
    DateTime now,
  ) =>
      schedule.values.where((r) => r.due(now)).toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  /// The next item that is not yet due, if any (Practice empty state).
  static ReviewItem? nextUpcoming(
    Map<String, ReviewItem> schedule,
    DateTime now,
  ) {
    final upcoming = schedule.values.where((r) => !r.due(now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return upcoming.firstOrNull;
  }
}
