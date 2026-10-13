# StandBy Studio

Clock and info widgets for iPhone **StandBy** mode (charging, sideways, at rest).
Built for iPhone and the new iPhone Duo. The app UI uses system containers so it resizes on both displays.

## What's inside

| Pack | Price | Clocks | Widgets |
|------|-------|--------|---------|
| Free | free | Flip, Minimal, Analog, Bold | Calendar, Battery |
| Retro | $1.99 | Neon, LCD, Terminal, Synthwave | |
| Space | $1.99 | Galaxy, Aurora, Nebula, Orbit | Moon Phase |
| Pro | $2.99 | Word Clock, Binary, Studio | Countdown, Quote (tap to shuffle), Photo Clock |
| All Access | $4.99 | everything | everything |

Every user can pick an accent color, font and 12/24-hour time. Locked styles still show in the widget picker, blurred, and tapping them opens the store.

## Project layout

```
project.yml              XcodeGen spec (app + widget extension)
StandByStudio.storekit   Local StoreKit products for testing purchases
App/                     The iOS app (gallery, StandBy preview, customize, store)
Widgets/                 WidgetKit extension (7 widgets)
Shared/                  Code used by both: styles, faces, settings, purchases
```

## Build

1. On a Mac with Xcode 16 or newer: `brew install xcodegen` then run `xcodegen` in this folder.
2. Open `StandByStudio.xcodeproj`, set your Team for both targets.
3. Both targets use the App Group `group.com.ariberko.standbystudio`. Register it in your Apple Developer account (or change it in `project.yml` and `Shared/AppGroup.swift`).
4. Run the `StandByStudio` scheme. Purchases use `StandByStudio.storekit`, so no real money is charged.

## Before the App Store

- Create the 4 non-consumable products in App Store Connect with the same IDs as `Shared/Pack.swift`.
- Add an app icon (1024x1024) to `App/Assets.xcassets/AppIcon.appiconset`.
