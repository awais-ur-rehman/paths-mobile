# Assets

## Original identity

Two rounded crossing paths form the Paths symbol. Custom vector lettering forms the primary wordmark. Original Paths project artwork created in this session; no reference-app marks or photos reused. Rights reserved to the project owner; no third-party attribution required for this artwork. Editable SVG sources and reproducible Pillow exporter are retained in paths-mobile/tools/export_brand.py. No stock or generated people are presented as members.

| Asset | Purpose and locations | Source/license |
|---|---|---|
| paths-logo.svg; paths-logo-ink.svg; paths-logo-white.svg | Primary wordmark, product/admin identity | Original SVG geometry, project artwork |
| paths-symbol.svg/.png; ink/white variants | App/splash/shared symbol | Original SVG geometry; PNG exports via local Pillow 12.3 |
| Android mipmap icons + drawable/paths_symbol.xml | Density PNG fallback, adaptive foreground, themed monochrome, Android 12 splash | Same symbol; foreground stays inside 66/108 safe region; OS supplies adaptive mask |
| iOS Assets.xcassets/AppIcon + LaunchImage | Opaque square app icons (OS rounds), transparent centered launch symbol | Same symbol; each required size exported separately |
| Inter-Variable.ttf | Bundled UI font | https://github.com/google/fonts/tree/main/ofl/inter — SIL Open Font License 1.1, retained Inter-OFL.txt with copyright notices |
| LilitaOne-Regular.ttf | Bundled short expressive headline | https://github.com/google/fonts/tree/main/ofl/lilitaone — SIL Open Font License 1.1, retained LilitaOne-OFL.txt with copyright notices |
| Flutter Material line icons, when needed | One consistent built-in family; no new icon dependency | Flutter SDK notices; no external icon pack downloaded |

Mobile assets: assets/brand, assets/fonts, android/app/src/main/res, ios/Runner/Assets.xcassets. Admin assets: public/brand and public/fonts; integration into its React shell remains in the admin phase. Fonts were downloaded under the owner's explicit visual-asset exception on 2026-10-17; no dependency/SDK/tool installation. Source font files are bundled unmodified; licenses permit commercial use subject to their terms.

## Verification scope

Exporter executed locally. SVGs parsed as XML; all raster variants opened with Pillow. Flutter widget rendering checked at 320/360/390/430/600/768/1024 and 100%/200% text. Real launcher masking and native splash appearance require device evidence; screenshot unit tests cannot prove them. Photo-led onboarding and full product UI belong to subsequent phases; no unlicensed photo placeholders were added.

## Downloaded font SHA-256

- `Inter-OFL.txt`: `5b9321a4298cfeb6b34354164a1c3afc3db114569984c502b9b35d988fd58c57`
- `Inter-Variable.ttf`: `29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031`
- `LilitaOne-OFL.txt`: `255d5debbb80eb2ea762644311f266a279e8778f00156655a516e2b7781a63e1`
- `LilitaOne-Regular.ttf`: `f5b641c45c69d772ee4eda687bc9fda411d5cad6b0b45371491da4580cbc8d59`

## Task3 onboarding photograph

- Purpose: illustrative onboarding hero only; no person is presented as a Paths member or endorser.
- Photo: MART PRODUCTION, Pexels photo8121667, “Group of Friends Walking in the Park”: https://www.pexels.com/photo/group-of-friends-walking-in-the-park-8121667/ . Download URL: https://images.pexels.com/photos/8121667/pexels-photo-8121667.jpeg?auto=compress&cs=tinysrgb&w=1600 .
- License checked2026-10-17: https://www.pexels.com/license/ . Free commercial/app use and modification permitted; attribution not required. Do not imply endorsement, misuse identifiable people, resell unaltered copies or redistribute as stock. Optional photographer credit appears in the app's image credits.
- Source retained: assets/source/friends-walking-pexels-8121667.jpg. Optimized locally with Pillow (resize only, original aspect, JPEG85): assets/onboarding/friends-walking.jpg. Source remains editable; production bundles only optimized asset. No hotlink.
