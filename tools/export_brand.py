"""Export the approved SVG masters with existing local Sharp/Pillow; no installs."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT/'assets/brand'
SOURCE = BRAND/'source'
RES = ROOT/'android/app/src/main/res'
INK, BLUE, WHITE = '#101418', '#147DCE', '#FFFFFF'
S = '{http://www.w3.org/2000/svg}'
A = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('', S[1:-1])
symbol = ET.parse(SOURCE/'paths-symbol.svg').getroot()
logo = ET.parse(SOURCE/'paths-logo.svg').getroot()
route = symbol.find(S+'path')
if route is None or symbol.attrib['viewBox'] != '0 0 256 256':
    raise ValueError('Expected the approved single-route 256-unit symbol')
path_data = route.attrib['d']
stroke = float(route.attrib['stroke-width'])

def colored(root, color):
    copy = ET.fromstring(ET.tostring(root))
    for element in copy.iter():
        for key in ['fill', 'stroke']:
            if element.get(key) == INK:
                element.set(key, color)
    return ET.tostring(copy, encoding='unicode')+'\n'

# Additional lockups are built from the same master paths, never redrawn.
stacked = ET.Element(S+'svg', {'viewBox':'0 0 256 320','role':'img'})
ET.SubElement(stacked,S+'title').text='Paths stacked logo'
for original,transform in [(logo.find(f"{S}g[@id='symbol']"),'translate(25.6 0) scale(.8)'),(logo.find(f"{S}g[@id='wordmark']"),'translate(43.4 264) scale(.68)')]:
    group=ET.fromstring(ET.tostring(original)); group.set('transform',transform); stacked.append(group)
word_only=ET.Element(S+'svg',{'viewBox':'0 -78 250 84','role':'img'})
ET.SubElement(word_only,S+'title').text='Paths wordmark only'
group=ET.fromstring(ET.tostring(logo.find(f"{S}g[@id='wordmark']")));group.attrib.pop('transform');word_only.append(group)
for name,master in [('paths-logo-stacked',stacked),('paths-wordmark',word_only)]:
    (BRAND/f'{name}.svg').write_text(colored(master,INK))

jobs = []
for base, master in [('paths-symbol', symbol), ('paths-logo', logo)]:
    for suffix, color in [('', INK), ('-ink', INK), ('-white', WHITE), ('-blue', BLUE)]:
        p = BRAND/f'{base}{suffix}.svg'
        p.write_text(colored(master, color))
        jobs.append({'input': str(p), 'output': str(p.with_suffix('.png')), 'width': 1024 if base == 'paths-symbol' else 1300})
# Use the installed backend renderer, without npm resolution or external fetching.
renderer = ROOT.parent/'paths-backend/node_modules/sharp'
if not renderer.is_dir():
    raise RuntimeError('Existing paths-backend/node_modules/sharp is required; do not install automatically')
script = """const sharp=require(process.argv[1]); const jobs=JSON.parse(process.argv[2]);
(async()=>{for(const job of jobs)await sharp(job.input).resize(job.width).png().toFile(job.output)})()
.catch(error=>{console.error(error.message);process.exit(1)});"""
subprocess.run(['node', '-e', script, str(renderer), json.dumps(jobs)], check=True)

def icon(size, scale=1, opaque=False):
    canvas = Image.new('RGBA', (size,size), WHITE if opaque else (0,0,0,0))
    mark = Image.open(BRAND/'paths-symbol-ink.png')
    side = round(size*scale)
    mark = mark.resize((side,side), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, ((size-side)//2,(size-side)//2))
    return canvas.convert('RGB') if opaque else canvas

for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    directory = RES/f'mipmap-{density}'
    directory.mkdir(exist_ok=True)
    icon(size,.82,True).save(directory/'ic_launcher.png',optimize=True)

def vector(name, color, scale=None):
    path = f'<path android:pathData="{path_data}" android:strokeColor="{color}" android:strokeWidth="{stroke:g}" android:strokeLineCap="round" android:strokeLineJoin="round" android:fillColor="@android:color/transparent"/>'
    if scale is not None:
        path = f'<group android:pivotX="128" android:pivotY="128" android:scaleX="{scale}" android:scaleY="{scale}">{path}</group>'
    (RES/f'drawable/{name}.xml').write_text(f'<vector xmlns:android="{A}" android:width="108dp" android:height="108dp" android:viewportWidth="256" android:viewportHeight="256">{path}</vector>\n')

vector('paths_symbol',INK,.68)
vector('paths_splash',INK,.60)
vector('paths_notification',WHITE)
(RES/'mipmap-anydpi-v26/ic_launcher.xml').write_text(f'<adaptive-icon xmlns:android="{A}"><background android:drawable="@color/paths_background"/><foreground android:drawable="@drawable/paths_symbol"/><monochrome android:drawable="@drawable/paths_symbol"/></adaptive-icon>\n')
contents = json.loads((ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text())
for item in contents['images']:
    size = round(float(item['size'].split('x')[0])*float(item['scale'][:-1]))
    icon(size,.82,True).save(ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'/item['filename'],optimize=True)
for suffix,size in [('',128),('@2x',256),('@3x',384)]:
    icon(size,.70).save(ROOT/f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png',optimize=True)

# Only the masters' absolute commands are supported; fail rather than silently
# generating different artwork when a designer introduces a new SVG construct.
def dart_path(data):
    tokens = re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?', data)
    commands = {'M':('moveTo',2),'L':('lineTo',2),'V':('lineTo',1),'H':('lineTo',1),'C':('cubicTo',6),'Q':('quadraticBezierTo',4),'Z':('close',0)}
    index = 0
    x = y = '0'
    result = []
    while index < len(tokens):
        command = tokens[index]
        if command not in commands:
            raise ValueError(f'Unsupported master SVG command: {command}')
        method,count = commands[command]
        values = tokens[index+1:index+1+count]
        if len(values) != count: raise ValueError('Incomplete SVG command')
        index += 1+count
        if command == 'H': values = [values[0],y]
        elif command == 'V': values = [x,values[0]]
        if values: x,y = values[-2:]
        result.append(f"    ..{method}({', '.join(values)})")
    return '\n'.join(result)

wordmark = logo.find(f"{S}g[@id='wordmark']")
if wordmark is None: raise ValueError('Missing outlined wordmark')
lettering = ''.join(p.attrib['d'] for p in wordmark.findall(S+'path'))
output = ROOT/'lib/shared/widgets/generated/paths_geometry.dart'
output.parent.mkdir(exist_ok=True)
def transform_values(group):
    transform = group.attrib['transform']
    match = re.fullmatch(r'translate\(([-.\d]+) ([-.\d]+)\) scale\(([-.\d]+)\)', transform)
    if not match: raise ValueError('Unsupported lockup transform')
    return match.groups()

sx,sy,ss = transform_values(logo.find(f"{S}g[@id='symbol']"))
wx,wy,ws = transform_values(wordmark)
output.write_text('// Generated by tools/export_brand.py from assets/brand/source.\n// Outlined Inter lettering retains assets/fonts/Inter-OFL.txt.\nimport \'dart:ui\';\n\n'
    +f'const double pathsSymbolStrokeWidth = {stroke:g};\nconst pathsSymbolOffset = Offset({sx}, {sy});\nconst pathsSymbolScale = {ss};\nconst pathsWordmarkOffset = Offset({wx}, {wy});\nconst pathsWordmarkScale = {ws};\n'
    +'\nPath createPathsRoute() => Path()\n'+dart_path(path_data)+';\n\nPath createPathsLettering() => Path()\n'+dart_path(lettering)+';\n')
subprocess.run(['dart', 'format', str(output)], check=True)
(BRAND/'paths-loader.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><title>Paths loading</title><path d="{path_data}" fill="none" stroke="{INK}" stroke-width="20" stroke-linecap="round" opacity=".22"/><circle r="12" fill="{INK}"><animateMotion dur="1.6s" repeatCount="indefinite" path="{path_data}"/></circle></svg>\n')
admin = ROOT.parent/'paths-admin/public/brand'
for p in BRAND.iterdir():
    if p.is_file() and p.suffix in ['.svg','.png']: shutil.copy2(p,admin/p.name)
favicon = ET.fromstring(colored(symbol, INK))
favicon.insert(0, ET.Element(S+'rect', {'width':'256','height':'256','rx':'56','fill':WHITE}))
(ROOT.parent/'paths-admin/public/favicon.svg').write_text(ET.tostring(favicon, encoding='unicode')+'\n')
icon(180,.82,True).save(ROOT.parent/'paths-admin/public/apple-touch-icon.png',optimize=True)
print('Exported Open P SVG/PNG, native icons/splash and Flutter geometry from the approved masters.')
