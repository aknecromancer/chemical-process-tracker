#!/bin/bash

echo "🚀 Starting Chemical Process Tracker Web Setup..."
echo ""

# Navigate to project directory
cd /Users/aknecromancer/CursorProjects/chemical_process_tracker

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo ""
echo "🔧 Building web version..."
flutter build web

echo ""
echo "🌐 Starting web server..."
echo "📱 Your Chemical Process Tracker will be available at:"
echo "🔗 http://localhost:8080"
echo ""
echo "💡 To stop the server, press Ctrl+C"
echo ""

# Start web server
cd build/web
python3 -m http.server 8080