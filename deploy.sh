#!/bin/bash

# Chemical Process Tracker - Deployment Script
# Phase 2 Production Build

echo "🚀 Building Chemical Process Tracker for Production..."

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web production
echo "🔨 Building for web (production)..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📂 Output directory: build/web"
    echo ""
    echo "🌐 Ready for deployment!"
    echo "   - Netlify: Connect your repo and auto-deploy"
    echo "   - Manual: Upload build/web folder to your web server"
    echo ""
    echo "🔍 Build stats:"
    du -sh build/web
    echo "📁 Files in build/web:"
    ls -la build/web/
else
    echo "❌ Build failed!"
    exit 1
fi