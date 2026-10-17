from pathlib import Path
import importlib.util
import tempfile
import unittest
from zipfile import ZipFile

spec = importlib.util.spec_from_file_location('android_kernel', Path(__file__).resolve().parents[2] / 'tools/check_android_kernel.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class AndroidKernelTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='paths-kernel-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.stage = self.root / 'build/app/intermediates/flutter/debug'
        (self.stage / 'flutter_assets').mkdir(parents=True)
        self.build_id = 'a' * 32
        (self.stage / '.last_build_id').write_text(self.build_id)
        source = self.root / '.dart_tool/flutter_build' / self.build_id
        source.mkdir(parents=True)
        self.kernel = bytes.fromhex('90abcdef') + b'compiler fixture with nonzero trailer'
        (source / 'app.dill').write_bytes(self.kernel)
        self.staged = self.stage / 'flutter_assets/kernel_blob.bin'
        self.staged.write_bytes(self.kernel)
        self.apk = self.root / 'app.apk'
        self.package(self.kernel)

    def package(self, data):
        with ZipFile(self.apk, 'w') as bundle:
            bundle.writestr('assets/flutter_assets/kernel_blob.bin', data)

    def test_exact_compiler_output_passes(self):
        self.assertEqual(checker.verify(self.root, self.apk)[0], len(self.kernel))

    def test_zero_padding_in_packaged_kernel_is_rejected(self):
        self.package(self.kernel + bytes(64))
        with self.assertRaisesRegex(ValueError, 'APK bundle differs'):
            checker.verify(self.root, self.apk)

    def test_corrupt_staging_and_apk_cannot_validate_each_other(self):
        corrupt = self.kernel[:-8] + bytes(8)
        self.staged.write_bytes(corrupt)
        self.package(corrupt)
        with self.assertRaisesRegex(ValueError, 'staged bundle differs'):
            checker.verify(self.root, self.apk)

    def test_build_id_cannot_escape_compiler_cache(self):
        (self.stage / '.last_build_id').write_text('../../other')
        with self.assertRaisesRegex(ValueError, 'Invalid Flutter build ID'):
            checker.verify(self.root, self.apk)
