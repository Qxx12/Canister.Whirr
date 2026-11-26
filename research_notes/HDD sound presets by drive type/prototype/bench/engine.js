// Whirr seek synthesis, ported from Sources/Whirr/SoundBank.swift and Enclosure.swift
// (plus the prototype stepper gesture, body layer and rumble from the sample renderer).
// Runs as a Web Worker in the tuning bench, and under Node for checking against Swift.
(function (root) {
  "use strict";
  const SR = 48000;
  const POLL = 1 / 30;
  const db = (x) => Math.pow(10, x / 20);

  function makeRNG(seed) {
    let a = seed >>> 0;
    const next = () => {
      a = (a + 0x6d2b79f5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    const uniform = (lo, hi) => lo + (hi - lo) * next();
    const int = (lo, hi) => lo + Math.floor(next() * (hi - lo + 1));
    const gaussian = () => {
      const u1 = Math.max(next(), 2.220446049250313e-16), u2 = next();
      return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    };
    const jitter = (amount) => 1 + uniform(-amount, amount);
    return { next, uniform, int, gaussian, jitter };
  }

  class Biquad {
    constructor(b0, b1, b2, a0, a1, a2) {
      this.b0 = b0 / a0; this.b1 = b1 / a0; this.b2 = b2 / a0; this.a1 = a1 / a0; this.a2 = a2 / a0;
      this.x1 = 0; this.x2 = 0; this.y1 = 0; this.y2 = 0;
    }
    static bandPass(hz, q) {
      const w = 2 * Math.PI * hz / SR, alpha = Math.sin(w) / (2 * q);
      return new Biquad(alpha, 0, -alpha, 1 + alpha, -2 * Math.cos(w), 1 - alpha);
    }
    static lowPass(hz, q) {
      const w = 2 * Math.PI * Math.min(hz, SR * 0.45) / SR, alpha = Math.sin(w) / (2 * q), c = Math.cos(w);
      return new Biquad((1 - c) / 2, 1 - c, (1 - c) / 2, 1 + alpha, -2 * c, 1 - alpha);
    }
    static highPass(hz, q) {
      const w = 2 * Math.PI * hz / SR, alpha = Math.sin(w) / (2 * q), c = Math.cos(w);
      return new Biquad((1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + alpha, -2 * c, 1 - alpha);
    }
    process(x) {
      const y = this.b0 * x + this.b1 * this.x1 + this.b2 * this.x2 - this.a1 * this.y1 - this.a2 * this.y2;
      this.x2 = this.x1; this.x1 = x; this.y2 = this.y1; this.y1 = y;
      return y;
    }
  }

  function seekTime(v, d) {
    if (d <= 0) return 0;
    if (d < 0.33) return v.trackToTrack + (v.average - v.trackToTrack) * Math.sqrt(d / 0.33);
    return v.average + (v.fullStroke - v.average) * (d - 0.33) / 0.67;
  }

  // Adds a two-pole ring of `mode` driven by `input` into `out`.
  function resonate(out, input, hz, q, amplitude) {
    const omega = 2 * Math.PI * hz / SR;
    if (omega >= Math.PI) return;
    const r = Math.exp(-Math.PI * hz / (q * SR));
    const a1 = 2 * r * Math.cos(omega), a2 = -r * r, g = amplitude * Math.sin(omega);
    let y1 = 0, y2 = 0;
    for (let i = 0; i < out.length; i++) {
      const y = a1 * y1 + a2 * y2 + g * input[i];
      y2 = y1; y1 = y;
      out[i] += y;
    }
  }

  function applyEnclosure(input, force, e) {
    const n = input.length;
    const delaysMs = [0.83, 1.13, 1.37, 1.71, 2.03, 2.59, 3.07, 3.61];
    const lengths = delaysMs.map((ms) => Math.max(1, Math.floor(ms * e.size * SR / 1000)));
    const lines = lengths.length;
    const buffers = lengths.map((l) => new Float64Array(l));
    const positions = new Int32Array(lines);
    const damping = new Float64Array(lines), outs = new Float64Array(lines);
    const gains = lengths.map((l) => Math.pow(10, -3 * l / SR / e.reverbTime));
    const dampCoef = 1 - Math.exp(-2 * Math.PI * e.bounceDamping / SR);
    const inside = new Float64Array(n);
    const direct = db(e.directDB);
    const lowLoss = Math.exp(-2 * Math.PI * 300 / SR);
    const hpIn = new Float64Array(lines), hpOut = new Float64Array(lines);
    const feedIn = Biquad.highPass(300, 0.707);
    for (let i = 0; i < n; i++) {
      let sum = 0;
      for (let l = 0; l < lines; l++) { outs[l] = buffers[l][positions[l]]; sum += outs[l]; }
      const mix = sum * 2 / lines;
      const source = feedIn.process(input[i]) / lines;
      for (let l = 0; l < lines; l++) {
        const feedback = (outs[l] - mix) * gains[l];
        damping[l] += dampCoef * (feedback - damping[l]);
        hpOut[l] = lowLoss * (hpOut[l] + damping[l] - hpIn[l]);
        hpIn[l] = damping[l];
        buffers[l][positions[l]] = source + hpOut[l];
        positions[l] = (positions[l] + 1) % lengths[l];
      }
      inside[i] = direct * input[i] + sum;
    }
    let panel = new Float64Array(n);
    const lp1 = Biquad.lowPass(e.panelLowPass, 0.6), lp2 = Biquad.lowPass(e.panelLowPass * 1.4, 0.6);
    for (let i = 0; i < n; i++) panel[i] = lp2.process(lp1.process(inside[i]));
    if (e.exitTaps.length) {
      const through = panel;
      panel = new Float64Array(n);
      for (const [delayMs, tapDB] of e.exitTaps) {
        const delay = Math.floor(delayMs * SR / 1000), g = db(tapDB);
        for (let i = delay; i < n; i++) panel[i] += g * through[i - delay];
      }
    }
    const modeGain = db(e.panelModeDB);
    for (const [hz, q, mdb] of e.panelModes) {
      const res = Biquad.bandPass(hz, q), g = modeGain * db(mdb) * 4;
      for (let i = 0; i < n; i++) panel[i] += g * res.process(inside[i]);
    }
    const leakHP = Biquad.highPass(400, 0.707), leakLP = Biquad.lowPass(e.leakLowPass, 0.707);
    const leak = db(e.leakDB);
    const output = new Float64Array(n);
    for (let i = 0; i < n; i++) output[i] = panel[i] + leak * leakLP.process(leakHP.process(inside[i]));
    const chassis = db(e.chassisDB);
    for (const [hz, q, mdb] of e.chassisModes) resonate(output, force, hz, q, chassis * db(mdb));
    if (e.deskModes.length) {
      const f1 = Biquad.lowPass(e.feetLowPass, 0.707), f2 = Biquad.lowPass(e.feetLowPass, 0.707);
      const shaken = new Float64Array(n);
      for (let i = 0; i < n; i++) shaken[i] = f2.process(f1.process(force[i]));
      const desk = db(e.deskDB);
      for (const [hz, q, mdb] of e.deskModes) resonate(output, shaken, hz, q, desk * db(mdb));
    }
    return output;
  }

  // One seek gesture of distance d (fraction of full stroke). `v` is the
  // effective voice; `t` holds the tuning knobs that act inside a gesture.
  function renderGesture(d, v, t, rng) {
    const jitter = rng.jitter;
    const basePulse = (0.25 - 0.15 * Math.sqrt(d)) / 1000 * t.pulseScale;
    const strikes = [];
    let coast = null, moveTime = 0;
    if (d <= 0) {
      strikes.push({ time: 0, gain: 1, pulse: basePulse * jitter(0.3) });
    } else if (v.stepper) {
      const s = v.stepper;
      const n = Math.min(12, Math.max(1, Math.round(seekTime(v, d) * jitter(0.1) / (0.006 * s.rateScale))));
      let intervals = [];
      if (n >= 2) {
        const tail = n >= 8 ? s.tail : [], decel = n >= 4 ? s.decel : [];
        const core = Math.max(0, n - 1 - tail.length - decel.length);
        intervals = Array(core).fill(s.rate).concat(decel, tail).map((x) => x * s.rateScale);
      }
      let time = 0;
      for (let k = 0; k < n; k++) {
        const gain = db((k < n - (n >= 8 ? 2 : 0) ? 0 : -3) + rng.gaussian());
        strikes.push({ time, gain, pulse: basePulse * jitter(0.3) });
        if (k < intervals.length) time += intervals[k] + rng.uniform(-s.jitter, s.jitter);
      }
      moveTime = time;
    } else {
      const seek = seekTime(v, d) * jitter(0.1);
      const move = Math.max(0.0003, seek - v.settle);
      moveTime = move;
      strikes.push({ time: 0, gain: 1, pulse: basePulse * jitter(0.3) });
      if (move >= 0.002) {
        strikes.push({ time: move / 2, gain: db(t.strikeBDB + 2 * rng.gaussian()), pulse: basePulse * 1.5 * jitter(0.3) });
      }
      const stop = { time: move, gain: db(rng.uniform(-5, 1) + t.stopDB), pulse: basePulse * jitter(0.3) };
      strikes.push(stop);
      let settleTime = move, settleGap = rng.uniform(0.0004, 0.0012);
      const ticks = rng.int(1, 3);
      for (let k = 0; k < ticks; k++) {
        settleTime += settleGap * jitter(0.2);
        settleGap *= 1.8;
        strikes.push({ time: settleTime, gain: stop.gain * db(rng.uniform(-16, -8) + t.settleDB), pulse: basePulse * jitter(0.3) });
      }
      if (move > 0.004) coast = [0, move];
    }

    const lastStrike = strikes.reduce((m, s) => Math.max(m, s.time), 0);
    const enc = v.enclosure;
    const count = Math.floor((lastStrike + 0.11 + (enc ? enc.reverbTime * 1.1 : 0)) * SR);
    const excitation = new Float64Array(count), grit = new Float64Array(count);
    const addPulse = (time, width, gain) => {
      const start = Math.floor(time * SR), n = Math.max(2, Math.floor(width * SR));
      for (let i = 0; i < n && start + i < count; i++) excitation[start + i] += gain * (1 - Math.cos(2 * Math.PI * i / n)) / n;
    };
    for (const s of strikes) {
      addPulse(s.time, s.pulse, s.gain);
      let bt = s.time, bg = s.gain;
      const bounces = rng.int(2, 4);
      for (let k = 0; k < bounces; k++) {
        bt += rng.uniform(0.00015, 0.0008);
        bg *= rng.uniform(0.3, 0.5);
        addPulse(bt, s.pulse * 0.7, bg);
      }
      const gs = Math.floor(s.time * SR), gl = Math.floor(rng.uniform(0.0002, 0.0005) * SR);
      const level = s.gain * db(rng.uniform(-18, -10) + t.gritDB);
      let prev = 0;
      for (let i = 0; i < gl && gs + i < count; i++) {
        const noise = rng.uniform(-1, 1);
        grit[gs + i] += level * (noise - prev) * Math.exp(-i / gl * 3);
        prev = noise;
      }
    }
    const force = new Float64Array(count);
    if (enc) {
      for (const s of strikes) {
        const start = Math.floor(s.time * SR), n = Math.max(2, Math.floor(s.pulse * SR));
        for (let i = 0; i < n && start + i < count; i++) force[start + i] += 0.3 * s.gain * (1 - Math.cos(2 * Math.PI * i / n)) / n;
      }
      if (d > 0 && moveTime > 0.0005) {
        const half = Math.max(2, Math.floor(moveTime / 2 * SR));
        const area = 1.2 * Math.sqrt(d) * jitter(0.2);
        for (let lobe = 0; lobe < 2; lobe++) {
          const sign = lobe === 0 ? 1 : -1;
          for (let i = 0; i < half && lobe * half + i < count; i++) {
            force[lobe * half + i] += sign * area * (1 - Math.cos(2 * Math.PI * i / half)) / half;
          }
        }
      }
    }
    if (coast) {
      const band = Biquad.bandPass(2000, 0.7);
      const a = Math.floor(coast[0] * SR), b = Math.floor(coast[1] * SR);
      const level = db(rng.uniform(-17, -12) + t.coastDB) * 0.02;
      for (let i = a; i < Math.min(b, count); i++) {
        const shape = 1 - Math.cos(2 * Math.PI * (i - a) / (b - a));
        excitation[i] += level * shape * band.process(rng.uniform(-1, 1));
      }
    }

    let out = new Float64Array(count);
    const globalTune = jitter(0.01);
    const singleStep = !!v.stepper && strikes.length === 1;
    for (const [hz0, q0, mdb] of v.modes) {
      const hz = hz0 * globalTune * jitter(0.003);
      const q = q0 * jitter(0.15);
      const boost = singleStep && hz0 < 650 ? v.stepper.singleStepLowBoostDB : 0;
      resonate(out, excitation, hz, q, db(mdb + boost + t.modeSpreadDB * rng.gaussian()));
    }
    for (let i = 0; i < count; i++) out[i] += grit[i];

    // The body: cover and casting plates, driven by a softer, longer copy of
    // each strike plus the arm's push-pull reaction (short seeks knock deeper).
    if (v.body && v.body.length) {
      const push = new Float64Array(count);
      for (const s of strikes) {
        const start = Math.floor(s.time * SR), n = Math.max(2, Math.floor(Math.max(0.0006, s.pulse * 2.5) * SR));
        for (let i = 0; i < n && start + i < count; i++) push[start + i] += s.gain * (1 - Math.cos(2 * Math.PI * i / n)) / n;
      }
      if (d > 0 && moveTime > 0.0005 && !v.stepper) {
        const half = Math.max(2, Math.floor(moveTime / 2 * SR));
        const area = 0.4 * Math.sqrt(d) * jitter(0.2);
        for (let lobe = 0; lobe < 2; lobe++) {
          const sign = lobe === 0 ? 1 : -1;
          for (let i = 0; i < half && lobe * half + i < count; i++) {
            push[lobe * half + i] += sign * area * (1 - Math.cos(2 * Math.PI * i / half)) / half;
          }
        }
      }
      for (const [hz0, q0, mdb] of v.body) {
        resonate(out, push, hz0 * globalTune * jitter(0.02), q0 * jitter(0.15), db(mdb + 2 * rng.gaussian()));
      }
    }

    if (v.thump && d > 0) {
      const th = v.thump;
      const push = new Float64Array(count);
      const origin = v.stepper ? lastStrike : 0;
      const start = Math.floor((origin + rng.uniform(th.delay[0], th.delay[1])) * SR);
      const n = Math.floor(rng.uniform(0.001, 0.002) * SR);
      for (let i = 0; i < n && start + i < count; i++) push[start + i] = (1 - Math.cos(2 * Math.PI * i / n)) / n;
      resonate(out, push, th.hz * jitter(0.05), th.q, db(th.db - 6 + 6 * Math.sqrt(d) + 2 * rng.gaussian()));
    }
    if (enc) out = applyEnclosure(out, force, enc);
    // Room reflections come back darker: surfaces soak up the top.
    const dry = out.slice(), refl = new Float64Array(count);
    for (let k = 0; k < 5; k++) {
      const delay = Math.floor(rng.uniform(0.0007, 0.009) * SR), gain = db(rng.uniform(-22, -14) + t.roomDB);
      for (let i = delay; i < count; i++) refl[i] += gain * dry[i - delay];
    }
    const absorb = Biquad.lowPass(4000, 0.707);
    for (let i = 0; i < count; i++) out[i] += absorb.process(refl[i]);
    const lp = Biquad.lowPass(v.lowPassHz, 0.707), hp = Biquad.highPass(v.highPassHz, 0.707);
    const fade = Math.floor(0.01 * SR);
    const result = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      const y = hp.process(lp.process(out[i]));
      const tail = count - i;
      result[i] = y * (tail < fade ? tail / fade : 1);
    }
    return result;
  }

  // Default knob values: everything neutral, so a fresh bench render equals the preset.
  const NEUTRAL = {
    pitch: 1, qScale: 1, tiltDB: 0, pulseScale: 1, lowPassHz: null, highPassHz: null,
    strikeBDB: -10, stopDB: 0, settleDB: 0, gritDB: 0, coastDB: 0, roomDB: 0, modeSpreadDB: 3,
    thumpOn: null, thumpHz: null, thumpQ: null, thumpDB: null, thumpDelay: null,
    bodyDB: 0, bodyPitch: 1, bodyQ: 1,
    mount: null, rumbleDB: 0, stepRateScale: 1, levelSpanDB: 8, modes: null,
  };

  // The voice a set of knobs produces from a drive's preset.
  function effectiveVoice(drive, knobs, enclosures) {
    const p = drive.preset, k = Object.assign({}, NEUTRAL, knobs);
    const modes = (k.modes || p.modes.map((m) => [m[0], m[1], m[2], true]))
      .filter((m) => m[3] !== false)
      .map(([hz, q, mdb]) => {
        const f = hz * k.pitch;
        return [f, Math.max(2, q * k.qScale), mdb + k.tiltDB * Math.log2(f / 2000)];
      });
    const thumpOn = k.thumpOn === null ? !!p.thump : k.thumpOn;
    const baseThump = p.thump || { hz: 200, q: 12, db: -6, delay: [0.006, 0.012] };
    const thump = thumpOn ? {
      hz: k.thumpHz ?? baseThump.hz, q: k.thumpQ ?? baseThump.q, db: k.thumpDB ?? baseThump.db,
      delay: k.thumpDelay != null ? [k.thumpDelay * 0.7, k.thumpDelay * 1.3] : baseThump.delay,
    } : null;
    const body = (p.body || []).map(([hz, q, mdb]) => [hz * k.bodyPitch, Math.max(2, q * k.bodyQ), mdb + k.bodyDB]);
    const mount = k.mount === null ? (p.enclosure || "bare") : k.mount;
    return {
      knobs: k,
      voice: {
        trackToTrack: p.trackToTrack, average: p.average, fullStroke: p.fullStroke, settle: p.settle,
        modes, thump, body,
        lowPassHz: k.lowPassHz ?? p.lowPassHz, highPassHz: k.highPassHz ?? p.highPassHz,
        enclosure: mount === "bare" ? null : enclosures[mount],
        stepper: p.stepper ? Object.assign({ rateScale: k.stepRateScale }, p.stepper) : null,
      },
    };
  }

  const DISTANCES = [0, 0.002, 0.01, 0.04, 0.12, 0.33, 0.6, 1.0];
  const REFERENCE_PEAK = 0.17;

  function buildBank(voice, knobs, seed, variations) {
    const rng = makeRNG(seed);
    // This drive's personality: modes sit slightly off the preset's.
    const v = Object.assign({}, voice, { modes: voice.modes.map(([hz, q, mdb]) => [hz * rng.uniform(0.985, 1.015), q, mdb]) });
    const bins = DISTANCES.map((d) => Array.from({ length: variations }, () => renderGesture(d, v, knobs, rng)));
    const ref = DISTANCES.indexOf(0.33);
    const peaks = bins[ref].map((b) => b.reduce((m, x) => Math.max(m, Math.abs(x)), 0)).sort((a, b) => a - b);
    const scale = REFERENCE_PEAK / Math.max(peaks[Math.floor(peaks.length / 2)], 1e-9);
    for (const bin of bins) for (const b of bin) for (let i = 0; i < b.length; i++) b[i] *= scale;
    return bins;
  }

  // Playback level by distance (SoundBank.level), with an adjustable span.
  const level = (d, span) => (d <= 0 ? -16 : -span + span * Math.sqrt(d));

  function renderTrack(drive, knobs, enclosures, opts) {
    opts = opts || {};
    const { voice, knobs: k } = effectiveVoice(drive, knobs, enclosures);
    const bins = buildBank(voice, k, opts.seed || 0x5768697272, opts.variations || 12);
    const total = Math.floor(drive.total * SR);
    const mix = new Float32Array(total);
    const pick = makeRNG(1234);
    const last = new Int32Array(DISTANCES.length).fill(-1);
    for (const [time, d, gain] of drive.events) {
      let bin = 0;
      for (let b = 1; b < DISTANCES.length; b++) if (Math.abs(DISTANCES[b] - d) < Math.abs(DISTANCES[bin] - d)) bin = b;
      const list = bins[bin];
      let v = Math.floor(pick.next() * list.length);
      if (v === last[bin]) v = (v + 1) % list.length;
      last[bin] = v;
      // Re-apply the distance law so the span knob works: the exported gain
      // already holds level(d, 8) plus jitter.
      const g = gain * db(level(d, k.levelSpanDB) - level(d, 8));
      const buf = list[v], start = Math.floor(time * SR);
      for (let i = 0; i < buf.length && start + i < total; i++) mix[start + i] += buf[i] * g;
    }
    const reference = REFERENCE_PEAK * db(level(0.33, 8));
    if (drive.rumble) {
      const r = drive.rumble, noise = makeRNG(11);
      const bands = r.bands.map(([hz, q]) => Biquad.bandPass(hz, q)), weights = r.bands.map((b) => db(b[2]));
      const lvl = reference * db(r.levelDB + k.rumbleDB) * 4;
      let env = 0;
      for (let i = 0; i < total; i++) {
        const t = i / SR;
        const idx = Math.min(r.activity.length - 1, Math.max(0, Math.floor((t - drive.start) / POLL)));
        const target = t < drive.start ? 0 : r.activity[idx];
        env += (target - env) * (target > env ? 0.0006 : 0.00015);
        const x = noise.uniform(-1, 1);
        let y = 0;
        for (let b = 0; b < bands.length; b++) y += weights[b] * bands[b].process(x);
        mix[i] += lvl * env * y;
      }
    }
    return mix;
  }

  // Loudness: the scale that puts the 99.9th-percentile |sample| at -9 dBFS.
  function loudnessScale(mix) {
    const step = Math.max(1, Math.floor(mix.length / 200000));
    const a = [];
    for (let i = 0; i < mix.length; i += step) a.push(Math.abs(mix[i]));
    a.sort((x, y) => x - y);
    return db(-9) / Math.max(a[Math.floor((a.length - 1) * 0.999)], 1e-9);
  }

  function finish(mix, scale) {
    const ceiling = db(-1), out = new Float32Array(mix.length);
    for (let i = 0; i < mix.length; i++) {
      const x = mix[i] * scale, ax = Math.abs(x);
      out[i] = ax <= ceiling ? x : Math.sign(x) * (ceiling + (1 - ceiling) * Math.tanh((ax - ceiling) / (1 - ceiling)));
    }
    return out;
  }

  const api = { SR, NEUTRAL, DISTANCES, renderTrack, renderGesture, effectiveVoice, buildBank, loudnessScale, finish, makeRNG };
  root.WhirrEngine = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;

  // Worker protocol: { id, drive, knobs, enclosures, scale? } -> { id, samples, scale, ms }
  if (typeof self !== "undefined" && typeof self.postMessage === "function" && typeof window === "undefined") {
    self.onmessage = (e) => {
      const { id, drive, knobs, enclosures, scale } = e.data;
      const t0 = Date.now();
      try {
        const mix = renderTrack(drive, knobs, enclosures);
        const s = scale || loudnessScale(mix);
        const out = finish(mix, s);
        self.postMessage({ id, samples: out, scale: s, ms: Date.now() - t0 }, [out.buffer]);
      } catch (err) {
        self.postMessage({ id, error: String(err && err.message || err) });
      }
    };
  }
})(typeof self !== "undefined" ? self : globalThis);
