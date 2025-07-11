#!/usr/bin/env python3
"""
🚀 Chemical Process Tracker - Easy Startup Script
Run this to automatically build and serve your Flutter web app
"""

import os
import subprocess
import sys
import time
import webbrowser
import socket
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"🔧 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed:")
        print(f"Error: {e.stderr}")
        return False

def find_free_port(start_port=8080):
    """Find an available port starting from start_port"""
    for port in range(start_port, start_port + 100):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', port))
            sock.close()
            return port
        except OSError:
            continue
    return None

def main():
    print("🚀 Chemical Process Tracker - Automated Setup")
    print("=" * 50)
    
    # Set working directory
    project_dir = Path(__file__).parent
    os.chdir(project_dir)
    print(f"📁 Working directory: {project_dir}")
    
    # Step 1: Flutter pub get
    if not run_command("flutter pub get", "Getting Flutter dependencies"):
        print("💡 Please ensure Flutter is installed and in your PATH")
        return
    
    # Step 2: Build web
    if not run_command("flutter build web", "Building web version"):
        print("💡 Please check for any compilation errors above")
        return
        
    # Step 3: Check if build was successful
    web_dir = project_dir / "build" / "web"
    if not web_dir.exists() or not (web_dir / "index.html").exists():
        print("❌ Web build failed - index.html not found")
        return
        
    print("✅ Web build successful!")
    print("")
    
    # Step 4: Find available port and start web server
    port = find_free_port(8080)
    if port is None:
        print("❌ Could not find an available port. Please close other applications and try again.")
        return
        
    os.chdir(web_dir)
    url = f"http://localhost:{port}"
    print(f"🌐 Starting web server on {url}")
    print("🔗 Opening browser in 3 seconds...")
    print("💡 Press Ctrl+C to stop the server")
    print("")
    
    # Open browser after a short delay
    def open_browser():
        time.sleep(3)
        webbrowser.open(url)
    
    import threading
    browser_thread = threading.Thread(target=open_browser)
    browser_thread.daemon = True
    browser_thread.start()
    
    # Start server
    try:
        subprocess.run([sys.executable, "-m", "http.server", str(port)], check=True)
    except KeyboardInterrupt:
        print("\n👋 Server stopped. Thank you for testing!")
    except Exception as e:
        print(f"❌ Server error: {e}")

if __name__ == "__main__":
    main()