"""Apply the checked-in Firebase client to Flutter's generated Android project."""
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'config/firebase/google-services.json'
PACKAGE = 'com.talib.app'
PLUGIN = '4.4.4'


def configure(root=ROOT):
    config = root / 'config/firebase/google-services.json'
    data = json.loads(config.read_text())
    clients = [c for c in data['client'] if c['client_info']['android_client_info']['package_name'] == PACKAGE]
    if len(clients) != 1:
        raise ValueError('Firebase configuration must contain exactly one com.talib.app client')
    app = root / 'android/app'
    settings = root / 'android/settings.gradle.kts'
    gradle = app / 'build.gradle.kts'
    if not settings.exists() or not gradle.exists():
        raise FileNotFoundError('Generate Android with Flutter before running this script')
    source = gradle.read_text()
    for field in ('namespace', 'applicationId'):
        source, count = re.subn(rf'\b{field}\s*=\s*"[^"]+"', f'{field} = "{PACKAGE}"', source)
        if count != 1:
            raise ValueError(f'Expected one {field} in generated Android Gradle file')
    if 'id("com.google.gms.google-services")' not in source:
        source = source.replace('plugins {', 'plugins {\n    id("com.google.gms.google-services")', 1)
    gradle.write_text(source)
    source = settings.read_text()
    if 'id("com.google.gms.google-services")' not in source:
        source = source.replace('plugins {', f'plugins {{\n    id("com.google.gms.google-services") version "{PLUGIN}" apply false', 1)
    settings.write_text(source)
    activities = list((app / 'src/main/kotlin').rglob('MainActivity.kt'))
    if len(activities) != 1:
        raise ValueError('Expected one generated Kotlin MainActivity')
    activity = activities[0]
    source = re.sub(r'^package\s+[^\n]+', f'package {PACKAGE}', activity.read_text(), count=1, flags=re.M)
    target = app / 'src/main/kotlin' / PACKAGE.replace('.', '/') / 'MainActivity.kt'
    target.parent.mkdir(parents=True, exist_ok=True)
    if activity != target:
        activity.unlink()
    target.write_text(source)
    manifest = app / 'src/main/AndroidManifest.xml'
    source = manifest.read_text()
    source = re.sub(r'android:label="[^"]+"', 'android:label="Talib"', source, count=1)
    if 'android.permission.INTERNET' not in source:
        source = re.sub(r'(<manifest\b[^>]*>)', r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', source, count=1)
    manifest.write_text(source)
    shutil.copyfile(config, app / 'google-services.json')
    print(f'Configured Android {PACKAGE} for Firebase {data["project_info"]["project_id"]}')


if __name__ == '__main__':
    configure()
