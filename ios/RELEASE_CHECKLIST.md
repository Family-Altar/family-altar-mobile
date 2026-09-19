# iOS Release Checklist

## Pre-flight

- [ ] Bump version in `pubspec.yaml` (`version: X.Y.Z+build`)
- [ ] `fvm flutter build ios --release --no-codesign --flavor production` — **required**. Rewrites `ios/Flutter/Generated.xcconfig` with the new `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` (which `Info.plist` references) and catches native/plugin build issues before Xcode. `flutter pub get` alone does **not** reliably refresh the xcconfig.
- [ ] Commit and tag the release (`git tag vX.Y.Z && git push --tags`)

## Archive in Xcode

- [ ] Open **`ios/Runner.xcworkspace`** — never open `Runner.xcodeproj` directly (it skips CocoaPods)
- [ ] Scheme: **`production`**
- [ ] Destination: **Any iOS Device (arm64)**
- [ ] Product → Archive
- [ ] Wait for Organizer to open

## Distribute

- [ ] Organizer → select the archive → **Distribute App**
- [ ] **App Store Connect** → **Upload**
- [ ] Upload symbols: **YES** (dSYMs needed for crash symbolication)
- [ ] Wait for "Upload Successful"

## App Store Connect

- [ ] Wait for processing (~10–30 min); build appears under TestFlight/Builds
- [ ] Attach build to a new version (or TestFlight group)
- [ ] Fill release notes
- [ ] Submit for review

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Unable to resolve module dependency: 'Flutter'` / `'Flutter/Flutter.h' file not found` on a plugin target | Flutter SPM got re-enabled. Run `fvm flutter config --no-enable-swift-package-manager`, `fvm flutter clean`, `fvm flutter pub get`, then `cd ios && pod install`. |
| `Unable to read contents of XCFileList` / `Pods-Runner-*.xcfilelist` missing | `Pods/` was deleted. Run `cd ios && pod install`. |
| Archive shows the previous version number | `Generated.xcconfig` is stale. Run `fvm flutter build ios --release --no-codesign --flavor production` (not just `pub get`) to force-regenerate it, then re-archive. |
| `MinimumOSVersion too low` from App Store Connect | Deployment target dropped below 15.0. Check `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj/project.pbxproj`. |
| Xcode won't stop showing stale SPM package errors | File → Packages → Reset Package Caches, then re-open the workspace. |

## Never

- **Never** re-enable Flutter SPM support (`fvm flutter config --enable-swift-package-manager`). This project is pure CocoaPods on iOS. Mixed mode breaks the archive because Xcode compiles SPM plugin targets before the Flutter "Run Script" build phase can stage the Flutter framework.
- **Never** open `Runner.xcodeproj` directly — always the `.xcworkspace`.
- **Never** downgrade `IPHONEOS_DEPLOYMENT_TARGET` below **15.0** (Spring 2027 App Store Connect requirement).
