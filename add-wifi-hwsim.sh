#!/bin/bash
#
# Automated WiFi HWSim Integration Script for Redroid Samsung Thai
# This script will modify device configuration to add WiFi Hardware Simulator
#

set -e

REDROID_DIR="${1:-$HOME/redroid-samsung-thai}"
DEVICE_DIR="$REDROID_DIR/device/redroid/redroid_x86_64"

echo "================================================"
echo "🔧 WiFi HWSim Integration Script"
echo "================================================"
echo ""

# Check if redroid directory exists
if [ ! -d "$REDROID_DIR" ]; then
    echo "❌ Error: Redroid directory not found: $REDROID_DIR"
    echo "Usage: $0 [redroid_directory]"
    exit 1
fi

echo "📂 Redroid directory: $REDROID_DIR"
echo "📂 Device directory: $DEVICE_DIR"
echo ""

# Backup original files
echo "💾 [1/5] Creating backups..."
cp "$DEVICE_DIR/device.mk" "$DEVICE_DIR/device.mk.backup.$(date +%Y%m%d_%H%M%S)"
cp "$DEVICE_DIR/BoardConfig.mk" "$DEVICE_DIR/BoardConfig.mk.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
echo "✅ Backups created"
echo ""

# Step 1: Modify device.mk
echo "🛠️ [2/5] Modifying device.mk..."

# Check if WiFi HWSim is already added
if grep -q "com.google.cf.wifi_hwsim" "$DEVICE_DIR/device.mk"; then
    echo "⚠️  WiFi HWSim already configured in device.mk"
else
    cat >> "$DEVICE_DIR/device.mk" << 'EOF'

# ========================================
# WiFi Hardware Simulator (WiFi HWSim)
# ========================================

# WiFi HWSim APEX from Cuttlefish
PRODUCT_SOONG_NAMESPACES += device/google/cuttlefish/apex/com.google.cf.wifi_hwsim
PRODUCT_PACKAGES += com.google.cf.wifi_hwsim

# WPA Supplicant Configuration
$(call add_soong_config_namespace, wpa_supplicant)
$(call add_soong_config_var_value, wpa_supplicant, platform_version, $(PLATFORM_VERSION))
$(call add_soong_config_var_value, wpa_supplicant, nl80211_driver, CONFIG_DRIVER_NL80211_QCA)

# WiFi Implementation: mac80211_hwsim
PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.wifi_impl=mac8011_hwsim_virtio

# Enforce mac80211_hwsim
$(call soong_config_append,cvdhost,enforce_mac80211_hwsim,true)

# WiFi Packages
PRODUCT_PACKAGES += \
    mac80211_create_radios \
    wpa_supplicant_cf \
    hostapd_cf

EOF
    echo "✅ device.mk updated"
fi
echo ""

# Step 2: Create BoardConfig.mk if not exists
echo "🛠️ [3/5] Updating BoardConfig.mk..."

if [ ! -f "$DEVICE_DIR/BoardConfig.mk" ]; then
    cat > "$DEVICE_DIR/BoardConfig.mk" << 'EOF'
# Board Configuration for Redroid x86_64 with WiFi HWSim

# WiFi HWSim APEX Configuration
BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim

EOF
    echo "✅ BoardConfig.mk created"
else
    # Check if already configured
    if grep -q "com.google.cf.wifi_hwsim" "$DEVICE_DIR/BoardConfig.mk"; then
        echo "⚠️  WiFi HWSim already configured in BoardConfig.mk"
    else
        cat >> "$DEVICE_DIR/BoardConfig.mk" << 'EOF'

# WiFi HWSim APEX Configuration
BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim

EOF
        echo "✅ BoardConfig.mk updated"
    fi
fi
echo ""

# Step 3: Create init.wifi.rc
echo "🛠️ [4/5] Creating init.wifi.rc..."

cat > "$DEVICE_DIR/init.wifi.rc" << 'EOF'
# WiFi Hardware Simulator Init Script

service mac80211_create_radios /vendor/bin/mac80211_create_radios
    class late_start
    user root
    group root
    oneshot
    disabled

on post-fs-data
    # Create WiFi directories
    mkdir /data/vendor/wifi 0770 wifi wifi
    mkdir /data/vendor/wifi/wpa 0770 wifi wifi
    mkdir /data/vendor/wifi/wpa/sockets 0770 wifi wifi
    
    # Set permissions
    chown wifi wifi /data/vendor/wifi
    chown wifi wifi /data/vendor/wifi/wpa
    chown wifi wifi /data/vendor/wifi/wpa/sockets
    
    # Start WiFi hardware simulator
    start mac80211_create_radios

on property:sys.boot_completed=1
    # Enable WiFi on boot
    exec_background -- /system/bin/svc wifi enable

EOF

# Add init.wifi.rc to device.mk if not already there
if ! grep -q "init.wifi.rc" "$DEVICE_DIR/device.mk"; then
    cat >> "$DEVICE_DIR/device.mk" << 'EOF'

# WiFi Init Script
PRODUCT_COPY_FILES += \
    device/redroid/redroid_x86_64/init.wifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.wifi.rc

EOF
fi

echo "✅ init.wifi.rc created and configured"
echo ""

# Step 4: Summary
echo "🎉 [5/5] WiFi HWSim Integration Complete!"
echo ""
echo "================================================"
echo "📋 Summary of Changes:"
echo "================================================"
echo "✅ device.mk - Added WiFi HWSim packages"
echo "✅ BoardConfig.mk - Added bootconfig"
echo "✅ init.wifi.rc - Created WiFi init script"
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
echo "2️⃣  Create new Docker image:"
echo "   cd $REDROID_DIR/out/target/product/redroid_x86_64"
echo "   sudo mount system.img system -o ro"
echo "   sudo mount vendor.img vendor -o ro"
echo "   sudo tar --xattrs -c vendor -C system --exclude=\"./vendor\" . | \\"
echo "     docker import \\"
echo "     -c 'ENTRYPOINT [\"/init\", \"androidboot.hardware=redroid\"]' \\"
echo "     - redroid-samsung-thai:14-wifi-hwsim"
echo "   sudo umount system vendor"
echo ""
echo "3️⃣  Load kernel module (on host):"
echo "   sudo modprobe mac80211_hwsim radios=1"
echo ""
echo "4️⃣  Run container with WiFi HWSim:"
echo "   ~/start-samsung-thai-wifi-hwsim.sh"
echo ""
echo "================================================"
echo "📚 For detailed guide, see:"
echo "   /root/redroid-doc/WIFI-HWSIM-GUIDE.md"
echo "================================================"
echo ""
