# Whirr

The sound of an old mechanical hard drive, driven by your Mac's real disk activity.
Seek ticks while the disk is busy, heavier clunks and chatter under load, silence when
it's idle.

Whirr is a single command-line binary that runs as a per-user background agent. It has
no menu bar icon, Dock icon or window.

## Install from source

Requires macOS 27 or later and Swift 6.4 or later (Xcode 27 or its Command Line Tools).

```bash
swift build -c release
```

Copy the binary somewhere on your PATH that you can write to without sudo, such as
`~/.local/bin` (`/usr/local/bin` often needs sudo on Apple Silicon Macs):

```bash
mkdir -p ~/.local/bin
```

```bash
cp "$(swift build -c release --show-bin-path)/whirr" ~/.local/bin/
```

If `~/.local/bin` isn't on your PATH yet, add `export PATH="$HOME/.local/bin:$PATH"` to
`~/.zshrc` and open a new terminal. Then:

```bash
whirr start
```

`whirr start` installs a login agent (`~/Library/LaunchAgents/io.github.qxx12.whirr.plist`)
that points at the binary you ran, so run it from where the binary will stay. Don't run
Whirr with sudo: it's a per-user agent and refuses to.

## Commands

| Command | What it does |
|---|---|
| `whirr start` | Start now and at every login |
| `whirr stop` | Stop and remove from login |
| `whirr restart` | Restart the running agent |
| `whirr status` | Running state, settings and output device |
| `whirr mute` / `unmute` / `toggle` | Silence or resume (polling stops while muted, 0% CPU) |
| `whirr volume [0-100]` | Show or set the volume |
| `whirr sensitivity [0.25-4]` | How eagerly activity makes sound (default 1) |
| `whirr haptics [on\|off\|75-150]` | A trackpad hum that follows the seeks (default off); a number sets its strength (default 85) |
| `whirr demo` | Play sample sounds and exit |
| `whirr monitor` | Print live disk activity levels, no sound |

Settings live in `~/Library/Application Support/Whirr/config.json`; logs in
`~/Library/Logs/Whirr/whirr.log`.

## How it works

- **Disk activity:** about 30 times a second Whirr reads the kernel's I/O counters for
  each disk (the same `IOBlockStorageDriver` statistics `iostat` uses). No root or
  permission prompt is needed. Mounted disk images are skipped because their I/O also
  counts on the disk that holds them; drives that are plugged in or removed are picked up
  automatically.
- **Rhythm (a virtual drive head):** macOS only reports how much each disk did, not
  where, so Whirr runs a pretend drive. It learns your Mac's background activity and
  turns clear bursts above it into requests. Each request gets a target from a locality
  model (mostly short moves, sometimes a long jump), and the head serves them spaced by
  real seek times plus a wait for the platter to come round. A burst starts with an
  accented long seek; busy moments become sweeps of soft short seeks; the ceiling is the
  drive's mechanical limit (about 80 seeks a second at 7200 rpm). Small background blips
  give an occasional ambient tick.
- **Sound (struck resonances):** each seek is a gesture: a strike when the arm starts, a
  softer one when the current reverses mid-seek, one when it stops, then small settle
  ticks, with a faint coast hiss on long seeks. Each strike is a short force pulse with
  micro-bounces that rings a bank of resonators: a moderately damped cluster for the
  attack and a few lightly damped partials for the metallic tail. Longer seeks are
  louder. Gestures are pre-rendered at startup for 8 seek distances with many
  variations; no recordings are bundled.
- **Drive voices:** the default is a quiet 2010s 7200 rpm drive. Voices for a 1993
  vintage drive, a 2000 5400 rpm drive, a 2005 desktop drive and a 2.5-inch laptop
  drive, and optional enclosures (closed or vented tower, laptop body, laptop on a desk
  with the drive facing down), exist in code. Their resonances and timings come from
  measurements of CC0 drive recordings and datasheets; see
  `reports/Realistic HDD sound synthesis.md`.
- **Playback:** an AVAudioEngine with a pool of 32 voices plays the gestures with a
  256-frame buffer. The engine pauses after 3 seconds of silence, which lets the Mac
  sleep and costs nothing while quiet; restarting takes under 10 ms. The default volume
  is 20%, meant to sit in the background.

- **Haptics (optional):** with `whirr haptics on`, the Force Touch trackpad (a MacBook's
  built-in one or a Magic Trackpad) hums along with the seeks, felt while a finger rests
  on it. Each seek starts a 35 ms burst of a 60 Hz vibration, timed by the output's
  reported latency to land with the sound. A busy disk runs the bursts together into a
  continuous hum, a lone seek is one soft thrum, and longer seeks hum a little stronger.
  60 Hz is low enough to feel without hearing it; the trackpad's built-in taps feel like
  clicks instead. `whirr haptics 80` or `120` makes it fainter or stronger. Whirr drives
  the trackpad through Apple's private MultitouchSupport framework, since the public
  haptics API is only for a foreground app's own controls. Its calls were worked out on
  macOS 27, so haptics stay off on other versions until they're checked (`whirr status`
  says so) rather than risk a crash; `WHIRR_HAPTICS_UNVERIFIED=1 whirr demo` tries them
  anyway.

On built-in speakers or wired headphones a click follows disk activity by a few tens of
milliseconds. Bluetooth headphones such as AirPods add roughly 150–250 ms that no app can
remove.

## Troubleshooting

- **"Switched off" in `whirr status`:** turn Whirr on in System Settings > General >
  Login Items & Extensions, then run `whirr start`.
- **Too chatty or too quiet:** adjust `whirr sensitivity` (for example `0.5` or `2`), and
  use `whirr monitor` to see what your disk is doing.

## License

MIT. See [LICENSE](LICENSE).
