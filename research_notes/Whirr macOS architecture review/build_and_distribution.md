# Build and Distribution of a Small Open-Source Swift CLI Helper for macOS (SwiftPM, no .app bundle)

Context: background helper that plays sounds (AVFoundation/AVAudioEngine, CoreAudio) and reads IORegistry (IOKit), built with `swift build`, no Xcode project. Targets macOS 15 Sequoia and macOS 26 Tahoe; research date 2026-11-23. NOTE: the research machine itself runs **macOS 27.2 (Darwin 27.2, build 26B123) with Swift 6.4.2**, and Homebrew docs already treat macOS 27 as "the latest stable macOS version" ([Homebrew Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)). The target matrix should probably add macOS 27.

"Local test" below means an experiment run during this research on the machine above (Xcode.app installed, plus a separate Command Line Tools install at `/Library/Developer/CommandLineTools`, CLT pkg version 27.2.0.0.1792721180, SDKs MacOSX26.sdk / 26.5 / 27 / 27.2). The test package imported AVFoundation, CoreAudio, IOKit and IOKit.ps, created an `AVAudioEngine`, called `IORegistryEntryFromPath`, and embedded an Info.plist through `-sectcreate`.

## Q1. Is SwiftPM with only the Command Line Tools viable (IOKit, AVFoundation, CoreAudio)? Do universal builds work without Xcode?

### Takeaway
Yes. Under the CLT toolchain alone (`DEVELOPER_DIR=/Library/Developer/CommandLineTools`), the local test package built both a single-arch release and a universal (`--arch arm64 --arch x86_64`) release, and the result ran natively and under Rosetta. IOKit, AVFoundation and CoreAudio are all in the CLT's macOS SDK. Two big changes since older advice: Swift 6.4 made "Swift Build" the default SwiftPM build engine and moved the output paths, and x86_64 is now deprecated by both the toolchain and Homebrew.

### Cited Findings
- Local test, CLT only: `swift build -c release` printed "Build complete!" with only a harmless warning (`search path '/Library/Developer/CommandLineTools/Developer/Library/Frameworks' not found`), so no Xcode-only framework was needed for AVFoundation, CoreAudio or IOKit — local test (see header).
- Local test, CLT only: `swift build -c release --arch arm64 --arch x86_64` also printed "Build complete!" The product was `.build/out/Products/Release/t`. It ran natively, and `arch -x86_64` ran it under Rosetta. Two warnings appeared:
  - `ignoring file .../CommandLineTools/usr/lib/swift/macosx/libswiftCompatibilityPacks.a: fat file missing arch 'x86_64'`. This back-deployment shim only matters if the code uses parameter packs on older OSes.
  - `The x86_64 architecture is deprecated for your deployment target (macOS 27.2)`.

  — local test.
- `swift build --help` on Swift 6.4.2 lists `--build-system` with the default `swiftbuild` ("Swift Build build engine (default)") and `native` ("Native Build System (deprecated)") — local test.
- Swift 6.4 "changes the default SwiftPM build system to use Swift Build". Build products moved, so scripts should use `swift build --show-bin-path` instead of hardcoding `.build/release`. `--build-system native` is the fallback — [Swift Package Index blog](https://swiftpackageindex.com/blog/swift-6-4-support-and-the-move-to-swift-build); [SwiftPM default build system update (Swift Forums)](https://forums.swift.org/t/swiftpm-development-update-default-build-system-change/85548); [What's new in Swift: March 2026](https://swift.org/blog/whats-new-in-swift-march-2026/).
- The SwiftPM plan includes "removal of SwiftPM's current default build system implementation in 2026H2" — [Swift Forums](https://forums.swift.org/t/swiftpm-development-update-default-build-system-change/85548) (as summarized by search; not independently confirmed that the removal shipped).
- homebrew-core already builds Swift CLIs without full Xcode:
  - `xcodes` declares only `uses_from_macos "swift"` and `depends_on macos: :sequoia`, with no `depends_on xcode` — [homebrew-core xcodes.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/x/xcodes.rb).
  - `mas` uses `uses_from_macos "swift" => :build, since: :sequoia # swift 6.2+` but adds `depends_on xcode: ["26.0", :build]` on Sequoia or newer — [homebrew-core mas.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/m/mas.rb).
  - `swiftlint` has `depends_on xcode: "8.0"` because it needs SourceKit at runtime — [homebrew-core swiftlint.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/s/swiftlint.rb).
- mas carries patches for "build with Swift 6.4" on Tahoe or newer. New Swift releases can break builds from source — [mas.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/m/mas.rb).
- xcodes builds its release binary with `--arch arm64 --arch x86_64` in its Makefile — [xcodes Makefile](https://github.com/XcodesOrg/xcodes/blob/main/Makefile).
- Homebrew moves Intel Macs to Tier 3 in September 2026 and stops working on Intel entirely in September 2027. macOS 26 Tahoe is the last macOS that supports Intel — [Workbrew: Homebrew 5.0.0](https://workbrew.com/blog/what-homebrew-5-0-0-means-for-your-mac-fleet).

### Inferences
- Full Xcode is not needed for this tool's frameworks (IOKit, AVFoundation, CoreAudio, Foundation). Xcode-only features are XCTest/Swift Testing in some setups, asset catalogs, Interface Builder, app bundles, `xcodebuild`, and `notarytool`/`stapler`, which ship in Xcode under `xcrun` (not verified here whether the current CLT includes `notarytool`).
- Universal builds remain possible, but x86_64 is a shrinking target. Shipping universal binaries for macOS 15 and 26 is still reasonable because Tahoe supports Intel. The value drops after September 2027. Set `platforms: [.macOS(.v15)]` explicitly in Package.swift.
- Formulas and release scripts should use `swift build --show-bin-path` (or `-c release --show-bin-path`) rather than `.build/release/<name>`. That path is still used by the current homebrew-core formulas and is what breaks with the Swift Build layout.

### Gaps
- Not tested on a machine with *only* CLT and no Xcode.app (`DEVELOPER_DIR` was overridden, but Xcode was still present). Not tested with a Sequoia-era CLT (Swift 6.0/6.1). Whether `swift build --arch` multi-arch needed Xcode's xcbuild on older toolchains was not confirmed.
- Did not verify that `xcrun notarytool` is included in the CLT-only install.

## Q2. When is an embedded Info.plist needed, and does an audio + IORegistry CLI need entitlements or usage strings?

### Takeaway
An embedded `__TEXT,__info_plist` is optional for this tool. It is only needed when TCC must prompt the tool itself, for example for microphone, camera, Bluetooth or Apple Events. Even then it only helps when the tool is the "responsible process", such as when it is launched by launchd. Playing audio and reading IORegistry trigger no TCC prompt. Embedding a minimal plist (CFBundleIdentifier, version) is cheap and gives the binary a stable identity.

### Cited Findings
- Recipe: link the plist into the `__TEXT,__info_plist` section with `-sectcreate` in SwiftPM linker flags, and verify with `otool -s __TEXT __info_plist` — [steipete: embedding Info.plist for macOS CLIs](https://steipete.me/posts/2025/applescript-cli-macos-complete-guide); same approach in CMake — [CMake Discourse](https://discourse.cmake.org/t/how-to-embed-info-plist-in-a-simple-mac-binary-file/512/2).
- Local test: `linkerSettings: [.unsafeFlags(["-Xlinker","-sectcreate","-Xlinker","__TEXT","-Xlinker","__info_plist","-Xlinker","Info.plist"])]` worked, and `Bundle.main.bundleIdentifier` returned the embedded ID. The linker's ad-hoc signature reported `Info.plist=not bound`, which means only a real `codesign` pass binds it.
- Caveat: `unsafeFlags` is disallowed for packages consumed as *dependencies*, but fine for a root executable package (well-known SwiftPM rule; not separately sourced here).
- TCC attributes requests to the "responsible process". If that process's Info.plist lacks the usage string, "macOS refuses to show the authorization prompt at all" — [Qt blog: The Curious Case of the Responsible Process](https://www.qt.io/blog/the-curious-case-of-the-responsible-process); [Michael Tsai summary](https://mjtsai.com/blog/2025/07/07/the-curious-case-of-the-responsible-process/).
- For a standalone tool, Apple DTS suggests adding an Info.plist "to a custom section in your executable" — [Apple Developer Forums: Command line tool camera permission](https://developer.apple.com/forums/thread/111100).
- Command-line tools needing camera or Bluetooth access require a usage-description key plus, under the hardened runtime, the matching device entitlement — [Apple Forums: Device Authorization in a C-Tool](https://developer.apple.com/forums/thread/701094); [Apple Forums: Command Line Utility vs Core Bluetooth](https://developer.apple.com/forums/thread/675773).
- Under Sonoma and later, `blueutil` cannot be tested in Homebrew CI because "OS privacy restrictions will wait until Bluetooth permission is either accepted or rejected". Hardware-access CLIs do hit TCC — [homebrew-core blueutil.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/b/blueutil.rb).
- Entitlements "only make sense on a main executable". Restricted entitlements require wrapping the executable in an app-like structure with a provisioning profile — [Quinn: Creating Distribution-Signed Code for Mac](https://developer.apple.com/forums/thread/701514).

### Inferences
- Sound *output* through AVAudioEngine or CoreAudio and IORegistry reads (battery, lid, power, USB via `IOServiceGetMatchingServices`/`IORegistryEntryCreateCFProperty`) are not TCC-protected. No usage string or entitlement is needed, even under the hardened runtime. Only `com.apple.security.device.audio-input` and `NSMicrophoneUsageDescription` would apply if the tool ever captured audio. This is based on general platform knowledge; I found no Apple page stating it for output-only audio.
- If features grow (input monitoring of keys, Accessibility, mic), an embedded Info.plist with a stable CFBundleIdentifier, plus a stable signing identity, becomes important. TCC grants are tied to the code's designated requirement. An ad-hoc signature's cdhash changes on every rebuild, so grants get lost after each `brew upgrade`.

### Gaps
- No authoritative Apple statement found that lists audio output or IORegistry reads as TCC-free.
- macOS 26 and 27 TCC changes for CLI tools were not investigated.

## Q3. Code signing, notarization and Gatekeeper/quarantine for a bare CLI binary (macOS 15, 26)

### Takeaway
On Apple Silicon the linker ad-hoc-signs automatically. That is enough to *run*, but Gatekeeper only checks quarantined files. Browser downloads are quarantined; `curl` downloads and Homebrew formula installs are not. For direct browser downloads, sign with Developer ID plus the hardened runtime plus a timestamp, then notarize a zip, dmg or pkg. A bare Mach-O or a zip cannot be stapled, so the check happens online. A `.pkg` can be stapled. Sequoia removed the Control-click override, so unsigned downloaded binaries now need a trip to System Settings or `xattr`.

### Cited Findings
- Local test: an SwiftPM-built binary showed `flags=0x20002(adhoc,linker-signed)` and `Signature=adhoc`, `TeamIdentifier=not set`.
- Signing non-bundled code takes `codesign -s "Developer ID Application" -f --timestamp -o runtime -i com.example.tool <path>`, with these parts:
  - `-i` is required, giving "the bundle ID the code would have if it had a bundle ID".
  - `-o runtime` turns on the Hardened Runtime for Developer ID main executables.
  - `--timestamp` is required for Developer ID.
  - Avoid `--deep`.

  — [Quinn: Creating Distribution-Signed Code for Mac](https://developer.apple.com/forums/thread/701514).
- Packaging: "Zip archives cannot be signed, although their contents can be". Build them with `ditto -c -k --keepParent`. "Only notarize the outermost container". dmg and pkg can be stapled. Stapling is "recommended but not mandatory"; without it, a product may be blocked "if they try to install or use it while the Mac is offline" — [Quinn: Packaging Mac Software for Distribution](https://developer.apple.com/forums/thread/701581).
- "The stapler does not accept zip files". Without a stapled ticket, Gatekeeper "attempts to get that ticket from the Apple notarisation servers" — [Apple Forums: Stapling ticket for Notarization](https://developer.apple.com/forums/thread/116812).
- "Unix-y networking tools, like curl and scp, don't quarantine the files they download", so Gatekeeper does not assess them — [Apple Forums (Quinn)](https://developer.apple.com/forums/thread/666452); attackers abuse the same fact — [Unit 42](https://unit42.paloaltonetworks.com/gatekeeper-bypass-macos).
- macOS 15 Sequoia removed the Control-click "Open" override for software that is not correctly signed or notarized. Users must try to open the item, then go to System Settings > Privacy & Security > "Open Anyway" and authenticate as admin — [MacRumors](https://www.macrumors.com/2024/08/06/macos-sequoia-gatekeeper-security-change/); [AppleInsider](https://appleinsider.com/articles/24/08/06/apple-removes-control-click-option-for-skipping-gatekeeper-in-macos-sequoia); [Michael Tsai](https://mjtsai.com/blog/2024/07/05/sequoia-removes-gatekeeper-contextual-menu-override).
- One report says that in macOS 15.1 the "Open Anyway" button did not appear for unsigned apps. This is a single unverified report — [OSNews](https://osnews.com/?p=141055); contradicted in part by [iDownloadBlog](https://www.idownloadblog.com/2024/08/07/apple-macos-sequoia-gatekeeper-change-install-unsigned-apps-mac/).
- Example: xcodes signs, zips with `zip --junk-paths xcodes.zip`, and runs `./notarize.sh xcodes.zip $TEAMID`. Its GitHub release ships `xcodes.zip` alongside bottles — [xcodes Makefile](https://github.com/XcodesOrg/xcodes/blob/main/Makefile); [xcodes 2.2.0 release assets](https://github.com/XcodesOrg/xcodes/releases/latest).
- Since Ventura, launchd agents appear under System Settings > General > Login Items ("Allow in the Background"). Items whose signature does not resolve to a developer show "Item from unidentified developer" — [Eclectic Light: Ventura login/background items](https://eclecticlight.co/2023/02/16/how-ventura-is-changing-login-and-background-items); [Apple Forums thread 721918](https://developer.apple.com/forums/thread/721918); [Apple Forums thread 757463](https://developer.apple.com/forums/thread/757463).

### Inferences
- Notarization *can* be done for a CLI: submit a zip (or pkg) with `xcrun notarytool submit --wait`. The ticket cannot be stapled to the bare binary or the zip, so first launch after a browser download needs a network check. A Developer ID-signed `.pkg` (`productbuild --sign "Developer ID Installer"`) is the only stapleable option for a non-app CLI. mas uses this route with per-arch pkgs ([mas v7.0.0 assets](https://github.com/mas-cli/mas/releases/latest)), and SwiftLint ships `SwiftLint.pkg` ([SwiftLint 0.65.1 assets](https://github.com/realm/SwiftLint/releases/latest)).
- Developer ID costs an Apple Developer Program membership (well known as US$99/yr; not re-verified here). For a small hobby open-source tool, it is reasonable to skip notarization if the primary channel is a Homebrew formula built from source.
- A LaunchAgent pointing at an ad-hoc-signed binary will likely show as "unidentified developer" in Login Items. This is cosmetic but can alarm users. Developer ID signing fixes the label.

### Gaps
- No Apple primary doc fetched on macOS 26 or 27 Gatekeeper changes for CLI tools; I found no reliable source describing Tahoe-specific changes. The Apple notarization doc page ("Customizing the notarization workflow") did not render through the fetch tool.
- Not verified whether `brew services`-generated plists pointing at ad-hoc binaries trigger "Background Items Added" notifications on macOS 15 and 26.

## Q4. Homebrew distribution: formula build-from-source, tap vs homebrew-core, `service do`, quarantine, casks and the signing policy

### Takeaway
Publish a **formula** (not a cask) in a personal tap (`<user>/homebrew-tap`) that builds from source with `swift build`. Add a `service do` block so `brew services start` manages the LaunchAgent. Formulae are not quarantined and are unaffected by the cask Gatekeeper policy. Casks must now pass Gatekeeper; the September 2026 deadline has passed and `--no-quarantine` is gone, so an unsigned cask is not viable in homebrew/cask. homebrew-core needs a stable tagged release, a repo at least 30 days old, and 75 stars or 30 forks or 30 watchers (225 / 90 / 90 if self-submitted).

### Cited Findings
- `service do` block example: `service do; run [opt_bin/"tool", "--flag"]; keep_alive true; end`. Options include:
  - `run_type :immediate|:interval|:cron`
  - `keep_alive` (bool or `successful_exit:`/`crashed:`)
  - `log_path`, `error_log_path`
  - `process_type :background|:standard|:interactive|:adaptive`
  - `run_at_load` (default true), `environment_variables`, `working_dir`, `restart_delay`, `throttle_interval`
  - `require_root` (default false)

  — [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook).
- `depends_on xcode: ["9.3", :build]` marks Xcode as build-only, so it "can be skipped when installing from a bottle". `uses_from_macos` uses the macOS-provided component, behaves like `depends_on` on Linux, and takes `since:` — [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook).
- Homebrew's `std_swift_args` is `["--configuration", "release", "--jobs", ENV.make_jobs.to_s]` — [Homebrew/brew formula.rb](https://github.com/Homebrew/brew/blob/HEAD/Library/Homebrew/formula.rb).
- The current homebrew-core Swift pattern is `def fetch; system "swift", "package", "resolve", "--disable-sandbox"; end`, then `system "swift", "build", *std_swift_args` and `bin.install ".build/release/<name>"`. The comment explains: "SwiftPM tries to apply its own sandbox, which cannot nest inside the build sandbox" — [xcodes.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/x/xcodes.rb); [swiftlint.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/s/swiftlint.rb); background: [Swift Forums on --disable-sandbox](https://forums.swift.org/t/what-does-disable-sandbox-do-for-swift-package-manager/40788).
- Comparable third-party taps (C tools) build from source and ad-hoc re-sign explicitly with `codesign --force -s -`:
  - SketchyBar — [FelixKratz/homebrew-formulae sketchybar.rb](https://github.com/FelixKratz/homebrew-formulae/blob/master/sketchybar.rb)
  - skhd — [koekeishiya/homebrew-formulae skhd.rb](https://github.com/koekeishiya/homebrew-formulae/blob/master/skhd.rb)
  - yabai, whose stable formula installs a prebuilt release tarball instead — [yabai.rb](https://github.com/koekeishiya/homebrew-formulae/blob/master/yabai.rb)

  skhd and yabai manage their own launchd agents (`--start-service`) rather than using `service do`.
- `blueutil` and `switchaudio-osx` in homebrew-core use `depends_on xcode: :build` + `xcodebuild` because they have Xcode projects — [blueutil.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/b/blueutil.rb); [switchaudio-osx.rb](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/s/switchaudio-osx.rb).
- homebrew-core acceptance:
  - "at least 30 forks, 30 watchers or 75 stars"; self-submitted needs "at least 90 forks, 90 watchers or 225 stars"
  - "A code repository less than 30 days old is normally not eligible"
  - non-qualifying software "can generally be maintained in a third-party tap"

  — [Homebrew Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy).
- Formulae need a stable release with "an immutable tag or release" and "must either build from source…"; "Proprietary or platform-specific binary-only software belongs in a cask" — [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae).
- Casks: executable artefacts "must pass Homebrew's Gatekeeper checks" and "must not require System Integrity Protection or Gatekeeper to be disabled or bypassed". Casks may ship "other pre-built files", not only apps — [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks).
- Homebrew 5.0.0 (Nov 2025) changes:
  - deprecated `--no-quarantine`/`--quarantine`
  - casks without codesigning and notarization are deprecated, and casks failing the audit "will be removed from the official Tap" by September 2026

  — [Workbrew: Homebrew 5.0.0](https://workbrew.com/blog/what-homebrew-5-0-0-means-for-your-mac-fleet); [Homebrew docs: Deprecating, Disabling and Removing Casks](https://docs.brew.sh/Deprecating-Disabling-and-Removing-Casks). Sources disagree on the exact version that removed the flag (4.7 vs 5.0) — [TomatoBar issue #102](https://github.com/ivoronin/TomatoBar/issues/102).
- The quarantine change "only affects Casks". Formula source builds and bottles are not directly affected — [HN discussion](https://hn.svelte.dev/item/45907259) (secondary source). Third-party taps shipping unsigned binaries via casks add a postflight `xattr -dr com.apple.quarantine` — [abizer/nssh PR #8](https://github.com/abizer/nssh/pull/8).
- Rosetta casks: new `requires_rosetta` casks became ineligible once macOS 27 was latest stable, and will be disabled after macOS 28 — [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks).

### Inferences
- For Whirr, a tap formula with no `depends_on xcode` (like xcodes) should work on CLT-only machines on macOS 15+. Add `depends_on macos: :sequoia` and `uses_from_macos "swift" => :build` if Swift 6.x features are needed. For robustness against the Swift Build path change, install from `Utils.safe_popen_read("swift", "build", "--show-bin-path", *std_swift_args).chomp` (or pin `--build-system native` while it exists).
- A tap formula built from source is never quarantined, and its locally-linked binary is ad-hoc-signed. Gatekeeper therefore never runs on it, which avoids the Apple Developer Program entirely. The trade-off: TCC grants and the Login Items label are tied to an unstable ad-hoc identity. Neither matters for audio output plus IORegistry.
- Bottles in a personal tap are optional; GitHub Actions `brew test-bot` can build them. Without bottles, users compile locally (tens of seconds for a small package).
- Self-hosted casks in a personal tap are not bound by homebrew/cask audits. However, Homebrew no longer offers `--no-quarantine`, so an unsigned cask binary would hit Gatekeeper unless the cask strips quarantine itself, a practice Homebrew discourages. Casks only make sense if the binary is Developer ID-signed and notarized.

### Gaps
- No official Homebrew changelog was fetched confirming what was actually disabled on/after 2026-09-01, or whether the deadline was extended.
- Did not confirm whether Homebrew-generated `brew services` plists include `AssociatedBundleIdentifiers` or how they are labelled in Login Items.

## Q5. Alternatives (Mint, GitHub releases, curl | sh, Mac App Store) and what comparable tools do

### Takeaway
Comparable Swift CLIs combine two channels: a Homebrew formula (core or tap) plus GitHub release artifacts (a notarized zip or a signed pkg). Mint still works but is low-activity. `curl | sh` avoids quarantine, but for the same reason it skips Gatekeeper, so trust rests on the script and TLS. The Mac App Store is not realistic for a LaunchAgent CLI.

### Cited Findings
- **xcodes 2.2.0** (2026-11-11): formula in homebrew-core (CLT-only) plus a GitHub release with `xcodes.zip` (universal, signed, notarized via Makefile) and bottles — [xcodes releases](https://github.com/XcodesOrg/xcodes/releases/latest); [Makefile](https://github.com/XcodesOrg/xcodes/blob/main/Makefile).
- **SwiftLint 0.65.1**: homebrew-core formula plus release assets including `portable_swiftlint.zip`, `SwiftLint.pkg`, and a SwiftPM `artifactbundle.zip` — [SwiftLint releases](https://github.com/realm/SwiftLint/releases/latest).
- **mas v7.0.0**: homebrew-core formula plus per-arch `.pkg` installers — [mas releases](https://github.com/mas-cli/mas/releases/latest).
- **blueutil, switchaudio-osx**: homebrew-core formulae built from Xcode projects with `xcodebuild` — see Q4 citations.
- **skhd, yabai, SketchyBar** (C/ObjC): personal taps; source builds ad-hoc-signed with `codesign -fs -` — see Q4 citations.
- **Mint**: latest release 0.18.0 (2025-06-04); last push 2026-01-03; about 2.5k stars; not archived — [GitHub API: yonaskolb/Mint](https://github.com/yonaskolb/Mint).
- curl downloads are not quarantined, so an install script that `curl`s a binary bypasses Gatekeeper checks entirely. This property is also exploited by malware such as Shlayer — [Apple Forums](https://developer.apple.com/forums/thread/666452); [Red Canary](https://redcanary.com/threat-detection-report/techniques/gatekeeper-bypass/).
- Mac App Store distribution requires signing with "Apple Distribution" — [Quinn: Creating Distribution-Signed Code](https://developer.apple.com/forums/thread/701514).

### Inferences
- Mac App Store: effectively impossible for this design. The App Store requires an app bundle and App Sandbox. A standalone CLI installed into PATH, plus a user-installed `~/Library/LaunchAgents` plist, is not an App Store shape. The only route would be an app with an `SMAppService` login item, which contradicts the "no .app bundle" constraint. This is based on general platform knowledge, not a fetched Apple source.
- Mint suits Swift developers installing dev tools pinned per project. It is a poor fit for an end-user background helper, because it doesn't manage launchd and requires a Swift toolchain.
- **Recommendation:**
  1. Primary channel: a personal tap `<user>/homebrew-tap` with a source-build formula and a `service do` block (`run [opt_bin/"whirr", "daemon"]`, `keep_alive true`, `process_type :interactive` or `:adaptive` for low-latency audio, `log_path var/"log/whirr.log"`). No Xcode dependency; `depends_on macos: :sequoia`.
  2. Secondary: tagged GitHub releases with a universal binary in a zip. If and when an Apple Developer account exists, sign it with Developer ID plus `-o runtime --timestamp -i <id>`, notarize, and preferably ship a stapled Developer ID-signed `.pkg`. Until then, document `xattr -d com.apple.quarantine` or `curl` download, and note the Sequoia "Open Anyway" flow.
  3. Defer homebrew-core until the project has 225 stars (self-submit) or someone else submits it at 75 stars.
  4. Skip casks, Mint and the Mac App Store.
  5. Embed a minimal Info.plist via `-sectcreate` now so the binary has a stable identifier for future TCC needs.
  6. Use `swift build --show-bin-path` in all scripts.

### Gaps
- Did not fetch release workflows (GitHub Actions YAML) for SwiftLint or mas to confirm their notarization steps.
- Did not check whether skhd or yabai publish notarized release binaries.

## Q6. Licensing: procedurally generated sounds vs bundled sample recordings (brief)

### Takeaway
Procedurally synthesized sounds (oscillators, noise, envelopes in code) carry only the code's license, which is the simplest option. Bundled recordings bring separate per-file licenses that must be tracked and redistributed correctly. No sources were researched for this item.

### Cited Findings
- None. This question was not researched with sources within the tool-call budget.

### Inferences
- Generated audio from your own code is covered by the project's code license (e.g., MIT); there are no third-party sample rights. Recorded samples need a license that permits redistribution and modification, such as CC0 or CC-BY with attribution in a NOTICE or credits file. Avoid CC-NC/ND and "royalty-free for personal use" packs, which conflict with OSI licenses and Homebrew/Linux distro packaging. Apple's system sounds (`/System/Library/Sounds`) can be *played* from the user's own system but should not be copied into the repo. Treat all of this as unverified general knowledge.

### Gaps
- No primary source (Creative Commons FAQ, Apple macOS SLA text on system sounds, Debian/Homebrew policy on media licenses) was consulted.
