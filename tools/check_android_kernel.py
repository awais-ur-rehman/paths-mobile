"""Check that an Android debug APK contains the compiler's exact Dart bundle."""
import argparse
import hashlib
from pathlib import Path
import re
from zipfile import BadZipFile, ZipFile


def verify(root: Path, apk: Path) -> tuple[int, str]:
    intermediate = root / 'build/app/intermediates/flutter/debug'
    build_id = (intermediate / '.last_build_id').read_text().strip()
    if not re.fullmatch(r'[a-f0-9]{32}', build_id):
        raise ValueError('Invalid Flutter build ID; rebuild Android before checking.')
    source = root / '.dart_tool/flutter_build' / build_id / 'app.dill'
    with source.open('rb') as stream:
        if stream.read(4) != bytes.fromhex('90abcdef'):
            raise ValueError('Compiler output is not a Dart kernel; rebuild Android.')
        stream.seek(0)
        expected = fingerprint(stream)
    with (intermediate / 'flutter_assets/kernel_blob.bin').open('rb') as stream:
        staged = fingerprint(stream)
    with ZipFile(apk) as bundle, bundle.open('assets/flutter_assets/kernel_blob.bin') as stream:
        packaged = fingerprint(stream)
    for label, actual in [('staged bundle', staged), ('APK bundle', packaged)]:
        if actual != expected:
            raise ValueError(f'{label} differs from compiler output. Clear generated Android build files and rebuild; do not install this APK.')
    return expected


def fingerprint(stream) -> tuple[int, str]:
    digest = hashlib.sha256()
    size = 0
    while chunk := stream.read(1024 * 1024):
        size += len(chunk)
        digest.update(chunk)
    return size, digest.hexdigest()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    apk = args.apk or root / 'build/app/outputs/flutter-apk/app-debug.apk'
    try:
        size, digest = verify(root, apk)
    except (OSError, ValueError, KeyError, BadZipFile) as error:
        parser.exit(1, f'Android kernel check failed: {error}\n')
    print(f'Verified Android debug kernel matches compiler output: {size} bytes; SHA256 {digest}')
