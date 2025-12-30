#!/bin/bash

echo "🚀 Attempting to build and install app on iPhone..."
echo ""

DEVICE_ID="00008030-001D18AA14DB802E"

cd "$(dirname "$0")/ios"

echo "📦 Building app for device..."
echo ""

# Try to build with automatic signing
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="" \
  build 2>&1 | tee /tmp/xcode_build.log

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
  echo ""
  echo "✅ Build successful! Attempting to install..."
  echo ""
  
  # Try to install
  xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -destination "id=$DEVICE_ID" \
    -allowProvisioningUpdates \
    install 2>&1 | tail -20
else
  echo ""
  echo "⚠️  Build failed. This is expected if Developer Mode is not enabled."
  echo ""
  echo "📱 On your iPhone, please check:"
  echo "   1. Settings → Privacy & Security"
  echo "   2. Look for 'Developer Mode'"
  echo "   3. If it appears, enable it and restart iPhone"
  echo ""
  echo "If Developer Mode doesn't appear, you need to:"
  echo "   1. Open Xcode (should be open now)"
  echo "   2. Select 'Runner' in left sidebar"
  echo "   3. Go to 'Signing & Capabilities' tab"
  echo "   4. Add your Apple ID under 'Team'"
  echo "   5. Press ⌘+B to build"
  echo ""
fi

