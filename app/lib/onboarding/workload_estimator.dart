import '../models.dart';

/// ONB-07: "At {m} minutes a day, the first project is roughly {a}–{b}
/// sessions." Total node minutes up to and including the first project node,
/// divided by the daily minutes, then ±25 % (floor and ceiling). Always a
/// range, never a single number.
(int, int) estimateFirstProjectSessions(Catalog catalog, int minutesPerDay) {
  var total = 0;
  for (final m in catalog.milestones) {
    total += m.minutes;
    if (m.type == NodeType.projectStep) break;
  }
  if (total == 0) total = 60;
  final sessions = total / minutesPerDay;
  var low = (sessions * .75).floor();
  var high = (sessions * 1.25).ceil();
  if (low < 1) low = 1;
  if (high <= low) high = low + 1;
  return (low, high);
}
