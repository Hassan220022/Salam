#!/bin/sh

# Xcode Cloud pre-build script for Flutter iOS projects
# This script runs just before Xcode starts building

set -e

echo "🔧 Pre-build setup for Xcode Cloud..."

# Ensure Flutter is in PATH
export PATH="$PATH:$HOME/flutter/bin"

# Verify we're in the right directory
echo "📍 Current directory: $(pwd)"

# Ensure Flutter configurations are generated
echo "⚙️ Ensuring Flutter configurations..."
flutter build ios --config-only --no-codesign

# Verify required files exist
echo "🔍 Verifying required files..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Generated.xcconfig not found! Creating it..."
    flutter build ios --config-only --no-codesign
fi

if [ ! -f "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-output-files.xcfilelist" ]; then
    echo "❌ CocoaPods files missing! Reinstalling..."
    cd ios
    pod install --repo-update
    cd ..
fi

echo "✅ Pre-build setup completed!" 