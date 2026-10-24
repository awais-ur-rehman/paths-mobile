# Paths icon family

The navigation uses original editable SVG masters in `assets/icons/`: Home, Likes, Chats, Profile and Plus. Keep future icons in this family instead of mixing platform glyphs with these controls.

- Canvas:24×24. Optical content sits between3 and21; leave room for rounded stroke caps.
- Stroke:1.8 units, rounded caps/joins, no fills. Use smooth curves and simple silhouettes; internal detail must remain legible at24px.
- Color: masters use ink#101418. Runtime uses Paths ink for idle, blue#147DCE for selection/action, white on the raised blue button. Selection has a14×2px rounded underline; do not encode state or tint into duplicated masters.
- Navigation display:28px icons,26px Plus inside56px circle; tab touch targets>=48px. Icon-only controls still expose names and selection to assistive technologies.
- Export: `python3 tools/export_icons.py` compiles the masters to `lib/shared/widgets/generated/paths_icon_geometry.dart`. It uses installed Dart formatting and Python stdlib only. No runtime SVG parser, bitmap export or new package is required. Do not edit generated paths by hand.
- Supported master geometry: explicit absolute M/L/C/Q/Z commands on unfilled paths with the documented rounded1.8 stroke. Convert arcs/shapes to paths first; exporter rejects unsupported elements/styles instead of silently changing artwork.
- Use `PathsIcon(PathsIconName.chats, color: ..., size:28)` within an accessible control. The icon itself is decorative; the control owns its label/semantics.

New icon checklist: draw an original master, extend the exporter's NAMES list, regenerate, inspect24/28px alongside this set, then verify the real control's hit area/contrast and semantics. No third-party icon source or attribution applies to this original family.
