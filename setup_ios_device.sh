#!/bin/bash

echo "🔌 Setting up iPhone for development..."
echo ""

# Get device ID
DEVICE_ID="00008030-001D18AA14DB802E"
DEVICE_NAME="Marwa's iPhone"

echo "📱 Device: $DEVICE_NAME"
echo "🆔 ID: $DEVICE_ID"
echo ""

# Step 1: Open Xcode workspace
echo "📂 Opening Xcode workspace..."
open ios/Runner.xcworkspace

echo ""
echo "✅ Xcode is opening..."
echo ""
echo "📋 Please follow these steps in Xcode (it's very simple):"
echo ""
echo "1️⃣  Wait for Xcode to fully open"
echo ""
echo "2️⃣  At the top of Xcode, next to the ▶️ button, click the device selector"
echo "    You should see '$DEVICE_NAME' - click on it"
echo ""
echo "3️⃣  If you see a 'Signing & Capabilities' error:"
echo "    → Click on 'Runner' in the left sidebar"
echo "    → Click on 'Signing & Capabilities' tab"
echo "    → Under 'Team', click 'Add Account...' and sign in with your Apple ID"
echo "    → (You can use a free Apple ID, no paid developer account needed)"
echo ""
echo "4️⃣  Once the device is selected and signing is set up, press:"
echo "    ⌘ + B  (Command + B) to build"
echo ""
echo "5️⃣  On your iPhone, you'll see:"
echo "    → A popup asking to trust this computer (tap 'Trust')"
echo "    → Developer Mode will appear in Settings → Privacy & Security"
echo "    → Enable Developer Mode"
echo "    → Restart your iPhone"
echo ""
echo "6️⃣  After restart, Developer Mode will ask you to enable it again"
echo "    → Enter your passcode"
echo ""
echo "7️⃣  Come back here and run: flutter run -d $DEVICE_ID"
echo ""
echo "🚀 That's it! The app will install on your iPhone!"

