"""Configure generated Flutter Android runner with SKE label, permissions, minSdk, and launcher icon."""
from pathlib import Path
import re
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ANDROID_DIR = ROOT / "android"
MANIFEST = ANDROID_DIR / "app" / "src" / "main" / "AndroidManifest.xml"
RES_DIR = ANDROID_DIR / "app" / "src" / "main" / "res"
LOGO_SRC = ROOT / "assets" / "ske_logo.webp"

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def update_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")
    if "android.permission.INTERNET" not in text:
        text = text.replace(
            "<application",
            '    <uses-permission android:name="android.permission.INTERNET" />\n\n    <application',
            1,
        )
    text = re.sub(
        r'android:label="[^"]*"',
        'android:label="Sinar Kencana Elektronik"',
        text,
        count=1,
    )
    if "android:usesCleartextTraffic" not in text:
        text = text.replace(
            "<application",
            '<application\n        android:usesCleartextTraffic="true"',
            1,
        )
    MANIFEST.write_text(text, encoding="utf-8")


def update_min_sdk() -> None:
    for name in ("build.gradle", "build.gradle.kts"):
        gradle = ANDROID_DIR / "app" / name
        if not gradle.exists():
            continue
        txt = gradle.read_text(encoding="utf-8")
        txt = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 21", txt)
        txt = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 21", txt)
        gradle.write_text(txt, encoding="utf-8")


def generate_icons() -> None:
    if not LOGO_SRC.exists():
        return
    src = Image.open(LOGO_SRC).convert("RGBA")
    # Remove adaptive icon XMLs if flutter create generated them so PNG launcher icons display cleanly
    anydpi = RES_DIR / "mipmap-anydpi-v26"
    if anydpi.exists():
        shutil.rmtree(anydpi)
    for folder, size in DENSITIES.items():
        out_dir = RES_DIR / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
        inner = max(1, int(size * 0.84))
        resized = src.resize((inner, inner), Image.Resampling.LANCZOS)
        offset = (size - inner) // 2
        canvas.paste(resized, (offset, offset), resized)
        canvas.save(out_dir / "ic_launcher.png", format="PNG")


if __name__ == "__main__":
    update_manifest()
    update_min_sdk()
    generate_icons()
    print("Android runner configured for Sinar Kencana Elektronik.")
