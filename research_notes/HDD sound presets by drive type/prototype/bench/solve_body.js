const fs = require("fs"), E = require("./engine.js");
const data = JSON.parse(fs.readFileSync("bench-data.json", "utf8"));
const src = fs.readFileSync("gesture_balance.js", "utf8");
function bandEnergy(x, lo, hi) { let e = 0; for (let f = lo; f < hi; f += 25) { const w = 2*Math.PI*f/E.SR; let re=0, im=0; for (let i=0;i<x.length;i++){re+=x[i]*Math.cos(w*i); im-=x[i]*Math.sin(w*i);} e+=re*re+im*im; } return e; }
const targets = { vintage1993: 2, woody2000: 2, desktop2005: 0, laptop2007: -3, quiet2010s: -3, server10k: -3, server15k: -3, helium2020: 2 };
for (const [name, target] of Object.entries(targets)) {
  const drive = data.drives.find((d) => d.name === name);
  const meas = (off) => { const { voice, knobs: k } = E.effectiveVoice(drive, { bodyDB: off }, data.enclosures); voice.enclosure = null;
    const bins = E.buildBank(voice, k, 7, 4); let lo=0, hi=0; for (const g of bins[5]) { lo += bandEnergy(g,250,1200); hi += bandEnergy(g,1500,8000);} return 10*Math.log10(lo/hi); };
  let a = -6, b = 20;
  for (let it = 0; it < 9; it++) { const m = (a + b) / 2; if (meas(m) < target) a = m; else b = m; }
  const off = Math.round((a + b) / 2);
  console.log(name, "offset", off, "first-mode dB", drive.preset.body[0][2] + off, "->", meas(off).toFixed(1));
}
