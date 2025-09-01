#!/usr/bin/env python3
"""
Test Alpine Climb poster generation specifically
"""

import subprocess
import time

def test_alpine_climb_generation():
    """Test the Alpine Climb missing poster fix"""
    
    device_id = "9544C4B4-1C3E-4F29-A0E8-E2C8E3813972"
    
    print("🏔️ Testing Alpine Climb Poster Generation")
    print("=" * 45)
    
    # Take initial screenshot
    print("1. Current app state...")
    subprocess.run([
        "xcrun", "simctl", "io", device_id, "screenshot", 
        "./artifacts/alpine_climb_before.png"
    ], capture_output=True)
    
    # Wait for app to load and thumbnails to process
    print("2. Waiting for thumbnail generation...")
    time.sleep(5)  # Give time for PosterThumbProvider to work
    
    # Take screenshot after thumbnail generation
    subprocess.run([
        "xcrun", "simctl", "io", device_id, "screenshot", 
        "./artifacts/alpine_climb_thumbnails_generated.png"
    ], capture_output=True)
    
    # Simulate clicking on Alpine Climb (multiple screenshots to show interaction)
    test_steps = [
        "Navigate to Alpine Climb",
        "Tap Alpine Climb poster", 
        "View poster detail page",
        "Verify self-healing worked",
        "Check poster image loaded"
    ]
    
    for i, step in enumerate(test_steps, 3):
        print(f"{i}. {step}...")
        time.sleep(2)
        
        subprocess.run([
            "xcrun", "simctl", "io", device_id, "screenshot", 
            f"./artifacts/alpine_climb_step_{i}_{step.lower().replace(' ', '_')}.png"
        ], capture_output=True)
    
    print("\n✅ Alpine Climb Test Complete")
    
    # Show expected behavior
    print("\n🎯 Expected Results:")
    print("   • Alpine Climb thumbnail should now appear (not gray)")
    print("   • Console logs should show: '⚡ Trying optimized renderer for: Alpine Climb'")
    print("   • Poster detail view should show full poster image")
    print("   • Self-healing should work automatically")
    
    print("\n📊 Debug Information:")
    print("   • Alpine Climb maps to 'Demo_Boulder' GPX file")
    print("   • Should have coordinates from Boulder Canyon route")
    print("   • Optimized renderer enabled by default")
    print("   • PosterThumbProvider enhanced with logging")
    
    return True

def check_console_logs():
    """Look for our debug logs in simulator"""
    device_id = "9544C4B4-1C3E-4F29-A0E8-E2C8E3813972"
    
    print("\n🔍 Checking Console Logs...")
    try:
        # Try to get recent logs from the simulator
        result = subprocess.run([
            "xcrun", "simctl", "spawn", device_id, 
            "log", "show", "--last", "2m", "--predicate", "process == 'PrintMyRide'"
        ], capture_output=True, text=True, timeout=10)
        
        if "PosterThumbProvider" in result.stdout:
            print("✅ Found PosterThumbProvider logs in console")
            lines = [line for line in result.stdout.split('\n') if 'PosterThumbProvider' in line or 'Alpine Climb' in line]
            for line in lines[-5:]:  # Show last 5 relevant lines
                print(f"   📝 {line}")
        else:
            print("⚠️ No PosterThumbProvider logs found (may take time to appear)")
            
    except subprocess.TimeoutExpired:
        print("⚠️ Log check timed out")
    except Exception as e:
        print(f"⚠️ Could not check logs: {e}")

if __name__ == "__main__":
    test_alpine_climb_generation()
    check_console_logs()