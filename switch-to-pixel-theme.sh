#!/bin/bash
#
# Switch from Samsung Theme to Google Pixel Theme
# While keeping WiFi HWSim + Virtual SIM
#

set -e

REDROID_DIR="${1:-$HOME/redroid-samsung-thai}"
DEVICE_DIR="$REDROID_DIR/device/redroid/redroid_x86_64"

echo "================================================"
echo "🎨 Switch to Google Pixel Theme"
echo "================================================"
echo ""

# Check redroid directory
if [ ! -d "$REDROID_DIR" ]; then
    echo "❌ Error: Redroid directory not found: $REDROID_DIR"
    exit 1
fi

echo "📂 Redroid directory: $REDROID_DIR"
echo "📂 Device directory: $DEVICE_DIR"
echo ""

# Backup
echo "💾 Creating backup..."
cp "$DEVICE_DIR/device.mk" "$DEVICE_DIR/device.mk.backup.pixel.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup created"
echo ""

# Check if pixel_thai.mk exists
if [ ! -f "$DEVICE_DIR/pixel_thai.mk" ]; then
    echo "❌ Error: pixel_thai.mk not found!"
    echo "Please ensure the file exists at: $DEVICE_DIR/pixel_thai.mk"
    exit 1
fi

# Modify device.mk to use Pixel theme instead of Samsung
echo "🛠️ Switching to Pixel theme..."

# Comment out Samsung Thai and add Pixel Thai
if grep -q "samsung_thai.mk" "$DEVICE_DIR/device.mk"; then
    # Backup the line and comment it out
    sed -i 's/^\(.*samsung_thai.mk\)/# \1  # Commented for Pixel theme/' "$DEVICE_DIR/device.mk"
    
    # Add Pixel Thai configuration after the commented line
    sed -i '/# Commented for Pixel theme/a\
\
# Google Pixel Thai Configuration\
$(call inherit-product, device/redroid/redroid_x86_64/pixel_thai.mk)' "$DEVICE_DIR/device.mk"
    
    echo "✅ Switched from Samsung to Pixel theme"
else
    # If samsung_thai.mk not found, just add Pixel
    if ! grep -q "pixel_thai.mk" "$DEVICE_DIR/device.mk"; then
        cat >> "$DEVICE_DIR/device.mk" << 'EOF'

# Google Pixel Thai Configuration
$(call inherit-product, device/redroid/redroid_x86_64/pixel_thai.mk)
EOF
        echo "✅ Added Pixel theme configuration"
    else
        echo "⚠️  Pixel theme already configured"
    fi
fi

echo ""
echo "================================================"
echo "✅ Theme Switch Complete!"
echo "================================================"
echo ""
echo "📋 Changes:"
echo "   ✅ Brand: Samsung → Google"
echo "   ✅ Model: SM-A546E → Pixel 7 Pro"
echo "   ✅ Theme: One UI → Material You"
echo "   ✅ Locale: Still Thai (th-TH)"
echo "   ✅ Carrier: Still AIS Thailand"
echo "   ✅ WiFi HWSim: Still enabled"
echo "   ✅ Virtual SIM: Still enabled"
echo ""
echo "================================================"
echo "🚀 Next Steps:"
echo "================================================"
echo ""
echo "1️⃣  Rebuild AOSP:"
echo "   cd $REDROID_DIR"
echo "   . build/envsetup.sh"
echo "   lunch redroid_x86_64-userdebug"
echo "   m -j\$(nproc)"
echo ""
echo "2️⃣  Create Docker image:"
echo "   Image name: redroid-pixel-thai:14-full"
echo ""
echo "3️⃣  Run with Pixel theme:"
echo "   ~/start-samsung-thai-full.sh"
echo "   (Will show as Pixel 7 Pro)"
echo ""
echo "================================================"
echo "💡 To switch back to Samsung:"
echo "================================================"
echo ""
echo "# In device.mk, uncomment samsung_thai.mk"
echo "# and comment out pixel_thai.mk"
echo ""
