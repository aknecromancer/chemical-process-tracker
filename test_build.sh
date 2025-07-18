#!/bin/bash

echo "🔧 Testing compilation fixes..."

# Clean and get dependencies
flutter clean
flutter pub get

# Try to compile (but don't build APK yet)
flutter analyze

if [ $? -eq 0 ]; then
    echo "✅ Code analysis passed!"
    
    # Test build
    flutter build apk --debug
    
    if [ $? -eq 0 ]; then
        echo "✅ Compilation successful!"
        echo "📱 Debug APK created successfully"
    else
        echo "❌ Build failed"
        exit 1
    fi
else
    echo "❌ Code analysis failed"
    exit 1
fi