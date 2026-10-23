"""Check actual native logo geometry and Android circular safe areas."""
from pathlib import Path
import math
import re
import unittest
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[2]
A = '{http://schemas.android.com/apk/res/android}'

def points(data):
    tokens = re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?', data)
    x = y = 0.0
    hull = []
    index = 0
    while index < len(tokens):
        command = tokens[index]
        index += 1
        count = {'M': 2, 'V': 1, 'H': 1, 'C': 6}[command]
        values = list(map(float, tokens[index:index + count]))
        index += count
        if command == 'V': y = values[0]
        elif command == 'H': x = values[0]
        else:
            hull.extend(zip(values[::2], values[1::2]))
            x, y = values[-2:]
        hull.append((x, y))
    return hull

class SplashSafeArea(unittest.TestCase):
    def test_native_drawables_use_selected_open_p(self):
        approved = ET.parse(ROOT/'design/logo-refresh/b-open-p-v2.svg').getroot()
        expected = next(e for e in approved if e.tag.endswith('path')).attrib['d']
        normalized = lambda text: re.findall(r'[A-Za-z]|-?\d+(?:\.\d+)?', text)
        for name in ['paths_symbol', 'paths_splash', 'paths_notification']:
            with self.subTest(name=name):
                native = ET.parse(ROOT/f'android/app/src/main/res/drawable/{name}.xml').getroot()
                actual = next(e for e in native.iter() if e.tag == 'path').attrib[A+'pathData']
                self.assertEqual(normalized(actual), normalized(expected))

    def test_entire_mark_fits_both_system_circles(self):
        for name, fraction in [('paths_splash', 1/3), ('paths_symbol', 33/108)]:
            with self.subTest(name=name):
                root = ET.parse(ROOT/f'android/app/src/main/res/drawable/{name}.xml').getroot()
                width = float(root.attrib[A+'viewportWidth'])
                group = root.find('group')
                self.assertIsNotNone(group)
                scale = max(float(group.attrib[A+'scaleX']), float(group.attrib[A+'scaleY']))
                path = group.find('path')
                extent = max(math.hypot(x-width/2, y-width/2) for x,y in points(path.attrib[A+'pathData']))
                extent += float(path.attrib[A+'strokeWidth'])/2
                self.assertLessEqual(extent*scale, width*fraction)
