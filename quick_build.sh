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
    echo "- FIXED: Default rate changes no longer affect historical LOTs"
    echo "- FIXED: LOT-specific price changes now reliable with success messages"
    echo "- FIXED: PD Efficiency now shows 4 decimal places everywhere"
    echo "- FIXED: Default rate changes truly no longer affect historical LOTs"
    echo "- FIXED: Manual entries now save immediately and persist correctly"
    echo "- FIXED: Materials tab now shows correct frozen rates (not current defaults)"
    echo ""
    echo "🧪 Test these scenarios:"
    echo "1. Create new LOT → Enter Patti 100kg @ ₹50/kg → Check Results tab"
    echo "2. Enter PD quantity → Check efficiency shows 4 decimal places"
    echo "3. Edit LOT-specific rates → Should show success message"
    echo "4. Change default rates in Settings → Should NOT affect existing LOTs"
    echo "5. Check Materials tab → Should show same rates as Results tab"
    echo "6. Add manual entry → Should save immediately and persist"
    echo "7. Check Analytics tab for improved protip design"
else
    echo "❌ Build failed!"
    exit 1
fi