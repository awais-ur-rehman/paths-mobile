"""A failed native build must not echo app defines from the child argv."""
from pathlib import Path
import base64
import json
import subprocess
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[2]
class BuildFailurePrivacy(unittest.TestCase):
 def test_failed_gradle_hides_local_defines(self):
  with tempfile.TemporaryDirectory(prefix='paths-build-failure-') as temp:
   directory=Path(temp)
   gradle=directory/'gradle'
   gradle.write_text('#!/bin/sh\nexit 7\n');gradle.chmod(0o700)
   private='private-fixture-never-print'
   defines=directory/'defines.json'
   defines.write_text(json.dumps({'PATHS_API_ORIGIN':'http://127.0.0.1:8080','PRIVATE_FIXTURE':private}))
   result=subprocess.run(['python3',str(ROOT/'tools/build_android_offline.py'),'--gradle',str(gradle),'--defines-from-file',str(defines)],capture_output=True,text=True)
   self.assertNotIn(private,result.stdout+result.stderr)
   encoded=base64.b64encode(f'PRIVATE_FIXTURE={private}'.encode()).decode()
   self.assertNotIn(encoded,result.stdout+result.stderr)
   self.assertEqual(result.returncode,7)
