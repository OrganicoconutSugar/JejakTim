import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Flat geometric overlapping-color vector icons inspired by translucent
/// duotone/tri-tone graphic design (no drop shadows, no 3D shading).
enum GeoIconKind {
  folder,
  folderPlus,
  scan,
  key,
  bell,
  layers,
  checkCircle,
  review,
  sync,
  clipboard,
  clipboardTodo,
  star,
  home,
  plus,
  profile,
  crown,
  users,
  calendar,
  arrowRight,
  arrowUpRight,
  chevronRight,
  lightbulb,
  info,
  sprout,
  rocket,
  code,
  target,
  book,
  pencil,
  shield,
  document,
  compass,
  logout,
  settings,
  search,
  camera,
  userPlus,
  clock,
  sliders,
  trash,
}

class GeoIcon extends StatelessWidget {
  final GeoIconKind kind;
  final double size;
  final double opacity;

  const GeoIcon(
    this.kind, {
    super.key,
    this.size = 24,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.string(
      _svgs[kind]!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return opacity == 1.0 ? svg : Opacity(opacity: opacity, child: svg);
  }
}

// Color palette matched to the flat geometric overlap reference:
// Gold/Yellow: #F2C100, #F7D426 | Overlap Amber: #E06D00
// Cyan/Aqua:   #35D5E4, #5BE4EE | Overlap Teal:  #169AB5
// Violet:      #761EFF          | Overlap Indigo:#3412A8 / #2C4FD8
// Mint Green:  #2CD4A2          | Overlap Deep:  #129E75
const Map<GeoIconKind, String> _svgs = {
  // Reference top-right: overlapping yellow & amber-orange geometric folder.
  GeoIconKind.folder: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 10 H20 L23 14 H40 V39 H5 Z" fill="#F2C100"/>
  <rect x="8" y="16" width="35" height="23" fill="#F2C100"/>
  <rect x="8" y="16" width="32" height="23" fill="#E06D00"/>
</svg>
''',

  // Overlapping folder + cyan/purple geometric plus badge.
  GeoIconKind.folderPlus: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 11 H18 L21 15 H36 V39 H4 Z" fill="#F2C100"/>
  <rect x="7" y="17" width="32" height="22" fill="#F2C100"/>
  <rect x="7" y="17" width="29" height="22" fill="#E06D00"/>
  <rect x="29" y="11" width="16" height="5" fill="#35D5E4"/>
  <rect x="34.5" y="5.5" width="5" height="16" fill="#761EFF"/>
  <rect x="34.5" y="11" width="5" height="5" fill="#2C4FD8"/>
</svg>
''',

  // Geometric overlapping scan / QR brackets + active scan line.
  GeoIconKind.scan: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 17 V6 H17 V11 H11 V17 Z" fill="#35D5E4"/>
  <path d="M31 6 H42 V17 H37 V11 H31 Z" fill="#F7D426"/>
  <path d="M6 31 H11 V37 H17 V42 H6 Z" fill="#F7D426"/>
  <path d="M37 31 H42 V42 H31 V37 H37 Z" fill="#35D5E4"/>
  <rect x="14" y="15" width="12" height="18" fill="#761EFF"/>
  <rect x="20" y="15" width="14" height="18" fill="#35D5E4"/>
  <rect x="20" y="15" width="6" height="18" fill="#2C4FD8"/>
  <rect x="8" y="22" width="32" height="4" fill="#2CD4A2"/>
</svg>
''',

  // Overlapping purple key bow + gold blade & teeth.
  GeoIconKind.key: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="19" y="21" width="24" height="6" fill="#F2C100"/>
  <rect x="32" y="27" width="4.5" height="6.5" fill="#E06D00"/>
  <rect x="38.5" y="27" width="4.5" height="4.5" fill="#E06D00"/>
  <path fill-rule="evenodd" d="M16 12 A12 12 0 1 0 16 36 A12 12 0 1 0 16 12 Z M16 19 A5 5 0 1 1 16 29 A5 5 0 1 1 16 19 Z" fill="#761EFF"/>
  <rect x="19" y="21" width="8.5" height="6" fill="#4312A8"/>
</svg>
''',

  // Geometric gold bell + overlapping amber rim + purple clapper + cyan dot.
  GeoIconKind.bell: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="23" cy="37" r="5" fill="#761EFF"/>
  <path d="M23 7 C15 7 10 13 10 21 V30 H36 V21 C36 13 31 7 23 7 Z" fill="#F2C100"/>
  <rect x="6" y="28" width="34" height="6.5" fill="#E06D00"/>
  <path d="M18 32 H28 A5 5 0 0 1 18 32 Z" fill="#4312A8"/>
  <circle cx="36.5" cy="11.5" r="5.5" fill="#35D5E4"/>
</svg>
''',

  // Overlapping geometric layers (cyan & purple squares with indigo overlap).
  GeoIconKind.layers: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="16" y="16" width="25" height="25" fill="#761EFF"/>
  <rect x="7" y="7" width="25" height="25" fill="#35D5E4"/>
  <rect x="16" y="16" width="16" height="16" fill="#2C4FD8"/>
</svg>
''',

  // Reference coin-style circle in mint green with crisp overlapping check strokes.
  GeoIconKind.checkCircle: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="19" fill="#2CD4A2"/>
  <polygon points="13.5,24.5 17.2,20.8 23.8,27.4 20.1,31.1" fill="#A6F5DC"/>
  <polygon points="20.1,27.4 31.8,15.7 35.5,19.4 23.8,31.1" fill="#A6F5DC"/>
  <polygon points="20.1,27.4 23.8,23.7 27.5,27.4 23.8,31.1" fill="#FFFFFF"/>
</svg>
''',

  // Reference top-middle-right: overlapping cyan & purple speech bubbles.
  GeoIconKind.review: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 7 H31 V26 H15 L8 33 V26 H5 Z" fill="#35D5E4"/>
  <path d="M17 18 H43 V37 H40 V44 L33 37 H17 Z" fill="#761EFF"/>
  <rect x="17" y="18" width="14" height="8" fill="#2C4FD8"/>
  <rect x="10" y="13" width="11" height="3.2" fill="#169AB5"/>
  <rect x="25" y="29" width="12" height="3.2" fill="#4312A8"/>
</svg>
''',

  // Reference bottom-middle-left: flat mint-green overlapping sync/revision arrows.
  GeoIconKind.sync: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 26 A14 14 0 0 1 25 10 V15 A9 9 0 0 0 16 26 Z" fill="#2CD4A2"/>
  <polygon points="23,5 35,12.5 23,20" fill="#2CD4A2"/>
  <polygon points="23,10 27,12.5 23,15" fill="#129E75"/>
  <path d="M37 22 A14 14 0 0 1 23 38 V33 A9 9 0 0 0 32 22 Z" fill="#2CD4A2"/>
  <polygon points="25,43 13,35.5 25,28" fill="#2CD4A2"/>
  <polygon points="25,38 21,35.5 25,33" fill="#129E75"/>
</svg>
''',

  // Active task clipboard: cyan board overlapping purple sheet + gold clip.
  GeoIconKind.clipboard: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="9" width="26" height="34" fill="#35D5E4"/>
  <rect x="16" y="15" width="24" height="28" fill="#761EFF"/>
  <rect x="16" y="15" width="18" height="28" fill="#2C4FD8"/>
  <rect x="15" y="5" width="14" height="7" fill="#F2C100"/>
  <rect x="15" y="9" width="14" height="3" fill="#E06D00"/>
  <rect x="21" y="23" width="13" height="3.2" fill="#5BE4EE"/>
  <rect x="21" y="30" width="9" height="3.2" fill="#5BE4EE"/>
</svg>
''',

  // Todo task clipboard: golden-yellow board overlapping amber-orange sheet + purple clip.
  GeoIconKind.clipboardTodo: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="9" width="26" height="34" fill="#F2C100"/>
  <rect x="16" y="15" width="24" height="28" fill="#F2C100"/>
  <rect x="16" y="15" width="18" height="28" fill="#E06D00"/>
  <rect x="15" y="5" width="14" height="7" fill="#761EFF"/>
  <rect x="15" y="9" width="14" height="3" fill="#4312A8"/>
  <rect x="21" y="23" width="13" height="3.2" fill="#F7D426"/>
  <rect x="21" y="30" width="9" height="3.2" fill="#F7D426"/>
</svg>
''',

  // Reference bottom-right: overlapping yellow star with amber-orange inner pentagon.
  GeoIconKind.star: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="24,4 29.8,17.2 44,18.6 33.2,28.1 36.4,42 24,34.7 11.6,42 14.8,28.1 4,18.6 18.2,17.2" fill="#F4D000"/>
  <polygon points="24,13.2 31.2,18.4 28.5,26.9 19.5,26.9 16.8,18.4" fill="#E06D00"/>
</svg>
''',

  // Nav Home: cyan roof overlapping purple house + indigo overlap + gold door.
  GeoIconKind.home: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="20" width="28" height="22" fill="#761EFF"/>
  <polygon points="24,6 44,24 4,24" fill="#35D5E4"/>
  <rect x="10" y="20" width="28" height="4" fill="#2C4FD8"/>
  <rect x="19" y="28" width="10" height="14" fill="#F2C100"/>
</svg>
''',

  // Nav Plus: pure flat overlapping cyan & purple bars with indigo center square.
  GeoIconKind.plus: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="19.5" width="32" height="9" fill="#35D5E4"/>
  <rect x="19.5" y="8" width="9" height="32" fill="#761EFF"/>
  <rect x="19.5" y="19.5" width="9" height="9" fill="#2C4FD8"/>
</svg>
''',

  // Nav Profile: cyan shoulders overlapping purple head circle with indigo lens.
  GeoIconKind.profile: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 42 C8 31 15 25 24 25 C33 25 40 31 40 42 Z" fill="#35D5E4"/>
  <circle cx="24" cy="17" r="10.5" fill="#761EFF"/>
  <path d="M17.5 25.4 A10.5 10.5 0 0 0 30.5 25.4 A16 14 0 0 0 17.5 25.4 Z" fill="#2C4FD8"/>
</svg>
''',

  // Crown (Ketua): overlapping yellow triangles with amber-orange intersections.
  GeoIconKind.crown: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="6,37 6,16 24,30 42,16 42,37" fill="#F7D426"/>
  <polygon points="12,37 24,11 36,37" fill="#F2C100"/>
  <polygon points="16.5,37 24,22 31.5,37" fill="#E06D00"/>
</svg>
''',

  // Users (Anggota): overlapping cyan & purple silhouettes.
  GeoIconKind.users: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="18" cy="16" r="8" fill="#35D5E4"/>
  <path d="M5 40 C5 31 10.5 26 18 26 C25.5 26 31 31 31 40 Z" fill="#35D5E4"/>
  <circle cx="31" cy="18" r="7.5" fill="#761EFF"/>
  <path d="M19 40 C19 32 24 27.5 31 27.5 C38 27.5 43 32 43 40 Z" fill="#761EFF"/>
  <path d="M19 40 C19 33.5 22.8 29.5 28 28.2 C30 31.2 31 35 31 40 Z" fill="#2C4FD8"/>
</svg>
''',

  // Calendar: cyan body overlapping purple top header bar + gold date block.
  GeoIconKind.calendar: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="11" width="36" height="31" fill="#35D5E4"/>
  <rect x="6" y="11" width="36" height="10" fill="#761EFF"/>
  <rect x="6" y="17" width="36" height="4" fill="#2C4FD8"/>
  <rect x="13" y="6" width="5" height="9" fill="#F2C100"/>
  <rect x="30" y="6" width="5" height="9" fill="#F2C100"/>
  <rect x="13" y="27" width="8" height="8" fill="#F2C100"/>
</svg>
''',

  // Flat geometric arrow right (mint shaft + purple arrowhead + overlap).
  GeoIconKind.arrowRight: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="7" y="20.5" width="24" height="7" fill="#35D5E4"/>
  <polygon points="24,10 41,24 24,38" fill="#761EFF"/>
  <rect x="24" y="20.5" width="7" height="7" fill="#2C4FD8"/>
</svg>
''',

  // Flat geometric arrow up-right (cyan + yellow overlap).
  GeoIconKind.arrowUpRight: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="11,32 30,13 35,18 16,37" fill="#35D5E4"/>
  <polygon points="17,11 37,11 37,31 31,31 31,17 17,17" fill="#F7D426"/>
  <rect x="31" y="11" width="6" height="6" fill="#2CD4A2"/>
</svg>
''',

  // Flat geometric chevron right (cyan + purple overlapping strokes).
  GeoIconKind.chevronRight: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="17,9 22,9 35,24 30,24" fill="#35D5E4"/>
  <polygon points="30,24 35,24 22,39 17,39" fill="#761EFF"/>
  <polygon points="27.5,21 32.5,21 35,24 32.5,27 27.5,27 30,24" fill="#2C4FD8"/>
</svg>
''',

  // Reference bottom-middle-right: gold bulb + orange filament + purple base.
  GeoIconKind.lightbulb: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="19" r="14" fill="#F2BA00"/>
  <rect x="17" y="28" width="14" height="7" fill="#F2BA00"/>
  <polygon points="18,21 30,21 26,26 26,35 22,35 22,26" fill="#E06D00"/>
  <polygon points="16,35 32,35 32,40 24,43 16,40" fill="#761EFF"/>
  <rect x="17" y="34" width="14" height="3.5" fill="#4312A8"/>
</svg>
''',

  // Reference bottom-left: purple info bubble + cyan "i".
  GeoIconKind.info: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="25" cy="24" r="18" fill="#761EFF"/>
  <polygon points="7,42 12,30 22,39" fill="#761EFF"/>
  <rect x="22" y="12" width="6" height="5.5" fill="#5BE4EE"/>
  <rect x="22" y="21" width="6" height="14" fill="#5BE4EE"/>
  <rect x="18" y="31.5" width="14" height="4" fill="#35D5E4"/>
  <rect x="22" y="31.5" width="6" height="4" fill="#169AB5"/>
</svg>
''',

  // Project avatar: sprout (overlapping mint & gold leaves).
  GeoIconKind.sprout: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="22" y="20" width="4.5" height="22" fill="#129E75"/>
  <path d="M24 27 C12 27 7 20 7 10 C17 10 24 15 24 27 Z" fill="#2CD4A2"/>
  <path d="M24 23 C36 23 41 16 41 6 C31 6 24 11 24 23 Z" fill="#F2C100"/>
  <path d="M22 20 H26.5 V27 H22 Z" fill="#129E75"/>
</svg>
''',

  // Project avatar: rocket (cyan & purple overlap + gold flame).
  GeoIconKind.rocket: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="24,6 34,20 34,34 14,34 14,20" fill="#761EFF"/>
  <polygon points="14,24 6,34 14,34" fill="#35D5E4"/>
  <polygon points="34,24 42,34 34,34" fill="#35D5E4"/>
  <circle cx="24" cy="21" r="5" fill="#35D5E4"/>
  <polygon points="18,34 30,34 24,44" fill="#F2C100"/>
  <rect x="18" y="32" width="12" height="4" fill="#E06D00"/>
</svg>
''',

  // Project avatar: code (overlapping cyan & purple chevrons).
  GeoIconKind.code: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="18,12 6,24 18,36 22,32 14,24 22,16" fill="#35D5E4"/>
  <polygon points="30,12 42,24 30,36 26,32 34,24 26,16" fill="#761EFF"/>
  <polygon points="26,10 30,10 22,38 18,38" fill="#F2C100"/>
</svg>
''',

  // Project avatar: target (concentric overlapping rings).
  GeoIconKind.target: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="19" fill="#761EFF"/>
  <circle cx="24" cy="24" r="12" fill="#35D5E4"/>
  <circle cx="24" cy="24" r="5.5" fill="#F2C100"/>
</svg>
''',

  // Project avatar: book (overlapping cyan & gold pages).
  GeoIconKind.book: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="10" width="21" height="29" fill="#35D5E4"/>
  <rect x="21" y="10" width="21" height="29" fill="#761EFF"/>
  <rect x="21" y="10" width="6" height="29" fill="#2C4FD8"/>
  <rect x="11" y="16" width="8" height="3" fill="#F7D426"/>
  <rect x="29" y="16" width="8" height="3" fill="#5BE4EE"/>
</svg>
''',

  // Pencil (Edit profil / catatan): gold body + amber overlap + purple eraser + cyan tip.
  GeoIconKind.pencil: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="8,40 12,26 22,36" fill="#35D5E4"/>
  <polygon points="12,26 30,8 40,18 22,36" fill="#F2C100"/>
  <polygon points="17,31 35,13 40,18 22,36" fill="#E06D00"/>
  <polygon points="30,8 35,3 45,13 40,18" fill="#761EFF"/>
  <polygon points="28,10 38,20 40,18 30,8" fill="#4312A8"/>
</svg>
''',

  // Shield (Privasi & data): overlapping mint & cyan halves with deep teal center + gold check.
  GeoIconKind.shield: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 5 L8 11 V23 C8 33 15 40 24 43 Z" fill="#2CD4A2"/>
  <path d="M24 5 L40 11 V23 C40 33 33 40 24 43 Z" fill="#35D5E4"/>
  <path d="M20 7 L28 7 V41 L24 43 L20 41 Z" fill="#129E75"/>
  <polygon points="16.5,24 19.8,20.7 23.5,24.4 30.5,17.4 33.8,20.7 23.5,31" fill="#F7D426"/>
</svg>
''',

  // Document (Ketentuan / Laporan): cyan sheet overlapping gold sheet + purple bars.
  GeoIconKind.document: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="6" width="26" height="33" fill="#35D5E4"/>
  <rect x="14" y="10" width="26" height="33" fill="#F2C100"/>
  <rect x="14" y="10" width="20" height="29" fill="#2CD4A2"/>
  <rect x="19" y="18" width="14" height="3.5" fill="#761EFF"/>
  <rect x="19" y="25" width="14" height="3.5" fill="#761EFF"/>
  <rect x="19" y="32" width="9" height="3.5" fill="#4312A8"/>
</svg>
''',

  // Compass (Perkenalan aplikasi): purple circle + overlapping cyan & gold diamond needle.
  GeoIconKind.compass: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="19" fill="#761EFF"/>
  <polygon points="33,15 27,27 21,21" fill="#F7D426"/>
  <polygon points="15,33 21,21 27,27" fill="#35D5E4"/>
  <circle cx="24" cy="24" r="3.5" fill="#E06D00"/>
</svg>
''',

  // Logout (Keluar): rose/purple door frame overlapping gold exit arrow.
  GeoIconKind.logout: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 8 H28 V15 H15 V33 H28 V40 H8 Z" fill="#761EFF"/>
  <rect x="19" y="20.5" width="16" height="7" fill="#FF4D79"/>
  <polygon points="31,13 43,24 31,35" fill="#F2C100"/>
  <rect x="31" y="20.5" width="5" height="7" fill="#E06D00"/>
</svg>
''',

  // Settings (Pengaturan): overlapping cyan & purple geometric sliders/gear.
  GeoIconKind.settings: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="7" y="13" width="34" height="5" fill="#35D5E4"/>
  <circle cx="18" cy="15.5" r="6" fill="#761EFF"/>
  <rect x="7" y="30" width="34" height="5" fill="#F2C100"/>
  <circle cx="31" cy="32.5" r="6" fill="#2CD4A2"/>
  <rect x="12" y="13" width="12" height="5" fill="#2C4FD8"/>
  <rect x="25" y="30" width="12" height="5" fill="#129E75"/>
</svg>
''',

  // Search: cyan lens ring overlapping purple handle.
  GeoIconKind.search: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <polygon points="27,31 32,26 43,37 38,42" fill="#761EFF"/>
  <path fill-rule="evenodd" d="M21 7 A14 14 0 1 0 21 35 A14 14 0 1 0 21 7 Z M21 13 A8 8 0 1 1 21 29 A8 8 0 1 1 21 13 Z" fill="#35D5E4"/>
  <polygon points="27,31 32,26 34.5,28.5 29.5,33.5" fill="#2C4FD8"/>
</svg>
''',

  // Camera / Photo: purple body + gold flash + overlapping cyan lens.
  GeoIconKind.camera: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="15" y="9" width="14" height="7" fill="#F2C100"/>
  <rect x="6" y="14" width="36" height="26" fill="#761EFF"/>
  <rect x="15" y="14" width="14" height="3" fill="#4312A8"/>
  <circle cx="24" cy="27" r="9.5" fill="#35D5E4"/>
  <circle cx="24" cy="27" r="4.5" fill="#2C4FD8"/>
  <circle cx="36" cy="20" r="2.5" fill="#F7D426"/>
</svg>
''',

  // User Plus (Undang): purple/cyan person + gold/mint plus.
  GeoIconKind.userPlus: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 41 C5 31 11 26 19 26 C27 26 33 31 33 41 Z" fill="#35D5E4"/>
  <circle cx="19" cy="17" r="9" fill="#761EFF"/>
  <rect x="30" y="17" width="14" height="4.5" fill="#2CD4A2"/>
  <rect x="34.75" y="12.25" width="4.5" height="14" fill="#F2C100"/>
  <rect x="34.75" y="17" width="4.5" height="4.5" fill="#129E75"/>
</svg>
''',

  // Clock (inspired by purple clock face in reference): cyan/purple overlapping disc + gold hands.
  GeoIconKind.clock: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="19" fill="#761EFF"/>
  <path d="M24 5 A19 19 0 0 1 43 24 H24 Z" fill="#35D5E4"/>
  <rect x="22" y="13" width="4.5" height="13" fill="#F7D426"/>
  <rect x="22" y="22" width="12" height="4.5" fill="#F2C100"/>
  <rect x="22" y="22" width="4.5" height="4.5" fill="#E06D00"/>
</svg>
''',

  // Sliders (Atur notifikasi).
  GeoIconKind.sliders: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="12" width="36" height="4" fill="#35D5E4"/>
  <rect x="13" y="8" width="9" height="12" fill="#761EFF"/>
  <rect x="6" y="22" width="36" height="4" fill="#F2C100"/>
  <rect x="27" y="18" width="9" height="12" fill="#E06D00"/>
  <rect x="6" y="32" width="36" height="4" fill="#2CD4A2"/>
  <rect x="17" y="28" width="9" height="12" fill="#129E75"/>
</svg>
''',

  // Trash (Hapus akun): overlapping rose/purple bin.
  GeoIconKind.trash: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="6" width="12" height="5" fill="#761EFF"/>
  <rect x="8" y="11" width="32" height="5.5" fill="#FF4D79"/>
  <polygon points="12,16.5 36,16.5 33,42 15,42" fill="#F2C100"/>
  <rect x="12" y="16.5" width="24" height="4" fill="#E06D00"/>
  <rect x="21.5" y="23" width="5" height="13" fill="#761EFF"/>
</svg>
''',
};
