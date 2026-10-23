# Paths / Open P

Selected by the owner on 23 October 2026. A continuous, open-ended route forms a P. The drawing is the approved concept B; it is not a map pin, closed loop or crossing/hourglass.

## Files and reproduction

Editable masters: assets/brand/source/paths-symbol.svg and paths-logo.svg. Run `python3 tools/export_brand.py` with existing Dart, Pillow and sibling backend Sharp available. It performs no installation/resolution. It also produces the generated Dart geometry; do not edit that generated file by hand. SVG master lettering is outlined and needs no installed font for rendering.

Default symbol/primary horizontal lockup are ink; `-white` is inverse, `-blue` is the existing primary-blue accent. `-ink` files preserve current asset references. `paths-logo-stacked.svg` and `paths-wordmark.svg` are additional compositions of the same master paths. The P retains round strokes for consistent platform rendering; no filter, raster, mask or live SVG text is used.

## Palette and space

- Ink: #101418 / RGB16,20,24.
- White: #FFFFFF / RGB255,255,255.
- Accent blue: #147DCE / RGB20,125,206. Retained palette, not a new theme.
- Preserve the viewBox and aspect ratio. Keep external clear space of at least one symbol stroke; do not stretch, close the open bowl, add gradients/shadows or add decorative dots to the static logo.
- General UI symbol:24px or larger preferred;16px is the inspected minimum. Horizontal lockup:116px or larger in headers. Use the symbol without tiny lettering for launcher/favicon use.

## Platform treatment

Legacy Android and iOS icons are white, opaque squares with a centered P; their visible glyph is about 61.5% of the tile height. iOS applies its own corner mask. Adaptive Android foreground scales the 256-unit drawing by .68 about its center; splash uses .60 to respect Android12's tighter circle. Notification artwork is a separate white alpha silhouette. These are distinct native exports, not one image stretched to all formats.

iOS LaunchImage scales the source by .70 inside each 1x/2x/3x bitmap and retains centered 96pt aspect-fit storyboard constraints. The Flutter splash uses the same P route. SVG web favicon includes a white tile so the ink P remains visible in dark browser chrome.

## Motion and accessibility

The existing 1.6-second loader follows the open P contour. Reduced motion stops the animation, and the controller is disposed as before. Brand widgets retain the Paths semantic label; the loader has one Loading label. Tinting the vector does not change the geometry.

## Attribution

Symbol: original Paths project artwork. Wordmark: outlined Inter variable font at weight 460 with adjusted tracking; existing assets/fonts/Inter-OFL.txt remains bundled. No reference-library logo is distributed. Methodology: https://github.com/kaankiziltug/logo-design-skill; references are study material only.

## Checks and limits

Actual SVG/native safe-area parity, XML/PNG catalog validity, opaque iOS app icons, rendered small/reversed marks and Flutter goldens are checked during implementation. Exact command results belong in docs/IMPLEMENTATION_STATUS.md. Device launcher masks, Android system splash transition and signed iOS runtime appearance require device evidence.
