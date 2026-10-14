#!/bin/zsh
# Собирает приложение и открывает его в симуляторе айфона.
set -e
cd "$(dirname "$0")"
export PATH="$HOME/development/flutter/bin:$PATH"
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
SIM="iPhone 16"

xcrun simctl boot "$SIM" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$SIM" >/dev/null
flutter build ios --simulator --debug
xcrun simctl terminate "$SIM" com.kapiras.kapiras 2>/dev/null || true
xcrun simctl install "$SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$SIM" com.kapiras.kapiras
