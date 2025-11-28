#!/bin/bash

# Script to help set up Android device for Flutter development

echo "=========================================="
echo "Android Device Setup Guide"
echo "=========================================="
echo ""

echo "STEP 1: Enable Developer Options on Samsung Device"
echo "----------------------------------------"
echo "1. Open Settings > About phone"
echo "2. Find 'Build number' and tap it 7 times"
echo "3. You'll see 'You are now a developer!' message"
echo ""

echo "STEP 2: Enable USB Debugging"
echo "----------------------------------------"
echo "1. Go to Settings > Developer options"
echo "2. Turn ON 'USB debugging'"
echo "3. Turn ON 'Install via USB' (if available)"
echo "4. Turn ON 'USB debugging (Security settings)' (if available)"
echo ""

echo "STEP 3: Connect Device"
echo "----------------------------------------"
echo "1. Connect your Samsung device via USB cable"
echo "2. On your phone, when prompted:"
echo "   - Tap 'Allow USB debugging'"
echo "   - Check 'Always allow from this computer'"
echo "   - Tap 'OK'"
echo "3. Pull down notification panel on phone"
echo "4. Tap USB notification"
echo "5. Select 'File Transfer' or 'MTP' mode (NOT 'Charging only')"
echo ""

echo "STEP 4: Verify Connection"
echo "----------------------------------------"
echo "Running: adb devices"
adb devices
echo ""

echo "If you see your device listed above, you're ready!"
echo "Then run: flutter run"
echo ""

echo "TROUBLESHOOTING:"
echo "----------------------------------------"
echo "If device still not detected:"
echo "1. Try a different USB cable (some cables are charging-only)"
echo "2. Try a different USB port on your Mac"
echo "3. Restart ADB: adb kill-server && adb start-server"
echo "4. Check if device appears in Android Studio > Device Manager"
echo "5. On Samsung devices, you might need to install 'Samsung USB Driver'"
echo "   Download from: https://developer.samsung.com/mobile/android-usb-driver.html"
echo ""

