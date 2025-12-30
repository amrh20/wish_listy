#!/bin/bash

echo "🚀 Quick iOS Setup - Developer Mode"
echo "===================================="
echo ""

# Make sure Xcode is open
echo "📂 Opening Xcode workspace..."
open ios/Runner.xcworkspace

sleep 3

echo ""
echo "✅ Xcode should be open now!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 ACTION REQUIRED - فقط خطوتين في Xcode:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  في Xcode:"
echo "    • اضغط على 'Runner' في الجانب الأيسر"
echo "    • اضغط على تبويب 'Signing & Capabilities'"
echo "    • تحت 'Team' اضغط 'Add Account...'"
echo "    • سجل دخول بـ Apple ID (أي Apple ID مجاني)"
echo ""
echo "2️⃣  بعد إضافة Apple ID:"
echo "    • اضغط ⌘+B (Command + B) في Xcode"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 بعد كدا على iPhone:"
echo "    • Settings → Privacy & Security"
echo "    • Developer Mode سيظهر (كان مخفي قبل كدا!)"
echo "    • فعّله → Restart iPhone"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ بعد ما تفعل Developer Mode على iPhone، ارجع هنا واضغط Enter..."
read -p "Press Enter when Developer Mode is enabled and iPhone restarted..."

echo ""
echo "🚀 Trying to run the app now..."
cd "$(dirname "$0")"
flutter run -d 00008030-001D18AA14DB802E

