"""Export original Paths artwork using locally available Pillow. No remote assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, shutil
ROOT=Path(__file__).resolve().parents[1]
BLUE='#147DCE'; INK='#101418'; BG='#F5FBFF'
paths=[((32,96),(32,58),(96,70),(96,32)),((32,32),(32,70),(96,58),(96,96))]
def svg(color):
 return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128"><g fill="none" stroke="{color}" stroke-width="12" stroke-linecap="round"><path d="M32 96 C32 58 96 70 96 32"/><path d="M32 32 C32 70 96 58 96 96"/></g></svg>\n'
def symbol(size,color=BLUE,background=None,padding=0):
 scale=4; im=Image.new('RGBA',(size*scale,size*scale),background or (0,0,0,0)); d=ImageDraw.Draw(im)
 factor=size*scale/128
 for curve in paths:
  points=[]
  for i in range(161):
   t=i/160; x=sum([((1-t)**3)*curve[0][0],3*((1-t)**2)*t*curve[1][0],3*(1-t)*(t*t)*curve[2][0],t**3*curve[3][0]])
   y=sum([((1-t)**3)*curve[0][1],3*((1-t)**2)*t*curve[1][1],3*(1-t)*(t*t)*curve[2][1],t**3*curve[3][1]])
   points.append((x*factor,y*factor))
  width=round(12*factor); d.line(points,fill=color,width=width,joint='curve')
  for x,y in [points[0],points[-1]]: d.ellipse((x-width/2,y-width/2,x+width/2,y+width/2),fill=color)
 return im.resize((size,size),Image.Resampling.LANCZOS)
brand=ROOT/'assets/brand'
for name,color in [('paths-symbol',BLUE),('paths-symbol-ink',INK),('paths-symbol-white','#FFFFFF')]:
 (brand/f'{name}.svg').write_text(svg(color)); symbol(512,color).save(brand/f'{name}.png',optimize=True)
# Wordmark uses editable custom geometric lettering, avoiding a font-license dependency.
letters='M155 86 V42 H173 C198 42 198 66 173 66 H155 M211 86 L227 42 L243 86 M217 72 H237 M255 42 H287 M271 42 V86 M300 42 V86 M332 42 V86 M300 64 H332 M376 47 C352 32 341 59 363 64 C389 71 376 96 349 82'
for name,color in [('paths-logo',BLUE),('paths-logo-ink',INK),('paths-logo-white','#FFFFFF')]:
 mark=svg(color).split('<g',1)[1].split('</svg>')[0]
 (brand/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 408 128"><g{mark}<path d="{letters}" fill="none" stroke="{color}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/></svg>\n')
res=ROOT/'android/app/src/main/res'
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 p=res/f'mipmap-{density}'; p.mkdir(parents=True,exist_ok=True); symbol(size,background=BG).save(p/'ic_launcher.png')
# Adaptive foreground geometry stays inside Android's 66/108 safe region.
p=res/'drawable'; p.mkdir(exist_ok=True)
(p/'paths_symbol.xml').write_text('<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="128" android:viewportHeight="128"><path android:pathData="M32,96 C32,58 96,70 96,32 M32,32 C32,70 96,58 96,96" android:strokeColor="#147DCE" android:strokeWidth="12" android:strokeLineCap="round" android:fillColor="@android:color/transparent"/></vector>')
for directory in ['mipmap-anydpi-v26']:
 p=res/directory; p.mkdir(exist_ok=True)
 (p/'ic_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/paths_background"/><foreground android:drawable="@drawable/paths_symbol"/><monochrome android:drawable="@drawable/paths_symbol"/></adaptive-icon>')
icons=ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
contents=json.loads((icons/'Contents.json').read_text())
for item in contents['images']:
 size=round(float(item['size'].split('x')[0])*float(item['scale'][:-1])); symbol(size,background=BG).convert('RGB').save(icons/item['filename'])
launch=ROOT/'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for suffix,size in [('',128),('@2x',256),('@3x',384)]: symbol(size).save(launch/f'LaunchImage{suffix}.png')
for f in brand.glob('*'): shutil.copy2(f,ROOT.parent/'paths-admin/public/brand'/f.name)
print('Exported SVG sources, Android icons, iOS icons and splash symbols.')
