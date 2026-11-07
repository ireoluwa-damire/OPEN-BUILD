"""Synthesize Sumi's original UI sounds (no samples, no third-party audio).
Run: python make_sounds.py <out_dir>"""
import sys, wave, numpy as np
SR = 44100
def t(d): return np.arange(int(SR*d))/SR
def env(n, a=0.005, d=0.25):
    x = np.arange(n)/SR
    e = np.minimum(1, x/a) * np.exp(-x/d)
    return e
def bell(f, d, decay=0.25, bright=0.35):
    x = t(d)
    s = np.sin(2*np.pi*f*x) + bright*np.sin(2*np.pi*2*f*x)*np.exp(-x/0.08) + 0.12*np.sin(2*np.pi*3.01*f*x)*np.exp(-x/0.05)
    return s*env(len(x), 0.004, decay)
def tri(f, d):
    x = t(d); return 2*np.abs(2*((f*x) % 1)-1)-1
def place(buf, sig, at):
    i = int(at*SR); buf[i:i+len(sig)] += sig[:len(buf)-i]
def norm(s, peak=0.8):
    fade = np.ones_like(s); n = int(0.01*SR); fade[-n:] = np.linspace(1,0,n)
    s = s*fade; return s/np.max(np.abs(s))*peak
def save(name, s, out):
    s = (norm(s)*32767).astype(np.int16)
    with wave.open(f"{out}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(s.tobytes())
note = lambda m: 440*2**((m-69)/12)
out = sys.argv[1]
# Correct: bright rising major third + fifth, quick.
b = np.zeros(int(SR*0.55)); place(b, bell(note(84), .5, .22), 0); place(b, bell(note(88), .45, .25), .075); place(b, .6*bell(note(91), .4, .25), .15)
save("correct", b, out)
# Incorrect: soft, low, two falling muted tones (gentle, not punishing).
b = np.zeros(int(SR*0.5))
for i,(m,at) in enumerate([(58,0),(53,.13)]):
    x = t(.32); s = (0.7*np.sin(2*np.pi*note(m)*x)+0.3*tri(note(m),.32))*env(len(x),.008,.12)
    place(b, s, at)
save("incorrect", b, out)
# Lesson complete: rising arpeggio + held chord shimmer.
b = np.zeros(int(SR*1.6))
for i,m in enumerate([72,76,79,84]): place(b, bell(note(m), .9, .35), i*.09)
for m in [84,88,91]: place(b, .5*bell(note(m), 1.2, .6, .2), .42)
x = t(1.0); shimmer = 0.08*np.sin(2*np.pi*note(96)*x)*np.sin(2*np.pi*7*x)**2*np.exp(-x/0.5); place(b, shimmer, .45)
save("lesson_complete", b, out)
# Node unlock: upward pitch sweep + sparkle pings.
x = t(.28); f = np.linspace(note(67), note(79), len(x)); ph = 2*np.pi*np.cumsum(f)/SR
b = np.zeros(int(SR*.7)); place(b, 0.5*np.sin(ph)*env(len(x),.01,.18), 0)
for i,m in enumerate([91,96,98]): place(b, .45*bell(note(m), .3, .09), .2+i*.06)
save("node_unlock", b, out)
# Node complete: single warm pop + chime.
b = np.zeros(int(SR*.6)); x=t(.08); place(b, np.sin(2*np.pi*np.linspace(300,90,len(x))*x)*env(len(x),.002,.03), 0)
place(b, bell(note(86), .5, .25), .04)
save("node_complete", b, out)
# Tap: tiny soft tick.
x = t(.05); s = np.sin(2*np.pi*1800*x)*env(len(x),.001,.008)
save("tap", s, out)
# Select: a soft, short wooden click (option chosen).
x = t(.07); s = (np.sin(2*np.pi*1100*x)+.4*np.sin(2*np.pi*2300*x))*env(len(x),.001,.015)
save("select", s, out)
# Partial: two gentle neutral tones, the second slightly lower (almost).
b = np.zeros(int(SR*.45))
place(b, .8*bell(note(79), .3, .14, .2), 0); place(b, .7*bell(note(76), .3, .16, .2), .1)
save("partial", b, out)
# Streak: warm rising fourth with a soft glow tail.
b = np.zeros(int(SR*.9))
place(b, bell(note(74), .7, .3), 0); place(b, bell(note(79), .8, .4), .11)
x = t(.6); place(b, .06*np.sin(2*np.pi*note(91)*x)*np.exp(-x/.3), .2)
save("streak", b, out)
# Reward: three quick sparkle pings, ascending.
b = np.zeros(int(SR*.8))
for i,m in enumerate([88,93,96]): place(b, .7*bell(note(m), .45, .18), i*.07)
save("reward", b, out)
# Model ready: calm two-note confirmation, low then high.
b = np.zeros(int(SR*.8))
place(b, .8*bell(note(67), .5, .3, .15), 0); place(b, .8*bell(note(74), .6, .35, .15), .16)
save("model_ready", b, out)
print("ok")
