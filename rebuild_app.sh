#!/bin/bash

echo "🔄 Rebuilding Chemical Process Tracker with latest LOT bug fixes..."

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
echo "🔧 Critical Fixes in this build:"
echo "- [✓] CRITICAL: FIXED calculation engine failure for new LOTs"
echo "- [✓] CRITICAL: FIXED ConfigurableDefaults initialization with proper parameters"
echo "- [✓] CRITICAL: FIXED rate snapshot system with fallback to defaults"
echo "- [✓] CRITICAL: Patti price now reflects in materials/results"
echo "- [✓] CRITICAL: PD rate changes now affect P&L calculations"
echo "- [✓] CRITICAL: PD efficiency shows correct color coding"
echo "- [✓] CRITICAL: Default configuration created when none exists"
echo "- [✓] FIXED: Delete button now shows for all LOT statuses (not just draft)"
echo "- [✓] FIXED: PD quantity now displays 3 decimal places in cost breakdown"
echo "- [✓] FIXED: Auto-save on navigation to prevent data loss"
echo "- [✓] FIXED: Different delete confirmation messages based on LOT status"
echo "- [✓] FIXED: Save button always shows success message"
echo "- [✓] FIXED: Rate independence - LOT-specific rates vs default rates"
echo "- [✓] FIXED: Custom rates override LOT snapshot rates"
echo "- [✓] FIXED: Historical LOTs now immune to default rate changes"
echo "- [✓] DESIGN: Improved analytics protip with better alignment and premium design"

echo ""
echo "🧪 Testing Checklist:"
echo "- [ ] CRITICAL: NEW LOT - Patti price changes reflect in materials/results"
echo "- [ ] CRITICAL: NEW LOT - PD quantity changes affect efficiency calculation"
echo "- [ ] CRITICAL: NEW LOT - PD rate changes affect P&L calculation"
echo "- [ ] CRITICAL: NEW LOT - Materials tab shows correct calculated quantities"
echo "- [ ] CRITICAL: NEW LOT - Results tab shows correct P&L and cost breakdown"
echo "- [ ] CRITICAL: EXISTING LOT - Uses rate snapshot for calculations"
echo "- [ ] CRITICAL: CUSTOM RATES - LOT-specific rate changes override defaults"
echo "- [ ] Materials tab retains data after navigation"
echo "- [ ] Manual entries persist after navigation"
echo "- [ ] Delete button works for all LOT statuses"
echo "- [ ] PD quantity shows 3 decimal places in cost breakdown"
echo "- [ ] Auto-save works when navigating away"
echo "- [ ] Save button always shows success message"
echo "- [ ] PD efficiency shows correct color based on actual P&L"