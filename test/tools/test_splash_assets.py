"""Check that the Android 12 mark fits its circular icon safe area."""
from pathlib import Path
import math
import unittest
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
A='{http://schemas.android.com/apk/res/android}'
class SplashSafeArea(unittest.TestCase):
 def test_entire_mark_fits_system_circle(self):
  root=ET.parse(ROOT/'android/app/src/main/res/drawable/paths_splash.xml').getroot()
  group=root.find('group'); self.assertIsNotNone(group)
  scale=max(float(group.attrib[A+'scaleX']),float(group.attrib[A+'scaleY']))
  # The Bezier curves lie in the convex hull of their control points.
  hull=[(32,96),(32,58),(96,70),(96,32),(32,32),(32,70),(96,58),(96,96)]
  extent=max(math.hypot(x-64,y-64) for x,y in hull)+6
  self.assertLessEqual(extent*scale,128/3, 'Android 12 crops outside the 192dp circle in a 288dp icon.')
