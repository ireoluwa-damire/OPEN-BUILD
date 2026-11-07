// Sumi — code-drawn chameleon companion (soft style, matches the approved character sheet).
// One pose function per animation; the Flutter port (sumi_mascot.dart) mirrors
// this file 1:1. No reference artwork, paths, or timings from any other mascot.
(function (root) {
  const PI = Math.PI, TAU = PI * 2;
  const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
  const lerp = (a, b, t) => a + (b - a) * t;
  const seg = (p, a, b) => clamp((p - a) / (b - a));
  const easeOut = (t) => 1 - Math.pow(1 - t, 3);
  const easeInOut = (t) => (t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  const backOut = (t) => { const c = 1.70158; return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2); };
  const hop = (t) => Math.sin(clamp(t) * PI); // 0→1→0
  const blink = (time) => { const k = time % 3.4; return k > 3.25 ? Math.abs(Math.cos((k - 3.25) / .15 * PI)) : 1; };

  const SKINS = {
    default: { body: '#22C08B', deep: '#14A070', ring: '#5FE0AA', belly: '#FFD93F', stripe: '#F4B630', crest: '#FFD93F', cheek: '#FF9C8F', iris: '#1C2433', line: '#0E7A55' },
    midnight: { body: '#5257B8', deep: '#3A3E96', ring: '#8E93F0', belly: '#9FDCFF', stripe: '#6FB8E8', crest: '#9FDCFF', cheek: '#FF9AD0', iris: '#1C2433', line: '#262A6E' },
    glow: { body: '#5ED9E8', deep: '#3BB5CF', ring: '#A8F1F7', belly: '#FFE08A', stripe: '#F5C451', crest: '#FF9AD0', cheek: '#FF8A7A', iris: '#1C2433', line: '#1F7F96', aura: true },
    gold: { body: '#FFC93F', deep: '#E9A514', ring: '#FFE69A', belly: '#FFF3C4', stripe: '#F2C55A', crest: '#FF7B69', cheek: '#FF7B69', iris: '#1C2433', line: '#9A6408' },
  };


  function basePose() {
    return {
      x: 0, y: 0, rot: 0, sx: 1, sy: 1, alpha: 1,
      eyes: 'open', eyeOpen: 1, lookX: 0, lookY: 0,
      brow: 0, browOn: false, mouth: 'smile', blush: 0,
      armL: { a: .35, c: -1.5 }, armR: { a: .35, c: -1.5 },
      frillAmp: 2, frillPhase: 0, frillScale: 1, tent: 0,
      glow: 0, skin: null, prop: null, fx: [],
    };
  }

  // ---------- animation library ----------
  // group / duo describe the equivalent slot in the Duo reference inventory.
  const A = [];
  const def = (id, group, duo, loop, dur, f, note) => A.push({ id, group, duo, loop, dur, f, note: note || '' });

  const idleMotion = (P, time) => {
    const b = Math.sin(time * TAU / 3);
    P.y = b * 1.6; P.sy = 1 + b * .012; P.sx = 1 - b * .008;
    P.frillPhase = time * 2.2; P.tent = time * 1.6; P.eyeOpen = blink(time);
  };

  // Lesson reactions — Duo/cast state machine (reset_trig, correct_trig, incorrect_trig)
  def('idle', 'Lesson reactions', 'reset_trig — neutral / unanswered', true, 3000, (P, p, time) => { idleMotion(P, time); });
  def('correct', 'Lesson reactions', 'correct_trig — success reaction', false, 900, (P, p, time) => {
    idleMotion(P, time);
    const h = hop(seg(p, .1, .6));
    P.y = -22 * h; P.sy = 1 + .08 * h - .1 * hop(seg(p, 0, .12)) - .08 * hop(seg(p, .6, .72)); P.sx = 2 - P.sy;
    const up = easeOut(seg(p, .05, .3));
    P.armL = { a: lerp(.35, 2.5, up), c: -.3 }; P.armR = { a: lerp(.35, 2.5, up), c: -.3 };
    P.eyes = 'happy'; P.mouth = 'grin'; P.blush = 1;
    P.fx.push({ k: 'sparkle', t: seg(p, .15, 1) });
  });
  def('incorrect', 'Lesson reactions', 'incorrect_trig — retry reaction', false, 1000, (P, p, time) => {
    idleMotion(P, time);
    const d = easeOut(seg(p, 0, .2)), back = seg(p, .75, 1), slump = d * (1 - back);
    P.sy = 1 - .08 * slump; P.sx = 1 + .04 * slump; P.rot = -.12 * slump; P.y = 3 * slump;
    P.lookY = .6 * (1 - back); P.lookX = -.3 * (1 - back);
    P.eyes = 'open'; P.lookY = .8 * (1 - back); P.browOn = back < 1; P.brow = -1.2;
    P.mouth = p < .75 ? 'frown' : 'smile';
    const droop = { a: lerp(.35, .15, slump), c: lerp(-1.5, .2, slump) };
    P.armL = droop; P.armR = { ...droop };
    P.fx.push({ k: 'sweat', t: seg(p, .1, .8), big: true });
  });

  // Path activities — one slot per Duo path animation
  def('juggle', 'Path activities', 'DUO_BALL', true, 1600, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: lerp(1.65, 1.95, hop(p * 2 % 1)), c: -.3 }; P.armR = { a: lerp(1.95, 1.65, hop(p * 2 % 1)), c: -.3 };
    P.lookY = -.8; P.lookX = Math.sin(p * TAU) * .6; P.mouth = 'o';
    P.prop = { k: 'bubbles', t: p };
  });
  def('reading', 'Path activities', 'DUO_BOOKS', true, 3200, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: -.18, c: -1.6 }; P.armR = { a: -.18, c: -1.6 };
    P.lookY = .8; P.lookX = Math.sin(p * TAU) * .5; P.mouth = 'smile';
    P.prop = { k: 'book', t: p };
  });
  def('fish_friend', 'Path activities', 'DUO_BUTTERFLY', true, 3000, (P, p, time) => {
    idleMotion(P, time);
    const fx = Math.cos(p * TAU) * 58, fy = -100 + Math.sin(p * TAU * 2) * 14;
    P.lookX = clamp(fx / 50, -1, 1); P.lookY = clamp((fy + 82) / 30, -1, 1);
    P.rot = fx / 900; P.mouth = 'grin'; P.blush = .6;
    P.armR = { a: 1.2 + .3 * Math.sin(p * TAU), c: -.3 };
    P.fx.push({ k: 'fish', x: fx, y: fy, dir: -Math.sin(p * TAU) });
  });
  def('cheer', 'Path activities', 'DUO_CHEER', true, 1000, (P, p, time) => {
    idleMotion(P, time);
    const h = hop(p);
    P.y = -14 * h; P.sy = 1 + .06 * h; P.sx = 1 - .04 * h;
    P.armL = { a: 2.4 + .3 * Math.sin(p * TAU * 2), c: -.4 }; P.armR = { a: 2.4 - .3 * Math.sin(p * TAU * 2), c: -.4 };
    P.eyes = 'happy'; P.mouth = 'grin'; P.blush = 1;
  });
  def('pearl', 'Path activities', 'DUO_GEM', true, 2600, (P, p, time) => {
    idleMotion(P, time);
    P.armR = { a: 2.2, c: -.2 }; P.lookX = .7; P.lookY = -.8; P.mouth = 'o';
    P.prop = { k: 'pearl', t: p };
  });
  def('globe', 'Path activities', 'DUO_GLOBE', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: -.18, c: -1.6 }; P.armR = { a: -.18, c: -1.6 }; P.lookY = .7; P.mouth = 'smile';
    P.prop = { k: 'globe', t: p };
  });
  def('headphones', 'Path activities', 'DUO_HEADPHONES', true, 1000, (P, p, time) => {
    idleMotion(P, time);
    const beat = hop(p * 2 % 1);
    P.y = -4 * beat; P.rot = Math.sin(p * TAU) * .08; P.eyes = 'happy'; P.mouth = 'smile';
    P.armL = { a: .7 + .5 * beat, c: -.2 }; P.armR = { a: .7 + .5 * (1 - beat), c: -.2 };
    P.prop = { k: 'headphones' };
    P.fx.push({ k: 'notes', t: p });
  });
  def('jet_hop', 'Path activities', 'DUO_JUMPFLAP', true, 1600, (P, p, time) => {
    idleMotion(P, time);
    const crouch = hop(seg(p, 0, .2)), air = hop(seg(p, .18, .82)), land = hop(seg(p, .8, 1));
    P.y = -48 * Math.sin(seg(p, .18, .82) * PI);
    P.sy = 1 - .14 * crouch - .1 * land + .1 * air * (p < .5 ? 1 : 0); P.sx = 2 - P.sy;
    const flap = Math.sin(p * TAU * 5) * air;
    P.armL = { a: 1.6 + .8 * flap, c: .1 }; P.armR = { a: 1.6 + .8 * flap, c: .1 };
    P.frillAmp = 2 + 5 * air; P.mouth = air > .3 ? 'open' : 'smile'; P.eyes = air > .3 ? 'wide' : 'open';
    P.fx.push({ k: 'puffs', t: seg(p, .18, .6) });
  });
  def('ink_mix', 'Path activities', 'DUO_POTION', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: -.18, c: -1.6 }; P.armR = { a: -.2 + .25 * Math.sin(p * TAU * 2), c: .5 };
    P.lookY = .8; P.mouth = 'o';
    P.prop = { k: 'inkpot', t: p };
    if (p > .6) P.fx.push({ k: 'sparkle', t: seg(p, .6, 1), small: true });
  });
  def('shades', 'Path activities', 'DUO_SUNGLASSES', true, 2600, (P, p, time) => {
    idleMotion(P, time);
    const on = easeInOut(seg(p, .1, .35)), off = easeInOut(seg(p, .8, 1));
    const v = on * (1 - off);
    P.armR = { a: lerp(.35, 2.1, hop(seg(p, .05, .4)) + hop(seg(p, .75, 1))), c: -.4 };
    P.mouth = v > .5 ? 'smirk' : 'smile'; P.rot = .05 * v;
    P.prop = { k: 'shades', v };
  });
  def('twirl', 'Path activities', 'DUO_TWIRL', true, 1400, (P, p, time) => {
    idleMotion(P, time);
    const s = easeInOut(seg(p, .1, .8));
    P.sx = Math.cos(s * TAU); if (Math.abs(P.sx) < .25) P.sx = .25 * Math.sign(P.sx || 1);
    P.y = -10 * hop(seg(p, .1, .8));
    P.armL = { a: 1.9, c: 0 }; P.armR = { a: 1.9, c: 0 }; P.eyes = 'happy'; P.mouth = 'grin';
    P.frillAmp = 2 + 4 * hop(seg(p, .1, .8));
  });
  def('humming', 'Path activities', 'DUO_WHISTLING', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.mouth = 'whistle'; P.eyes = 'happy'; P.rot = Math.sin(p * TAU) * .05;
    P.armL = { a: .5, c: .6 }; P.armR = { a: .5, c: .6 };
    P.fx.push({ k: 'notes', t: p, from: 'mouth' });
  });

  // Math path slots
  def('clock', 'Math path', 'DUO_CLOCK (math)', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: -.18, c: -1.6 }; P.armR = { a: -.18, c: -1.6 }; P.lookY = .7; P.lookX = Math.sin(p * TAU) * .3;
    P.prop = { k: 'clock', t: p };
  });
  def('tape_measure', 'Math path', 'DUO_RULER (math)', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    const e = hop(p);
    P.armL = { a: lerp(1.2, 1.7, e), c: 0 }; P.armR = { a: lerp(1.2, 1.7, e), c: 0 };
    P.lookX = -.2; P.mouth = 'smile';
    P.prop = { k: 'tape', ext: e };
  });

  // Coaching poses (Duo chess-pose slots)
  def('board', 'Coaching poses', 'DUO_BLACKBOARD (chess)', true, 2800, (P, p, time) => {
    idleMotion(P, time);
    P.x = 18; P.armL = { a: 1.75 + .1 * Math.sin(p * TAU * 2), c: -.1 }; P.lookX = -.9; P.mouth = 'smile';
    P.prop = { k: 'board', t: p };
  });
  def('flip', 'Coaching poses', 'DUO_FLIPPING (chess)', false, 1200, (P, p, time) => {
    idleMotion(P, time);
    const crouch = hop(seg(p, 0, .15)), air = seg(p, .15, .8), land = hop(seg(p, .8, 1));
    P.y = -56 * Math.sin(air * PI); P.rot = -easeInOut(air) * TAU;
    P.sy = 1 - .14 * crouch - .12 * land; P.sx = 2 - P.sy;
    P.armL = { a: 2.3 * hop(air) + .35, c: 0 }; P.armR = { a: 2.3 * hop(air) + .35, c: 0 };
    P.eyes = air > 0 && air < 1 ? 'happy' : 'open'; P.mouth = 'grin';
  });
  def('lifting', 'Coaching poses', 'DUO_LIFTING (chess)', true, 1800, (P, p, time) => {
    idleMotion(P, time);
    const l = hop(p);
    P.armL = { a: lerp(1.55, 2.0, l), c: -.2 }; P.armR = { a: lerp(1.55, 2.0, l), c: -.2 }; P.y = -3 * l;
    P.sy = 1 - .09 * l; P.sx = 1 + .06 * l; P.browOn = true; P.brow = 1; P.mouth = l > .5 ? 'grit' : 'flat';
    P.prop = { k: 'barbell', lift: l };
    if (l > .7) P.fx.push({ k: 'sweat', t: .5 });
  });
  def('ponder', 'Coaching poses', 'DUO_PONDERING (chess)', true, 3600, (P, p, time) => {
    idleMotion(P, time);
    P.armR = { a: -2.25, c: .6 }; P.lookX = .6; P.lookY = -.7; P.mouth = 'flat'; P.browOn = true; P.brow = .4;
    P.rot = -.04;
    P.fx.push({ k: 'question', t: p });
  });
  def('shocked', 'Coaching poses', 'DUO_SHOCKED (chess)', false, 900, (P, p, time) => {
    idleMotion(P, time);
    const j = hop(seg(p, 0, .35));
    P.y = -16 * j; P.sy = 1 + .1 * j; P.sx = 1 - .06 * j;
    P.eyes = 'wide'; P.mouth = 'open'; P.browOn = true; P.brow = .2;
    P.armL = { a: 2.0, c: .4 }; P.armR = { a: 2.0, c: .4 }; P.frillAmp = 6; P.frillScale = 1.08;
    P.fx.push({ k: 'exclaim', t: seg(p, 0, .5) });
  });

  // Documented moments
  def('greet', 'Documented moments', 'Welcome / instruction (onboarding speech)', false, 1200, (P, p, time) => {
    idleMotion(P, time);
    const w = seg(p, .1, .9);
    P.armR = { a: 2.4 + .35 * Math.sin(w * TAU * 2.5) * hop(w), c: -.5 };
    P.rot = -.04 * hop(w); P.mouth = 'grin'; P.eyes = p > .3 && p < .8 ? 'happy' : 'open'; P.blush = .6;
  });
  def('dash_across', 'Documented moments', 'Mid-lesson interstitial (runs across scene)', false, 1600, (P, p, time) => {
    idleMotion(P, time);
    P.x = lerp(-80, 80, easeInOut(p)); P.rot = .14; P.y = -6 * Math.abs(Math.sin(p * PI * 6));
    P.armL = { a: 1.8, c: .3 }; P.armR = { a: 1.8, c: .3 }; P.eyes = 'happy'; P.mouth = 'grin'; P.frillAmp = 5;
    P.fx.push({ k: 'trail', t: p });
  });
  def('milestone_number', 'Documented moments', 'Streak milestone (holds number balloons)', true, 2800, (P, p, time) => {
    idleMotion(P, time);
    P.armR = { a: 2.3, c: -.2 }; P.lookX = .5; P.lookY = -.6; P.mouth = 'grin'; P.blush = .7;
    P.prop = { k: 'balloon', t: p, label: '7' };
  });
  def('ink_bloom', 'Documented moments', 'Streak phoenix transformation', false, 2200, (P, p, time) => {
    idleMotion(P, time);
    const charge = seg(p, 0, .45), burst = seg(p, .45, .6), settle = seg(p, .6, 1);
    P.sy = 1 - .12 * easeOut(charge) * (1 - burst) + .12 * hop(burst); P.sx = 2 - P.sy;
    P.y = -10 * hop(burst);
    P.rot = Math.sin(charge * PI * 10) * .03 * charge * (1 - burst);
    P.eyes = charge < 1 ? 'closed' : 'happy'; P.mouth = charge < 1 ? 'flat' : 'grin';
    P.glow = easeOut(charge) * (1 - .5 * settle);
    P.skin = burst > .5 ? 'gold' : null;
    P.frillScale = 1 + .25 * hop(burst) + .08 * (burst >= 1 ? 1 : 0);
    P.frillAmp = 2 + 6 * hop(burst);
    P.armL = { a: lerp(.35, 2.6, burst), c: -.3 }; P.armR = { a: lerp(.35, 2.6, burst), c: -.3 };
    P.fx.push({ k: 'burst', t: burst });
    if (settle > 0) P.fx.push({ k: 'sparkle', t: settle });
  });

  // Sumi contract states (no verified individual Duo clip in the research)
  def('point', 'Sumi guidance', 'No verified Duo clip — Sumi addition', false, 700, (P, p, time) => {
    idleMotion(P, time);
    const e = backOut(seg(p, 0, .6));
    P.armR = { a: lerp(.35, 1.6, e), c: -.1 }; P.lookX = .9 * e; P.rot = .05 * e; P.mouth = 'smile';
  });
  def('think', 'Sumi guidance', 'No verified Duo clip — Sumi addition', true, 2800, (P, p, time) => {
    idleMotion(P, time);
    P.lookX = Math.sin(p * TAU) * .7; P.lookY = -.6; P.mouth = 'flat'; P.rot = Math.sin(p * TAU) * .03;
    P.fx.push({ k: 'dots', t: p });
  });
  def('hint', 'Sumi guidance', 'No verified Duo clip — Sumi addition', false, 900, (P, p, time) => {
    idleMotion(P, time);
    const e = easeOut(seg(p, 0, .4));
    P.armR = { a: lerp(.35, 2.4, e), c: -.6 }; P.eyes = 'open'; P.mouth = 'open'; P.browOn = true; P.brow = .3;
    P.prop = { k: 'bulb', t: seg(p, .2, 1) };
  });
  def('complete', 'Sumi guidance', 'No verified Duo clip — Sumi addition (pairs with lesson end)', false, 1400, (P, p, time) => {
    idleMotion(P, time);
    const h1 = hop(seg(p, .05, .4)), h2 = hop(seg(p, .4, .7));
    P.y = -26 * h1 - 14 * h2; P.sy = 1 + .07 * (h1 + h2); P.sx = 2 - P.sy;
    P.rot = Math.sin(seg(p, .05, .7) * TAU) * .06;
    P.armR = { a: 2.8 + .15 * Math.sin(seg(p, .05, .7) * TAU * 2), c: -.3 }; P.eyes = 'happy'; P.mouth = 'grin'; P.blush = 1;
    P.frillAmp = 4;
    P.fx.push({ k: 'sparkle', t: seg(p, .1, 1) }, { k: 'bigstar', t: seg(p, .2, 1) });
  });
  def('local_ready', 'Sumi guidance', 'No verified Duo clip — Sumi addition', false, 800, (P, p, time) => {
    idleMotion(P, time);
    const n = hop(seg(p, .1, .5));
    P.rot = .0; P.y = 3 * n; P.sy = 1 - .04 * n; P.eyes = 'happy'; P.mouth = 'smile';
    P.armR = { a: lerp(.35, 1.9, easeOut(seg(p, 0, .4))), c: -.8 };
    P.prop = { k: 'check', t: seg(p, .2, .8) };
  });
  def('recover', 'Sumi guidance', 'No verified Duo clip — Sumi addition', false, 1000, (P, p, time) => {
    idleMotion(P, time);
    const breath = hop(seg(p, .1, .9));
    P.sy = 1 + .05 * breath; P.sx = 1 + .03 * breath; P.eyes = breath > .4 ? 'closed' : 'open';
    P.armL = { a: lerp(.35, 1.1, breath), c: .4 }; P.armR = { a: lerp(.35, 1.1, breath), c: .4 }; P.mouth = 'smile';
  });
  def('listen', 'Sumi guidance', 'No verified Duo clip — Sumi addition', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.rot = .1; P.armR = { a: 2.5, c: 1.2 }; P.lookX = .8; P.mouth = 'o';
    P.fx.push({ k: 'waves', t: p });
  });
  def('compare', 'Sumi guidance', 'No verified Duo clip — Sumi addition', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    const side = Math.sin(p * TAU);
    P.lookX = side; P.rot = side * .04; P.armL = { a: 1.4, c: -.1 }; P.armR = { a: 1.4, c: -.1 }; P.mouth = 'flat';
    P.prop = { k: 'cards', side };
  });
  def('music_count', 'Sumi guidance', 'No verified Duo clip — Sumi addition (Music)', true, 2000, (P, p, time) => {
    idleMotion(P, time);
    const beat = Math.floor(p * 4), k = (p * 4) % 1;
    P.y = -6 * hop(k); P.armR = { a: lerp(2.2, 1.0, easeOut(k)), c: -.2 }; P.mouth = 'open';
    P.prop = { k: 'count', beat: beat + 1, ph: k };
  });
  def('design_make', 'Sumi guidance', 'No verified Duo clip — Sumi addition (Fashion)', true, 2400, (P, p, time) => {
    idleMotion(P, time);
    P.armL = { a: -.18, c: -1.6 }; P.armR = { a: -.45 + .3 * Math.sin(p * TAU * 2), c: .4 }; P.lookY = .8; P.lookX = .2;
    P.mouth = 'smile'; P.prop = { k: 'sewing', t: p };
  });

  // ---------- drawing ----------
  function poseFor(id, p, time) {
    const anim = A.find((a) => a.id === id) || A[0];
    const P = basePose();
    anim.f(P, p, time);
    return P;
  }

  // Shoulders sit on the body's edge. Bending the arm (|c|) shortens its reach like an elbow.
  // Positive c bends the elbow inward, negative c pushes it outward (hands on hips).
  function armTip(side, arm) {
    const sx = side * 31, sy = -80, L = 40 * (1 - .22 * Math.min(Math.abs(arm.c), 1.6));
    return [sx + side * L * Math.sin(arm.a), sy + L * Math.cos(arm.a)];
  }

  // Filled shape with the bold outline.
  function inked(ctx, S, fill) { ctx.fillStyle = fill; ctx.fill(); }
  // Stroked limb with outline: dark pass then colour pass.
  function limb(ctx, S, path, w, col) { ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.strokeStyle = col; ctx.lineWidth = w; path(); ctx.stroke(); }

  // Chunky tapered arm growing out of the side of the torso, with a soft offset shade so a
  // green arm over the green body still has an edge.
  function armShape(side, arm) {
    const sx = side * 31, sy = -80, [tx, ty] = armTip(side, arm), rx = side * 24, ry = -84;
    const mx = (sx + tx) / 2, my = (sy + ty) / 2, dx = tx - sx, dy = ty - sy, len = Math.hypot(dx, dy) || 1;
    const cx = mx + (-dy / len) * arm.c * 26 * side, cy = my + (dx / len) * arm.c * 26 * side;
    const N = 16, L = [], Rr = [];
    for (let i = 0; i <= N; i++) {
      const t = i / N, u = 1 - t;
      const px = u * u * u * rx + 3 * u * u * t * sx + 3 * u * t * t * cx + t * t * t * tx;
      const py = u * u * u * ry + 3 * u * u * t * sy + 3 * u * t * t * cy + t * t * t * ty;
      const qx = 3 * u * u * (sx - rx) + 6 * u * t * (cx - sx) + 3 * t * t * (tx - cx);
      const qy = 3 * u * u * (sy - ry) + 6 * u * t * (cy - sy) + 3 * t * t * (ty - cy);
      const ql = Math.hypot(qx, qy) || 1, nx = -qy / ql, ny = qx / ql, w = 11.5 - 3 * t;
      L.push([px + nx * w, py + ny * w]); Rr.push([px - nx * w, py - ny * w]);
    }
    return { L, R: Rr, tx, ty };
  }
  function tracePath(ctx, sh, ox = 0, oy = 0) {
    ctx.beginPath(); sh.L.forEach(([x, y], i) => (i ? ctx.lineTo(x + ox, y + oy) : ctx.moveTo(x + ox, y + oy)));
    for (let i = sh.R.length - 1; i >= 0; i--) ctx.lineTo(sh.R[i][0] + ox, sh.R[i][1] + oy); ctx.closePath();
  }
  function drawArm(ctx, side, arm, S) {
    const sh = armShape(side, arm);
    ctx.globalAlpha = .28; tracePath(ctx, sh, 0, 2.5); ctx.fillStyle = S.deep; ctx.fill();
    ctx.beginPath(); ctx.arc(sh.tx, sh.ty + 2.5, 12, 0, TAU); ctx.fill(); ctx.globalAlpha = 1;
    tracePath(ctx, sh); ctx.fillStyle = S.body; ctx.fill();
    drawMitt(ctx, side, arm, S);
  }
  function drawMitt(ctx, side, arm, S) {
    const [tx, ty] = armTip(side, arm);
    ctx.beginPath(); ctx.arc(tx, ty, 12, 0, TAU); ctx.fillStyle = S.body; ctx.fill();
    ctx.beginPath(); ctx.arc(tx + side * 2.5, ty + 3.5, 7.5, 0, PI); ctx.fillStyle = S.deep; ctx.globalAlpha = .45; ctx.fill(); ctx.globalAlpha = 1;
  }

  // Spiral tail: thick soft band, darker inner half, tapering to a tight curl.
  function drawTail(ctx, P, S) {
    const curl = 1 + .05 * Math.sin(P.tent * .8) + .1 * (P.frillAmp - 2) / 6;
    const cx = 66, cy = -42, N = 48, c = [];
    for (let i = 0; i <= N; i++) { const t = i / N, a = PI * 1.0 - t * PI * 2.55 * curl, r = 40 * Math.pow(1 - t * .86, 1.15); c.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r, 15 - 10.5 * t]); }
    const band = (scale, col, inner) => { ctx.strokeStyle = col; ctx.lineCap = 'round';
      for (let i = 1; i <= N; i++) { const p = c[i - 1], q = c[i]; const dx = q[0] - p[0], dy = q[1] - p[1], L = Math.hypot(dx, dy) || 1, nx = -dy / L, ny = dx / L;
        const off = inner ? q[2] * .45 : 0; ctx.lineWidth = q[2] * scale; ctx.beginPath(); ctx.moveTo(p[0] + nx * off, p[1] + ny * off); ctx.lineTo(q[0] + nx * off, q[1] + ny * off); ctx.stroke(); } };
    // root from the body's back
    ctx.strokeStyle = S.body; ctx.lineCap = 'round'; ctx.lineWidth = 26; ctx.beginPath(); ctx.moveTo(18, -46); ctx.quadraticCurveTo(26, -24, c[0][0], c[0][1]); ctx.stroke();
    band(1.85, S.body, false);
    band(.85, S.deep, true);
  }

  function drawLegs(ctx, P, S) {
    [-1, 1].forEach((s) => {
      const w = Math.sin(P.tent + s) * 1.2, col = s > 0 ? S.deep : S.body;
      limb(ctx, S, () => { ctx.beginPath(); ctx.moveTo(s * 15, -40); ctx.quadraticCurveTo(s * 24, -26 + w, s * 21, -10); }, 18, col);
      ctx.beginPath(); ctx.ellipse(s * 23, -5, 15, 9, 0, PI, TAU); ctx.lineTo(s * 23 + 15, -3); ctx.lineTo(s * 23 - 15, -3); ctx.closePath(); inked(ctx, S, S.deep);
    });
  }

  function drawBody(ctx, P, S) {
    ctx.beginPath(); ctx.ellipse(0, -58, 40, 40, 0, 0, TAU); inked(ctx, S, S.body);
    // shadow side
    ctx.save(); ctx.beginPath(); ctx.ellipse(0, -58, 40, 40, 0, 0, TAU); ctx.clip();
    ctx.beginPath(); ctx.ellipse(33, -56, 18, 44, 0, 0, TAU); ctx.fillStyle = S.deep; ctx.fill(); ctx.restore();
    ctx.beginPath(); ctx.ellipse(-3, -54, 25, 31, 0, 0, TAU); ctx.fillStyle = S.belly; ctx.fill();
    ctx.strokeStyle = S.stripe; ctx.lineWidth = 4; ctx.lineCap = 'round';
    [-60, -48].forEach((y) => { ctx.beginPath(); ctx.moveTo(-15, y); ctx.lineTo(9, y); ctx.stroke(); });
  }

  function drawHead(ctx, P, S) {
    const wob = Math.sin(P.frillPhase) * (P.frillAmp - 2) * .7, k = P.frillScale;
    const peakY = -196 - 14 * (k - 1) * 4;
    const head = () => { ctx.beginPath();
      ctx.moveTo(-52, -118);
      ctx.bezierCurveTo(-56, -146, -44, -162, -28, -166);
      ctx.bezierCurveTo(-18 + wob, peakY + 16, -4 + wob, peakY, 6 + wob, peakY);
      ctx.bezierCurveTo(18 + wob, peakY, 30, -176, 34, -164);
      ctx.bezierCurveTo(48, -160, 56, -142, 52, -118);
      ctx.bezierCurveTo(50, -90, -50, -90, -52, -118);
      ctx.closePath(); };
    head(); inked(ctx, S, S.body);
    // soft shadow on the right of the head
    ctx.save(); head(); ctx.clip();
    ctx.beginPath(); ctx.ellipse(50, -126, 22, 44, -.2, 0, TAU); ctx.fillStyle = S.deep; ctx.fill(); ctx.restore();
    // casque stripe: one thick curved accent
    ctx.beginPath(); ctx.moveTo(-10, -164); ctx.quadraticCurveTo(-6 + wob, peakY + 20, 2 + wob, peakY + 8);
    ctx.lineWidth = 7; ctx.strokeStyle = S.crest; ctx.lineCap = 'round'; ctx.stroke();
    // nostrils
    ctx.fillStyle = S.line; ctx.globalAlpha = .55;
    [-5, 5].forEach((x) => { ctx.beginPath(); ctx.ellipse(x, -124, 1.6, 1.1, 0, 0, TAU); ctx.fill(); }); ctx.globalAlpha = 1;
  }

  function drawEye(ctx, side, P, S) {
    const ex = side * 42, ey = -132, r = 23;
    ctx.beginPath(); ctx.arc(ex, ey, r, 0, TAU); ctx.fillStyle = S.ring; ctx.fill();
    if (P.eyes === 'happy') { ctx.strokeStyle = S.iris; ctx.lineWidth = 4; ctx.lineCap = 'round'; ctx.beginPath(); ctx.arc(ex, ey + 5, 8.5, PI * 1.15, PI * 1.85); ctx.stroke(); return; }
    if (P.eyes === 'closed') { ctx.strokeStyle = S.iris; ctx.lineWidth = 4; ctx.lineCap = 'round'; ctx.beginPath(); ctx.arc(ex, ey - 2, 8.5, PI * .15, PI * .85); ctx.stroke(); return; }
    const wr = P.eyes === 'wide' ? 21 : 19.5;
    const lx = P.lookX + side * .12, ly = P.lookY;
    const ax = ex + lx * 3, ay = ey + ly * 3;
    ctx.save(); ctx.beginPath(); ctx.arc(ex, ey, r - 1, 0, TAU); ctx.clip();
    ctx.beginPath(); ctx.arc(ax, ay, wr, 0, TAU); ctx.fillStyle = '#FFFDF7'; ctx.fill();
    const pr = P.eyes === 'wide' ? 6 : 9.5, px = ax + lx * 5, py = ay + ly * 5;
    ctx.fillStyle = S.iris; ctx.beginPath(); ctx.ellipse(px, py, pr, pr * 1.12, 0, 0, TAU); ctx.fill();
    ctx.fillStyle = '#FFFFFF'; ctx.beginPath(); ctx.arc(px - pr * .35, py - pr * .45, pr * .28, 0, TAU); ctx.fill();
    if (P.eyeOpen < 1) { ctx.fillStyle = S.ring; ctx.fillRect(ex - r, ey - r, r * 2, r * 2 * (1 - P.eyeOpen)); }
    ctx.restore();
  }

  function drawFace(ctx, P, S) {
    drawEye(ctx, -1, P, S); drawEye(ctx, 1, P, S);
    if (P.browOn) {
      ctx.strokeStyle = S.line; ctx.lineWidth = 3.4; ctx.lineCap = 'round';
      [-1, 1].forEach((s) => { const tilt = P.brow * .35 * s; ctx.beginPath(); ctx.moveTo(s * 42 - 10, -163 + tilt * 8 * -1 * s); ctx.lineTo(s * 42 + 10, -163 + tilt * 8 * s); ctx.stroke(); });
    }
    if (P.blush > 0) { ctx.fillStyle = S.cheek; ctx.globalAlpha = .8 * P.blush; ctx.beginPath(); ctx.ellipse(-26, -110, 7, 4, 0, 0, TAU); ctx.fill(); ctx.beginPath(); ctx.ellipse(26, -110, 6, 3.5, 0, 0, TAU); ctx.fill(); ctx.globalAlpha = 1; }
    const my = -112; ctx.strokeStyle = S.line; ctx.fillStyle = S.line; ctx.lineWidth = 2.8; ctx.lineCap = 'round';
    switch (P.mouth) {
      case 'smile': ctx.beginPath(); ctx.moveTo(-13, my - 2); ctx.quadraticCurveTo(0, my + 6, 13, my - 2); ctx.stroke(); break;
      case 'smirk': ctx.beginPath(); ctx.moveTo(-12, my); ctx.quadraticCurveTo(4, my + 4, 15, my - 5); ctx.stroke(); break;
      case 'grin':
        ctx.beginPath(); ctx.moveTo(-17, my - 3); ctx.quadraticCurveTo(0, my + 15, 17, my - 3); ctx.closePath(); ctx.fill();
        ctx.fillStyle = S.cheek; ctx.beginPath(); ctx.ellipse(0, my + 4, 6, 3, 0, 0, TAU); ctx.fill(); break;
      case 'open': ctx.beginPath(); ctx.ellipse(0, my + 1, 7, 6, 0, 0, TAU); ctx.fill(); ctx.fillStyle = S.cheek; ctx.beginPath(); ctx.ellipse(0, my + 4, 4, 2, 0, 0, TAU); ctx.fill(); break;
      case 'o': ctx.beginPath(); ctx.ellipse(0, my, 3.6, 3.6, 0, 0, TAU); ctx.fill(); break;
      case 'whistle': ctx.beginPath(); ctx.ellipse(6, my, 3, 3.2, 0, 0, TAU); ctx.stroke(); break;
      case 'flat': ctx.beginPath(); ctx.moveTo(-12, my); ctx.lineTo(12, my); ctx.stroke(); break;
      case 'frown': ctx.beginPath(); ctx.moveTo(-12, my + 3); ctx.quadraticCurveTo(0, my - 5, 12, my + 3); ctx.stroke(); break;
      case 'grit': ctx.beginPath(); ctx.rect(-10, my - 4, 20, 8); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-10, my); ctx.lineTo(10, my); ctx.stroke(); break;
      case 'wobble': ctx.beginPath(); for (let i = 0; i <= 12; i++) { const x = -12 + i * 2, y = my + Math.sin(i * 1.4) * 1.8; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); } ctx.stroke(); break;
    }
  }

  // Props are drawn in body space (anchored to the character).
  function drawProp(ctx, P, S) {
    const pr = P.prop; if (!pr) return;
    const L = armTip(-1, P.armL), R = armTip(1, P.armR);
    const ink = '#141832';
    ctx.save();
    switch (pr.k) {
      case 'bubbles': for (let i = 0; i < 3; i++) {
        const ph = (pr.t + i / 3) % 1, k = ph < .5 ? ph * 2 : 2 - ph * 2; const mid = (L[0] + R[0]) / 2, half = (R[0] - L[0]) / 2, x = mid - half * 1.3 * Math.cos(k * PI), base = lerp(L[1], R[1], k) - 14, y = base + (-205 - base) * hop(k);
        ctx.fillStyle = ['#3FB8AF', '#FF7B69', '#FFC64A'][i]; ctx.beginPath(); ctx.arc(x, y, 7, 0, TAU); ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.beginPath(); ctx.arc(x - 2, y - 2, 2, 0, TAU); ctx.fill(); } break;
      case 'book': {
        const flip = (pr.t * 2) % 1;
        ctx.translate(0, -60); ctx.fillStyle = '#FF7B69'; ctx.fillRect(-26, -16, 52, 26);
        ctx.fillStyle = '#FFF6E8'; ctx.fillRect(-24, -18, 23, 24); ctx.fillRect(1, -18, 23, 24);
        const w = Math.cos(flip * PI) * 23; ctx.fillStyle = '#F2E6D2'; ctx.fillRect(Math.min(1, 1 + w), -18, Math.abs(w), 24);
        ctx.strokeStyle = '#C9B8A0'; ctx.lineWidth = 1.2; for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.moveTo(-20, -12 + i * 6); ctx.lineTo(-5, -12 + i * 6); ctx.stroke(); } break; }
      case 'pearl': {
        const g = .5 + .5 * Math.sin(pr.t * TAU);
        ctx.fillStyle = '#FFF4F8'; ctx.beginPath(); ctx.arc(R[0], R[1] - 12, 12, 0, TAU); ctx.fill();
        ctx.strokeStyle = '#E8C9D8'; ctx.lineWidth = 1.5; ctx.stroke();
        ctx.fillStyle = `rgba(255,255,255,${g})`; star(ctx, R[0] + 8, R[1] - 20, 3 + 3 * g); break; }
      case 'globe': {
        ctx.translate(0, -60); ctx.fillStyle = '#4AA8E0'; ctx.beginPath(); ctx.arc(0, 0, 18, 0, TAU); ctx.fill();
        ctx.save(); ctx.clip(); ctx.fillStyle = '#7CC96B';
        const off = (pr.t * 72) % 72 - 36; [[-14, -6, 10, 7], [10, 6, 8, 6], [-2, 10, 6, 4]].forEach(([x, y, a, b]) => { [0, 72].forEach((o) => { ctx.beginPath(); ctx.ellipse(x + off + o - 36, y, a, b, 0, 0, TAU); ctx.fill(); }); });
        ctx.restore(); ctx.strokeStyle = '#2B6E99'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(0, 0, 18, 0, TAU); ctx.stroke(); break; }
      case 'headphones':
        ctx.strokeStyle = '#141832'; ctx.lineWidth = 5; ctx.beginPath(); ctx.arc(0, -128, 66, PI * 1.12, PI * 1.88); ctx.stroke();
        ctx.fillStyle = '#FF7B69'; ctx.strokeStyle = '#1B1C2E'; ctx.lineWidth = 3.5; ctx.beginPath(); ctx.ellipse(-64, -132, 9, 14, 0, 0, TAU); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.ellipse(64, -132, 9, 14, 0, 0, TAU); ctx.fill(); ctx.stroke(); break;
      case 'inkpot': {
        ctx.translate(-4, -46); ctx.fillStyle = '#5A6A86'; ctx.beginPath(); ctx.moveTo(-14, -10); ctx.lineTo(14, -10); ctx.lineTo(18, 12); ctx.lineTo(-18, 12); ctx.closePath(); ctx.fill();
        const hue = ['#3FB8AF', '#7B6CF0', '#FF7B69'][Math.floor(pr.t * 3) % 3]; ctx.fillStyle = hue; ctx.beginPath(); ctx.ellipse(0, -10, 14, 4, 0, 0, TAU); ctx.fill();
        ctx.strokeStyle = '#B98A55'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(R[0] + 4, R[1] + 36); ctx.lineTo(Math.sin(pr.t * TAU * 2) * 6, -8); ctx.stroke(); break; }
      case 'shades': {
        const y = lerp(-178, -130, pr.v); if (pr.v <= 0) break;
        ctx.globalAlpha = clamp(pr.v * 3);
        ctx.fillStyle = '#141832'; ctx.beginPath(); ctx.roundRect(-64, y - 15, 46, 30, 11); ctx.roundRect(18, y - 15, 46, 30, 11); ctx.fill();
        ctx.fillRect(-20, y - 6, 40, 4); ctx.fillStyle = 'rgba(255,255,255,.45)'; ctx.beginPath(); ctx.moveTo(-54, y - 8); ctx.lineTo(-46, y - 8); ctx.lineTo(-52, y + 4); ctx.lineTo(-58, y + 4); ctx.fill(); ctx.beginPath(); ctx.moveTo(28, y - 8); ctx.lineTo(36, y - 8); ctx.lineTo(30, y + 4); ctx.lineTo(24, y + 4); ctx.fill(); break; }
      case 'clock': {
        ctx.translate(0, -60); ctx.fillStyle = '#FFFFFF'; ctx.strokeStyle = '#FF7B69'; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(0, 0, 18, 0, TAU); ctx.fill(); ctx.stroke();
        ctx.strokeStyle = ink; ctx.lineWidth = 2.5; const a1 = pr.t * TAU * 2 - PI / 2, a2 = pr.t * TAU / 6 - PI / 2;
        ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(Math.cos(a1) * 13, Math.sin(a1) * 13); ctx.moveTo(0, 0); ctx.lineTo(Math.cos(a2) * 8, Math.sin(a2) * 8); ctx.stroke(); break; }
      case 'tape': {
        ctx.fillStyle = '#FFC64A'; ctx.fillRect(L[0], L[1] - 4, R[0] - L[0], 8);
        ctx.strokeStyle = '#B5821A'; ctx.lineWidth = 1; for (let x = L[0] + 4; x < R[0]; x += 5) { ctx.beginPath(); ctx.moveTo(x, L[1] - 4); ctx.lineTo(x, L[1] - (Math.round((x - L[0]) / 5) % 2 ? 1 : -1)); ctx.stroke(); }
        ctx.fillStyle = '#FF7B69'; ctx.beginPath(); ctx.arc(L[0], L[1], 7, 0, TAU); ctx.fill(); break; }
      case 'board':
        ctx.fillStyle = '#2F4F46'; ctx.fillRect(-124, -150, 70, 54); ctx.strokeStyle = '#B98A55'; ctx.lineWidth = 4; ctx.strokeRect(-124, -150, 70, 54);
        ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(-114, -132); ctx.lineTo(-96, -112); ctx.lineTo(-78, -130); ctx.stroke();
        ctx.beginPath(); ctx.arc(-70, -112, 4, 0, TAU); ctx.stroke(); break;
      case 'barbell': {
        const y = Math.min(L[1], R[1]); ctx.strokeStyle = '#5A6A86'; ctx.lineWidth = 4; ctx.beginPath(); ctx.moveTo(L[0] - 18, y); ctx.lineTo(R[0] + 18, y); ctx.stroke();
        ctx.fillStyle = '#FF7B69'; ctx.fillRect(L[0] - 24, y - 10, 8, 20); ctx.fillRect(R[0] + 16, y - 10, 8, 20); break; }
      case 'balloon': {
        const bx = R[0] + 6 + Math.sin(pr.t * TAU) * 4, by = R[1] - 56;
        ctx.strokeStyle = '#8A93B5'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(R[0], R[1]); ctx.quadraticCurveTo(bx - 6, (R[1] + by) / 2, bx, by + 20); ctx.stroke();
        ctx.fillStyle = '#FF7B69'; ctx.beginPath(); ctx.ellipse(bx, by, 17, 20, 0, 0, TAU); ctx.fill();
        ctx.fillStyle = '#FFFFFF'; ctx.font = 'bold 20px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(pr.label, bx, by + 1); break; }
      case 'bulb': {
        if (pr.t <= 0) break; const s = backOut(pr.t);
        ctx.translate(R[0] + 6, -205); ctx.scale(s, s); ctx.fillStyle = '#FFD45A'; ctx.beginPath(); ctx.arc(0, 0, 10, 0, TAU); ctx.fill();
        ctx.fillStyle = '#C9CED8'; ctx.fillRect(-5, 8, 10, 6);
        ctx.strokeStyle = '#FFD45A'; ctx.lineWidth = 2.5; for (let i = 0; i < 5; i++) { const a = -PI / 2 + (i - 2) * .55; ctx.beginPath(); ctx.moveTo(Math.cos(a) * 14, Math.sin(a) * 14); ctx.lineTo(Math.cos(a) * 20, Math.sin(a) * 20); ctx.stroke(); } break; }
      case 'check': {
        if (pr.t <= 0) break; ctx.translate(R[0] + 4, R[1] - 16); const s = backOut(pr.t); ctx.scale(s, s);
        ctx.fillStyle = '#50C86A'; ctx.beginPath(); ctx.arc(0, 0, 12, 0, TAU); ctx.fill();
        ctx.strokeStyle = '#FFFFFF'; ctx.lineWidth = 3.4; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(-5, 0); ctx.lineTo(-1, 4); ctx.lineTo(6, -4); ctx.stroke(); break; }
      case 'cards':
        [[-1, '#FFE3DF'], [1, '#DDF5F2']].forEach(([s, c]) => { const lift = s * pr.side > 0 ? -6 : 0; ctx.fillStyle = c; ctx.strokeStyle = s < 0 ? '#FF7B69' : '#3FB8AF'; ctx.lineWidth = 2;
          ctx.beginPath(); ctx.roundRect(s * 74 - 18, -112 + lift, 36, 44, 6); ctx.fill(); ctx.stroke(); ctx.fillStyle = s < 0 ? '#FF7B69' : '#3FB8AF'; ctx.fillRect(s * 74 - 10, -100 + lift, 20, 3); ctx.fillRect(s * 74 - 10, -92 + lift, 14, 3); }); break;
      case 'count':
        for (let i = 1; i <= 4; i++) { const on = i === pr.beat; ctx.fillStyle = on ? '#FF7B69' : 'rgba(43,52,116,.18)'; ctx.beginPath(); ctx.arc(-36 + (i - 1) * 24, -192, on ? 7 + 3 * hop(pr.ph) : 5, 0, TAU); ctx.fill(); } break;
      case 'sewing': {
        ctx.translate(0, -58); ctx.fillStyle = '#7B6CF0'; ctx.beginPath(); ctx.moveTo(-26, -8); ctx.lineTo(24, -12); ctx.lineTo(26, 10); ctx.lineTo(-24, 12); ctx.closePath(); ctx.fill();
        ctx.strokeStyle = '#FFFFFF'; ctx.setLineDash([3, 3]); ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(-20, 0); ctx.lineTo(-20 + 40 * pr.t, -1); ctx.stroke(); ctx.setLineDash([]);
        const nx = -20 + 40 * pr.t, ny = -1 - 8 * hop((pr.t * 6) % 1); ctx.strokeStyle = '#C9CED8'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(nx, ny - 8); ctx.lineTo(nx, ny + 2); ctx.stroke(); break; }
    }
    ctx.restore();
  }

  function star(ctx, x, y, r) {
    ctx.beginPath(); for (let i = 0; i < 10; i++) { const rr = i % 2 ? r * .45 : r, a = i * PI / 5 - PI / 2; const px = x + Math.cos(a) * rr, py = y + Math.sin(a) * rr; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); } ctx.closePath(); ctx.fill();
  }

  // FX drawn in world space around the character.
  function drawFx(ctx, P, ox, oy) {
    P.fx.forEach((f) => {
      ctx.save();
      switch (f.k) {
        case 'sparkle': if (f.t <= 0 || f.t >= 1) break; for (let i = 0; i < (f.small ? 4 : 7); i++) {
          const a = i / (f.small ? 4 : 7) * TAU + .3, d = 50 + 40 * easeOut(f.t); ctx.fillStyle = ['#FFC64A', '#3FB8AF', '#FF7B69'][i % 3];
          ctx.globalAlpha = 1 - f.t; star(ctx, ox + Math.cos(a) * d, oy - 86 + Math.sin(a) * d * .8, 5 * (1 - f.t * .5)); } break;
        case 'stars': if (f.t <= 0 || f.t >= 1) break; for (let i = 0; i < 3; i++) { const x = ox + (i - 1) * 46, y = oy - 170 - 20 * easeOut(f.t) + Math.abs(i - 1) * 14; ctx.fillStyle = '#FFC64A'; ctx.globalAlpha = 1 - Math.max(0, f.t - .6) / .4; star(ctx, x, y, 9 * backOut(clamp(f.t * 2.5 - i * .3))); } break;
        case 'bigstar': if (f.t <= 0) break; { const s = backOut(clamp(f.t * 2)), gy = oy - P.y * .3 - 172, gx = ox - 66; ctx.fillStyle = '#FFC64A'; star(ctx, gx, gy, 15 * s); ctx.fillStyle = '#FFFFFF'; ctx.globalAlpha = .6; star(ctx, gx - 3, gy - 3, 4.5 * s); } break; // ground-anchored, beside the head
        case 'sweat': if (f.t <= 0) break; ctx.fillStyle = '#7FD3F7'; ctx.globalAlpha = 1 - f.t * .6; { const z = f.big ? 2 : 1, x = ox + 46, y = oy - 128 + 18 * f.t; ctx.beginPath(); ctx.moveTo(x, y - 8 * z); ctx.quadraticCurveTo(x + 6 * z, y, x, y + 4 * z); ctx.quadraticCurveTo(x - 6 * z, y, x, y - 8 * z); ctx.fill(); } break;
        case 'notes': for (let i = 0; i < 2; i++) { const t = (f.t + i * .5) % 1; const x = ox + (f.from === 'mouth' ? 14 : 46) + t * 26 + Math.sin(t * TAU) * 6, y = oy - (f.from === 'mouth' ? 92 : 130) - t * 50;
          ctx.globalAlpha = 1 - t; ctx.fillStyle = '#7B6CF0'; ctx.beginPath(); ctx.ellipse(x, y, 4.5, 3.5, -.4, 0, TAU); ctx.fill(); ctx.fillRect(x + 3, y - 14, 1.8, 14); ctx.fillRect(x + 3, y - 14, 7, 2.5); } break;
        case 'fish': { const x = ox + f.x, y = oy + f.y; ctx.translate(x, y); ctx.scale(f.dir >= 0 ? 1 : -1, 1); ctx.fillStyle = '#FFB547'; ctx.beginPath(); ctx.ellipse(0, 0, 9, 6, 0, 0, TAU); ctx.fill(); ctx.beginPath(); ctx.moveTo(-7, 0); ctx.lineTo(-15, -6); ctx.lineTo(-15, 6); ctx.closePath(); ctx.fill(); ctx.fillStyle = '#141832'; ctx.beginPath(); ctx.arc(4, -1.5, 1.4, 0, TAU); ctx.fill(); break; }
        case 'puffs': if (f.t <= 0 || f.t >= 1) break; for (let i = 0; i < 4; i++) { const t = clamp(f.t * 1.4 - i * .12); ctx.globalAlpha = (1 - t) * .5; ctx.fillStyle = '#5A6A9E'; ctx.beginPath(); ctx.arc(ox + (i - 1.5) * 12, oy + 22 + t * 10, 6 + 6 * t, 0, TAU); ctx.fill(); } break;
        case 'question': { const b = Math.sin(f.t * TAU) * 3; ctx.fillStyle = '#7B6CF0'; ctx.font = 'bold 26px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.fillText('?', ox + 48, oy - 140 + b); break; }
        case 'exclaim': { const s = backOut(clamp(f.t)); ctx.fillStyle = '#FF7B69'; ctx.font = `bold ${28 * s}px system-ui, sans-serif`; ctx.textAlign = 'center'; ctx.fillText('!', ox + 46, oy - 140); break; }
        case 'dots': for (let i = 0; i < 3; i++) { const k = hop(((f.t * 1.5) - i * .2 + 1) % 1); ctx.fillStyle = '#7B6CF0'; ctx.globalAlpha = .35 + .65 * k; ctx.beginPath(); ctx.arc(ox + 40 + i * 11, oy - 146 - 4 * k, 4, 0, TAU); ctx.fill(); } break;
        case 'waves': for (let i = 0; i < 3; i++) { const t = (f.t + i / 3) % 1; ctx.strokeStyle = '#3FB8AF'; ctx.globalAlpha = 1 - t; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.arc(ox + 56, oy - 106, 8 + t * 22, -.7, .7); ctx.stroke(); } break;
        case 'trail': ctx.strokeStyle = '#3FB8AF'; ctx.lineCap = 'round'; ctx.lineWidth = 4; for (let i = 0; i < 3; i++) { ctx.globalAlpha = .7 - i * .18; const y = oy - 110 + i * 26; ctx.beginPath(); ctx.moveTo(ox - 60 - i * 6, y); ctx.lineTo(ox - 90 - i * 14, y); ctx.stroke(); } break;
        case 'burst': if (f.t <= 0 || f.t >= 1) break; { const r = 40 + 90 * easeOut(f.t); ctx.strokeStyle = '#FFC34D'; ctx.globalAlpha = 1 - f.t; ctx.lineWidth = 8 * (1 - f.t) + 1; ctx.beginPath(); ctx.arc(ox, oy - 84, r, 0, TAU); ctx.stroke();
          for (let i = 0; i < 12; i++) { const a = i * TAU / 12; ctx.beginPath(); ctx.moveTo(ox + Math.cos(a) * r * .7, oy - 84 + Math.sin(a) * r * .7); ctx.lineTo(ox + Math.cos(a) * r, oy - 84 + Math.sin(a) * r); ctx.stroke(); } } break;
      }
      ctx.restore();
    });
  }

  // Draws one frame. Canvas space: 240 x 240 units, ground at y = 214.
  function drawSumi(ctx, w, h, id, p, time, opts = {}) {
    const P = poseFor(id, p, time);
    P.darkMode = !!opts.darkMode;
    const S = SKINS[P.skin || opts.skin || 'default'];
    const k = Math.min(w, h) / 240;
    ctx.save(); ctx.clearRect(0, 0, w, h);
    ctx.translate((w - 240 * k) / 2, (h - 240 * k) / 2); ctx.scale(k, k);
    if (opts.rtl) { ctx.translate(240, 0); ctx.scale(-1, 1); }
    ctx.translate(120, 214); ctx.scale(.88, .88); ctx.translate(-120, -214); // headroom for jumps
    const ox = 120 + P.x, oy = 214;
    // shadow
    const lift = Math.max(0, -P.y);
    ctx.fillStyle = opts.darkMode ? 'rgba(0,0,0,.35)' : 'rgba(30,37,89,.14)';
    ctx.beginPath(); ctx.ellipse(ox + 14, oy, 52 / (1 + lift / 70), 6 / (1 + lift / 70), 0, 0, TAU); ctx.fill();
    // dark stage: soft halo so the bold outline still separates from the background
    if (opts.darkMode) {
      const h = ctx.createRadialGradient(ox, oy - 96, 20, ox, oy - 96, 118);
      h.addColorStop(0, 'rgba(232,247,244,.30)'); h.addColorStop(1, 'rgba(232,247,244,0)');
      ctx.fillStyle = h; ctx.beginPath(); ctx.arc(ox, oy - 96, 118, 0, TAU); ctx.fill();
    }
    // aura
    if (P.glow > 0 || S.aura) {
      const g = ctx.createRadialGradient(ox, oy - 100 + P.y, 10, ox, oy - 100 + P.y, 104);
      const a = Math.max(P.glow, S.aura ? .45 : 0);
      g.addColorStop(0, `rgba(255,210,110,${.55 * a})`); g.addColorStop(1, 'rgba(255,210,110,0)');
      ctx.fillStyle = g; ctx.beginPath(); ctx.arc(ox, oy - 100 + P.y, 104, 0, TAU); ctx.fill();
    }
    ctx.save();
    ctx.translate(ox, oy + P.y);
    ctx.translate(0, -90); ctx.rotate(P.rot); ctx.translate(0, 90);
    ctx.scale(P.sx, P.sy);
    ctx.globalAlpha = P.alpha;
    if (P.prop && P.prop.k === 'board') drawProp(ctx, P, S);
    drawTail(ctx, P, S);
    drawLegs(ctx, P, S);
    drawBody(ctx, P, S);
    drawHead(ctx, P, S);
    drawFace(ctx, P, S);
    drawArm(ctx, -1, P.armL, S); drawArm(ctx, 1, P.armR, S);
    if (P.prop && P.prop.k !== 'board') drawProp(ctx, P, S);
    if (P.prop && ['book', 'globe', 'clock', 'sewing'].includes(P.prop.k)) { drawMitt(ctx, -1, P.armL, S); drawMitt(ctx, 1, P.armR, S); }
    ctx.restore();
    ctx.save(); ctx.translate(0, -18); drawFx(ctx, P, ox, oy + P.y * .3); ctx.restore();
    ctx.restore();
  }

  root.SumiRig = { ANIMS: A, drawSumi, SKINS };
})(typeof window !== 'undefined' ? window : globalThis);
