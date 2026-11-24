# Running a lightweight per-user background CLI process at login on modern macOS

Scope note for the report writer: target is macOS 15 Sequoia / macOS 26 Tahoe. The research machine itself reports `sw_vers` ProductVersion 27.2 (build 26B123), so the man-page text quoted below as "local man page" was read from that system on 2026-11-23; it is the newest launchd documentation available and is cited as `man:launchd.plist(5)` / `man:launchctl(1)`. Apple's online developer docs were read via their JSON endpoints (developer.apple.com/tutorials/data/...), which return the same text as the HTML pages linked.

**Overall recommendation (inference, details below):** For a plain CLI binary with no .app bundle, write a per-user LaunchAgent plist to `~/Library/LaunchAgents/<reverse-dns-label>.plist` and manage it with the modern `launchctl` verbs against `gui/$UID` (`enable` -> `bootstrap` / `kickstart -k` / `bootout`, `print` for status). This is exactly what Homebrew's `brew services`, yabai and skhd do today. SMAppService is Apple's preferred API but requires an app bundle; adopt it only if the tool later ships inside a signed .app. Sign the binary with a Developer ID so Login Items shows a developer name instead of the raw executable name. Use `ProcessType` = `Interactive` (or at minimum `Standard`/unset), never `Background`, for a low-latency audio helper; use `RunAtLoad` + `KeepAlive {SuccessfulExit=false}` so `stop` (clean exit) works and crashes respawn.

## 1. Per-user LaunchAgent in ~/Library/LaunchAgents + launchctl (modern vs legacy subcommands) — still supported/common?

### Takeaway
Yes. Plain plists in `~/Library/LaunchAgents` remain fully supported and are the mainstream mechanism for CLI tools (Homebrew, yabai, skhd all use them). Apple calls this the "earlier versions of macOS" / "legacy plist" route and points app developers to SMAppService, but launchd still loads these and they get a Login Items toggle. `load`/`unload` are documented as "legacy subcommands"; use `bootstrap`/`bootout`/`enable`/`disable`/`kickstart`/`print`.

### Cited Findings
- launchctl man page lists `load | unload` under "LEGACY SUBCOMMANDS", which "select the target domain based on whether they are executed as root or not", with "Recommended alternative subcommands: bootstrap | bootout | enable | disable" — [man:launchctl(1), local macOS 27.2](man:launchctl)
- `enable | disable service-target`: "Once a service is disabled, it cannot be loaded in the specified domain until it is once again enabled. This state persists across boots of the device." — [man:launchctl(1)](man:launchctl)
- `kickstart [-kp] service-target`: "Instructs launchd to run the specified service immediately, regardless of its configured launch conditions"; `-k` kills a running instance before restarting — [man:launchctl(1)](man:launchctl)
- Apple's SMAppService docs frame SMAppService agent `register()`/`unregister()` as "a replacement for installing property lists in `~/Library/LaunchAgents` or `/Library/LaunchAgents`" (i.e., the old path is the thing being replaced, not removed) — [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- Apple: "Prior to macOS 13, part of the application-design process of helper executables included scripts that installed one or more property lists into ... `$HOME/Library/LaunchAgents`"; "In apps that target macOS 13 and later, your app needs to only use the property list locations outlined above [inside the bundle]." Apple still documents `statusForLegacyPlist(at:)` for apps that "don't use the new bundle structure" — [Apple: Updating helper executables from earlier versions of macOS](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- Homebrew `brew services` (current `Homebrew/brew` main) installs user services into `#{Dir.home}/Library/LaunchAgents` (root: `/Library/LaunchDaemons`), uses domain target `gui/#{Process.uid}` (falls back to `user/#{uid}` with a warning when run over SSH without console ownership or via sudo; `system` when root), starts with `launchctl enable <domain>/<label>` then `launchctl bootstrap <domain> <plist>`, stops with `launchctl bootout <domain>/<label>`, and checks status with `launchctl print <domain>/<label>` falling back to `launchctl list <label>` — [Homebrew services/system.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/services/system.rb); [Homebrew services/cli.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/services/cli.rb)
- Forum/third-party reports: on macOS 13+ legacy verbs intermittently fail with "Input/output error"; `bootstrap` error 5 commonly means the job is already loaded (bootout first) or has a persisted disabled override (`launchctl print-disabled gui/$UID`, fix with `launchctl enable`) — [Apple Dev Forums 774570](https://developer.apple.com/forums/thread/774570); [MacRumors: launchctl legacy subcommands deprecated](https://forums.macrumors.com/threads/launchctl-legacy-subcommands-deprecated.2431281); [StepSecurity launchd troubleshooting](https://docs.stepsecurity.io/developer-machines/installation/script/mdm-deployment/macos/launchd-troubleshooting) (secondary sources)
- Per-user LaunchAgent is not loaded and won't fire when no console user is logged in — [StepSecurity launchd troubleshooting](https://docs.stepsecurity.io/developer-machines/installation/script/mdm-deployment/macos/launchd-troubleshooting)

### Inferences
- Outdated advice to flag: tutorials using `launchctl load -w ~/Library/LaunchAgents/x.plist` / `unload -w` still mostly work but are "legacy"; `-w` was the old way to flip the disabled override, now `launchctl enable/disable gui/$UID/<label>`.
- Canonical CLI sequence (derived from brew/yabai): install = write plist, `launchctl enable gui/$UID/<label>`, `launchctl bootstrap gui/$UID <plist>`; restart = `launchctl kickstart -k gui/$UID/<label>`; stop/uninstall = `launchctl bootout gui/$UID/<label>` (and delete plist for uninstall); status = `launchctl print gui/$UID/<label>` (exit code non-zero if not bootstrapped; output contains `state = running` and `pid = N`).
- Do not run these under `sudo` or over SSH without a GUI login, or you target the wrong domain (brew explicitly warns about this).

### Gaps
- No Apple statement found announcing removal of `load`/`unload`; they're "legacy", not removed, as of the local man page.
- The man page says enable/disable "may only target services within the system domain or user and user-login domains", yet brew/yabai successfully use `gui/$UID/<label>`; I found no doc reconciling this (empirically it works per those projects).

## 2. SMAppService (.agent / .loginItem / .mainApp / .daemon): app bundle requirement; can a bare CLI use it? Deprecated APIs

### Takeaway
SMAppService is bundle-centric: `.agent(plistName:)` requires the plist in the *calling app's* `Contents/Library/LaunchAgents`, and `BundleProgram` (bundle-relative path) works only for SMAppService-installed plists. A bare CLI binary without a bundle cannot meaningfully use it. `SMLoginItemSetEnabled` is superseded by `SMAppService.loginItem` register/unregister; legacy plists remain the non-bundle path.

### Cited Findings
- "In macOS 13 and later, use `SMAppService` to register and control `LoginItems`, `LaunchAgents`, and `LaunchDaemons` as helper executables for your app"; "An object the framework uses to control helper executables that live inside an app's main bundle." For LoginItems, register/unregister "provide a replacement for `SMLoginItemSetEnabled(_:_:)`" — [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- `agent(plistName:)`: "The property list name must correspond to a property list in the calling app's `Contents/Library/LaunchAgents` directory." — [Apple: agent(plistName:)](https://developer.apple.com/documentation/servicemanagement/smappservice/agent(plistname:))
- Migration steps: put helper in bundle (e.g. `Contents/Resources`), agent plists in `Contents/Library/LaunchAgents`, "replace the `Program` key with the `BundleProgram` key and make the path relative to the bundle" — [Apple: Updating helper executables](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- `BundleProgram`: "an app-bundle relative path to the executable for the job. This key is only supported for plists that are installed using SMAppService." — [man:launchd.plist(5), local macOS 27.2](man:launchd.plist)
- Quinn (DTS) on forums: the plist name passed to `agent(plistName:)` must include `.plist`; registering an agent via SMAppService from a command-line context needs a logged-in user context (workaround `launchctl asuser`); an accepted enterprise pattern is running the *app's own main binary* as a CLI with an "install" argument so it makes the SMAppService calls — [Apple Dev Forums 771162](https://www.developer.apple.com/forums/thread/771162); [Apple Dev Forums 745720](https://developer.apple.com/forums/thread/745720); [Apple Dev Forums 766351](https://developer.apple.com/forums/thread/766351) (as summarized by search results; not all threads fully read)
- launchd starts jobs on demand; an SMAppService-registered agent with no demand (no RunAtLoad/KeepAlive/MachServices) never starts by itself; use `launchctl start <label>` to test — [Quinn, Apple Dev Forums 737190](https://developer.apple.com/forums/thread/737190)
- Status APIs: `statusForLegacyPlist(at:)` — "Check the authorization status of an earlier OS version login item" given the plist URL; `openSystemSettingsLoginItems()` to send the user to approve — [Apple: statusForLegacyPlist(at:)](https://developer.apple.com/documentation/servicemanagement/smappservice/statusforlegacyplist(at:)); [Apple: Updating helper executables](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)

### Inferences
- A pure CLI could still *call* the ServiceManagement framework for read-only `SMAppService.statusForLegacyPlist(at:)` to detect whether the user disabled its legacy agent in Login Items (this API takes a plist URL, not a bundle). Not verified that it works from an unbundled, ad-hoc-signed CLI — treat as "try it".
- If the tool ever ships as a .app (e.g., a menu-bar companion), the path is `SMAppService.agent(plistName:)` with `BundleProgram` pointing at the CLI inside the bundle; `.mainApp`/`.loginItem` launch app bundles, not bare executables, so they don't fit a headless CLI.
- `LSSharedFileList` login items and `SMLoginItemSetEnabled`/`SMJobBless` are the outdated approaches; don't use them on 15/26.

### Gaps
- Could not render Apple's per-symbol deprecation annotations for `SMLoginItemSetEnabled`/`SMJobBless`/`LSSharedFileList` (the docs JSON extract didn't include them); Apple's text says "replacement" but I didn't capture the formal "Deprecated macOS 13" label directly.

## 3. Background Items notifications, Login Items & Extensions toggles, attribution, unsigned binaries, user disabling and detection

### Takeaway
Since macOS 13, Background Task Management (BTM) tracks every LaunchAgent/LaunchDaemon, shows a "Background Items Added" notification and a per-item switch in System Settings > General > Login Items & Extensions (section "Allow in the Background" / "App Background Activity"). Attribution: SMAppService items -> their app; legacy plists -> app named in `AssociatedBundleIdentifiers` (only if Team IDs match), else the signing certificate's organization name, else (unsigned, unattributed) the executable name from `Program`/`ProgramArguments`. Users can switch items off; a disabled item is not launched. Detection options: `launchctl print gui/$UID/<label>` / `print-disabled`, `SMAppService.statusForLegacyPlist(at:)`, or parsing `sfltool dumpbtm`.

### Cited Findings
- "Every app that supports a `LoginItem`, `LaunchAgent`, or `LaunchDaemon` has a corresponding switch in the Login Items panel in System Settings." — [Apple: Updating helper executables](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- Attribution rules (verbatim-level): legacy agents "can adopt the new `AssociatedBundleIdentifiers` key"; "The Team Identifier of the `Program` or `ProgramArguments` executable in the legacy property list must match that of the app bundle"; Launch Services must know the app (register via `LSRegisterURL` if needed); "If a legacy `LaunchAgent` or `LaunchDaemon` doesn't have the `AssociatedBundleIdentifiers` key ... System Settings displays the organization name in the app's signing certificate"; "If the system can't attribute a `LaunchAgent` or `LaunchDaemon` to an app and the executable isn't signed, System Settings displays the executable name from the `Program` or `ProgramArguments` key" — [Apple: Updating helper executables](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos)
- `AssociatedBundleIdentifiers <string or array>`: "indicates which bundles are associated with this job in the System Settings Login Items UI. If an app installs a legacy plist the plist should include this key with a value of the app's bundle identifier." — [man:launchd.plist(5)](man:launchd.plist)
- Attribution is buggy in practice: developers report items still showing the developer name despite `AssociatedBundleIdentifiers`; Quinn's partial workaround was registering the parent app with Launch Services before copying the plist, which "helps in some situations" but still failed in some cases; advice is to file bugs — [Apple Dev Forums 718720](https://developer.apple.com/forums/thread/718720)
- Settings location in current macOS: General > Login Items & Extensions; login items under "Open at Login", background helpers under "App Background Activity"; you can only turn items on/off; "Some disabled items are automatically re-enabled"; dump Developer Name comes from the code-signing certificate; entries may show "Unknown Developer" — [Eclectic Light, Manage login and background items (2025-12-03)](https://eclecticlight.co/2025/12/03/manage-login-and-background-items/)
- `sfltool dumpbtm` prints status of login/background items; `sfltool resetbtm` resets (restart afterward); Console filter subsystem `backgroundtaskmanagement`; dump "Disposition" field e.g. `[disabled, allowed, visible, not notified]` — [Apple Platform Deployment: Manage login items and background tasks](https://support.apple.com/guide/deployment/manage-login-items-and-background-tasks-on-mac-depdca572563/web); [Eclectic Light, How to diagnose and control login and background items (2023-07-04)](https://eclecticlight.co/2023/07/04/how-to-diagnose-and-control-login-and-background-items)
- Notification behavior (managed context): end users get one notification ("managed items are being installed..."); MDM `com.apple.servicemanagement` rules (BundleIdentifier, BundleIdentifierPrefix, TeamIdentifier, Label, LabelPrefix) auto-approve and suppress; Apple's `attributions.plist` in `BackgroundTaskManagement.framework` maps common helpers to apps — [Apple Platform Deployment](https://support.apple.com/guide/deployment/manage-login-items-and-background-tasks-on-mac-depdca572563/web)
- NEW in macOS 26: "if background tasks stay active after a user quits the app, the user is prompted to allow or deny them" (suppressible via Service Management MDM rules) — [Apple Platform Deployment](https://support.apple.com/guide/deployment/manage-login-items-and-background-tasks-on-mac-depdca572563/web)
- System log entries like "untrusted service was denied launch by BTM" have been reported — [search summary of Apple Dev Forums threads; not verified first-hand](https://developer.apple.com/forums/thread/774570)
- Detection approach used by an open-source BTM manager: parse `sfltool dumpbtm` (needs sudo for full output) and cross-check `launchctl print-disabled gui/<uid>` — [btmgr (GitHub)](https://github.com/rapatao/btmgr)
- Reported: "Background Items Added" banners sometimes appear when the app launches rather than when the plist is loaded (non-staff report) — [Apple Dev Forums 718720](https://developer.apple.com/forums/thread/718720)

### Inferences
- For a CLI dropping `~/Library/LaunchAgents/com.example.tool.plist`: the user sees a "Background Items Added" notification at first load; under Login Items it is listed by the Developer ID organization name if the binary is signed, or by the bare executable name (e.g. "whirr") if unsigned/ad-hoc. Signing with a Developer ID + notarization (and `AssociatedBundleIdentifiers` only if there's a companion app with matching Team ID) gives the best presentation.
- If the user toggles it off, expect `launchctl bootstrap` to fail (often error 5 / "Input/output error") and the job not to run. A robust `tool status` should: (1) check `launchctl print gui/$UID/<label>` exit code and pid; (2) if not running and plist exists, check `launchctl print-disabled gui/$UID` for the label; (3) optionally call `SMAppService.statusForLegacyPlist(at:)` (via a tiny Swift shim) to get `.requiresApproval`/`.notRegistered`; (4) tell the user to re-enable in System Settings > General > Login Items & Extensions (deep link via `SMAppService.openSystemSettingsLoginItems()` or `open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"` — the URL scheme is unverified).
- Homebrew-installed binaries live under `/opt/homebrew/...`; their plists commonly appear in Login Items under whatever signed the binary (often unsigned -> executable name). This matches user reports of cryptic entries like "sh" or "bash" when plists invoke shell scripts — so invoke the real binary directly in `ProgramArguments`, not via `/bin/sh -c`.

### Gaps
- No Apple primary source found that states precisely how a BTM "off" toggle is enforced for legacy agents (launchd disabled override vs BTM deny at spawn) or whether it shows up in `launchctl print-disabled`. Evidence is indirect (forum reports, third-party tools). Needs empirical test on 15/26.
- Not verified whether `statusForLegacyPlist(at:)` works from an unbundled CLI process.
- Exact UI section label differs across versions ("Allow in the Background" in 13–15 vs "App Background Activity" per Eclectic Light 2025); not verified on 26 directly.

## 4. Recommended plist keys for an always-on, low-latency audio helper (ProcessType, KeepAlive, etc.)

### Takeaway
Use `RunAtLoad=true`, `KeepAlive={SuccessfulExit=false}` (restart on crash/non-zero exit, allow clean stop), `ProcessType=Interactive` (what yabai/skhd/sketchybar use for latency-sensitive helpers) or at least leave it unset/`Standard`. Avoid `ProcessType=Background`, `LowPriorityIO`, and positive `Nice` for audio — `Background` is designed to throttle CPU/I/O, and unset/Standard already gets "light" throttling. `LegacyTimers=true` disables timer coalescing but "may have no effect" unless `Interactive`.

### Cited Findings
- `ProcessType`: "The system will apply resource limits based on what kind of job it is. If left unspecified, the system will apply light resource limits to the job, throttling its CPU usage and I/O bandwidth. This classification is preferable to using the HardResourceLimits, SoftResourceLimits and Nice keys." Background: limits "intended to prevent them from disrupting the user experience"; Standard = unset; Adaptive "move between the Background and Interactive classifications based on activity over XPC connections"; Interactive "run with the same resource limitations as apps, that is to say, none ... should only be used if an app's ability to be responsive depends on it, and cannot be made Adaptive." — [man:launchd.plist(5), local macOS 27.2](man:launchd.plist); online mirror [leancrew launchd.plist(5)](https://leancrew.com/all-this/man/man5/launchd.plist.html)
- `LegacyTimers`: launchd job timers are coalesced by default since 10.9; `true` opts into "less efficient but more precise behavior"; "This key may have no effect if the job's ProcessType is not set to Interactive." — [man:launchd.plist(5)](man:launchd.plist)
- `LowPriorityIO`: kernel treats the job as low priority for filesystem I/O; `LowPriorityBackgroundIO` applies when throttled as Darwin-background — [man:launchd.plist(5)](man:launchd.plist)
- `ThrottleInterval`: default, jobs "will not be spawned more than once every 10 seconds" — [man:launchd.plist(5)](man:launchd.plist)
- `LimitLoadToSessionType`: "only applies to jobs which are agents"; values per TN2083: `Aqua` (GUI agent, "Has access to all GUI services; much like a login item", the default), `StandardIO` (SSH sessions), `Background` (per-user context), `LoginWindow` — [man:launchd.plist(5)](man:launchd.plist); [Apple TN2083 Daemons and Agents (archived, 10.5-era)](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
- Privacy caveat: launchd jobs are "subject to macOS user privacy protections. Specifying privacy sensitive files and folders in a launchd plist may not have the desired effect, and may prevent the job from running." — [man:launchd.plist(5)](man:launchd.plist)
- yabai's self-installed plist: `RunAtLoad true`, `KeepAlive {SuccessfulExit false, Crashed true}`, `ProcessType Interactive`, `Nice -20`, `EnvironmentVariables PATH`, logs to `/tmp/yabai_$USER.{out,err}.log`; skhd uses the same template — [yabai src/misc/service.h](https://github.com/koekeishiya/yabai/blob/master/src/misc/service.h); [skhd src/service.h](https://github.com/koekeishiya/skhd/blob/master/src/service.h)
- sketchybar's Homebrew service: `keep_alive true`, `process_type :interactive`, logs under `var/log/sketchybar` — [FelixKratz/homebrew-formulae sketchybar.rb](https://github.com/FelixKratz/homebrew-formulae/blob/master/sketchybar.rb)
- Third-party docs: launchd silently ignores an unrecognized ProcessType value (runs in default band) — [jsr @nullstyle/launch-agents ProcessType](https://jsr.io/@nullstyle/launch-agents/doc/~/ProcessType) (secondary)

### Inferences
- `ProcessType=Background` would likely hurt an audio/polling helper: CPU throttling and timer coalescing add latency/jitter to polling loops and buffer refills. Core Audio's own IOProc thread is a time-constraint (real-time) thread created by the HAL, which may be less affected, but any app-side producer thread feeding it would be throttled. Not verified by an Apple source — flag as inference; test with `taskpolicy`/`ps -o pri` and glitch counting.
- `Nice -20` in a *user* agent: negative nice normally requires root; launchd may apply it since launchd itself is privileged, but I found no doc confirming. `ProcessType=Interactive` is Apple's preferred knob over `Nice` per the man page.
- Prefer `KeepAlive {SuccessfulExit=false}` over `KeepAlive=true`: with `true`, a user's `tool stop` that exits 0 would be immediately respawned (after ThrottleInterval); with SuccessfulExit=false, clean exits stay stopped while crashes/non-zero exits respawn. (Colima's formula uses `keep_alive successful_exit: true` — the opposite semantic, respawn on clean exit — because `colima start -f` foreground; ollama/syncthing use `keep_alive true`.) — [homebrew-core colima.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/c/colima.rb); [ollama.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/o/ollama.rb); [syncthing.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/s/syncthing.rb)
- Put logs in `~/Library/Logs/<tool>/` rather than `/tmp` (yabai's `/tmp` choice is world-readable and cleared on reboot). `StandardOutPath`/`StandardErrorPath` files are created by launchd; rotate or cap them yourself.
- Always set `EnvironmentVariables PATH` if the helper shells out (launchd's default PATH is minimal: yabai/skhd/brew all inject PATH).
- `LimitLoadToSessionType=Aqua` is the default for `~/Library/LaunchAgents` at GUI login; setting it explicitly prevents duplicate instances in SSH (`StandardIO`) sessions.

### Gaps
- No Apple documentation found quantifying what "light" vs "Background" resource limits are (CPU %, timer slack values) or how they interact with Core Audio real-time threads.
- `Adaptive` requires XPC transactions (`xpc_transaction_begin`) — not useful for a CLI that doesn't vend XPC services; no source on using it with plain sockets.

## 5. Does a launchd-spawned agent get proper access to the user's audio session? LaunchAgent vs LaunchDaemon

### Takeaway
Yes for a LaunchAgent in the user's GUI (Aqua) session: it runs in the per-session bootstrap namespace like a login item, so Core Audio output to the user's devices works (this is how countless menu-bar/audio helpers run). LaunchDaemons (root, global context) are the problematic case: historical reports show output tied to the active console user and failing/stopping on fast user switching, plus TCC/session-scoped services are unavailable.

### Cited Findings
- Agents "can do things that daemons can't, like reliably access the user's home directory or connect to the window server"; Aqua agents have "access to all GUI services; much like a login item"; CoreAudio, AudioToolbox, AudioUnit are listed as daemon-safe frameworks (loadable in any context) — [Apple TN2083 (archived; 10.5-era)](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
- Core Audio mailing-list report (2015): a daemon playing audio lost output when switching users; "Prior to OS 10.8" playback continued regardless — [coreaudio-api list, Jun 2015](https://lists.apple.com/archives/coreaudio-api/2015/Jun/msg00025.html) (via search summary; page returned 502 on direct fetch)
- Reports of root LaunchDaemons failing at session-scoped tasks (e.g., screen recording on Sequoia) where a LaunchAgent works — [Apple Dev Forums 759833](https://developer.apple.com/forums/thread/759833) (via search summary)
- Per-user LaunchAgent is not loaded when no console user is present — [StepSecurity launchd troubleshooting](https://docs.stepsecurity.io/developer-machines/installation/script/mdm-deployment/macos/launchd-troubleshooting)

### Inferences
- Use a LaunchAgent in `gui/$UID`, not a daemon. Bootstrapping into `user/$UID` (what brew falls back to over SSH/sudo) puts the job outside the Aqua session; audio and GUI-adjacent services may misbehave — another reason to refuse install from SSH or warn as brew does.
- With fast user switching, a per-user agent keeps running in the background user's session; expect Core Audio to route/stop per the active console user. Handle device-change/interruption notifications.
- If the helper ever needs microphone input, TCC attribution for an unbundled CLI launched by launchd is awkward (no Info.plist usage string, responsible-process attribution); output-only playback needs no TCC permission. (Inference; not researched in depth.)

### Gaps
- No current (macOS 15/26) Apple source explicitly documenting audio output behavior from LaunchAgents vs LaunchDaemons; evidence is archival (TN2083) and anecdotal.

## 6. How popular background CLI tools do it; what `brew services` does under the hood

### Takeaway
They all use legacy per-user LaunchAgent plists in `~/Library/LaunchAgents` with modern launchctl verbs; none uses SMAppService. Homebrew generates plists named `homebrew.mxcl.<formula>.plist` from a `service do` DSL; yabai/skhd embed a plist template in the binary and expose `--install-service/--start-service/--stop-service/--restart-service/--uninstall-service`.

### Cited Findings
- brew services: user plists in `~/Library/LaunchAgents`, root in `/Library/LaunchDaemons`; labels/files matching `{homebrew.*,sh.brew.*}.plist`; start: `launchctl enable gui/$UID/<label>` (only when enabling for login) + `launchctl bootstrap gui/$UID <plist>`; `brew services run` bootstraps without enabling/installing to LaunchAgents (temp file or source plist); stop: `launchctl bootout <domain>/<label>` across candidate domains, falling back to `launchctl stop`; `brew services kill` uses `launchctl stop`; status via `launchctl print` then `launchctl list` — [Homebrew services/cli.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/services/cli.rb); [services/system.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/services/system.rb)
- brew's domain logic: root -> `system`; SSH without `/dev/console` ownership or sudo -> `user/$UID` with warning "running over SSH without /dev/console ownership, using user/* instead of gui/* domain!"; otherwise `gui/$UID` — [services/system.rb](https://github.com/Homebrew/brew/blob/main/Library/Homebrew/services/system.rb)
- yabai `--start-service`: checks `launchctl print gui/$UID/<label>`; if not bootstrapped, runs `launchctl enable gui/$UID/<label>` (comment: it's not possible to bootstrap a disabled service) then `launchctl bootstrap gui/$UID <plist>` ("will also start the program iff RunAtLoad is set"); if already bootstrapped, `launchctl kickstart gui/$UID/<label>` ("it is an error to bootstrap a service that has already been bootstrapped"); restart = `kickstart -k`; stop = `bootout gui/$UID <plist>` — [yabai src/misc/service.h](https://github.com/koekeishiya/yabai/blob/master/src/misc/service.h); skhd identical pattern — [skhd src/service.h](https://github.com/koekeishiya/skhd/blob/master/src/service.h)
- Homebrew formula service blocks: ollama `run [opt_bin/"ollama", "serve"]`, `keep_alive true`, `working_dir var`, single log `var/log/ollama.log`; syncthing `run [... "--no-browser", "--no-restart"]`, `keep_alive true`; colima `run [... "start", "-f"]`, `keep_alive successful_exit: true`, `working_dir Dir.home`, `PATH: std_service_path_env`; sketchybar `process_type :interactive`, `keep_alive true` — [ollama.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/o/ollama.rb); [syncthing.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/s/syncthing.rb); [colima.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/c/colima.rb); [sketchybar.rb](https://github.com/FelixKratz/homebrew-formulae/blob/master/sketchybar.rb)
- Syncthing passes `--no-restart` because launchd handles restarts (avoid two supervisors) — [syncthing.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/s/syncthing.rb) (flag visible in formula; rationale is inference)

### Inferences
- The Ollama desktop distribution is a .app and uses an app login item; the CLI-only path is via `brew services` (not researched further).
- yabai/skhd's state machine (Installed / Enabled / Bootstrapped) is the best reference implementation for a self-managing CLI.

### Gaps
- Did not inspect Homebrew's plist generator (`Library/Homebrew/service.rb`) for exact default keys (e.g., whether it sets `ProcessType` by default) — check if needed.

## 7. Self-install pattern (`tool start/stop/install-agent`): examples and pitfalls

### Takeaway
Pattern: binary writes its own plist (absolute path to itself), then `enable` + `bootstrap gui/$UID`; `stop` = `bootout`; `restart` = `kickstart -k`; `status` = `print`. Key pitfalls: stale absolute paths after upgrades/moves, bootstrapping an already-bootstrapped or disabled job (error 5), wrong domain under sudo/SSH, KeepAlive fighting `stop`, minimal PATH, BTM disable toggle, and unsigned binaries showing as bare names.

### Cited Findings
- yabai/skhd implement `--install-service`, `--uninstall-service`, `--start-service`, `--restart-service`, `--stop-service` using exactly enable/bootstrap/kickstart/bootout against `gui/$UID`, and embed the executable's resolved path and current PATH into the plist at install time — [yabai service.h](https://github.com/koekeishiya/yabai/blob/master/src/misc/service.h); [skhd service.h](https://github.com/koekeishiya/skhd/blob/master/src/service.h)
- Bootstrap error 5 causes: already loaded (bootout first) or disabled override (enable first) — [Apple Dev Forums 774570](https://developer.apple.com/forums/thread/774570); [StepSecurity launchd troubleshooting](https://docs.stepsecurity.io/developer-machines/installation/script/mdm-deployment/macos/launchd-troubleshooting)
- Reported Apple-forum issue: `launchctl bootout` for one's own LaunchAgent failing with "caller is not allowed to signal target process" (newer macOS) — [Apple Dev Forums 856201](https://developer.apple.com/forums/thread/856201) (title only; not read)
- Program path must be absolute ("The Program key must be an absolute path") — [man:launchd.plist(5)](man:launchd.plist)
- launchd throttles respawns to once per 10 s by default (`ThrottleInterval`) — [man:launchd.plist(5)](man:launchd.plist)
- Homebrew uses `opt_bin` (stable symlink `/opt/homebrew/opt/<f>/bin`) in plists so upgrades don't break the path — [ollama.rb](https://github.com/Homebrew/homebrew-core/blob/master/Formula/o/ollama.rb)

### Inferences
- Pitfall checklist for Whirr's CLI:
  1. Write the plist atomically with mode 0644, owned by the user; launchd rejects group/world-writable plists (well-known behavior; not re-verified here).
  2. Point `ProgramArguments[0]` at a stable path (Homebrew `opt` symlink, or resolve `realpath` at install time and re-run install on upgrade); the plist embeds an absolute path.
  3. Idempotent start: `print` -> if absent `enable` + `bootstrap`, else `kickstart` (yabai logic). Uninstall: `bootout` then delete file; tolerate "No such process"/error 3/113.
  4. Refuse or warn when `SUDO_USER` is set or no GUI session (`stat -f %u /dev/console` != uid), like brew.
  5. Single-instance guard inside the binary (lock file / socket) so a manual `tool run` doesn't collide with the agent.
  6. `KeepAlive {SuccessfulExit=false}` so `tool stop` -> clean exit isn't respawned; still prefer `bootout` for stop since it unloads the job.
  7. Detect BTM disable: if bootstrap fails / job not running, guide the user to Login Items & Extensions.
  8. Sign (Developer ID) + notarize the binary so Login Items shows the organization name; invoke the binary directly (not via `sh -c`) so attribution is to the signed executable.
  9. Don't also use `brew services` and self-install with different labels — two agents. If distributing via Homebrew, either define a `service do` block (label `homebrew.mxcl.<name>`) or ship self-install, and detect the other.

### Gaps
- No single authoritative "best practices for self-installing LaunchAgents" document from Apple exists; Apple's guidance is "use SMAppService from an app bundle". The checklist above is synthesized from open-source implementations and forum reports.
