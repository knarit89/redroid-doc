#!/bin/bash
#
# Add Virtual SIM (RIL Daemon) to Redroid Samsung Thai
# This enables full cellular/telephony simulation
#

set -e

REDROID_DIR="${1:-$HOME/redroid-samsung-thai}"
DEVICE_DIR="$REDROID_DIR/device/redroid/redroid_x86_64"

echo "================================================"
echo "📱 Virtual SIM (RIL) Integration Script"
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
cp "$DEVICE_DIR/device.mk" "$DEVICE_DIR/device.mk.backup.sim.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup created"
echo ""

# Add Virtual SIM configuration
echo "🛠️ Adding Virtual SIM (RIL) configuration..."

if grep -q "com.google.cf.rild" "$DEVICE_DIR/device.mk"; then
    echo "⚠️  Virtual SIM already configured"
else
    cat >> "$DEVICE_DIR/device.mk" << 'EOF'

# ========================================
# Virtual SIM / RIL Daemon (Cuttlefish)
# ========================================

# RIL Daemon APEX from Cuttlefish
PRODUCT_SOONG_NAMESPACES += device/google/cuttlefish/apex/com.google.cf.rild
PRODUCT_PACKAGES += com.google.cf.rild

# Telephony support
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_vendor.mk)

# RIL configuration
PRODUCT_VENDOR_PROPERTIES += \
    ro.telephony.default_network=10 \
    ro.com.android.dataroaming=true

# SIM properties (AIS Thailand)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_cdma_sub=0 \
    persist.radio.multisim.config=dsds

DISABLE_RILD_OEM_HOOK := true

EOF
    echo "✅ device.mk updated with Virtual SIM"
fi

# Add BoardConfig
echo ""
echo "🛠️ Updating BoardConfig..."

if [ ! -f "$DEVICE_DIR/BoardConfig.mk" ]; then
    cat > "$DEVICE_DIR/BoardConfig.mk" << 'EOF'
# Board Configuration for Redroid x86_64

# WiFi HWSim APEX Configuration
BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim

EOF
fi

if ! grep -q "com.google.cf.rild" "$DEVICE_DIR/BoardConfig.mk"; then
    cat >> "$DEVICE_DIR/BoardConfig.mk" << 'EOF'

# Virtual SIM / RIL APEX Configuration
BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.google.cf.rild=com.google.cf.rild

EOF
    echo "✅ BoardConfig.mk updated"
else
    echo "⚠️  BoardConfig already has Virtual SIM config"
fi

echo ""
echo "================================================"
echo "✅ Virtual SIM Integration Complete!"
echo "================================================"
echo ""
echo "📋 What was added:"
echo "   ✅ com.google.cf.rild APEX package"
echo "   ✅ Telephony framework"
echo "   ✅ RIL daemon configuration"
echo "   ✅ Bootconfig for RIL APEX"
echo ""
echo "================================================"
echo "🚀 Next Steps:"
echo "================================================"
echo ""
echo "1️⃣  Rebuild AOSP (same as WiFi HWSim):"
echo "   cd $REDROID_DIR"
echo "   . build/envsetup.sh"
echo "   lunch redroid_x86_64-userdebug"
echo "   m -j\$(nproc)"
echo ""
echo "2️⃣  Create Docker image with Virtual SIM"
echo ""
echo "3️⃣  When running container, SIM will be available:"
echo "   - Phone app will work"
echo "   - Can make/receive calls (simulated)"
echo "   - Can send/receive SMS (simulated)"
echo "   - Mobile data will work"
echo ""
echo "================================================"
echo "📚 For detailed guide, see:"
echo "   /root/redroid-doc/VIRTUAL-SIM-GUIDE.md"
echo "================================================"
echo ""
