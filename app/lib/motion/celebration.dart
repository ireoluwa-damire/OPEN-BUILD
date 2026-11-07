import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Original Sumi motion primitives. Every animation here is one-shot (no
/// repeat) so screens settle, and each has a static reduced-motion fallback.

const sumiCelebrationColors = [
  SumiColors.primary,
  SumiColors.sky,
  SumiColors.amber,
  SumiColors.coral,
  SumiColors.violet,
];

/// A single confetti burst that plays once when inserted.
class ConfettiBurst extends StatefulWidget {
  final bool reducedMotion;
  final int pieces;
  final Duration duration;
  final Alignment origin;
  const ConfettiBurst({
    super.key,
    required this.reducedMotion,
    this.pieces = 56,
    this.duration = const Duration(milliseconds: 1200), // CF-21
    this.origin = const Alignment(0, -.35),
  });
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Piece> pieces = _Piece.generate(widget.pieces, 7);
  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) c.forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reducedMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(pieces, c.value, widget.origin),
            ),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  final double angle, speed, spin, size;
  final Color color;
  final int shape;
  _Piece(this.angle, this.speed, this.spin, this.size, this.color, this.shape);
  static List<_Piece> generate(int n, int seed) {
    final r = math.Random(seed);
    return [
      for (var i = 0; i < n; i++)
        _Piece(
          // Mostly upward fan, -165° .. -15°.
          -math.pi * (.08 + r.nextDouble() * .84),
          420 + r.nextDouble() * 520,
          (r.nextDouble() - .5) * 14,
          6 + r.nextDouble() * 7,
          sumiCelebrationColors[i % sumiCelebrationColors.length],
          r.nextInt(3),
        ),
    ];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  final Alignment origin;
  _ConfettiPainter(this.pieces, this.t, this.origin);
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final o = origin.alongSize(size);
    final secs = t * 1.9;
    const gravity = 900.0;
    final fade = t < .7 ? 1.0 : 1 - (t - .7) / .3;
    final paint = Paint();
    for (final p in pieces) {
      // Air drag slows the outward speed over time.
      final drag = 1 - math.exp(-2.2 * secs);
      final dist = p.speed * drag / 2.2;
      final x = o.dx + math.cos(p.angle) * dist;
      final y = o.dy + math.sin(p.angle) * dist + .5 * gravity * secs * secs * .35;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * secs);
      switch (p.shape) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * .55,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        case 1:
          canvas.drawCircle(Offset.zero, p.size * .38, paint);
        default:
          final path = Path()
            ..moveTo(0, -p.size * .5)
            ..lineTo(p.size * .45, p.size * .4)
            ..lineTo(-p.size * .45, p.size * .4)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Ring + radiating sparks drawn around a node. [t] runs 0..1.
class SparkBurstPainter extends CustomPainter {
  final double t;
  final Color color;
  final int rays;
  final bool stars;
  SparkBurstPainter({
    required this.t,
    required this.color,
    this.rays = 8,
    this.stars = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final e = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    // Expanding ring.
    canvas.drawCircle(
      c,
      maxR * (.5 + .45 * e),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * fade + 1
        ..color = color.withValues(alpha: .55 * fade),
    );
    // Sparks.
    final spark = Paint()
      ..color = color.withValues(alpha: fade)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final r0 = maxR * (.48 + .3 * e);
      final r1 = maxR * (.6 + .38 * e);
      if (stars && i.isEven) {
        _star(canvas, c + dir * r1, 6 * fade + 2, spark);
      } else {
        canvas.drawLine(c + dir * r0, c + dir * r1, spark);
      }
    }
  }

  void _star(Canvas canvas, Offset at, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * .45;
      final a = i * math.pi / 5 - math.pi / 2;
      final pt = at + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = p.color);
  }

  @override
  bool shouldRepaint(covariant SparkBurstPainter old) =>
      old.t != t || old.color != color;
}

/// Slow rotating light rays behind a hero emblem (one revolution fraction,
/// not looping).
class RaysPainter extends CustomPainter {
  final double t;
  final Color color;
  RaysPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Paint()..color = color.withValues(alpha: .16);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi / 6);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - .12) * r, math.sin(a - .12) * r)
        ..lineTo(math.cos(a + .12) * r, math.sin(a + .12) * r)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RaysPainter old) => old.t != t;
}
