#!/bin/bash

echo "🔍 Building debug version with calculation debugging..."

# Clean and get dependencies
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

echo "✅ Debug build complete! APK location:"
echo "📱 build/app/outputs/flutter-apk/app-debug.apk"

echo ""
echo "🧪 Debug Testing Steps:"
echo "1. Install the debug APK"
echo "2. Open app and create new LOT"
echo "3. Enter Patti quantity (e.g., 100)"
echo "4. Enter Patti rate (e.g., 50)"
echo "5. Check console logs for DEBUG messages"
echo "6. Check if Results tab shows calculations"
echo ""
echo "🔍 Watch for these DEBUG messages:"
echo "- MobileStorageService.getDefaults() returned:"
echo "- AdvancedCalculationEngine created:"
echo "- Rate snapshot created:"
echo "- _calculateResults called with:"
echo "- effectiveRates ="
echo "- Calculation result ="
echo "- _buildResultsTab called:"