#!/bin/sh

# Xcode Cloud build script for Flutter iOS projects
# This script runs after the repository is cloned

set -e

echo "🚀 Starting Xcode Cloud Flutter setup..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "📱 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> $HOME/.zshrc
fi

# Add Flutter to PATH for this session
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Configure Flutter for iOS
echo "⚙️ Configuring Flutter..."
flutter config --enable-ios

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate necessary files
echo "🔧 Generating Flutter configurations..."
flutter build ios --config-only

# Navigate to iOS directory
cd ios

# Clean and reinstall Pods
echo "🧹 Cleaning existing Pods..."
rm -rf Pods
rm -rf Podfile.lock

# Install/update CocoaPods if needed
echo "📋 Setting up CocoaPods..."
sudo gem install cocoapods --no-document

# Install Pods
echo "🍃 Installing CocoaPods dependencies..."
pod install --repo-update

echo "✅ Xcode Cloud Flutter setup completed successfully!" 