#!/bin/bash

echo "🔍 iOS Device Connection Troubleshooter"
echo "=========================================="
echo ""

DEVICE_ID="00008030-001D18AA14DB802E"

echo "📱 Target Device ID: $DEVICE_ID"
echo ""

# Step 1: Check if device is connected via USB
echo "1️⃣ Checking USB connection..."
if system_profiler SPUSBDataType 2>/dev/null | grep -i "iphone\|ipad" > /dev/null; then
    echo "   ✅ iOS device detected in USB"
else
    echo "   ❌ No iOS device found in USB"
    echo "   → Please check USB cable connection"
    echo "   → Try a different USB port or cable"
fi
echo ""

# Step 2: Check Xcode devices
echo "2️⃣ Checking Xcode devices..."
XCODE_DEVICES=$(xcrun xctrace list devices 2>/dev/null | grep -v "Simulator" | grep -v "MacBook" | grep -v "^==" | grep -v "^$")
if [ -z "$XCODE_DEVICES" ]; then
    echo "   ❌ No physical devices found in Xcode"
    echo "   → Open Xcode and check Window → Devices and Simulators"
    echo "   → Make sure iPhone is unlocked"
    echo "   → Make sure 'Trust This Computer' was tapped"
else
    echo "   ✅ Devices found:"
    echo "$XCODE_DEVICES" | sed 's/^/      /'
fi
echo ""

# Step 3: Check Developer Mode
echo "3️⃣ Developer Mode Status..."
echo "   → On iPhone: Settings → Privacy & Security → Developer Mode"
echo "   → Should be ON (green toggle)"
echo "   → If OFF, turn it ON and restart iPhone"
echo ""

# Step 4: Restart usbmuxd
echo "4️⃣ Restarting usbmuxd service..."
if killall -9 usbmuxd 2>/dev/null; then
    echo "   ✅ usbmuxd restarted"
    echo "   → Please disconnect and reconnect iPhone USB cable"
    sleep 2
else
    echo "   ⚠️ Could not restart usbmuxd (may need sudo)"
fi
echo ""

# Step 5: Check Flutter
echo "5️⃣ Checking Flutter devices..."
flutter devices --device-timeout 30
echo ""

# Step 6: Manual steps
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Manual Steps to Try:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Disconnect iPhone USB cable completely"
echo "2. Wait 5 seconds"
echo "3. Reconnect iPhone USB cable"
echo "4. On iPhone: Unlock the screen"
echo "5. On iPhone: If 'Trust This Computer?' appears → Tap 'Trust'"
echo "6. On iPhone: Settings → Privacy & Security → Developer Mode → ON"
echo "7. Restart iPhone if Developer Mode was just enabled"
echo "8. After restart, enable Developer Mode again (enter passcode)"
echo "9. Open Xcode → Window → Devices and Simulators"
echo "10. Check if iPhone appears there"
echo ""
echo "If iPhone appears in Xcode but not in Flutter:"
echo "  → Run: flutter clean"
echo "  → Run: flutter pub get"
echo "  → Run: flutter devices"
echo ""
echo "If still not working:"
echo "  → Try: flutter run -d $DEVICE_ID (force device ID)"
echo "  → Or use Xcode directly: Press ▶️ in Xcode"
echo ""
