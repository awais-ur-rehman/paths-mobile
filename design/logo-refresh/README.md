# Paths logo exploration

Date: 23 October 2026. Status: concepts for owner selection; not integrated into the application.

## Brief

Replace the current bold crossing/hourglass mark with something elegant and subtle. Paths connects adults through real-world encounters; avoid presenting it as a dating-only or navigation product. Preserve the existing ink/white/blue palette, product name, small-screen clarity and original artwork. No new package, font or SDK is needed.

The owner requested the [logo-design skill](https://github.com/kaankiziltug/logo-design-skill/blob/main/skills/logo-design/SKILL.md). Followed its fast track: known project context, three concepts, monochrome construction, two visual refinement passes, small-size/reversed checks and a concept-selection checkpoint before production exports or integration. The skill was read directly, not installed.

## Exploration

Ten starting ideas were considered:

1. Open P: an open-ended route forms a readable letter P.
2. Passing: a lighter crossing with a gap separating the two paths.
3. Between: two opposing curves define a shared open space.
4. Parallel-stem P: a second stem adds plural routes, but crowds small sizes.
5. Wordmark only: quiet, but needs another mark for launcher use.
6. P inside a pin: too literal and close to mapping/dating conventions.
7. Infinity ribbon: familiar but generic in connection products.
8. Two connected dots: too close to generic messaging/networking symbols.
9. Compass P: implies navigation rather than encounters.
10. Four-way meeting flower: introduces an unwanted medical/sparkle reading.

Built the first three, spanning letterform and abstract marks. Recommendation: **B — Open P**. A retains the strongest continuity but remains an X at tiny sizes. B is the quietest and clearest initial, though less explicit about crossing. C is balanced and abstract, but offers the weakest connection to the name.

## Construction and refinement

- All symbols use a 256-unit square, few cubic anchors, flat ink and rounded terminals. No shadow, gradient, raster image, external font reference or live SVG text.
- A uses a continuous curve with the underpassing curve split at exact Bézier parameters. V2 reduces the gap from t=.30–.70 to t=.36–.64; the underpass remains visible at normal sizes but becomes an X at16px.
- B uses one open P gesture,24-unit stroke, a large counter and open lower bowl. No pin, heart, flame or enclosing badge is part of the mark.
- C uses two24-unit opposing curves. V2 opens the terminal gaps so they remain separated at16px.
- V2 lockups reduce the relative symbol size and tighten spacing to the title-case wordmark. The wordmark is outlined from the existing bundled Inter variable font at weight460 with slightly tightened advances, using local CoreText. Its SIL OFL notice remains at `assets/fonts/Inter-OFL.txt`.
- Meaningful V1/V2 SVG iterations are retained. These are stroked concept masters; production outline conversion and optical export adjustments belong to the selected direction.

## Study sources

Read the skill's redesign, SVG construction, testing and library guides. Studied Patreon, Gatsby and Amplitude SVG construction from its reference library for initial treatment, negative-space cuts and economical geometry. Temporary reference files stayed outside the repository. They are their owners' trademarks, not Paths assets; none was copied or traced into these marks. Studying these examples is not trademark clearance.

## Checks actually performed

- Rendered original SVGs with the already installed Sharp/librsvg, then inspected the images.
- Inspected both construction passes and corrected spacing/gaps in the second pass.
- Inspected true16/24/32/64px exports and a nearest-neighbour enlargement of16px results.
- Inspected ink-on-white, white-on-ink, mirrored,180-degree rotated and blurred views.
- Parsed every SVG as XML; verified positive viewBox dimensions and absence of live text, images, filters, scripts, external links and masks.
- Checked all PNGs decode at their intended sizes.

These are design checks, not Flutter/native runtime tests. No launcher, splash, loader, app header or admin branding has changed. Platform safe-area exports, Flutter rendering/goldens, Android rebuild/kernel comparison and physical-device confirmation remain pending selection.

## Files

`concepts.png` is the owner-facing comparison. `*-v1.svg` and `*-v2.svg` are editable originals; corresponding PNGs are local render/size checks. Reversed marks and icon tiles in the comparison demonstrate monochrome legibility, not a finished launcher-icon set.

Original symbol geometry is project artwork with no third-party attribution requirement. Outlined Inter lettering remains subject to its bundled SIL OFL. No downloaded photograph, stock person or new font was used.

## Next

After the owner selects A/B/C, refine that direction, create the production variants, update the shared Flutter painter/loader, Android adaptive/themed/notification/splash artwork, iOS launcher/launch artwork and admin copies, then verify available rendering/build checks before the owner's phone retest. Keep app geometry and export geometry consistent; preserve unrelated UI and backend functionality.
