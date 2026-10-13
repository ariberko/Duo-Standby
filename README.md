# StandBy Studio

Clock and info widgets for iPhone **StandBy** mode (charging, sideways, at rest).
Built for iPhone and the new iPhone Duo. The app UI uses system containers so it resizes on both displays.

## What's inside

| Pack | Price | Clocks | Widgets |
|------|-------|--------|---------|
| Free | free | Flip, Minimal, Analog, Bold | Name Tag, Calendar, Battery |
| Retro | $1.99 | Neon, LCD, Terminal, Synthwave | |
| Space | $1.99 | Galaxy, Aurora, Nebula, Orbit | Moon Phase |
| Pro | $2.99 | Word Clock, Binary, Studio | Countdown, Quote (tap to shuffle), Photo Clock |
| Live | $2.99 | | DVD Bounce, Matrix Rain, Starfield, Mystify, Fireplace, Candle, Lava Lamp |
| All Access | $5.99 | everything | everything |

**Name Tag** (free): type a name and title, or pick one of 16 signs like Do Not Disturb, Busy or Lunch Break. Pick your own background, text and accent colors (or a quick theme). Save your own tags as presets. Show it full screen for tent mode (the screen stays awake, and Flip turns it upside down), or add it as a StandBy widget. 5 styles: Classic, Hello, Alert, Neon, Minimal.

**Live scenes** (Live tab): full screen animations made natively with SwiftUI `TimelineView` and `Canvas`. Free: LED Scroller, Talk Timer, Now Serving. Live Pack: DVD Bounce (with corner hits!), Matrix Rain, Starfield, Mystify, Fireplace, Candle, Lava Lamp. They run in the app, not as widgets, because widgets can't animate.

Every user can pick an accent color, font and 12/24-hour time. Locked styles still show in the widget picker, blurred, and tapping them opens the store.

## Project layout

```
project.yml              XcodeGen spec (app + widget extension)
StandByStudio.storekit   Local StoreKit products for testing purchases
App/                     The iOS app (gallery, StandBy preview, customize, store)
StandByStudio.swiftpm/   iPad Swift Playgrounds preview of all designs
Widgets/                 WidgetKit extension (7 widgets)
Shared/                  Code used by the app, widgets and preview: styles, faces, settings
SharedApp/               Code used by the app and preview only (Name Tag editor, Live scenes)
```

## Preview on iPad (Swift Playgrounds)

`StandByStudio.swiftpm` is a small preview app with every clock and widget design. It has no real widgets or purchases.

1. On the iPad open this repo on github.com in Safari. Tap **Code** then **Download ZIP**.
2. In the **Files** app tap the ZIP to unzip it.
3. Open the folder and tap **StandByStudio.swiftpm**. It opens in Swift Playgrounds.
4. Tap ▶︎ to run. Tap any design for a full screen StandBy look. Turn the iPad sideways.

The preview keeps its own copy of `Shared/` and `SharedApp/`. After changing them, run `./scripts/sync-playground.sh`.

## Automatic checks

Every push runs `.github/workflows/build.yml` on GitHub's Macs. It builds the app with its widgets, builds the iPad preview, and checks the preview copy is up to date.

## Build

1. On a Mac with Xcode 16 or newer: `brew install xcodegen` then run `xcodegen` in this folder.
2. Open `StandByStudio.xcodeproj`, set your Team for both targets.
3. Both targets use the App Group `group.com.ariberko.standbystudio`. Register it in your Apple Developer account (or change it in `project.yml` and `Shared/AppGroup.swift`).
4. Run the `StandByStudio` scheme. Purchases use `StandByStudio.storekit`, so no real money is charged.

## Before the App Store

- Create the 5 non-consumable products in App Store Connect with the same IDs as `Shared/Pack.swift`.
- Add an app icon (1024x1024) to `App/Assets.xcassets/AppIcon.appiconset`.
