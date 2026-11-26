const fs = require("fs");
const E = require("./engine.js");
const data = JSON.parse(fs.readFileSync("bench-data.json", "utf8"));
fs.mkdirSync("js_out", { recursive: true });
for (const drive of data.drives) {
  if (process.argv.length > 2 && !process.argv.includes(drive.name)) continue;
  const t0 = Date.now();
  const mix = E.renderTrack(drive, {}, data.enclosures);
  const out = E.finish(mix, E.loudnessScale(mix));
  const buf = Buffer.alloc(44 + out.length * 2);
  buf.write("RIFF", 0); buf.writeUInt32LE(36 + out.length * 2, 4); buf.write("WAVEfmt ", 8);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22); buf.writeUInt32LE(48000, 24);
  buf.writeUInt32LE(96000, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34); buf.write("data", 36); buf.writeUInt32LE(out.length * 2, 40);
  for (let i = 0; i < out.length; i++) buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(out[i] * 32767))), 44 + 2 * i);
  fs.writeFileSync(`js_out/${drive.name}.wav`, buf);
  console.log(drive.name, Date.now() - t0, "ms");
}
