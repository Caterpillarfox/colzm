# BadQueryDemo

A minimal iOS demo app that writes a dummy file (`data.txt` = `"some data here"`)
to its **own** sandboxed container and reads it back.

> **Phase 1 only.** This does *not* use the [`bad_query`](https://github.com/forcequitOS/bad_query)
> sandbox escape. Writing to the app's own `Documents/` directory is ordinary
> `FileManager` work — it exists so the build → sign → sideload → run pipeline
> can be verified end to end before adding anything more interesting.

---

## What it does

- Shows the bundle identifier, iOS version, and the app's own `Documents/` path.
- **Write data.txt** — writes `Documents/data.txt` with the contents `some data here`.
- **Read data.txt** — reads the file back and displays its contents + byte count.
- On-screen scrolling log with a timestamp for every step.

Source layout:

```
BadQueryDemo/
├── BadQueryDemo.xcodeproj/                # Xcode project
├── BadQueryDemo/
│   ├── BadQueryDemoApp.swift              # @main SwiftUI app
│   ├── ContentView.swift                  # UI + log + demo state
│   ├── ContainerStore.swift               # FileManager wrapper (own container)
│   ├── Info.plist
│   └── BadQueryDemo.entitlements          # Phase 2 placeholder (see below)
├── export-options.plist                   # signed-export config (unused in Phase 1)
└── README.md
```

- **Bundle identifier:** `com.example.demo_data`
- **Deployment target:** iOS 17.0
- **Signing:** unsigned in CI; you sign at sideload time.

---

## Build it in the cloud (no Mac required)

A GitHub Actions workflow builds the app on a free macOS runner:

- Workflow: [`.github/workflows/badquerydemo.yml`](../.github/workflows/badquerydemo.yml)
- It is **path-filtered** to `BadQueryDemo/**`, so pushing other apps does not
  trigger it.
- It produces two artifacts: an unsigned `BadQueryDemo.ipa` and the raw `.app`.

Run it via **Actions → BadQueryDemo → Run workflow**, or just push a change under
`BadQueryDemo/`.

## Sideload it (no Mac required)

1. Download the `BadQueryDemo-unsigned-ipa` artifact.
2. Install [SideStore](https://sidestore.io) (or AltStore) on your iPhone.
   - SideStore generates a pairing file from Windows/Linux/macOS and uses your
     Apple ID to sign — no Mac needed.
3. Import the `.ipa`, let SideStore re-sign it, and launch.

The app needs no special entitlements in Phase 1, so a free Apple ID works.

---

## Phase 2 (not implemented yet): the actual `bad_query` demo

Planned additions:

```
BadQueryDemo/BadQuery/bad_query.c      # C exploit core (dlopen ContainerManager SPI)
BadQueryDemo/BadQuery/bad_query.h
BadQueryDemo/BadQueryDemo-Bridging-Header.h
BadQueryDemo/BadQuery.swift            # Swift wrapper + lease lifecycle
```

An **"Escape + write"** button will lease a *foreign* / system container path via
the exploit and write `data.txt` there, proving access outside the sandbox.

Requirements for Phase 2:

- A **physical** device — the Simulator cannot run the exploit.
- iOS **26.0 – 26.6.1** or **27.0 ≤ beta 4**. Apple patched it in **27.0 beta 5**;
  on patched builds ContainerManager rejects the query.
- A signing identity that can hold the `com.apple.security.application-groups`
  entitlement. Wire in `BadQueryDemo.entitlements` (currently a documented
  placeholder, deliberately *not* referenced by the build settings) and register
  the App Group in your Apple Developer account.

---

## Credits

`bad_query` is the work of [forcequitOS](https://github.com/forcequitOS/bad_query).
This repository only wraps it in a demo; see the upstream project for the original
research and licensing terms.
