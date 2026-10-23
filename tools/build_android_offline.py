"""Build a debug APK with explicit app configuration and cached Gradle artifacts."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--gradle', default=os.environ.get('GRADLE_OFFLINE_BIN'))
parser.add_argument('--defines-from-file', action='append', default=[])
parser.add_argument('--api-origin')
args = parser.parse_args()
if not args.gradle or not Path(args.gradle).is_file():
    parser.error('Set GRADLE_OFFLINE_BIN or --gradle to an existing Gradle executable.')
defines = {}
for name in args.defines_from_file:
    value = json.loads(Path(name).read_text())
    if not isinstance(value, dict) or any(not isinstance(k, str) or not isinstance(v, (str, bool, int, float)) for k, v in value.items()):
        parser.error('Dart defines must be a JSON object of scalar values.')
    defines.update(value)
if args.api_origin:
    defines['PATHS_API_ORIGIN'] = args.api_origin
if not defines.get('PATHS_API_ORIGIN'):
    parser.error('Supply --api-origin or PATHS_API_ORIGIN in a local defines file.')
encoded = ','.join(base64.b64encode((key+'='+str(value).lower() if isinstance(value, bool) else key+'='+str(value)).encode()).decode() for key, value in defines.items())
root = Path(__file__).resolve().parents[1]
# Never print the defines: local files may also contain private service options.
result = subprocess.run([str(Path(args.gradle).resolve()), '--offline', '--no-daemon',
    '-Pandroid.builder.sdkDownload=false', '-I', '../tools/offline-android.init.gradle',
    '-Ptarget=lib/main.dart', '-Pdart-defines='+encoded, ':app:assembleDebug'],
    cwd=root/'android', check=False)
if result.returncode:
    parser.exit(result.returncode, 'Android build failed; app configuration omitted. See Gradle output above.\n')
