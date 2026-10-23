# Assets

## Original identity

The owner selected **Open P (concept B)** on 23 October 2026. A single open-ended P route replaces the earlier crossing/hourglass mark. Original Paths symbol geometry is project artwork with no third-party symbol attribution. The title-case wordmark uses outlined bundled Inter at weight 460 with adjusted spacing; retain its existing SIL Open Font License 1.1 notice. No reference-app mark or reference-library trademark was copied.

Editable masters: assets/brand/source/paths-symbol.svg and paths-logo.svg. tools/export_brand.py uses existing local Sharp/librsvg and Pillow to generate SVG/PNG, Flutter vector paths, Android resources, iOS catalogs and admin assets. No new renderer package is installed. Native sizing is intentionally different from general UI artwork to respect platform masks.

| Asset | Purpose and locations | Source/license |
|---|---|---|
| paths-logo.svg; paths-logo-ink.svg; paths-logo-white.svg | Primary wordmark, product/admin identity | Original symbol; outlined Inter lettering under bundled SIL OFL |
| paths-symbol.svg/.png; ink/white variants | App/splash/shared symbol | Original Open P geometry; SVG rasterization via local Sharp, platform exports via Pillow |
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

Task3 originally exported the ink wordmark with tools/render_logo.swift. The Open P exporter now renders it directly from the approved SVG; the obsolete fixed-aspect Swift helper was retired. Font license files are bundled and registered with Flutter LicenseRegistry; the app credits link opens those notices. Onboarding/login golden renders were inspected for typography, icon glyphs, legibility and cropping. Native splash/icon masking remains owner-device evidence.

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

## Task7 relationship and notification screens

No new remote visual assets. Saved/Incoming/Sent, inbox, notification settings and peer actions reuse the bundled Inter font, Material outlined icons, Paths avatar, loader and toast. Editable sources are lib/features/relationships/presentation and lib/features/notifications/presentation. Android notification small icon reuses the existing monochrome res/drawable/paths_symbol.xml; it is not a stretched launcher bitmap. Existing Paths/Flutter/Material licensing and attribution remain applicable. Responsive Likes render was inspected locally at390px/200% using synthetic test-only identities; no fixture image/person ships in production.


## Task8 media

No new production stock photos, fonts or icon packages. Camera/gallery/post controls use the existing Material icon family supplied by Flutter (SDK notices retained by Flutter's license registry). The original Paths symbol, white surfaces and existing font bundles remain in use. Private images use authenticated in-memory pixels; no hotlinks or fake users.

`test/features/media/goldens/photo-preview.png` is an original widget-test render with bundled Inter and Material icons; test-only single-pixel PNG input is isolated in `photo_screen_test.dart`. Editable source is the widget/test code. `docs/licenses/` retains image_picker1.2.4 and crypto3.0.7 BSD notices; Flutter's generated application notices include plugin/transitive package licenses. Synthetic manual-test cards and their SVG sources live in paths-backend/docs/testing/media; these are development fixtures, never seeded as member content.


## Task8 synthetic media fixtures

| Asset | Purpose | Source / method | License / attribution | Outputs |
| --- | --- | --- | --- | --- |
| Profile, front and back test cards | Owner gallery/camera/upload testing, isolated from production seeds | Original Paths crossing symbol and text; editable SVG, PNG exported by existing Sharp via paths-backend/scripts/create-media-fixtures.ts | Original project artwork; no third-party image attribution | docs/testing/media/{profile,cnic-front,cnic-back}.{svg,png} |

Cards contain no people, identity numbers, real accounts or testimonials. SVG is editable source; upload the generated PNG. Exports are600×800, inspected locally, below10MB, and generated without downloading fonts/assets or a new dependency. Production app branding/fonts remain the existing locally bundled assets.

Profile handoff regression image: original1×1 RGBA PNG generated with Python standard-library PNG chunks/zlib and encoded inline in test/features/setup/setup_routing_test.dart (ProfilePickerFixture). Test-only decoder/route fixture, project-owned, no attribution or external asset dependency; no production asset/export or personal image is involved.

## Task 11 staff workspace

Reuses existing original Paths vector symbol/logo and bundled Inter. No new visual asset downloads or people images. Admin RHF/Zod MIT notices are retained in paths-admin/docs/licenses; these are code dependencies, not image assets.

## Task 13 hardening

No new production visual assets. Existing Paths branding, fonts and reference goldens are reused. The inline one-pixel RGBA PNG in mobile `test/features/media/private_image_lifecycle_test.dart` is original test-only artwork generated with Python standard-library PNG chunks/zlib; project-owned, no attribution required. It contains no people or personal data.

## Task14 sign-in controls (historical, replaced below)

`assets/auth/google-sign-in.png` is the unmodified 354×80 RGBA pre-approved light pill button from https://developers.google.com/static/identity/images/branding_guideline_sample_lt_rd_lg.png (6,953 bytes), linked by https://developers.google.com/identity/branding-guidelines. Google brand features remain Google's trademarks; use is limited to the documented sign-in control under those branding guidelines, not a general open-source logo license. No additional attribution is requested by the guidelines. Keep its proportions and colors. It is bundled locally, displayed with contain fit and a screen-reader button label; no hotlink, invented G or font dependency. This is third-party artwork, not Paths project artwork.

The Apple control uses the cached `sign_in_with_apple` package's standard button (8.2.0, MIT code license; Apple mark remains subject to Apple's Sign in with Apple design rules). No separate Apple logo asset was copied. Both controls retain their provider names and comparable size. Native signed-device presentation remains to be checked.

Google sign-in artwork SHA-256: `d260d50a14d8f7deb03025e8ceb644577a8798e127fe203a959cd6cebf145e4e`.


## Logo refresh concepts — 23 October 2026

Concept-stage record: production branding was unchanged pending owner direction selection.

| Asset | Purpose | Source / generation | License / attribution | Location |
| --- | --- | --- | --- | --- |
| Passing, Open P and Between V1/V2 SVGs | Original logo directions for owner review | Original cubic geometry; methodology from https://github.com/kaankiziltug/logo-design-skill; no reference-library logo copied | Project symbol artwork; no third-party symbol attribution | design/logo-refresh/*-v1.svg, *-v2.svg |
| Outlined Paths wordmark in concept lockups | Evaluate symbol/type proportions | Existing bundled Inter variable font, weight460, outlined with local CoreText; adjusted spacing | Inter SIL OFL1.1; retain assets/fonts/Inter-OFL.txt | design/logo-refresh/*-lockup-*.svg |
| concepts.png and PNG render checks | Comparison, small-size and monochrome inspection | Existing local Sharp/librsvg and Pillow; no new dependency | Same artwork/font terms | design/logo-refresh/*.png |

Design brief, examined references, actual checks and integration tasks are recorded in design/logo-refresh/README.md. These comparison tiles are not final Android/iOS launcher assets.


## Open P production assets — 23 October 2026

- Approved source: design/logo-refresh/b-open-p-v2.svg and b-open-p-lockup-v2.svg; owner selected B. Primary artwork is ink #101418 on white #FFFFFF; inverse white and existing blue #147DCE accent variants are exported.
- SVGs/PNGs: assets/brand/paths-symbol*, paths-logo*, paths-logo-stacked.svg and paths-wordmark.svg. paths-loader.svg follows the same P route. Symbols are monochrome SVG strokes with round caps; lettering is font-independent filled outlines.
- Runtime: generated/paths_geometry.dart is reproducibly derived from the SVG masters; shared PathsSymbol/PathsWordmark/PathsLoader use it. No SVG package or new font dependency.
- Android: density fallback PNGs, adaptive/themed foreground and Android12 splash use the P. Separate paths_notification.xml is white-on-transparent for push/tracking notifications. Actual control-hull tests verify the system-circle bounds.
- iOS: every catalog slot exported separately; app icons opaque RGB, launch symbols transparent, launch storyboard retains centered aspect-fit constraints.
- Admin: matching public/brand files, favicon.svg and apple-touch-icon.png. Reference-library SVGs were studied temporarily outside the repositories and are not bundled.
- Reproduce with existing tools: python3 tools/export_brand.py. Requires Dart on PATH, Pillow, and already-installed sibling paths-backend/node_modules/sharp; does not install or download them.

Usage/padding/minimum-size and source notes: docs/brand/OPEN_P.md. Runtime/system-mask appearance remains a phone check; catalog/XML/render checks are not device evidence.

`docs/brand/open-p-preview.png` is a white-background review export of the same primary logo; original artwork/Inter terms above apply.


## Authentication UI refresh — 24 October 2026

| Asset | Purpose / outputs | Source / method | License / attribution |
| --- | --- | --- | --- |
| Google round sign-in control | `assets/auth/google-round.svg` (editable vendor source), `google-round.png` (180px; only PNG bundled) | Unmodified official light round icon-mode SVG from https://developers.google.com/static/identity/images/branding_guideline_sample_lt_rd_sl.svg, linked at https://developers.google.com/identity/branding-guidelines . Rasterized with the already-installed sibling backend Sharp/librsvg; no new package/font | Google brand features remain Google's trademarks; use is limited to sign-in under the branding guidelines, not a general open-source mark license. Colors/aspect/boundary are preserved. No additional attribution requested. |
| Apple sign-in symbol | Public `AppleLogoPainter` in existing `sign_in_with_apple`8.2.0 renders the equal-size circular control; no new asset file | Existing installed MIT package implementation, original Apple brand symbol. Shown only where the provider SDK/configuration permits Apple sign-in | Retain existing package license; Apple brand use follows Sign in with Apple guidelines. Apple setup/runtime testing remains deferred. |
| Auth reference goldens | `test/features/auth/goldens/auth-login-configured.png`, `auth-signup-configured.png`, `auth-forgot.png` | Actual Flutter test renders with bundled Inter/Material icons and synthetic provider configuration. The supplied reference is studied for layout, not copied into the app. | Paths UI artwork plus existing font/provider terms. Test-only fixtures, no real users or credentials. |

The old pill `google-sign-in.png` is removed from the app and asset manifest; its historical source record remains above. No hotlinks or new runtime SVG dependency. All form icons use the existing Material icon family; primary Paths artwork remains the approved Open P.

google-round.svg SHA256: `4d197ab476078c8979c90ea9c4ed98e56a6748e118ace7a07caeb43266cad469`.

google-round.png SHA256: `b653ff86df9554970c3c88a57a51b208439ee9bc1a2b9944e4bbd12f3fbf8a7d`.
