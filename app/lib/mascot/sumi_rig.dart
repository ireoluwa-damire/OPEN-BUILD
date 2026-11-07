import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Sumi — code-drawn chameleon companion (soft style, matches the approved character sheet).
///
/// Mirrors research/mascot/sumi-rig.js 1:1 (same pose maths, same drawing
/// order). Every performance is original. No artwork, paths, timings, or files
/// from any other mascot are used. Research cross-references live only in the
/// debug-only `reference_slots_debug.dart` (GOV-05).

const _pi = math.pi, _tau = math.pi * 2;
double _clamp(double v, [double a = 0, double b = 1]) => v < a ? a : (v > b ? b : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _seg(double p, double a, double b) => _clamp((p - a) / (b - a));
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _easeInOut(double t) => t < .5
    ? 4 * t * t * t
    : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
double _backOut(double t) {
  const c = 1.70158;
  return (1 + (c + 1) * math.pow(t - 1, 3) + c * math.pow(t - 1, 2)).toDouble();
}

double _hop(double t) => math.sin(_clamp(t) * _pi);
double _blink(double time) {
  final k = time % 3.4;
  return k > 3.25 ? (math.cos((k - 3.25) / .15 * _pi)).abs() : 1.0;
}

enum SumiSkin { standard, midnight, glow, gold }

class SumiPalette {
  final Color body, deep, ring, belly, stripe, crest, cheek, iris, line;
  final bool aura;
  const SumiPalette(
    this.body,
    this.deep,
    this.ring,
    this.belly,
    this.stripe,
    this.crest,
    this.cheek,
    this.iris,
    this.line, {
    this.aura = false,
  });
  static const _ink = Color(0xFF141832);

  /// Chameleon colour changes. Gold is the end state of [SumiAnim.inkBloom].
  static SumiPalette of(SumiSkin s) => switch (s) {
    SumiSkin.standard => const SumiPalette(
      Color(0xFF22C08B),
      Color(0xFF14A070),
      Color(0xFF5FE0AA),
      Color(0xFFFFD93F),
      Color(0xFFF4B630),
      Color(0xFFFFD93F),
      Color(0xFFFF9C8F),
      Color(0xFF1C2433),
      Color(0xFF0E7A55),
    ),
    SumiSkin.midnight => const SumiPalette(
      Color(0xFF5257B8),
      Color(0xFF3A3E96),
      Color(0xFF8E93F0),
      Color(0xFF9FDCFF),
      Color(0xFF6FB8E8),
      Color(0xFF9FDCFF),
      Color(0xFFFF9AD0),
      Color(0xFF1C2433),
      Color(0xFF262A6E),
    ),
    SumiSkin.glow => const SumiPalette(
      Color(0xFF5ED9E8),
      Color(0xFF3BB5CF),
      Color(0xFFA8F1F7),
      Color(0xFFFFE08A),
      Color(0xFFF5C451),
      Color(0xFFFF9AD0),
      Color(0xFFFF8A7A),
      Color(0xFF1C2433),
      Color(0xFF1F7F96),
      aura: true,
    ),
    SumiSkin.gold => const SumiPalette(
      Color(0xFFFFC93F),
      Color(0xFFE9A514),
      Color(0xFFFFE69A),
      Color(0xFFFFF3C4),
      Color(0xFFF2C55A),
      Color(0xFFFF7B69),
      Color(0xFFFF7B69),
      Color(0xFF1C2433),
      Color(0xFF9A6408),
    ),
  };
}

/// Groups organise the gallery.
enum SumiAnimGroup {
  lessonReactions('Lesson reactions'),
  pathActivities('Path activities'),
  mathPath('Measuring'),
  coachingPoses('Coaching poses'),
  documentedMoments('Milestones'),
  sumiGuidance('Sumi guidance');

  final String label;
  const SumiAnimGroup(this.label);
}

enum SumiAnim {
  idle(SumiAnimGroup.lessonReactions, 'Neutral / waiting', true, 3000),
  correct(SumiAnimGroup.lessonReactions, 'Success reaction', false, 900, .45),
  incorrect(SumiAnimGroup.lessonReactions, 'Retry reaction', false, 1000, .4),
  juggle(SumiAnimGroup.pathActivities, 'Path activity: juggling', true, 1600),
  reading(SumiAnimGroup.pathActivities, 'Path activity: reading', true, 3200),
  fishFriend(SumiAnimGroup.pathActivities, 'Path activity: fish friend', true, 3000),
  cheer(SumiAnimGroup.pathActivities, 'Cheer', true, 1000),
  pearl(SumiAnimGroup.pathActivities, 'Path activity: pearl', true, 2600),
  globe(SumiAnimGroup.pathActivities, 'Path activity: globe', true, 2400),
  headphones(SumiAnimGroup.pathActivities, 'Path activity: listening', true, 1000),
  jetHop(SumiAnimGroup.pathActivities, 'Path activity: hop', true, 1600),
  inkMix(SumiAnimGroup.pathActivities, 'Path activity: mixing ink', true, 2400),
  shades(SumiAnimGroup.pathActivities, 'Path activity: sunglasses', true, 2600),
  twirl(SumiAnimGroup.pathActivities, 'Twirl', true, 1400, .3),
  humming(SumiAnimGroup.pathActivities, 'Humming', true, 2400),
  clock(SumiAnimGroup.mathPath, 'Measuring time', true, 2400),
  tapeMeasure(SumiAnimGroup.mathPath, 'Tape measure', true, 2400),
  board(SumiAnimGroup.coachingPoses, 'Teaching at a board', true, 2800),
  flip(SumiAnimGroup.coachingPoses, 'Flip', false, 1200, .5),
  lifting(SumiAnimGroup.coachingPoses, 'Lifting', true, 1800),
  ponder(SumiAnimGroup.coachingPoses, 'Pondering', true, 3600),
  shocked(SumiAnimGroup.coachingPoses, 'Surprised', false, 900, .3),
  greet(SumiAnimGroup.documentedMoments, 'Welcome / instruction', false, 1200, .35),
  dashAcross(SumiAnimGroup.documentedMoments, 'Mid-lesson interstitial', false, 1600),
  milestoneNumber(SumiAnimGroup.documentedMoments, 'Streak milestone', true, 2800),
  inkBloom(SumiAnimGroup.documentedMoments, 'Streak milestone bloom', false, 2200, .8),
  point(SumiAnimGroup.sumiGuidance, 'Pointing', false, 700, .9),
  think(SumiAnimGroup.sumiGuidance, 'Thinking', true, 2800),
  hint(SumiAnimGroup.sumiGuidance, 'Hint', false, 900, .9),
  complete(SumiAnimGroup.sumiGuidance, 'Lesson complete', false, 1400, .5),
  localReady(SumiAnimGroup.sumiGuidance, 'Offline model ready', false, 800, .9),
  recover(SumiAnimGroup.sumiGuidance, 'Recover', false, 1000, .5),
  listen(SumiAnimGroup.sumiGuidance, 'Listening', true, 2400),
  compare(SumiAnimGroup.sumiGuidance, 'Comparing', true, 2400, .25),
  musicCount(SumiAnimGroup.sumiGuidance, 'Counting beats (Music)', true, 2000, .3),
  designMake(SumiAnimGroup.sumiGuidance, 'Making (Fashion)', true, 2400);

  final SumiAnimGroup group;
  /// Plain description of what the performance communicates.
  final String role;
  final bool loops;
  final int durationMs;

  /// Progress used for the still pose when motion is reduced.
  final double posterProgress;
  const SumiAnim(
    this.group,
    this.role,
    this.loops,
    this.durationMs, [
    this.posterProgress = .5,
  ]);
}

class SumiArm {
  double a, c;
  SumiArm(this.a, this.c);
}

class SumiProp {
  final String k;
  final double t, v, ext, lift, side, ph;
  final int beat;
  final String label;
  const SumiProp(
    this.k, {
    this.t = 0,
    this.v = 0,
    this.ext = 0,
    this.lift = 0,
    this.side = 0,
    this.ph = 0,
    this.beat = 0,
    this.label = '',
  });
}

class SumiFx {
  final String k;
  final double t, x, y, dir;
  final bool small, big;
  final String from;
  const SumiFx(
    this.k, {
    this.t = 0,
    this.x = 0,
    this.y = 0,
    this.dir = 1,
    this.small = false,
    this.big = false,
    this.from = '',
  });
}

class SumiPose {
  double x = 0, y = 0, rot = 0, sx = 1, sy = 1;
  String eyes = 'open', mouth = 'smile';
  double eyeOpen = 1, lookX = 0, lookY = 0, brow = 0, blush = 0;
  bool browOn = false;
  SumiArm armL = SumiArm(.35, -1.5), armR = SumiArm(.35, -1.5);
  double frillAmp = 2, frillPhase = 0, frillScale = 1, tent = 0, glow = 0;
  SumiSkin? skin;
  SumiProp? prop;
  final List<SumiFx> fx = [];
}

void _idle(SumiPose p, double time) {
  final b = math.sin(time * _tau / 3);
  p.y = b * 1.6;
  p.sy = 1 + b * .012;
  p.sx = 1 - b * .008;
  p.frillPhase = time * 2.2;
  p.tent = time * 1.6;
  p.eyeOpen = _blink(time);
}

/// Pure pose function: (animation, progress 0..1, elapsed seconds) → pose.
SumiPose sumiPose(SumiAnim anim, double p, double time) {
  final q = SumiPose();
  _idle(q, time);
  switch (anim) {
    case SumiAnim.idle:
      break;
    case SumiAnim.correct:
      final h = _hop(_seg(p, .1, .6));
      q.y = -22 * h;
      q.sy = 1 + .08 * h - .1 * _hop(_seg(p, 0, .12)) - .08 * _hop(_seg(p, .6, .72));
      q.sx = 2 - q.sy;
      final up = _easeOut(_seg(p, .05, .3));
      q.armL = SumiArm(_lerp(.35, 2.5, up), -.3);
      q.armR = SumiArm(_lerp(.35, 2.5, up), -.3);
      q.eyes = 'happy';
      q.mouth = 'grin';
      q.blush = 1;
      q.fx.add(SumiFx('sparkle', t: _seg(p, .15, 1)));
    case SumiAnim.incorrect:
      final d = _easeOut(_seg(p, 0, .2)), back = _seg(p, .75, 1);
      final slump = d * (1 - back);
      q.sy = 1 - .08 * slump;
      q.sx = 1 + .04 * slump;
      q.rot = -.12 * slump;
      q.y = 3 * slump;
      q.lookX = -.3 * (1 - back);
      q.lookY = .8 * (1 - back);
      q.browOn = back < 1;
      q.brow = -1.2;
      q.mouth = p < .75 ? 'frown' : 'smile';
      q.armL = SumiArm(_lerp(.35, .15, slump), _lerp(-1.5, .2, slump));
      q.armR = SumiArm(_lerp(.35, .15, slump), _lerp(-1.5, .2, slump));
      q.fx.add(SumiFx('sweat', t: _seg(p, .1, .8), big: true));
    case SumiAnim.juggle:
      final k = _hop(p * 2 % 1);
      q.armL = SumiArm(_lerp(1.65, 1.95, k), -.3);
      q.armR = SumiArm(_lerp(1.95, 1.65, k), -.3);
      q.lookY = -.8;
      q.lookX = math.sin(p * _tau) * .6;
      q.mouth = 'o';
      q.prop = SumiProp('bubbles', t: p);
    case SumiAnim.reading:
      q.armL = SumiArm(-.18, -1.6);
      q.armR = SumiArm(-.18, -1.6);
      q.lookY = .8;
      q.lookX = math.sin(p * _tau) * .5;
      q.prop = SumiProp('book', t: p);
    case SumiAnim.fishFriend:
      final fx = math.cos(p * _tau) * 58, fy = -100 + math.sin(p * _tau * 2) * 14;
      q.lookX = _clamp(fx / 50, -1, 1);
      q.lookY = _clamp((fy + 82) / 30, -1, 1);
      q.rot = fx / 900;
      q.mouth = 'grin';
      q.blush = .6;
      q.armR = SumiArm(1.2 + .3 * math.sin(p * _tau), -.3);
      q.fx.add(SumiFx('fish', x: fx, y: fy, dir: -math.sin(p * _tau)));
    case SumiAnim.cheer:
      final h = _hop(p);
      q.y = -14 * h;
      q.sy = 1 + .06 * h;
      q.sx = 1 - .04 * h;
      q.armL = SumiArm(2.4 + .3 * math.sin(p * _tau * 2), -.4);
      q.armR = SumiArm(2.4 - .3 * math.sin(p * _tau * 2), -.4);
      q.eyes = 'happy';
      q.mouth = 'grin';
      q.blush = 1;
    case SumiAnim.pearl:
      q.armR = SumiArm(2.2, -.2);
      q.lookX = .7;
      q.lookY = -.8;
      q.mouth = 'o';
      q.prop = SumiProp('pearl', t: p);
    case SumiAnim.globe:
      q.armL = SumiArm(-.18, -1.6);
      q.armR = SumiArm(-.18, -1.6);
      q.lookY = .7;
      q.prop = SumiProp('globe', t: p);
    case SumiAnim.headphones:
      final beat = _hop(p * 2 % 1);
      q.y = -4 * beat;
      q.rot = math.sin(p * _tau) * .08;
      q.eyes = 'happy';
      q.armL = SumiArm(.7 + .5 * beat, -.2);
      q.armR = SumiArm(.7 + .5 * (1 - beat), -.2);
      q.prop = const SumiProp('headphones');
      q.fx.add(SumiFx('notes', t: p));
    case SumiAnim.jetHop:
      final crouch = _hop(_seg(p, 0, .2)),
          air = _hop(_seg(p, .18, .82)),
          land = _hop(_seg(p, .8, 1));
      q.y = -48 * math.sin(_seg(p, .18, .82) * _pi);
      q.sy = 1 - .14 * crouch - .1 * land + .1 * air * (p < .5 ? 1 : 0);
      q.sx = 2 - q.sy;
      final flap = math.sin(p * _tau * 5) * air;
      q.armL = SumiArm(1.6 + .8 * flap, .1);
      q.armR = SumiArm(1.6 + .8 * flap, .1);
      q.frillAmp = 2 + 5 * air;
      q.mouth = air > .3 ? 'open' : 'smile';
      q.eyes = air > .3 ? 'wide' : 'open';
      q.fx.add(SumiFx('puffs', t: _seg(p, .18, .6)));
    case SumiAnim.inkMix:
      q.armL = SumiArm(-.18, -1.6);
      q.armR = SumiArm(-.2 + .25 * math.sin(p * _tau * 2), .5);
      q.lookY = .8;
      q.mouth = 'o';
      q.prop = SumiProp('inkpot', t: p);
      if (p > .6) q.fx.add(SumiFx('sparkle', t: _seg(p, .6, 1), small: true));
    case SumiAnim.shades:
      final on = _easeInOut(_seg(p, .1, .35)), off = _easeInOut(_seg(p, .8, 1));
      final v = on * (1 - off);
      q.armR = SumiArm(
        _lerp(.35, 2.1, _hop(_seg(p, .05, .4)) + _hop(_seg(p, .75, 1))),
        -.4,
      );
      q.mouth = v > .5 ? 'smirk' : 'smile';
      q.rot = .05 * v;
      q.prop = SumiProp('shades', v: v);
    case SumiAnim.twirl:
      final s = _easeInOut(_seg(p, .1, .8));
      var sx = math.cos(s * _tau);
      if (sx.abs() < .25) sx = sx < 0 ? -.25 : .25;
      q.sx = sx;
      q.y = -10 * _hop(_seg(p, .1, .8));
      q.armL = SumiArm(1.9, 0);
      q.armR = SumiArm(1.9, 0);
      q.eyes = 'happy';
      q.mouth = 'grin';
      q.frillAmp = 2 + 4 * _hop(_seg(p, .1, .8));
    case SumiAnim.humming:
      q.mouth = 'whistle';
      q.eyes = 'happy';
      q.rot = math.sin(p * _tau) * .05;
      q.armL = SumiArm(.5, .6);
      q.armR = SumiArm(.5, .6);
      q.fx.add(SumiFx('notes', t: p, from: 'mouth'));
    case SumiAnim.clock:
      q.armL = SumiArm(-.18, -1.6);
      q.armR = SumiArm(-.18, -1.6);
      q.lookY = .7;
      q.lookX = math.sin(p * _tau) * .3;
      q.prop = SumiProp('clock', t: p);
    case SumiAnim.tapeMeasure:
      final e = _hop(p);
      q.armL = SumiArm(_lerp(1.2, 1.7, e), 0);
      q.armR = SumiArm(_lerp(1.2, 1.7, e), 0);
      q.lookX = -.2;
      q.prop = SumiProp('tape', ext: e);
    case SumiAnim.board:
      q.x = 18;
      q.armL = SumiArm(1.75 + .1 * math.sin(p * _tau * 2), -.1);
      q.lookX = -.9;
      q.prop = SumiProp('board', t: p);
    case SumiAnim.flip:
      final crouch = _hop(_seg(p, 0, .15)),
          air = _seg(p, .15, .8),
          land = _hop(_seg(p, .8, 1));
      q.y = -56 * math.sin(air * _pi);
      q.rot = -_easeInOut(air) * _tau;
      q.sy = 1 - .14 * crouch - .12 * land;
      q.sx = 2 - q.sy;
      q.armL = SumiArm(2.3 * _hop(air) + .35, 0);
      q.armR = SumiArm(2.3 * _hop(air) + .35, 0);
      q.eyes = air > 0 && air < 1 ? 'happy' : 'open';
      q.mouth = 'grin';
    case SumiAnim.lifting:
      final l = _hop(p);
      q.armL = SumiArm(_lerp(1.55, 2.0, l), -.2);
      q.armR = SumiArm(_lerp(1.55, 2.0, l), -.2);
      q.y = -3 * l;
      q.sy = 1 - .09 * l;
      q.sx = 1 + .06 * l;
      q.browOn = true;
      q.brow = 1;
      q.mouth = l > .5 ? 'grit' : 'flat';
      q.prop = SumiProp('barbell', lift: l);
      if (l > .7) q.fx.add(const SumiFx('sweat', t: .5));
    case SumiAnim.ponder:
      q.armR = SumiArm(-2.25, .6);
      q.lookX = .6;
      q.lookY = -.7;
      q.mouth = 'flat';
      q.browOn = true;
      q.brow = .4;
      q.rot = -.04;
      q.fx.add(SumiFx('question', t: p));
    case SumiAnim.shocked:
      final j = _hop(_seg(p, 0, .35));
      q.y = -16 * j;
      q.sy = 1 + .1 * j;
      q.sx = 1 - .06 * j;
      q.eyes = 'wide';
      q.mouth = 'open';
      q.browOn = true;
      q.brow = .2;
      q.armL = SumiArm(2.0, .4);
      q.armR = SumiArm(2.0, .4);
      q.frillAmp = 6;
      q.frillScale = 1.08;
      q.fx.add(SumiFx('exclaim', t: _seg(p, 0, .5)));
    case SumiAnim.greet:
      final w = _seg(p, .1, .9);
      q.armR = SumiArm(2.4 + .35 * math.sin(w * _tau * 2.5) * _hop(w), -.5);
      q.rot = -.04 * _hop(w);
      q.mouth = 'grin';
      q.eyes = p > .3 && p < .8 ? 'happy' : 'open';
      q.blush = .6;
    case SumiAnim.dashAcross:
      q.x = _lerp(-80, 80, _easeInOut(p));
      q.rot = .14;
      q.y = -6 * (math.sin(p * _pi * 6)).abs();
      q.armL = SumiArm(1.8, .3);
      q.armR = SumiArm(1.8, .3);
      q.eyes = 'happy';
      q.mouth = 'grin';
      q.frillAmp = 5;
      q.fx.add(SumiFx('trail', t: p));
    case SumiAnim.milestoneNumber:
      q.armR = SumiArm(2.3, -.2);
      q.lookX = .5;
      q.lookY = -.6;
      q.mouth = 'grin';
      q.blush = .7;
      q.prop = SumiProp('balloon', t: p, label: '7');
    case SumiAnim.inkBloom:
      final charge = _seg(p, 0, .45), burst = _seg(p, .45, .6), settle = _seg(p, .6, 1);
      q.sy = 1 - .12 * _easeOut(charge) * (1 - burst) + .12 * _hop(burst);
      q.sx = 2 - q.sy;
      q.y = -10 * _hop(burst);
      q.rot = math.sin(charge * _pi * 10) * .03 * charge * (1 - burst);
      q.eyes = charge < 1 ? 'closed' : 'happy';
      q.mouth = charge < 1 ? 'flat' : 'grin';
      q.glow = _easeOut(charge) * (1 - .5 * settle);
      q.skin = burst > .5 ? SumiSkin.gold : null;
      q.frillScale = 1 + .25 * _hop(burst) + .08 * (burst >= 1 ? 1 : 0);
      q.frillAmp = 2 + 6 * _hop(burst);
      q.armL = SumiArm(_lerp(.35, 2.6, burst), -.3);
      q.armR = SumiArm(_lerp(.35, 2.6, burst), -.3);
      q.fx.add(SumiFx('burst', t: burst));
      if (settle > 0) q.fx.add(SumiFx('sparkle', t: settle));
    case SumiAnim.point:
      final e = _backOut(_seg(p, 0, .6));
      q.armR = SumiArm(_lerp(.35, 1.6, e), -.1);
      q.lookX = .9 * e;
      q.rot = .05 * e;
    case SumiAnim.think:
      q.lookX = math.sin(p * _tau) * .7;
      q.lookY = -.6;
      q.mouth = 'flat';
      q.rot = math.sin(p * _tau) * .03;
      q.fx.add(SumiFx('dots', t: p));
    case SumiAnim.hint:
      final e = _easeOut(_seg(p, 0, .4));
      q.armR = SumiArm(_lerp(.35, 2.4, e), -.6);
      q.mouth = 'open';
      q.browOn = true;
      q.brow = .3;
      q.prop = SumiProp('bulb', t: _seg(p, .2, 1));
    case SumiAnim.complete:
      final h1 = _hop(_seg(p, .05, .4)), h2 = _hop(_seg(p, .4, .7));
      q.y = -26 * h1 - 14 * h2;
      q.sy = 1 + .07 * (h1 + h2);
      q.sx = 2 - q.sy;
      q.rot = math.sin(_seg(p, .05, .7) * _tau) * .06;
      q.armR = SumiArm(2.8 + .15 * math.sin(_seg(p, .05, .7) * _tau * 2), -.3);
      q.eyes = 'happy';
      q.mouth = 'grin';
      q.blush = 1;
      q.frillAmp = 4;
      q.fx
        ..add(SumiFx('sparkle', t: _seg(p, .1, 1)))
        ..add(SumiFx('bigstar', t: _seg(p, .2, 1)));
    case SumiAnim.localReady:
      final n = _hop(_seg(p, .1, .5));
      q.y = 3 * n;
      q.sy = 1 - .04 * n;
      q.eyes = 'happy';
      q.armR = SumiArm(_lerp(.35, 1.9, _easeOut(_seg(p, 0, .4))), -.8);
      q.prop = SumiProp('check', t: _seg(p, .2, .8));
    case SumiAnim.recover:
      final breath = _hop(_seg(p, .1, .9));
      q.sy = 1 + .05 * breath;
      q.sx = 1 + .03 * breath;
      q.eyes = breath > .4 ? 'closed' : 'open';
      q.armL = SumiArm(_lerp(.35, 1.1, breath), .4);
      q.armR = SumiArm(_lerp(.35, 1.1, breath), .4);
    case SumiAnim.listen:
      q.rot = .1;
      q.armR = SumiArm(2.5, 1.2);
      q.lookX = .8;
      q.mouth = 'o';
      q.fx.add(SumiFx('waves', t: p));
    case SumiAnim.compare:
      final side = math.sin(p * _tau);
      q.lookX = side;
      q.rot = side * .04;
      q.armL = SumiArm(1.4, -.1);
      q.armR = SumiArm(1.4, -.1);
      q.mouth = 'flat';
      q.prop = SumiProp('cards', side: side);
    case SumiAnim.musicCount:
      final beat = (p * 4).floor(), k = (p * 4) % 1;
      q.y = -6 * _hop(k);
      q.armR = SumiArm(_lerp(2.2, 1.0, _easeOut(k)), -.2);
      q.mouth = 'open';
      q.prop = SumiProp('count', beat: beat + 1, ph: k);
    case SumiAnim.designMake:
      q.armL = SumiArm(-.18, -1.6);
      q.armR = SumiArm(-.45 + .3 * math.sin(p * _tau * 2), .4);
      q.lookY = .8;
      q.lookX = .2;
      q.prop = SumiProp('sewing', t: p);
  }
  return q;
}

/// Paints one frame. Design space: 240 × 240 units, ground at y = 214.
class SumiPainter extends CustomPainter {
  final SumiAnim anim;
  final double progress, time;
  final SumiSkin skin;
  final bool darkMode, rtl;
  SumiPainter({
    required this.anim,
    required this.progress,
    required this.time,
    this.skin = SumiSkin.standard,
    this.darkMode = false,
    this.rtl = false,
  });

  static const _ink = SumiPalette._ink;
  static Paint _fill(Color c, [double a = 1]) =>
      Paint()..color = c.withValues(alpha: c.a * _clamp(a));
  static Paint _stroke(Color c, double w, [double a = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * _clamp(a))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final q = sumiPose(anim, progress, time);
    final pal = SumiPalette.of(q.skin ?? skin);
    final k = math.min(size.width, size.height) / 240;
    canvas.save();
    canvas.translate((size.width - 240 * k) / 2, (size.height - 240 * k) / 2);
    canvas.scale(k, k);
    if (rtl) {
      canvas.translate(240, 0);
      canvas.scale(-1, 1);
    }
    // Headroom for jumps.
    canvas.translate(120, 214);
    canvas.scale(.88, .88);
    canvas.translate(-120, -214);
    final ox = 120 + q.x, oy = 214.0;
    final lift = math.max(0.0, -q.y);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ox + 14, oy),
        width: 104 / (1 + lift / 70),
        height: 12 / (1 + lift / 70),
      ),
      _fill(darkMode ? const Color(0x59000000) : const Color(0x241E2559)),
    );
    if (darkMode) {
      final h = Offset(ox, oy - 96);
      canvas.drawCircle(
        h,
        118,
        Paint()
          ..shader = ui.Gradient.radial(h, 118, [
            const Color.fromRGBO(232, 247, 244, .30),
            const Color.fromRGBO(232, 247, 244, 0),
          ], [.15, 1]),
      );
    }
    if (q.glow > 0 || pal.aura) {
      final a = math.max(q.glow, pal.aura ? .45 : 0.0);
      final c = Offset(ox, oy - 100 + q.y);
      canvas.drawCircle(
        c,
        104,
        Paint()
          ..shader = ui.Gradient.radial(c, 104, [
            Color.fromRGBO(255, 210, 110, .55 * a),
            const Color.fromRGBO(255, 210, 110, 0),
          ], [.1, 1]),
      );
    }
    canvas.save();
    canvas.translate(ox, oy + q.y);
    canvas.translate(0, -90);
    canvas.rotate(q.rot);
    canvas.translate(0, 90);
    canvas.scale(q.sx, q.sy);
    if (q.prop?.k == 'board') _prop(canvas, q, pal);
    _tail(canvas, q, pal);
    _legs(canvas, q, pal);
    _body(canvas, q, pal);
    _head(canvas, q, pal);
    _face(canvas, q, pal);
    _arm(canvas, -1, q.armL, pal);
    _arm(canvas, 1, q.armR, pal);
    if (q.prop != null && q.prop!.k != 'board') _prop(canvas, q, pal);
    if (const ['book', 'globe', 'clock', 'sewing'].contains(q.prop?.k)) {
      _mitt(canvas, -1, q.armL, pal);
      _mitt(canvas, 1, q.armR, pal);
    }
    canvas.restore();
    canvas.save();
    canvas.translate(0, -18);
    _fx(canvas, q, ox, oy + q.y * .3);
    canvas.restore();
    canvas.restore();
  }

  Offset _tip(int side, SumiArm arm) {
    // Shoulders sit on the body edge; bending the arm shortens its reach.
    // Positive c bends the elbow inward, negative c pushes it outward.
    final sx = side * 31.0, sy = -80.0;
    final l = 40 * (1 - .22 * math.min(arm.c.abs(), 1.6));
    return Offset(sx + side * l * math.sin(arm.a), sy + l * math.cos(arm.a));
  }

  /// Soft style: limbs are single strokes with no outline.
  void _limb(Canvas c, Path path, SumiPalette pal, double w, Color col) {
    c.drawPath(path, _stroke(col, w));
  }

  /// Chunky tapered arm growing out of the side of the torso. A soft shade
  /// copy below it keeps a green arm readable over the green body.
  Path _armPath(int side, SumiArm arm, [Offset shift = Offset.zero]) {
    final s = Offset(side * 31.0, -80);
    final t = _tip(side, arm);
    final root = Offset(side * 24.0, -84);
    final m = (s + t) / 2;
    final d = t - s;
    final len = d.distance == 0 ? 1 : d.distance;
    final ctrl = Offset(
      m.dx + (-d.dy / len) * arm.c * 26 * side,
      m.dy + (d.dx / len) * arm.c * 26 * side,
    );
    const n = 16;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final k = i / n, u = 1 - k;
      final p = root * (u * u * u) + s * (3 * u * u * k) + ctrl * (3 * u * k * k) + t * (k * k * k);
      final g = (s - root) * (3 * u * u) + (ctrl - s) * (6 * u * k) + (t - ctrl) * (3 * k * k);
      final gl = g.distance == 0 ? 1.0 : g.distance;
      final nrm = Offset(-g.dy / gl, g.dx / gl);
      final w = 11.5 - 3 * k;
      left.add(p + nrm * w + shift);
      right.add(p - nrm * w + shift);
    }
    final path = Path()..moveTo(left[0].dx, left[0].dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _arm(Canvas c, int side, SumiArm arm, SumiPalette pal) {
    const shift = Offset(0, 2.5);
    final shade = _fill(pal.deep, .28);
    c.drawPath(_armPath(side, arm, shift), shade);
    c.drawCircle(_tip(side, arm) + shift, 12, shade);
    c.drawPath(_armPath(side, arm), _fill(pal.body));
    _mitt(c, side, arm, pal);
  }

  void _mitt(Canvas c, int side, SumiArm arm, SumiPalette pal) {
    final t = _tip(side, arm);
    c.drawCircle(t, 12, _fill(pal.body));
    c.drawArc(
      Rect.fromCircle(center: t + Offset(side * 2.5, 3.5), radius: 7.5),
      0,
      _pi,
      true,
      _fill(pal.deep, .45),
    );
  }

  void _tail(Canvas c, SumiPose q, SumiPalette pal) {
    final curl = 1 + .05 * math.sin(q.tent * .8) + .1 * (q.frillAmp - 2) / 6;
    const cx = 66.0, cy = -42.0, n = 48;
    final pts = <List<double>>[];
    for (var i = 0; i <= n; i++) {
      final t = i / n, a = _pi * 1.0 - t * _pi * 2.55 * curl;
      final r = 40 * math.pow(1 - t * .86, 1.15).toDouble();
      pts.add([cx + math.cos(a) * r, cy + math.sin(a) * r, 15 - 10.5 * t]);
    }
    void band(double scale, Color col, bool inner) {
      for (var i = 1; i <= n; i++) {
        final p = pts[i - 1], e = pts[i];
        final dx = e[0] - p[0], dy = e[1] - p[1];
        final l = math.sqrt(dx * dx + dy * dy) == 0 ? 1.0 : math.sqrt(dx * dx + dy * dy);
        final nx = -dy / l, ny = dx / l;
        final off = inner ? e[2] * .45 : 0.0;
        c.drawLine(
          Offset(p[0] + nx * off, p[1] + ny * off),
          Offset(e[0] + nx * off, e[1] + ny * off),
          _stroke(col, e[2] * scale),
        );
      }
    }

    c.drawPath(
      Path()
        ..moveTo(18, -46)
        ..quadraticBezierTo(26, -24, pts[0][0], pts[0][1]),
      _stroke(pal.body, 26),
    );
    band(1.85, pal.body, false);
    band(.85, pal.deep, true);
  }

  void _legs(Canvas c, SumiPose q, SumiPalette pal) {
    for (final s in const [-1.0, 1.0]) {
      final w = math.sin(q.tent + s) * 1.2;
      _limb(
        c,
        Path()
          ..moveTo(s * 15, -40)
          ..quadraticBezierTo(s * 24, -26 + w, s * 21, -10),
        pal,
        18,
        s > 0 ? pal.deep : pal.body,
      );
      final foot = Path()
        ..addArc(Rect.fromCenter(center: Offset(s * 23, -5), width: 30, height: 18), _pi, _pi)
        ..lineTo(s * 23 + 15, -3)
        ..lineTo(s * 23 - 15, -3)
        ..close();
      c.drawPath(foot, _fill(pal.deep));
    }
  }

  void _body(Canvas c, SumiPose q, SumiPalette pal) {
    final torso = Rect.fromCenter(center: const Offset(0, -58), width: 80, height: 80);
    c.drawOval(torso, _fill(pal.body));
    c.save();
    c.clipPath(Path()..addOval(torso));
    c.drawOval(
      Rect.fromCenter(center: const Offset(33, -56), width: 36, height: 88),
      _fill(pal.deep),
    );
    c.restore();
    c.drawOval(
      Rect.fromCenter(center: const Offset(-3, -54), width: 50, height: 62),
      _fill(pal.belly),
    );
    for (final y in const [-60.0, -48.0]) {
      c.drawLine(Offset(-15, y), Offset(9, y), _stroke(pal.stripe, 4));
    }
  }

  void _head(Canvas c, SumiPose q, SumiPalette pal) {
    final wob = math.sin(q.frillPhase) * (q.frillAmp - 2) * .7;
    final peakY = -196 - 14 * (q.frillScale - 1) * 4;
    final head = Path()
      ..moveTo(-52, -118)
      ..cubicTo(-56, -146, -44, -162, -28, -166)
      ..cubicTo(-18 + wob, peakY + 16, -4 + wob, peakY, 6 + wob, peakY)
      ..cubicTo(18 + wob, peakY, 30, -176, 34, -164)
      ..cubicTo(48, -160, 56, -142, 52, -118)
      ..cubicTo(50, -90, -50, -90, -52, -118)
      ..close();
    c.drawPath(head, _fill(pal.body));
    c.save();
    c.clipPath(head);
    c.translate(50, -126);
    c.rotate(-.2);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 44, height: 88),
      _fill(pal.deep),
    );
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(-10, -164)
        ..quadraticBezierTo(-6 + wob, peakY + 20, 2 + wob, peakY + 8),
      _stroke(pal.crest, 7),
    );
    for (final x in const [-5.0, 5.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, -124), width: 3.2, height: 2.2),
        _fill(pal.line, .55),
      );
    }
  }

  void _eye(Canvas c, int side, SumiPose q, SumiPalette pal) {
    final ex = side * 42.0, ey = -132.0;
    const r = 23.0;
    c.drawCircle(Offset(ex, ey), r, _fill(pal.ring));
    if (q.eyes == 'happy') {
      c.drawArc(
        Rect.fromCircle(center: Offset(ex, ey + 5), radius: 8.5),
        _pi * 1.15,
        _pi * .7,
        false,
        _stroke(pal.iris, 4),
      );
      return;
    }
    if (q.eyes == 'closed') {
      c.drawArc(
        Rect.fromCircle(center: Offset(ex, ey - 2), radius: 8.5),
        _pi * .15,
        _pi * .7,
        false,
        _stroke(pal.iris, 4),
      );
      return;
    }
    // Turret eye: the white swivels toward the gaze, each leaning outward.
    final wr = q.eyes == 'wide' ? 21.0 : 19.5;
    final lx = q.lookX + side * .12, ly = q.lookY;
    final ap = Offset(ex + lx * 3, ey + ly * 3);
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(ex, ey), radius: r - 1)));
    c.drawCircle(ap, wr, _fill(const Color(0xFFFFFDF7)));
    final pr = q.eyes == 'wide' ? 6.0 : 9.5;
    final pupil = ap + Offset(lx * 5, ly * 5);
    c.drawOval(
      Rect.fromCenter(center: pupil, width: pr * 2, height: pr * 2.24),
      _fill(pal.iris),
    );
    c.drawCircle(pupil + Offset(-pr * .35, -pr * .45), pr * .28, _fill(Colors.white));
    if (q.eyeOpen < 1) {
      c.drawRect(
        Rect.fromLTWH(ex - r, ey - r, r * 2, r * 2 * (1 - q.eyeOpen)),
        _fill(pal.ring),
      );
    }
    c.restore();
  }

  void _face(Canvas c, SumiPose q, SumiPalette pal) {
    _eye(c, -1, q, pal);
    _eye(c, 1, q, pal);
    if (q.browOn) {
      for (final s in const [-1.0, 1.0]) {
        final tilt = q.brow * .35 * s;
        c.drawLine(
          Offset(s * 42 - 10, -163 + tilt * 8 * -1 * s),
          Offset(s * 42 + 10, -163 + tilt * 8 * s),
          _stroke(pal.line, 3.4),
        );
      }
    }
    if (q.blush > 0) {
      final b = _fill(pal.cheek, .8 * q.blush);
      c.drawOval(Rect.fromCenter(center: const Offset(-26, -110), width: 14, height: 8), b);
      c.drawOval(Rect.fromCenter(center: const Offset(26, -110), width: 14, height: 8), b);
    }
    const my = -112.0;
    final st = _stroke(pal.line, 2.8), fl = _fill(pal.line);
    switch (q.mouth) {
      case 'smile':
        c.drawPath(
          Path()
            ..moveTo(-13, my - 2)
            ..quadraticBezierTo(0, my + 6, 13, my - 2),
          st,
        );
      case 'smirk':
        c.drawPath(
          Path()
            ..moveTo(-12, my)
            ..quadraticBezierTo(4, my + 4, 15, my - 5),
          st,
        );
      case 'grin':
        c.drawPath(
          Path()
            ..moveTo(-17, my - 3)
            ..quadraticBezierTo(0, my + 15, 17, my - 3)
            ..close(),
          fl,
        );
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, my + 4), width: 12, height: 6),
          _fill(pal.cheek),
        );
      case 'open':
        c.drawOval(Rect.fromCenter(center: const Offset(0, my + 1), width: 14, height: 12), fl);
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, my + 4), width: 8, height: 4),
          _fill(pal.cheek),
        );
      case 'o':
        c.drawOval(Rect.fromCenter(center: const Offset(0, my), width: 7.2, height: 7.2), fl);
      case 'whistle':
        c.drawOval(Rect.fromCenter(center: const Offset(6, my), width: 6, height: 6.4), st);
      case 'flat':
        c.drawLine(const Offset(-12, my), const Offset(12, my), st);
      case 'frown':
        c.drawPath(
          Path()
            ..moveTo(-12, my + 3)
            ..quadraticBezierTo(0, my - 5, 12, my + 3),
          st,
        );
      case 'grit':
        c.drawRect(const Rect.fromLTWH(-10, my - 4, 20, 8), st);
        c.drawLine(const Offset(-10, my), const Offset(10, my), st);
      case 'wobble':
        final path = Path();
        for (var i = 0; i <= 12; i++) {
          final x = -12.0 + i * 2, y = my + math.sin(i * 1.4) * 1.8;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        c.drawPath(path, st);
    }
  }

  static void _star(Canvas c, Offset at, double r, Paint p) {
    if (r <= 0) return;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isOdd ? r * .45 : r;
      final a = i * _pi / 5 - _pi / 2;
      final pt = at + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    c.drawPath(path..close(), p);
  }

  static void _text(Canvas c, String s, Offset center, double size, Color color) {
    if (size <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _prop(Canvas c, SumiPose q, SumiPalette pal) {
    final pr = q.prop!;
    final lt = _tip(-1, q.armL), rt = _tip(1, q.armR);
    c.save();
    switch (pr.k) {
      case 'bubbles':
        const cols = [Color(0xFF3FB8AF), Color(0xFFFF7B69), Color(0xFFFFC64A)];
        for (var i = 0; i < 3; i++) {
          final ph = (pr.t + i / 3) % 1, k = ph < .5 ? ph * 2 : 2 - ph * 2;
          final mid = (lt.dx + rt.dx) / 2, half = (rt.dx - lt.dx) / 2;
          final x = mid - half * 1.3 * math.cos(k * _pi);
          final base = _lerp(lt.dy, rt.dy, k) - 14;
          final y = base + (-205 - base) * _hop(k);
          c.drawCircle(Offset(x, y), 7, _fill(cols[i]));
          c.drawCircle(Offset(x - 2, y - 2), 2, _fill(Colors.white, .7));
        }
      case 'book':
        final flip = (pr.t * 2) % 1;
        c.translate(0, -60);
        c.drawRect(const Rect.fromLTWH(-26, -16, 52, 26), _fill(const Color(0xFFFF7B69)));
        c.drawRect(const Rect.fromLTWH(-24, -18, 23, 24), _fill(const Color(0xFFFFF6E8)));
        c.drawRect(const Rect.fromLTWH(1, -18, 23, 24), _fill(const Color(0xFFFFF6E8)));
        final w = math.cos(flip * _pi) * 23;
        c.drawRect(Rect.fromLTWH(math.min(1, 1 + w), -18, w.abs(), 24), _fill(const Color(0xFFF2E6D2)));
        for (var i = 0; i < 3; i++) {
          c.drawLine(Offset(-20, -12.0 + i * 6), Offset(-5, -12.0 + i * 6), _stroke(const Color(0xFFC9B8A0), 1.2));
        }
      case 'pearl':
        final g = .5 + .5 * math.sin(pr.t * _tau);
        c.drawCircle(rt + const Offset(0, -12), 12, _fill(const Color(0xFFFFF4F8)));
        c.drawCircle(rt + const Offset(0, -12), 12, _stroke(const Color(0xFFE8C9D8), 1.5));
        _star(c, rt + const Offset(8, -20), 3 + 3 * g, _fill(Colors.white, g));
      case 'globe':
        c.translate(0, -60);
        final ball = Rect.fromCircle(center: Offset.zero, radius: 18);
        c.drawOval(ball, _fill(const Color(0xFF4AA8E0)));
        c.save();
        c.clipPath(Path()..addOval(ball));
        final off = (pr.t * 72) % 72 - 36;
        for (final l in const [
          [-14.0, -6.0, 10.0, 7.0],
          [10.0, 6.0, 8.0, 6.0],
          [-2.0, 10.0, 6.0, 4.0],
        ]) {
          for (final o in const [0.0, 72.0]) {
            c.drawOval(
              Rect.fromCenter(center: Offset(l[0] + off + o - 36, l[1]), width: l[2] * 2, height: l[3] * 2),
              _fill(const Color(0xFF7CC96B)),
            );
          }
        }
        c.restore();
        c.drawOval(ball, _stroke(const Color(0xFF2B6E99), 2));
      case 'headphones':
        c.drawArc(
          Rect.fromCircle(center: const Offset(0, -128), radius: 66),
          _pi * 1.12,
          _pi * .76,
          false,
          _stroke(_ink, 5),
        );
        for (final x in const [-64.0, 64.0]) {
          final cup = Rect.fromCenter(center: Offset(x, -132), width: 18, height: 28);
          c.drawOval(cup, _fill(const Color(0xFFFF7B69)));
          c.drawOval(cup, _stroke(pal.line, 3.5));
        }
      case 'inkpot':
        c.translate(-4, -46);
        c.drawPath(
          Path()
            ..moveTo(-14, -10)
            ..lineTo(14, -10)
            ..lineTo(18, 12)
            ..lineTo(-18, 12)
            ..close(),
          _fill(const Color(0xFF5A6A86)),
        );
        const hues = [Color(0xFF3FB8AF), Color(0xFF7B6CF0), Color(0xFFFF7B69)];
        c.drawOval(
          Rect.fromCenter(center: const Offset(0, -10), width: 28, height: 8),
          _fill(hues[(pr.t * 3).floor() % 3]),
        );
        c.drawLine(
          Offset(rt.dx + 4, rt.dy + 36),
          Offset(math.sin(pr.t * _tau * 2) * 6, -8),
          _stroke(const Color(0xFFB98A55), 3),
        );
      case 'shades':
        if (pr.v <= 0) break;
        final y = _lerp(-178, -130, pr.v);
        final a = _clamp(pr.v * 3);
        final f = _fill(_ink, a);
        c.drawRRect(RRect.fromLTRBR(-64, y - 15, -18, y + 15, const Radius.circular(11)), f);
        c.drawRRect(RRect.fromLTRBR(18, y - 15, 64, y + 15, const Radius.circular(11)), f);
        c.drawRect(Rect.fromLTWH(-20, y - 6, 40, 4), f);
        final hl = _fill(Colors.white, .45 * a);
        for (final x0 in const [-54.0, 28.0]) {
          c.drawPath(
            Path()
              ..moveTo(x0, y - 8)
              ..lineTo(x0 + 8, y - 8)
              ..lineTo(x0 + 2, y + 4)
              ..lineTo(x0 - 4, y + 4)
              ..close(),
            hl,
          );
        }
      case 'clock':
        c.translate(0, -60);
        c.drawCircle(Offset.zero, 18, _fill(Colors.white));
        c.drawCircle(Offset.zero, 18, _stroke(const Color(0xFFFF7B69), 4));
        final a1 = pr.t * _tau * 2 - _pi / 2, a2 = pr.t * _tau / 6 - _pi / 2;
        c.drawLine(Offset.zero, Offset(math.cos(a1) * 13, math.sin(a1) * 13), _stroke(_ink, 2.5));
        c.drawLine(Offset.zero, Offset(math.cos(a2) * 8, math.sin(a2) * 8), _stroke(_ink, 2.5));
      case 'tape':
        c.drawRect(Rect.fromLTWH(lt.dx, lt.dy - 4, rt.dx - lt.dx, 8), _fill(const Color(0xFFFFC64A)));
        for (var x = lt.dx + 4; x < rt.dx; x += 5) {
          final tall = ((x - lt.dx) / 5).round().isOdd;
          c.drawLine(Offset(x, lt.dy - 4), Offset(x, lt.dy - (tall ? 1 : -1)), _stroke(const Color(0xFFB5821A), 1));
        }
        c.drawCircle(lt, 7, _fill(const Color(0xFFFF7B69)));
      case 'board':
        c.drawRect(const Rect.fromLTWH(-124, -150, 70, 54), _fill(const Color(0xFF2F4F46)));
        c.drawRect(const Rect.fromLTWH(-124, -150, 70, 54), _stroke(const Color(0xFFB98A55), 4));
        c.drawPath(
          Path()
            ..moveTo(-114, -132)
            ..lineTo(-96, -112)
            ..lineTo(-78, -130),
          _stroke(Colors.white, 2, .85),
        );
        c.drawCircle(const Offset(-70, -112), 4, _stroke(Colors.white, 2, .85));
      case 'barbell':
        final y = math.min(lt.dy, rt.dy);
        c.drawLine(Offset(lt.dx - 18, y), Offset(rt.dx + 18, y), _stroke(const Color(0xFF5A6A86), 4));
        c.drawRect(Rect.fromLTWH(lt.dx - 24, y - 10, 8, 20), _fill(const Color(0xFFFF7B69)));
        c.drawRect(Rect.fromLTWH(rt.dx + 16, y - 10, 8, 20), _fill(const Color(0xFFFF7B69)));
      case 'balloon':
        final b = Offset(rt.dx + 6 + math.sin(pr.t * _tau) * 4, rt.dy - 56);
        c.drawPath(
          Path()
            ..moveTo(rt.dx, rt.dy)
            ..quadraticBezierTo(b.dx - 6, (rt.dy + b.dy) / 2, b.dx, b.dy + 20),
          _stroke(const Color(0xFF8A93B5), 1.5),
        );
        c.drawOval(Rect.fromCenter(center: b, width: 34, height: 40), _fill(const Color(0xFFFF7B69)));
        _text(c, pr.label, b + const Offset(0, 1), 20, Colors.white);
      case 'bulb':
        if (pr.t <= 0) break;
        final s = _backOut(pr.t);
        c.translate(rt.dx + 6, -205);
        c.scale(s, s);
        c.drawCircle(Offset.zero, 10, _fill(const Color(0xFFFFD45A)));
        c.drawRect(const Rect.fromLTWH(-5, 8, 10, 6), _fill(const Color(0xFFC9CED8)));
        for (var i = 0; i < 5; i++) {
          final a = -_pi / 2 + (i - 2) * .55;
          c.drawLine(
            Offset(math.cos(a) * 14, math.sin(a) * 14),
            Offset(math.cos(a) * 20, math.sin(a) * 20),
            _stroke(const Color(0xFFFFD45A), 2.5),
          );
        }
      case 'check':
        if (pr.t <= 0) break;
        c.translate(rt.dx + 4, rt.dy - 16);
        final s = _backOut(pr.t);
        c.scale(s, s);
        c.drawCircle(Offset.zero, 12, _fill(const Color(0xFF50C86A)));
        c.drawPath(
          Path()
            ..moveTo(-5, 0)
            ..lineTo(-1, 4)
            ..lineTo(6, -4),
          _stroke(Colors.white, 3.4),
        );
      case 'cards':
        for (final s in const [-1.0, 1.0]) {
          final lift = s * pr.side > 0 ? -6.0 : 0.0;
          final accent = s < 0 ? const Color(0xFFFF7B69) : const Color(0xFF3FB8AF);
          final card = RRect.fromLTRBR(s * 74 - 18, -112 + lift, s * 74 + 18, -68 + lift, const Radius.circular(6));
          c.drawRRect(card, _fill(s < 0 ? const Color(0xFFFFE3DF) : const Color(0xFFDDF5F2)));
          c.drawRRect(card, _stroke(accent, 2));
          c.drawRect(Rect.fromLTWH(s * 74 - 10, -100 + lift, 20, 3), _fill(accent));
          c.drawRect(Rect.fromLTWH(s * 74 - 10, -92 + lift, 14, 3), _fill(accent));
        }
      case 'count':
        for (var i = 1; i <= 4; i++) {
          final on = i == pr.beat;
          c.drawCircle(
            Offset(-36.0 + (i - 1) * 24, -192),
            on ? 7 + 3 * _hop(pr.ph) : 5,
            _fill(on ? const Color(0xFFFF7B69) : const Color(0x2E2B3474)),
          );
        }
      case 'sewing':
        c.translate(0, -58);
        c.drawPath(
          Path()
            ..moveTo(-26, -8)
            ..lineTo(24, -12)
            ..lineTo(26, 10)
            ..lineTo(-24, 12)
            ..close(),
          _fill(const Color(0xFF7B6CF0)),
        );
        final end = -20 + 40 * pr.t;
        for (var x = -20.0; x < end; x += 6) {
          c.drawLine(Offset(x, 0), Offset(math.min(x + 3, end), 0), _stroke(Colors.white, 1.5));
        }
        final ny = -1 - 8 * _hop((pr.t * 6) % 1);
        c.drawLine(Offset(end, ny - 8), Offset(end, ny + 2), _stroke(const Color(0xFFC9CED8), 2));
    }
    c.restore();
  }

  void _fx(Canvas c, SumiPose q, double ox, double oy) {
    const sparkCols = [Color(0xFFFFC64A), Color(0xFF3FB8AF), Color(0xFFFF7B69)];
    for (final f in q.fx) {
      switch (f.k) {
        case 'sparkle':
          if (f.t <= 0 || f.t >= 1) break;
          final n = f.small ? 4 : 7;
          for (var i = 0; i < n; i++) {
            final a = i / n * _tau + .3, d = 50 + 40 * _easeOut(f.t);
            _star(
              c,
              Offset(ox + math.cos(a) * d, oy - 86 + math.sin(a) * d * .8),
              5 * (1 - f.t * .5),
              _fill(sparkCols[i % 3], 1 - f.t),
            );
          }
        case 'stars':
          if (f.t <= 0 || f.t >= 1) break;
          for (var i = 0; i < 3; i++) {
            final x = ox + (i - 1) * 46,
                y = oy - 170 - 20 * _easeOut(f.t) + (i - 1).abs() * 14;
            _star(
              c,
              Offset(x, y),
              9 * _backOut(_clamp(f.t * 2.5 - i * .3)),
              _fill(const Color(0xFFFFC64A), 1 - math.max(0.0, f.t - .6) / .4),
            );
          }
        case 'bigstar':
          // Ground-anchored beside the head so the hop never clips it.
          if (f.t <= 0) break;
          final s = _backOut(_clamp(f.t * 2));
          final g = Offset(ox - 66, oy - q.y * .3 - 172);
          _star(c, g, 15 * s, _fill(const Color(0xFFFFC64A)));
          _star(c, g - const Offset(3, 3), 4.5 * s, _fill(Colors.white, .6));
        case 'sweat':
          if (f.t <= 0) break;
          final z = f.big ? 2.0 : 1.0, x = ox + 46, y = oy - 128 + 18 * f.t;
          c.drawPath(
            Path()
              ..moveTo(x, y - 8 * z)
              ..quadraticBezierTo(x + 6 * z, y, x, y + 4 * z)
              ..quadraticBezierTo(x - 6 * z, y, x, y - 8 * z),
            _fill(const Color(0xFF7FD3F7), 1 - f.t * .6),
          );
        case 'notes':
          for (var i = 0; i < 2; i++) {
            final t = (f.t + i * .5) % 1;
            final mouth = f.from == 'mouth';
            final x = ox + (mouth ? 14 : 46) + t * 26 + math.sin(t * _tau) * 6,
                y = oy - (mouth ? 92 : 130) - t * 50;
            final p = _fill(const Color(0xFF7B6CF0), 1 - t);
            c.save();
            c.translate(x, y);
            c.rotate(-.4);
            c.drawOval(Rect.fromCenter(center: Offset.zero, width: 9, height: 7), p);
            c.restore();
            c.drawRect(Rect.fromLTWH(x + 3, y - 14, 1.8, 14), p);
            c.drawRect(Rect.fromLTWH(x + 3, y - 14, 7, 2.5), p);
          }
        case 'fish':
          c.save();
          c.translate(ox + f.x, oy + f.y);
          c.scale(f.dir >= 0 ? 1 : -1, 1);
          final p = _fill(const Color(0xFFFFB547));
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 12), p);
          c.drawPath(
            Path()
              ..moveTo(-7, 0)
              ..lineTo(-15, -6)
              ..lineTo(-15, 6)
              ..close(),
            p,
          );
          c.drawCircle(const Offset(4, -1.5), 1.4, _fill(_ink));
          c.restore();
        case 'puffs':
          if (f.t <= 0 || f.t >= 1) break;
          for (var i = 0; i < 4; i++) {
            final t = _clamp(f.t * 1.4 - i * .12);
            c.drawCircle(
              Offset(ox + (i - 1.5) * 12, oy + 22 + t * 10),
              6 + 6 * t,
              _fill(const Color(0xFF5A6A9E), (1 - t) * .5),
            );
          }
        case 'question':
          _text(c, '?', Offset(ox + 48, oy - 148 + math.sin(f.t * _tau) * 3), 26, const Color(0xFF7B6CF0));
        case 'exclaim':
          _text(c, '!', Offset(ox + 46, oy - 148), 28 * _backOut(_clamp(f.t)), const Color(0xFFFF7B69));
        case 'dots':
          for (var i = 0; i < 3; i++) {
            final k = _hop(((f.t * 1.5) - i * .2 + 1) % 1);
            c.drawCircle(
              Offset(ox + 40 + i * 11, oy - 146 - 4 * k),
              4,
              _fill(const Color(0xFF7B6CF0), .35 + .65 * k),
            );
          }
        case 'waves':
          for (var i = 0; i < 3; i++) {
            final t = (f.t + i / 3) % 1;
            c.drawArc(
              Rect.fromCircle(center: Offset(ox + 56, oy - 106), radius: 8 + t * 22),
              -.7,
              1.4,
              false,
              _stroke(const Color(0xFF3FB8AF), 2.5, 1 - t),
            );
          }
        case 'trail':
          for (var i = 0; i < 3; i++) {
            final y = oy - 110 + i * 26;
            c.drawLine(
              Offset(ox - 60 - i * 6, y),
              Offset(ox - 90 - i * 14, y),
              _stroke(const Color(0xFF3FB8AF), 4, .7 - i * .18),
            );
          }
        case 'burst':
          if (f.t <= 0 || f.t >= 1) break;
          final r = 40 + 90 * _easeOut(f.t);
          final p = _stroke(const Color(0xFFFFC34D), 8 * (1 - f.t) + 1, 1 - f.t);
          final ctr = Offset(ox, oy - 84);
          c.drawCircle(ctr, r, p);
          for (var i = 0; i < 12; i++) {
            final a = i * _tau / 12;
            final d = Offset(math.cos(a), math.sin(a));
            c.drawLine(ctr + d * r * .7, ctr + d * r, p);
          }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SumiPainter old) =>
      old.progress != progress ||
      old.time != time ||
      old.anim != anim ||
      old.skin != skin ||
      old.darkMode != darkMode ||
      old.rtl != rtl;
}
