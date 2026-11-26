# Sample-track renderer (prototype)

Renders the 22-second sample tracks on the "Whirr drive lineup" page from Whirr's real synthesis code.

- `src/SoundBank.swift`: a copy of `Sources/Whirr/SoundBank.swift` plus a prototype stepper impulse-train gesture (`DrivePreset.Stepper`), the body layer (`DrivePreset.body`), darker room reflections and a 120 Hz default bass cut.
- `src/Sonifier.swift`: an unchanged copy of `Sources/Whirr/Sonifier.swift`.
- `src/Presets.swift`: the proposed presets (stepper1987, woody2000, thunk2007, laptop2007, server10k, server15k, helium2020, failing) and the extras each sample previews: PWL idle ticks, writing rumble, failure clicks. No constant spindle sound.
- `src/main.swift`: a scripted workload (seek ladder, app launch, file copy, indexing, idle), mixing and loudness matching.
- `excerpt.py`: cuts the 8-second real-drive excerpts from the CC0/PD recordings.

Build and render (Enclosure.swift and DiskMonitor.swift come from the app's own sources):

```bash
swiftc -O -o /tmp/whirr-render src/*.swift ../../../Sources/Whirr/Enclosure.swift ../../../Sources/Whirr/DiskMonitor.swift
```

```bash
/tmp/whirr-render <output-folder> [preset names...]
```

## Tuning bench

`bench/` holds the "Whirr Tuning Bench" page: `engine.js` is a JavaScript port of the gesture synthesis
(`SoundBank.renderGesture`, `Enclosure.apply`, the bank normalization, the body layer and the prototype rumble),
and `index.html` is the page. `build.py` inlines the engine into the page and gathers `bench-data.json`
and the real-drive excerpts into `publish/`.

`bench-data.json` comes from the renderer: `WHIRR_EXPORT=bench-data.json /tmp/whirr-render <output-folder>`
writes each preset's parameters and the exact event timeline it rendered (`src/Export.swift`).

`node_render.js` renders every drive with the JS port under Node, and `compare.py` checks those renders against
the Swift ones (third-octave spectra and loudness envelopes). At the time of writing, every drive matched within
the variation you get from changing the random seed.

`gesture_balance.js` prints each drive's 250–1200 Hz vs 1.5–8 kHz energy for single gestures, with and
without the body layer; `solve_body.js` finds the body level that hits a target balance.
`compare.py` checks the JS renders against the Swift ones (`OUT=<swift output folder>`).
