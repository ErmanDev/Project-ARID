# A.R.I.D. mobile design

This design follows [Apple Design Skill](https://github.com/dickwu/apple-design-skill). To use it locally, download it into `.design-rules/`, which git ignores. The skill applies Apple's Human Interface Guidelines to this Flutter app as design principles. It is design guidance for development, not a runtime dependency.

**Product.** Community field reporters use A.R.I.D. to photograph possible mosquito breeding sites, check the on-device result and location, and save reports offline. The app syncs reports when a connection returns.

**Signature.** Each risk level has a shape as well as a color: a triangle for high risk, a diamond for moderate, and a circle for non-breeding. The same glyphs appear in badges, the Home risk summary, map pins and map filters, so the level stays readable without color vision.

## Redesign (2026-09-24, second pass)

The first pass fixed accessibility and navigation. This pass gives the app an iOS-style structure while keeping the teal identity. A review of the first-pass code found the following:

| Severity | Finding | Guideline | Change |
| --- | --- | --- | --- |
| High | A theme toggle sat in the toolbar of every tab, alongside the logo and a permanent "Online · ready to sync" banner | `branding.md › Best practices`: "Resist the temptation to display your logo throughout your app"; `dark-mode.md › Best practices`: "Avoid offering an app-specific appearance setting" | Removed the logo and toggle from the toolbars. Appearance is now one row in Profile, with *Match device* as the default. The connection banner appears only when offline. |
| High | Risk used color alone in dots and map pins. Moderate (`#C9A66B`) was 2.3:1 on white, below the 3:1 minimum for non-text | `color.md › Inclusive color`: "Avoid relying solely on color…" | Added the risk glyph shapes. New risk fills are ≥4.4:1 on the surface (see tokens below). |
| High | The map lost about 120 pt to a toolbar and a strip of eight chips | `layout.md › Visual hierarchy`: "Differentiate controls from content… extend it underneath… tab bars" | The map is full-bleed and extends under the tab bar. Floating glass controls hold the risk filter, a layers button, save-offline and my location. Layer toggles and dates moved to a sheet (progressive disclosure). |
| Medium | Card stacks had no list structure. Rows used no system anatomy, and values and actions were mixed | `lists-and-tables.md › Style`: "the grouped style uses headers, footers, and additional space" | Screens now use inset grouped lists (`GroupedSection`/`GroupedRow`) with icon tiles, trailing values, chevrons and explanatory footers. |
| Medium | Page titles were small toolbar text, and page headlines varied by screen | `typography.md › Conveying hierarchy` | Every tab has a large title that condenses into the toolbar on scroll (`LargeTitlePage`). |
| Medium | Copy exposed internals ("TFLite", "Chapter III" as a heading, raw exception text) | Skill Lens 5 (writing) | Errors say what happened and what to do, with no stack text. Actions keep one name through the flow: *Save report* → *Report saved*. |
| Medium | Report detail and ground-truth labeling were reachable only from a menu | `lists-and-tables.md › Best practices` (selection feedback) | Tapping a report row opens a detail sheet with a grabber, which includes *Actual result*. The menu keeps retry, move pin and delete. |

## Tokens

All colors live in `AridPalette` ([lib/ui/theme/app_colors.dart](lib/ui/theme/app_colors.dart)) as a `ThemeExtension`, with light, dark and increased-contrast variants. Contrast is calculated from the sRGB values and checked by tests.

| Role | Light | Dark | Contrast |
| --- | --- | --- | --- |
| Grouped background | `#F2F4F5` | `#0B1114` | — |
| Surface | `#FFFFFF` | `#162024` | — |
| Ink | `#1B2529` | `#EDF3F5` | 15.6 / 14.8 on surface |
| Secondary ink | `#586569` | `#A1AFB4` | 5.5 / 8.4 on grouped background |
| Accent (primary actions, selection) | `#2C6B80` | `#72B6CB` | Label on fill: 6.0 / 7.4 |
| Risk: high / moderate / non-breeding | `#B8434A` `#A26F12` `#3F8052` | `#F07C80` `#E6B558` `#7FC592` | Glyphs ≥4.4 / ≥6.2 on surface; badge text ≥6.1 / ≥9.2 on its tint |

- **Type.** Uses the platform font for body text and controls, with the iOS scale: body 17, subheadline 15, footnote 13, caption 12. Montserrat is used only for large titles (34 bold). Large titles scale to 150%, tab labels to 130%, and body text without a cap.
- **Shape.** Cards and grouped lists use a 22 radius, buttons 14, sheets 28, and the tab bar is a 32-radius capsule. Buttons are at least 52 tall, and all controls are at least 48 × 48.
- **Glass.** A blurred, saturated fill (`GlassSurface`) is used only on the floating layer: the tab bar, map controls, toolbar scroll edges and the review action bar. Content never uses it. Flutter exposes no Reduce Transparency signal, so Increase Contrast switches every glass surface to an opaque one with an outline.
- **Motion.** None is decorative. The toolbar title fades and tab selection animates, and both drop to zero duration with Reduce Motion.

## Layout

```text
Compact (phone)                    Regular (≥ 840)
+----------------------+           +---------+-------------------------+
| Home         (large) |           | Home    | Home               large |
| Seen standing water? |           | Map     | Report prompt           |
| [Report a breeding…] |           | Capture | Reported sites ▲ ◆ ●    |
| Reported sites ▲ ◆ ● |           | History | Your activity           |
| Your activity  …   > |           | Profile | Recent reports          |
| Recent reports     > |           |         |                         |
|  ( glass tab bar )   |           +---------+-------------------------+
+----------------------+
```

- **Home.** One prominent action, the risk summary (signature), activity rows, and the five most recent reports.
- **Map.** Full-bleed tiles; the glass risk filter and layers button sit at the top, and save-offline and my location sit at the bottom right above the tab bar.
- **Capture.** A large viewfinder target, *Take photo*, *Choose existing photo*, and a numbered *How it works* list. The numbers mark a real sequence.
- **Review.** Photo, result with a confidence meter, and location rows. *Save report* and *Discard* sit on a floating bar.
- **History.** Status filter chips and day-grouped lists. Tapping a row opens its detail sheet.
- **Profile.** A settings-style grouped list: name, Rewards, Appearance, Sync, Photo upload, Model evaluation, About.
- **Onboarding.** A welcome screen with three feature rows and the location rationale, followed by *Allow location* or *Not now*. This is the one screen where the brand leads.

## Platform decisions and limits

- The app shares Flutter Material widgets on Android and iOS, restyled with iOS proportions: `NavigationBar` inside a glass capsule, `NavigationRail` at 840 px and wider, and modal bottom sheets. It does not claim native SwiftUI controls or real Liquid Glass.
- The *Appearance* override stays for compatibility with users who already set it. This goes against the skill's system-only preference, which is why it defaults to *Match device* and is kept out of every toolbar.
- Swipe actions on History rows are not implemented. Actions stay in the row's ••• menu.
- The map tile provider (CARTO) currently returns "API KEY REQUIRED" tiles. This is a configuration issue in `TileCacheService`, not part of the design.

## Validation

- `flutter analyze` reports no issues, and all 18 tests pass. [test/mobile_design_test.dart](test/mobile_design_test.dart) covers:
  - Home, History, Capture, Profile and Rewards at 320 px with 100/200/300% text, in both appearances
  - increased contrast (no blur)
  - the large-title condense behavior
  - tab labels at 300% text, with pages padded clear of the floating bar
  - the wide rail
  - delete confirmation, and no delete option for synced reports
  - contrast of text, accent and risk colors
- Home, Map, Capture, History and Profile were checked on the Android 16 emulator: `output/redesign-*.png`. iOS and physical devices were not tested.
