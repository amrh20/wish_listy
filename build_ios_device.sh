#!/bin/bash

echo "🚀 Building for Marwa's iPhone..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$SCRIPT_DIR/ios"

if [ ! -d "$IOS_DIR" ]; then
  echo "❌ iOS directory not found: $IOS_DIR"
  exit 1
fi

cd "$IOS_DIR"

DEVICE_ID="00008030-001D18AA14DB802E"

echo "📱 Device: $DEVICE_ID"
echo "📦 Starting build from: $(pwd)"
echo ""

# Verify workspace exists
if [ ! -d "Runner.xcworkspace" ]; then
  echo "❌ Runner.xcworkspace not found in $(pwd)"
  exit 1
fi

# Build for device
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  build 2>&1 | tee /tmp/xcode_build.log | grep -E "(error|warning|succeeded|failed|BUILD)" | tail -20

BUILD_RESULT=${PIPESTATUS[0]}

echo ""
if [ $BUILD_RESULT -eq 0 ]; then
  echo "✅ Build successful!"
  echo ""
  echo "🎯 Now try running from Flutter:"
  echo "   flutter run -d $DEVICE_ID"
else
  echo "❌ Build failed. Check the error above."
  echo ""
  echo "💡 Common fixes:"
  echo "   1. Make sure iPhone is unlocked"
  echo "   2. Make sure Developer Mode is ON and iPhone was restarted"
  echo "   3. Check Xcode → Signing & Capabilities → Team is set"
fi
