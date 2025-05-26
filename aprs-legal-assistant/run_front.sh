#!/bin/bash
# run_front.sh - Builds and serves the Flutter web frontend

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to Flutter project
cd "$SCRIPT_DIR/frontend/flutter_app"

# Check for Flutter CLI
echo "[INFO] Checking for Flutter CLI..."
if ! command -v flutter &> /dev/null; then
    echo "[ERROR] Flutter CLI not found. Install Flutter SDK to build frontend."
    exit 1
fi

# Get dependencies and build web
echo "[INFO] Fetching dependencies..."
flutter pub get || exit 1

echo "[INFO] Building Flutter web (release)..."
flutter build web --release || exit 1

# Serve the built web app
cd build/web

echo "[INFO] Serving Flutter web app on port 8080..."
exec python3 -m http.server 8080
