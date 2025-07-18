#!/bin/bash

echo "🚀 Building Chemical Process Tracker APK..."

# Clean and build
flutter clean
flutter pub get
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "🔧 Key fixes in this build:"
    echo "- FIXED: Calculation engine failure for new LOTs"
    echo "- FIXED: ConfigurableDefaults initialization"
    echo "- FIXED: Rate snapshot system with fallback"
    echo "- FIXED: Analytics protip design improvement"
    echo ""
    echo "🧪 Test these scenarios:"
    echo "1. Create new LOT → Enter Patti 100kg @ ₹50/kg → Check Results tab"
    echo "2. Enter PD quantity → Check efficiency color coding"
    echo "3. Check Materials tab for calculated rates"
    echo "4. Check Analytics tab for improved protip design"
else
    echo "❌ Build failed!"
    exit 1
fi