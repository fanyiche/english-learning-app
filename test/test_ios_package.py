"""Packaging contract tests using fixtures, not real compiled iPhone applications."""
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('ios_packager', Path(__file__).parents[1] / 'scripts/package-ios-unsigned.py')
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.app = self.root / 'Garden.app'
        self.app.mkdir()
        self.output = self.root / 'Garden.ipa'

    def app_fixture(self, platform):
        (self.app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleSupportedPlatforms': [platform], 'CFBundleExecutable': 'Garden', 'CFBundleIdentifier': 'test.fixture.Garden'}))
        (self.app / 'Garden').write_bytes(b'packaging-fixture-not-a-MachO-binary')
        (self.app / 'Garden').chmod(0o755)

    def test_reject_simulator(self):
        self.app_fixture('iPhoneSimulator')
        with self.assertRaisesRegex(ValueError, 'simulator'):
            packager.package_app(self.app, self.output)
        self.assertFalse(self.output.exists())

    def test_payload_layout_contents_and_permissions(self):
        self.app_fixture('iPhoneOS')
        (self.app / 'careers.json').write_text('["fixture"]')
        (self.app / 'alias').symlink_to('careers.json')
        packager.package_app(self.app, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertEqual(archive.read('Payload/Garden.app/careers.json'), b'["fixture"]')
            self.assertEqual(archive.read('Payload/Garden.app/alias'), b'careers.json')
            self.assertIsNone(archive.testzip())
            self.assertTrue(archive.getinfo('Payload/Garden.app/Garden').external_attr >> 16 & 0o100)
            self.assertTrue(all(path.startswith('Payload/Garden.app/') for path in archive.namelist()))

    def test_reject_missing_executable(self):
        self.app_fixture('iPhoneOS')
        (self.app / 'Garden').unlink()
        with self.assertRaisesRegex(ValueError, 'executable'):
            packager.package_app(self.app, self.output)


if __name__ == '__main__':
    unittest.main()
