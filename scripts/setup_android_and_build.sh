#!/usr/bin/env bash
# setup_android_and_build.sh
# Sets up Android SDK + JDK (no sudo required) and builds the release APK.
#
# Prerequisites (must be done once by the user):
#   sudo apt-get install openjdk-17-jdk
#   (OR let this script download a standalone JDK to ~/jdk17 — slow on low-bandwidth)
#
# Usage:
#   bash scripts/setup_android_and_build.sh
#   bash scripts/setup_android_and_build.sh --split-per-abi
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANDROID_SDK_HOME="$HOME/android-sdk"
FLUTTER_BIN="$HOME/flutter/bin"
SPLIT_ABI="${1:-}"

# ── 1. Locate Java ─────────────────────────────────────────────────────────
find_java() {
  for candidate in \
    "$(which java 2>/dev/null)" \
    "$JAVA_HOME/bin/java" \
    /usr/lib/jvm/java-17-openjdk-amd64/bin/java \
    /usr/lib/jvm/java-17-openjdk-amd64/jre/bin/java \
    "$HOME/jdk17/bin/java"; do
    [ -x "$candidate" ] && echo "$candidate" && return 0
  done
  return 1
}

JAVA_BIN=$(find_java || true)
if [ -z "$JAVA_BIN" ]; then
  echo ""
  echo "ERROR: Java not found. Run one of:"
  echo "  sudo apt-get install openjdk-17-jdk"
  echo ""
  echo "  OR let this script download a standalone JDK (slow, ~185MB):"
  echo "  wget -q https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz -O /tmp/jdk17.tar.gz"
  echo "  mkdir -p \$HOME/jdk17 && tar xzf /tmp/jdk17.tar.gz -C \$HOME/jdk17 --strip-components=1"
  echo ""
  exit 1
fi

JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
export JAVA_HOME
echo "Using Java: $JAVA_BIN (JAVA_HOME=$JAVA_HOME)"
"$JAVA_BIN" -version 2>&1 | head -1

# ── 2. Android cmdline-tools ───────────────────────────────────────────────
if [ ! -f "$ANDROID_SDK_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo ""
  CMDLINE_ZIP="/tmp/android-cmdline-tools.zip"
  if [ ! -f "$CMDLINE_ZIP" ] || [ "$(stat -c%s "$CMDLINE_ZIP" 2>/dev/null || echo 0)" -lt 100000000 ]; then
    echo "Downloading Android cmdline-tools (~133MB)..."
    wget -q --show-progress \
      "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
      -O "$CMDLINE_ZIP"
  fi
  echo "Extracting cmdline-tools..."
  mkdir -p "$ANDROID_SDK_HOME/cmdline-tools"
  TMP_EXTRACT=$(mktemp -d)
  unzip -q "$CMDLINE_ZIP" -d "$TMP_EXTRACT"
  mv "$TMP_EXTRACT/cmdline-tools" "$ANDROID_SDK_HOME/cmdline-tools/latest"
  rm -rf "$TMP_EXTRACT"
fi

export ANDROID_HOME="$ANDROID_SDK_HOME"
export PATH="$ANDROID_SDK_HOME/cmdline-tools/latest/bin:$ANDROID_SDK_HOME/platform-tools:$PATH"
echo "Android SDK: $ANDROID_HOME"

# ── 3. Install required SDK packages ───────────────────────────────────────
echo ""
echo "Installing Android SDK packages (first run downloads NDK ~1.5GB)..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager \
  "platform-tools" \
  "build-tools;36.0.0" \
  "platforms;android-36" \
  "ndk;28.2.13676358" \
  "cmake;3.22.1"

# ── 4. Configure Flutter ───────────────────────────────────────────────────
export PATH="$FLUTTER_BIN:$PATH"
flutter config --android-sdk "$ANDROID_SDK_HOME"
flutter doctor --android-licenses || true

# ── 5. Build ───────────────────────────────────────────────────────────────
echo ""
echo "Building release APK..."
cd "$PROJECT_ROOT"
flutter pub get

if [ "$SPLIT_ABI" = "--split-per-abi" ]; then
  flutter build apk --release --split-per-abi 2>&1 | tee /tmp/flutter_build.log
  echo ""
  echo "=== Split APKs built ==="
  ls -lh build/app/outputs/flutter-apk/
  echo ""
  echo "Install the arm64-v8a APK on your Pixel 7:"
  echo "  adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
else
  flutter build apk --release 2>&1 | tee /tmp/flutter_build.log
  echo ""
  echo "=== Universal APK built ==="
  ls -lh build/app/outputs/flutter-apk/app-release.apk
  echo ""
  echo "Install on your Pixel 7:"
  echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
fi
