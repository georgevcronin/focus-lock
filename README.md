# Focus Lock

Shields chosen apps/sites except inside per-weekday allowed windows. Native SwiftUI + Screen Time APIs.

## Before it will run on a phone
1. Apple Developer → request the **Family Controls (Distribution)** entitlement for both bundle IDs
   (`com.georgevcronin.focuslock`, `com.georgevcronin.focuslock.monitor`). Dev builds work without approval; TestFlight/App Store do not.
2. Create App Group `group.com.georgevcronin.focuslock` and add it to both App IDs.
3. Generate the Xcode project: `xcodegen` (on the Mac / Codemagic runner). Set your team for signing.
4. Real device only — Screen Time APIs don't work in the Simulator.

## Notes
- Locked by default: no windows = always locked.
- Not tamper-proof: you can turn off Screen Time access in Settings or edit the windows in-app.
