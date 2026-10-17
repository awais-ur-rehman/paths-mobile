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

Exporter executed locally. SVGs parsed as XML; all raster variants opened with Pillow. Flutter widget rendering checked at 320/360/390/430/600/768/1024 and 100%/200% text. Real launcher masking and native splash appearance require device evidence; screenshot unit tests cannot prove them. Task3 adds the licensed photo below; full profile/product UI remains in subsequent tasks.

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

Task3 exports the ink wordmark to assets/brand/paths-logo-ink.png using retained tools/render_logo.swift. Font license files are bundled and registered with Flutter LicenseRegistry; the app credits link opens those notices. Onboarding/login golden renders were inspected for typography, icon glyphs, legibility and cropping. Native splash/icon masking remains owner-device evidence.

## Device-feedback loader and splash

- assets/brand/paths-loader.svg: original Paths Bezier artwork with moving travellers; project-owned source, no third-party attribution. Runtime equivalent: lib/shared/widgets/paths_loader.dart (Flutter vector painter, no SVG/animation dependency). Curve/stroke/color source retained for editing. Reduced motion uses a static vector state.
- android/app/src/main/res/drawable/paths_splash.xml: original symbol scaled about its center to fit Android12's circular safe area. Native background is white; older Android uses96dp bounds. iOS launch storyboard uses96pt bounds and aspect fit; Flutter bootstrap uses72px bounds/contain. No stretched source or replacement reference-app logo.
- Existing licensed onboarding photo/font sources are unchanged. Onboarding uses a full-bleed top crop; photo/font notices moved to reachable policy credits rather than adding footer copy. Updated phone goldens: test/features/auth/goldens/{auth-onboarding,auth-login,age-check,profile-details}.png. Native masking still requires device retest.

In-app Paths wordmark/symbol now render synchronously from the original SVG geometry via lib/shared/widgets/paths_brand.dart; loader uses the same curve builder. Existing SVG/raster exports remain editable handoff assets. This preserves aspect ratios and avoids raster decoder timing when changing routes; no new asset package is installed.

Task4 adds no external assets or downloads. PathsAvatar uses the already bundled Material outline person glyph for unavailable/pending photos; VerificationBadge uses the same Material icon family and a factual explanation. Source: lib/shared/widgets/paths_avatar.dart and verification_badge.dart; existing Flutter/Material distribution licenses apply. Profile/review golden PNGs are synthetic test renders, not member records or testimonials.

## Task5 permission fixture

No new production visual asset or font. Location education reuses the original Paths vector symbol, loader/toast, bundled Inter and existing Material outline family under their recorded licenses. `test/features/discovery/goldens/location-permissions.png` is a locally rendered Flutter test fixture, not a production image or fabricated member. Editable source: `lib/features/discovery/presentation/location_setup_screen.dart`; inspected at390px, responsive fixtures cover320/390/768 and200% text.


## Task6 Home and maps

- Home test render: test/features/discovery/goldens/home-encounters.png, generated locally from editable Flutter Home/card/filter components. Clearly synthetic fixture profiles; no production fake users or stock portraits. Existing Paths vectors, neutral avatars, Material line icons, Inter, loader and toast reused.
- MapLibre GL0.27.1 and platform/web0.27.1 resolved from existing cache; their original license texts are retained in docs/licenses/maplibre_gl*.txt. New transitive archive4.5.1/image4.12.0/posix6.5.2 licenses retained alongside them. These are SDK dependencies, not new production visual assets.
- Editable map style URL: PATHS_MAP_STYLE_URL, example config/development.example.json. Example uses the provider-hosted OpenFreeMap Liberty style, documented for MapLibre Native at https://openfreemap.org/quick_start/ . The provider explicitly permits commercial use and requires attribution: https://openfreemap.org/ . MapLibre attribution remains enabled; retain OpenMapTiles/OpenStreetMap attribution in replacement styles. No tile database, remote app font, image or style snapshot was downloaded/bundled by the implementer. Runtime map labels/tiles are provider data; app typography remains locally bundled. No offline map-area downloader is implemented.
- Native map receives only server-quantized encounter area centers; its precise user-location layer is disabled. Provider requests can reveal the viewed coarse region and client network information; no account token, peer identity, exact fixes or private documents are given to the map provider. Release provider/privacy/operational choices remain Task15. Actual style/attribution rendering requires owner device evidence.


Task6 approved iOS dependency: MapLibre Native6.28.0 from https://github.com/maplibre/maplibre-gl-native-distribution/tree/6.28.0 , binary source https://github.com/maplibre/maplibre-native/releases/tag/ios-v6.28.0 . Xcode fetched the exact package/binary under owner approval and generated the source revision pin. BSD2-Clause copyright/redistribution notice copied verbatim from its LICENSE.md to docs/licenses/maplibre-native-ios-6.28.0.txt; retain it in distribution materials. Native binaries remain ignored build/cache artifacts, not repository assets. Existing map data attribution requirements remain unchanged.

## Profile reference update

Owner-supplied portrait profile screenshot guides cover proportions, centered identity, floating controls and framed bio only; its person/photos/UI brand are not bundled. Editable source: lib/features/profile/presentation/profile_surface.dart. Until Task8 supplies genuine profile media, the cover uses the existing Material person outline and an original neutral gradient with No photo yet. No stock/generated person or fabricated gallery is used. Existing Flutter/Material licenses apply. Updated local synthetic goldens: test/features/profile/goldens/own-profile.png, test/features/auth/goldens/profile-details.png and test/features/verification/goldens/optional-verification.png. Dotted document borders are drawn directly by the verification widget; no external asset/dependency. Sources remain editable Dart widgets and existing licensed fonts/icons.
