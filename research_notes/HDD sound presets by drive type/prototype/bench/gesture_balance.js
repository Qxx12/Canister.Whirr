// Per-gesture band balance: energy 250-1200 Hz vs 1.5-8 kHz for the d=0.33 and d=0.04 bins.
const fs = require("fs"), E = require("./engine.js");
const data = JSON.parse(fs.readFileSync("bench-data.json", "utf8"));
function bandEnergy(x, lo, hi) { // Goertzel-free: naive DFT over a coarse grid
  let e = 0; const N = x.length;
  for (let f = lo; f < hi; f += 25) {
    const w = 2 * Math.PI * f / E.SR; let re = 0, im = 0;
    for (let i = 0; i < N; i++) { re += x[i] * Math.cos(w * i); im -= x[i] * Math.sin(w * i); }
    e += re * re + im * im;
  }
  return e * 25;
}
const ratio = (bins, b) => { let lo = 0, hi = 0; for (const g of bins[b].slice(0, 4)) { lo += bandEnergy(g, 250, 1200); hi += bandEnergy(g, 1500, 8000); } return 10 * Math.log10(lo / hi); };
const only = process.argv.slice(2);
for (const drive of data.drives) {
  if (only.length && !only.includes(drive.name)) continue;
  const out = [];
  for (const knobs of [{ bodyDB: -100 }, {}]) {
    const { voice, knobs: k } = E.effectiveVoice(drive, knobs, data.enclosures);
    voice.enclosure = null;
    const bins = E.buildBank(voice, k, 7, 4);
    out.push(ratio(bins, 5).toFixed(1), ratio(bins, 3).toFixed(1));
  }
  console.log(drive.name.padEnd(26), "no body d.33/d.04:", out[0], out[1], "  with body:", out[2], out[3]);
}
