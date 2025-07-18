#!/bin/bash

echo "🔄 Rebuilding Chemical Process Tracker with latest LOT improvements..."

# Clean previous build
echo "1. Cleaning previous build..."
flutter clean

# Get dependencies
echo "2. Getting dependencies..."
flutter pub get

# Build release APK
echo "3. Building release APK..."
flutter build apk --release

echo "✅ Build complete! APK location:"
echo "📱 build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "🧪 Testing Checklist:"
echo "- [ ] Can edit LOT number in LOT entry screen"
echo "- [ ] HCl/Nitric automatically calculated from patti input"
echo "- [ ] LOT number saves when editing"
echo "- [ ] Analytics show LOTs by completion date"
echo "- [ ] LOT status workflow (Draft → Progress → Complete)"