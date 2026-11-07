import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart' show NodeType;
import '../theme.dart';

/// Phase 9 original graphics (GOV-04, DC §5, §12). Everything is drawn in
/// code: no image files, no third-party artwork.
///
/// Shape language: every object is a flat fill with a crisp darker edge
/// offset below it, the same depth the app's buttons use (DC §4.4). The one
/// signature element is the brush-ink route line that links things: it runs
/// through the onboarding hero and behind each path scene.

/// DC §2.2 shadow rule: base × 0.75 per channel.
Color edgeOf(Color c) => Color.fromARGB(
  (c.a * 255).round(),
  (c.r * 255 * .75).round(),
  (c.g * 255 * .75).round(),
  (c.b * 255 * .75).round(),
);

/// Draws [path] as a tactile piece: the edge copy [depth] below, then the face.
void tactile(Canvas canvas, Path path, Color fill, {double depth = 2, Color? edge}) {
  canvas.drawPath(path.shift(Offset(0, depth)), Paint()..color = edge ?? edgeOf(fill));
  canvas.drawPath(path, Paint()..color = fill);
}

/// The signature brush-ink route: a stroke that swells and thins along
/// [points], drawn as overlapping round dabs so it reads as one brush pass.
void inkRoute(
  Canvas canvas,
  List<Offset> points, {
  required double width,
  Color color = SumiColors.ink,
  double opacity = 1,
}) {
  if (points.length < 2) return;
  // Dabs are opaque inside one translucent layer, so overlaps never darken.
  final paint = Paint()..color = color;
  final layered = opacity < 1;
  if (layered) {
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  }
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length - 1; i++) {
    final mid = Offset.lerp(points[i], points[i + 1], .5)!;
    path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  for (final metric in path.computeMetrics()) {
    // Dense dabs so the stroke reads as one continuous brush pass.
    final steps = math.max(24, (metric.length / (width * .12)).round());
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final pos = metric.getTangentForOffset(metric.length * t)?.position;
      if (pos == null) continue;
      // Pressure: thin at the start, full in the middle, a dry tail.
      final pressure = math.sin(math.pi * math.min(1, t * 1.1)) * .55 + .45;
      canvas.drawCircle(pos, width / 2 * pressure, paint);
    }
  }
  if (layered) canvas.restore();
}

// ---------------------------------------------------------------- glyphs

/// Icon families from DC §5 (24 px grid, rounded joins).
enum SumiGlyphKind {
  // Node set.
  lesson,
  practice,
  review,
  video,
  project,
  checkpoint,
  chest,
  lock,
  check,
  // Rewards.
  flame,
  spark,
  points,
  shield,
  quest,
  // Exercise formats.
  choice,
  order,
  match,
  write,
  observe,
  tap,
  sketch,
  report,
  // Models.
  chip,
  download,
}

/// The node-set glyph for a path node type (DC §5).
SumiGlyphKind glyphForNode(NodeType t) => switch (t) {
  NodeType.microLesson => SumiGlyphKind.lesson,
  NodeType.guidedPractice => SumiGlyphKind.practice,
  NodeType.recallReview => SumiGlyphKind.review,
  NodeType.videoResource => SumiGlyphKind.video,
  NodeType.projectStep => SumiGlyphKind.project,
  NodeType.checkpoint => SumiGlyphKind.checkpoint,
  NodeType.rewardUnlock => SumiGlyphKind.chest,
};

/// An original filled icon. Decorative by default (excluded from semantics);
/// pass [semanticLabel] when the icon alone carries meaning.
class SumiGlyph extends StatelessWidget {
  final SumiGlyphKind kind;
  final double size;
  final Color color;
  final String? semanticLabel;
  const SumiGlyph(
    this.kind, {
    super.key,
    this.size = 24,
    this.color = SumiColors.ink,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(kind, color),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class _GlyphPainter extends CustomPainter {
  final SumiGlyphKind kind;
  final Color color;
  _GlyphPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cut = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    RRect rr(double l, double t, double w, double h, double r) =>
        RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(r));

    switch (kind) {
      case SumiGlyphKind.lesson:
        // An ink drop: the first mark of a new idea.
        final p = Path()
          ..moveTo(12, 2.5)
          ..cubicTo(15.5, 7.5, 19.5, 11.5, 19.5, 15)
          ..arcToPoint(const Offset(4.5, 15), radius: const Radius.circular(7.5))
          ..cubicTo(4.5, 11.5, 8.5, 7.5, 12, 2.5)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 15), radius: 4), 2.4, 1.1, false, cut);
      case SumiGlyphKind.practice:
        // A small deck of practice cards.
        canvas.drawRRect(rr(7.5, 3, 13, 15, 3), Paint()..color = color.withValues(alpha: .4));
        canvas.drawRRect(rr(3.5, 7, 13, 15, 3), fill);
        canvas.drawLine(const Offset(7, 12.5), const Offset(13, 12.5), cut);
        canvas.drawLine(const Offset(7, 16.5), const Offset(11, 16.5), cut);
      case SumiGlyphKind.review:
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 12), radius: 7.5), -0.6, 4.9, false, stroke);
        final head = Path()
          ..moveTo(19.8, 4.2)
          ..lineTo(20.2, 10.6)
          ..lineTo(14.2, 8.8)
          ..close();
        canvas.drawPath(head, fill..strokeJoin = StrokeJoin.round);
      case SumiGlyphKind.video:
        canvas.drawRRect(rr(2.5, 4.5, 19, 15, 4.5), fill);
        final tri = Path()
          ..moveTo(10, 8.5)
          ..lineTo(15.5, 12)
          ..lineTo(10, 15.5)
          ..close();
        canvas.drawPath(tri, Paint()..color = Colors.white);
      case SumiGlyphKind.project:
        // A pencil at work.
        canvas.save();
        canvas.translate(12, 12);
        canvas.rotate(-math.pi / 4);
        canvas.drawRRect(rr(-3, -9.5, 6, 14, 2), fill);
        final tip = Path()
          ..moveTo(-3, 5.5)
          ..lineTo(0, 10)
          ..lineTo(3, 5.5)
          ..close();
        canvas.drawPath(tip, fill);
        canvas.drawLine(const Offset(-3, -5.5), const Offset(3, -5.5), cut);
        canvas.restore();
      case SumiGlyphKind.checkpoint:
        // A seal stamp (hanko): proof the unit was passed.
        // The same flag as the onboarding hero's destination: unit reached.
        canvas.drawLine(const Offset(6, 21.5), const Offset(6, 3), stroke);
        final flag = Path()
          ..moveTo(7.5, 3.5)
          ..quadraticBezierTo(13, 1.5, 20, 4.5)
          ..lineTo(18, 9)
          ..lineTo(20, 13.5)
          ..quadraticBezierTo(13, 10.5, 7.5, 12.5)
          ..close();
        canvas.drawPath(flag, fill);
      case SumiGlyphKind.chest:
        canvas.drawRRect(rr(3.5, 10, 17, 11, 2.5), fill);
        canvas.drawRRect(rr(2.5, 6.5, 19, 5, 2), fill);
        canvas.drawLine(const Offset(12, 7), const Offset(12, 20.5), cut);
        final bow = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.25
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromLTWH(7.5, 2, 4.5, 5), 0.3, 3.9, false, bow);
        canvas.drawArc(Rect.fromLTWH(12, 2, 4.5, 5), -1.1, 3.9, false, bow);
      case SumiGlyphKind.lock:
        canvas.drawArc(Rect.fromLTWH(7, 3, 10, 12), math.pi, math.pi, false, stroke);
        canvas.drawLine(const Offset(7, 9), const Offset(7, 11), stroke);
        canvas.drawLine(const Offset(17, 9), const Offset(17, 11), stroke);
        canvas.drawRRect(rr(4.5, 10.5, 15, 11, 3), fill);
        canvas.drawCircle(const Offset(12, 15.5), 1.6, Paint()..color = Colors.white);
      case SumiGlyphKind.check:
        final p = Path()
          ..moveTo(5, 12.5)
          ..lineTo(10, 17.5)
          ..lineTo(19, 7);
        canvas.drawPath(p, stroke..strokeWidth = 3.25);
      case SumiGlyphKind.flame:
        final p = Path()
          ..moveTo(12, 2.5)
          ..cubicTo(13, 6.5, 19.5, 9, 19.5, 15)
          ..arcToPoint(const Offset(4.5, 15), radius: const Radius.circular(7.5))
          ..cubicTo(4.5, 12, 6.5, 10, 8, 8.5)
          ..cubicTo(8.5, 11, 9.5, 12, 10.5, 12.5)
          ..cubicTo(10, 8.5, 11, 5, 12, 2.5)
          ..close();
        canvas.drawPath(p, fill);
        final inner = Path()
          ..moveTo(12, 13)
          ..cubicTo(14.5, 15, 15.5, 16.5, 15, 18)
          ..arcToPoint(const Offset(9, 18), radius: const Radius.circular(3.2))
          ..cubicTo(9, 16.5, 10.5, 15, 12, 13)
          ..close();
        canvas.drawPath(inner, Paint()..color = Colors.white.withValues(alpha: .7));
      case SumiGlyphKind.spark:
        final p = Path()
          ..moveTo(12, 2.5)
          ..quadraticBezierTo(13.2, 10.8, 21.5, 12)
          ..quadraticBezierTo(13.2, 13.2, 12, 21.5)
          ..quadraticBezierTo(10.8, 13.2, 2.5, 12)
          ..quadraticBezierTo(10.8, 10.8, 12, 2.5)
          ..close();
        canvas.drawPath(p, fill);
      case SumiGlyphKind.points:
        // An eight-ray burst: practice adds up.
        final p = Path();
        for (var i = 0; i < 16; i++) {
          final r = i.isEven ? 10.0 : 5.6;
          final a = -math.pi / 2 + i * math.pi / 8;
          final o = Offset(12 + r * math.cos(a), 12 + r * math.sin(a));
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        p.close();
        canvas.drawPath(p, fill);
        canvas.drawCircle(const Offset(12, 12), 2.4, Paint()..color = Colors.white);
      case SumiGlyphKind.shield:
        final p = Path()
          ..moveTo(12, 2.5)
          ..lineTo(19.5, 5.5)
          ..cubicTo(19.5, 13, 17, 18, 12, 21.5)
          ..cubicTo(7, 18, 4.5, 13, 4.5, 5.5)
          ..close();
        canvas.drawPath(p, fill);
        final tick = Path()
          ..moveTo(8.5, 11.5)
          ..lineTo(11, 14)
          ..lineTo(15.5, 9);
        canvas.drawPath(tick, cut);
      case SumiGlyphKind.quest:
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 4.6, stroke);
        canvas.drawCircle(const Offset(12, 12), 1.8, fill);
      case SumiGlyphKind.choice:
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(rr(3, 3.5 + i * 6.5, 18, 4.5, 2.25), i == 1 ? fill : (Paint()..color = color.withValues(alpha: .35)));
        }
      case SumiGlyphKind.order:
        // Equal steps, each one further along.
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(rr(3 + i * 4.5, 3.5 + i * 6.5, 9, 4.5, 2.25), fill);
        }
      case SumiGlyphKind.match:
        canvas.drawCircle(const Offset(5.5, 7), 3, fill);
        canvas.drawCircle(const Offset(18.5, 17), 3, fill);
        canvas.drawCircle(const Offset(5.5, 17), 3, Paint()..color = color.withValues(alpha: .35));
        canvas.drawCircle(const Offset(18.5, 7), 3, Paint()..color = color.withValues(alpha: .35));
        canvas.drawLine(const Offset(8, 8.5), const Offset(16, 15.5), stroke);
      case SumiGlyphKind.write:
        canvas.drawLine(const Offset(4, 19.5), const Offset(20, 19.5), stroke);
        canvas.drawLine(const Offset(4, 13.5), const Offset(14, 13.5), stroke);
        canvas.drawLine(const Offset(4, 7.5), const Offset(18, 7.5), stroke);
      case SumiGlyphKind.observe:
        final eye = Path()
          ..moveTo(2.5, 12)
          ..quadraticBezierTo(12, 2.5, 21.5, 12)
          ..quadraticBezierTo(12, 21.5, 2.5, 12)
          ..close();
        canvas.drawPath(eye, fill);
        canvas.drawCircle(const Offset(12, 12), 3.6, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(12, 12), 1.6, fill);
      case SumiGlyphKind.tap:
        // Beats on a line: tap with the pulse.
        canvas.drawLine(const Offset(3, 19), const Offset(21, 19), stroke);
        for (final x in [6.0, 12.0, 18.0]) {
          canvas.drawCircle(Offset(x, 11), x == 12 ? 3.4 : 2.4, fill);
        }
      case SumiGlyphKind.sketch:
        final p = Path()
          ..moveTo(3.5, 16)
          ..cubicTo(7, 6, 9.5, 6, 11.5, 13)
          ..cubicTo(13.5, 20, 16.5, 19, 20.5, 8);
        canvas.drawPath(p, stroke);
      case SumiGlyphKind.report:
        // A clipboard: an outlined sheet with its clip.
        canvas.drawRRect(rr(5, 4.5, 14, 17, 3), stroke);
        canvas.drawRRect(rr(8.5, 2, 7, 5, 1.5), fill);
        final line = Paint()
          ..color = color
          ..strokeWidth = 2.25
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(9, 12), const Offset(15, 12), line);
        canvas.drawLine(const Offset(9, 16.5), const Offset(13, 16.5), line);
      case SumiGlyphKind.chip:
        canvas.drawRRect(rr(5.5, 5.5, 13, 13, 3), fill);
        final pin = Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (final v in [9.0, 12.0, 15.0]) {
          canvas.drawLine(Offset(v, 2.5), Offset(v, 4.5), pin);
          canvas.drawLine(Offset(v, 19.5), Offset(v, 21.5), pin);
          canvas.drawLine(Offset(2.5, v), Offset(4.5, v), pin);
          canvas.drawLine(Offset(19.5, v), Offset(21.5, v), pin);
        }
        canvas.drawRRect(rr(9.5, 9.5, 5, 5, 1.2), Paint()..color = Colors.white);
      case SumiGlyphKind.download:
        canvas.drawLine(const Offset(12, 3.5), const Offset(12, 14.5), stroke);
        final head = Path()
          ..moveTo(7, 10)
          ..lineTo(12, 15.5)
          ..lineTo(17, 10);
        canvas.drawPath(head, stroke);
        canvas.drawLine(const Offset(4.5, 20), const Offset(19.5, 20), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.kind != kind || old.color != color;
}

// ---------------------------------------------------------------- wordmark

/// The Sumi wordmark: rounded lowercase "sumi" drawn as strokes, with the dot
/// of the i as an ink drop. [compact] draws only the ink-drop mark.
class SumiWordmark extends StatelessWidget {
  final double width;
  final bool compact;
  const SumiWordmark({super.key, this.width = 144, this.compact = false});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sumi',
    header: !compact,
    image: true,
    child: CustomPaint(
      size: compact ? Size.square(width) : Size(width, width * 48 / 144),
      painter: _WordmarkPainter(compact),
    ),
  );
}

class _WordmarkPainter extends CustomPainter {
  final bool compact;
  _WordmarkPainter(this.compact);

  static Path _drop(Offset top, double h) => Path()
    ..moveTo(top.dx, top.dy)
    ..cubicTo(top.dx + h * .3, top.dy + h * .38, top.dx + h * .42, top.dy + h * .55, top.dx + h * .42, top.dy + h * .7)
    ..arcToPoint(Offset(top.dx - h * .42, top.dy + h * .7), radius: Radius.circular(h * .42))
    ..cubicTo(top.dx - h * .42, top.dy + h * .55, top.dx - h * .3, top.dy + h * .38, top.dx, top.dy)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (compact) {
      final h = size.height * .86;
      tactile(canvas, _drop(Offset(size.width / 2, size.height * .04), h), SumiColors.primary, depth: size.height * .06);
      return;
    }
    canvas.save();
    canvas.scale(size.width / 144);
    final ink = Paint()
      ..color = SumiColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // s
    final s = Path()
      ..moveTo(30, 22)
      ..cubicTo(26, 16, 10, 16, 10, 24)
      ..cubicTo(10, 31, 30, 29, 30, 37)
      ..cubicTo(30, 45, 13, 45, 8, 39);
    canvas.drawPath(s, ink);
    // u
    final u = Path()
      ..moveTo(42, 18)
      ..lineTo(42, 31)
      ..arcToPoint(const Offset(62, 31), radius: const Radius.circular(10), clockwise: false)
      ..lineTo(62, 18)
      ..moveTo(62, 31)
      ..lineTo(62, 42);
    canvas.drawPath(u, ink);
    // m
    final m = Path()
      ..moveTo(76, 42)
      ..lineTo(76, 18)
      ..moveTo(76, 28)
      ..arcToPoint(const Offset(93, 28), radius: const Radius.circular(8.5))
      ..lineTo(93, 42)
      ..moveTo(93, 28)
      ..arcToPoint(const Offset(110, 28), radius: const Radius.circular(8.5))
      ..lineTo(110, 42);
    canvas.drawPath(m, ink);
    // i, with an ink-drop dot
    canvas.drawLine(const Offset(126, 20), const Offset(126, 42), ink);
    tactile(canvas, _drop(const Offset(126, -1), 15), SumiColors.primary, depth: 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WordmarkPainter old) => old.compact != compact;
}

// ---------------------------------------------------------------- hero

/// ONB-01 hero: knowledge tiles flow along the ink route to a finished
/// project. Decorative (the promise text carries the meaning).
class RouteHero extends StatelessWidget {
  final double height;
  const RouteHero({super.key, this.height = 232});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(double.infinity, height),
      painter: _RouteHeroPainter(),
    ),
  );
}

class _RouteHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final unit = math.min(w / 340, h / 232);
    canvas.save();
    canvas.translate((w - 340 * unit) / 2, (h - 232 * unit) / 2);
    canvas.scale(unit);
    final route = [
      const Offset(28, 196),
      const Offset(90, 200),
      const Offset(120, 150),
      const Offset(180, 132),
      const Offset(214, 84),
      const Offset(278, 70),
    ];
    inkRoute(canvas, route, width: 14);
    // Knowledge tiles along the route, each tilted as if moving with it.
    const tiles = [
      (Offset(44, 172), SumiColors.sky, SumiGlyphKind.lesson, -.18),
      (Offset(116, 118), SumiColors.violet, SumiGlyphKind.review, .12),
      (Offset(184, 100), SumiColors.amber, SumiGlyphKind.spark, -.08),
    ];
    for (final (pos, color, glyph, angle) in tiles) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final tile = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -22, 44, 44), const Radius.circular(12)));
      tactile(canvas, tile, color, depth: 4);
      canvas.translate(-12, -12);
      _GlyphPainter(glyph, Colors.white).paint(canvas, const Size.square(24));
      canvas.restore();
    }
    // The destination: a raised plinth with the learner's flag planted on it.
    final plinth = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(244, 76, 76, 40), const Radius.circular(12)));
    tactile(canvas, plinth, SumiColors.primary, depth: 5);
    canvas.drawLine(
      const Offset(270, 78),
      const Offset(270, 18),
      Paint()
        ..color = SumiColors.ink
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(272, 20)
      ..quadraticBezierTo(290, 14, 308, 22)
      ..lineTo(304, 34)
      ..lineTo(308, 46)
      ..quadraticBezierTo(290, 38, 272, 44)
      ..close();
    tactile(canvas, flag, SumiColors.sky, depth: 3);
    canvas.save();
    canvas.translate(270, 88);
    _GlyphPainter(SumiGlyphKind.check, Colors.white).paint(canvas, const Size.square(24));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------- scenes

/// PTH-13 discipline scenes from the subject's own objects, full opacity,
/// token colours, a faint ink route behind. Keys come from `tracks[].scene`.
class DisciplineScene extends StatelessWidget {
  final String scene;
  final double size;
  const DisciplineScene({super.key, required this.scene, this.size = 120});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: DisciplineScenePainter(scene),
    ),
  );
}

class DisciplineScenePainter extends CustomPainter {
  final String scene;
  DisciplineScenePainter(this.scene);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120);
    inkRoute(
      canvas,
      const [Offset(8, 102), Offset(40, 96), Offset(70, 108), Offset(112, 94)],
      width: 8,
      opacity: .18,
    );
    switch (scene) {
      case 'music':
        _music(canvas);
      case 'fashion':
        _fashion(canvas);
      default:
        _blocks(canvas);
    }
    canvas.restore();
  }

  static RRect _rr(double l, double t, double w, double h, double r) =>
      RRect.fromLTRBR(l, t, l + w, t + h, Radius.circular(r));

  // Music: pulse grid, a note, a metronome.
  void _music(Canvas c) {
    // Pulse grid: four beats, the first accented.
    for (var i = 0; i < 4; i++) {
      tactile(c, Path()..addRRect(_rr(10 + i * 14, 70, 10, 10, 3)), i == 0 ? SumiColors.sky : SumiColors.border, depth: 2, edge: i == 0 ? SumiColors.skyShadow : SumiColors.borderShadow);
    }
    // Metronome.
    final body = Path()
      ..moveTo(70, 88)
      ..lineTo(80, 22)
      ..quadraticBezierTo(86, 16, 92, 22)
      ..lineTo(102, 88)
      ..close();
    tactile(c, body, SumiColors.unitTeal, depth: 4, edge: SumiColors.unitTealShadow);
    c.drawRRect(_rr(78, 66, 16, 14, 3), Paint()..color = Colors.white);
    final arm = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(86, 72), const Offset(96, 32), arm);
    c.drawCircle(const Offset(93.5, 42), 4, Paint()..color = SumiColors.amber);
    // A note.
    final ink = Paint()
      ..color = SumiColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.save();
    c.translate(30, 46);
    c.rotate(-.35);
    c.drawOval(const Rect.fromLTWH(-9, -6, 18, 12), Paint()..color = SumiColors.ink);
    c.restore();
    c.drawLine(const Offset(37.5, 44), const Offset(37.5, 14), ink);
    final flag = Path()
      ..moveTo(37.5, 14)
      ..quadraticBezierTo(50, 20, 48, 32);
    c.drawPath(flag, ink..style = PaintingStyle.stroke);
  }

  // Fashion: a fabric swatch, a measuring tape, a pattern piece.
  void _fashion(Canvas c) {
    // Pattern piece (a bodice front) with a dashed seam allowance.
    final piece = Path()
      ..moveTo(52, 18)
      ..lineTo(70, 14)
      ..quadraticBezierTo(80, 26, 92, 22)
      ..lineTo(106, 30)
      ..lineTo(100, 86)
      ..lineTo(58, 86)
      ..close();
    tactile(c, piece, SumiColors.surface, depth: 3, edge: SumiColors.borderShadow);
    c.drawPath(piece, Paint()
      ..color = SumiColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round);
    final dash = Paint()
      ..color = SumiColors.unitPlum
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = 34.0; y < 80; y += 8) {
      c.drawLine(Offset(64, y), Offset(64, y + 4), dash);
    }
    // Swatch with pinked edge.
    final swatch = Path()..moveTo(12, 44);
    for (var i = 0; i <= 8; i++) {
      swatch.lineTo(12 + i * 4.5, i.isEven ? 44 : 40);
    }
    swatch
      ..lineTo(48, 82)
      ..lineTo(12, 82)
      ..close();
    tactile(c, swatch, SumiColors.unitPlum, depth: 4, edge: SumiColors.unitPlumShadow);
    final weave = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = 2;
    for (var x = 18.0; x < 46; x += 7) {
      c.drawLine(Offset(x, 48), Offset(x, 78), weave);
    }
    // Measuring tape curling across the front.
    final tape = Path()
      ..moveTo(8, 104)
      ..quadraticBezierTo(40, 94, 74, 102)
      ..quadraticBezierTo(98, 108, 114, 98);
    c.drawPath(tape, Paint()
      ..color = SumiColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    final tick = Paint()
      ..color = SumiColors.amberShadow
      ..strokeWidth = 1.6;
    for (final metric in tape.computeMetrics()) {
      for (var d = 8.0; d < metric.length - 4; d += 7) {
        final p = metric.getTangentForOffset(d)!.position;
        c.drawLine(p.translate(0, -3), p.translate(0, 1), tick);
      }
    }
  }

  // Custom goals: modular blocks being stacked.
  void _blocks(Canvas c) {
    tactile(c, Path()..addRRect(_rr(16, 60, 40, 28, 7)), SumiColors.sky, depth: 4, edge: SumiColors.skyShadow);
    tactile(c, Path()..addRRect(_rr(60, 60, 40, 28, 7)), SumiColors.violet, depth: 4, edge: SumiColors.violetShadow);
    tactile(c, Path()..addRRect(_rr(38, 26, 40, 28, 7)), SumiColors.primary, depth: 4, edge: SumiColors.primaryShadow);
    // The next block, still to be placed.
    final ghost = Paint()
      ..color = SumiColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final r = _rr(82, 12, 26, 20, 6);
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        c.drawPath(metric.extractPath(d, d + 5), ghost);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DisciplineScenePainter old) => old.scene != scene;
}

// ---------------------------------------------------------------- empty states

/// DC §7.34 / §11.6 empty-state illustrations (120 px).
enum SumiEmptyKind { caughtUp, nothingSaved, noModel, routeComplete }

class SumiEmptyIllustration extends StatelessWidget {
  final SumiEmptyKind kind;
  final double size;
  const SumiEmptyIllustration(this.kind, {super.key, this.size = 120});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _EmptyPainter(kind),
    ),
  );
}

class _EmptyPainter extends CustomPainter {
  final SumiEmptyKind kind;
  _EmptyPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120);
    canvas.drawCircle(const Offset(60, 64), 50, Paint()..color = SumiColors.surfaceSoft);
    void glyph(SumiGlyphKind g, Offset at, double s, Color color) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      _GlyphPainter(g, color).paint(canvas, Size.square(s));
      canvas.restore();
    }

    switch (kind) {
      case SumiEmptyKind.caughtUp:
        // An inkwell with the brush resting: nothing left to do today.
        tactile(canvas, Path()..addRRect(RRect.fromLTRBR(38, 58, 82, 92, const Radius.circular(10))), SumiColors.ink, depth: 4);
        canvas.drawRRect(RRect.fromLTRBR(48, 50, 72, 60, const Radius.circular(4)), Paint()..color = SumiColors.ink);
        final brush = Paint()
          ..color = SumiColors.unitOlive
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(30, 46), const Offset(78, 30), brush);
        glyph(SumiGlyphKind.check, const Offset(48, 64), 24, Colors.white);
      case SumiEmptyKind.nothingSaved:
        // An empty bookmark tray.
        tactile(canvas, Path()..addRRect(RRect.fromLTRBR(26, 70, 94, 92, const Radius.circular(8))), SumiColors.border, depth: 4, edge: SumiColors.borderShadow);
        final ribbon = Path()
          ..moveTo(50, 24)
          ..lineTo(70, 24)
          ..lineTo(70, 62)
          ..lineTo(60, 54)
          ..lineTo(50, 62)
          ..close();
        tactile(canvas, ribbon, SumiColors.sky, depth: 3);
      case SumiEmptyKind.noModel:
        tactile(canvas, Path()..addRRect(RRect.fromLTRBR(36, 40, 84, 88, const Radius.circular(12))), SumiColors.unitTeal, depth: 4, edge: SumiColors.unitTealShadow);
        glyph(SumiGlyphKind.download, const Offset(46, 50), 28, Colors.white);
      case SumiEmptyKind.routeComplete:
        // A scroll sealed with the checkpoint stamp.
        tactile(canvas, Path()..addRRect(RRect.fromLTRBR(24, 46, 96, 84, const Radius.circular(8))), SumiColors.surface, depth: 3, edge: SumiColors.borderShadow);
        canvas.drawRRect(RRect.fromLTRBR(24, 46, 96, 84, const Radius.circular(8)), Paint()
          ..color = SumiColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
        inkRoute(canvas, const [Offset(32, 70), Offset(52, 60), Offset(70, 68)], width: 5);
        glyph(SumiGlyphKind.checkpoint, const Offset(70, 52), 26, SumiColors.coral);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmptyPainter old) => old.kind != kind;
}
