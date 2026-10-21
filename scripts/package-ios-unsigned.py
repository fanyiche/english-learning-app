#!/usr/bin/env python3
"""Package an Xcode iphoneos .app for later personal re-signing, never a simulator build."""
import argparse
import os
from pathlib import Path
import plistlib
import stat
import zipfile


def package_app(app: Path, output: Path) -> None:
    app = app.resolve()
    if app.suffix != '.app' or not app.is_dir():
        raise ValueError('Expected an existing .app directory')
    with (app / 'Info.plist').open('rb') as stream:
        info = plistlib.load(stream)
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
        raise ValueError('Only an iPhoneOS device build can be packaged; simulator apps cannot be installed on iPhone')
    executable = info.get('CFBundleExecutable')
    if not isinstance(executable, str) or Path(executable).name != executable or not (app / executable).is_file():
        raise ValueError('Missing or invalid app executable')
    if not info.get('CFBundleIdentifier'):
        raise ValueError('Missing bundle identifier')
    output = output.resolve()
    if output.is_relative_to(app):
        raise ValueError('Output must be outside the application bundle')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(app.rglob('*')):
            archive_path = (Path('Payload') / app.name / path.relative_to(app)).as_posix()
            if path.is_symlink():
                # Preserve framework symlinks instead of copying their targets.
                entry = zipfile.ZipInfo(archive_path)
                entry.create_system = 3
                entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(entry, os.readlink(path))
            elif path.is_file():
                archive.write(path, archive_path)
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise ValueError('IPA checksum verification failed')
        assert f'Payload/{app.name}/Info.plist' in archive.namelist()
    print(f'Created unsigned device IPA: {output.name}. It must be personally signed before installation.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    package_app(args.app, args.output)
