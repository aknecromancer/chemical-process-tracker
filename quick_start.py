#!/usr/bin/env python3
"""
🚀 Chemical Process Tracker - Quick Start
"""

import os
import subprocess
import socket
from pathlib import Path

def find_free_port(start_port=8080):
    """Find an available port starting from start_port"""
    for port in range(start_port, start_port + 20):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', port))
            sock.close()
            return port
        except OSError:
            continue
    return None

def main():
    # Set working directory
    project_dir = Path(__file__).parent
    os.chdir(project_dir)
    
    print("🚀 Chemical Process Tracker - Quick Setup")
    print("=" * 50)
    
    # Check if build exists
    web_dir = project_dir / "build" / "web"
    if not web_dir.exists() or not (web_dir / "index.html").exists():
        print("🔧 Building web version (this may take a moment)...")
        result = subprocess.run("flutter build web", shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Build failed: {result.stderr}")
            return
        print("✅ Build completed!")
    else:
        print("✅ Web build already exists!")
    
    # Find available port
    port = find_free_port(8080)
    if port is None:
        print("❌ No available ports found")
        return
        
    url = f"http://localhost:{port}"
    
    print(f"""
🎉 SUCCESS! Your Chemical Process Tracker is ready!

📍 NEXT STEPS:
1. Open a NEW terminal window
2. Run this command:
   cd /Users/aknecromancer/CursorProjects/chemical_process_tracker/build/web && python3 -m http.server {port}

3. Open your browser and go to: {url}

🧪 TESTING CHECKLIST:
✅ Create a batch
✅ Enter Patti: 1000kg @ ₹50/kg  
✅ See auto-calculations for Nitric & HCL
✅ Add PD: 45kg @ ₹2000/kg
✅ Check Results tab for P&L

💡 The app now has your exact Excel formulas implemented!
""")

if __name__ == "__main__":
    main()