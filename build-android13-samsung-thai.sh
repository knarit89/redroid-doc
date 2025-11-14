#!/bin/bash
#
# Build Android 13 Samsung Thai Edition with MindTheGapps
#

set -e

BUILD_DIR="$HOME/redroid-samsung-thai"

echo "================================================"
echo "🇹🇭 Build Android 13 - Samsung Thai Edition"
echo "================================================"
echo ""

# ขั้นที่ 1: Clean up
echo "[1/7] Cleaning up old build..."
docker rm -f redroid-builder 2>/dev/null || true
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
echo "✅ Cleaned"
echo ""

# ขั้นที่ 2: Init repo (Android 13)
echo "[2/7] Initializing Android 13 repo..."
~/bin/repo init -u https://android.googlesource.com/platform/manifest \
  --git-lfs --depth=1 -b android-13.0.0_r82
echo "✅ Initialized"
echo ""

# ขั้นที่ 3: Add Redroid manifests
echo "[3/7] Adding Redroid manifests..."
git clone https://github.com/remote-android/local_manifests.git \
  .repo/local_manifests -b 13.0.0
echo "✅ Redroid manifests added"
echo ""

# ขั้นที่ 4: Add MindTheGapps (tau revision for Android 13)
echo "[4/7] Adding MindTheGapps manifests..."
cat > .repo/local_manifests/mindthegapps.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="mtg" fetch="https://gitlab.com/MindTheGapps/" />
  <project path="vendor/gapps" name="vendor_gapps" revision="tau" remote="mtg" />
</manifest>
EOF
echo "✅ MindTheGapps manifests added"
echo ""

# ขั้นที่ 5: Sync code
echo "[5/7] Syncing code (1-2 hours)..."
~/bin/repo sync -c -j$(nproc)
echo "✅ Code synced"
echo ""

# ขั้นที่ 6: Apply patches
echo "[6/7] Applying Redroid patches..."
rm -rf ~/redroid-patches
git clone https://github.com/remote-android/redroid-patches.git ~/redroid-patches
~/redroid-patches/apply-patch.sh "$BUILD_DIR"
echo "✅ Patches applied"
echo ""

# ขั้นที่ 7: Create Samsung Thai configuration
echo "[7/7] Creating Samsung Thai configuration..."
cat > "$BUILD_DIR/device/redroid/redroid_x86_64/samsung_thai.mk" << 'EOF'
# Samsung Galaxy A54 5G (Thailand Model SM-A546E)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.product.device=a54x \
    ro.build.fingerprint=samsung/a54xdxm/a54x:13/TP1A.220624.014/A546EDXU2AWL1:user/release-keys

# Thai Locale
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.locale=th-TH \
    persist.sys.language=th \
    persist.sys.country=TH \
    persist.sys.timezone=Asia/Bangkok

# WiFi MAC Address
PRODUCT_PROPERTY_OVERRIDES += \
    ro.boot.wifimacaddr=A8:5E:45:00:00:00

# AIS Thailand
PRODUCT_PROPERTY_OVERRIDES += \
    ro.carrier=AIS \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    gsm.operator.iso-country=th
EOF

# Add to device.mk
if ! grep -q "samsung_thai.mk" "$BUILD_DIR/device/redroid/redroid_x86_64/device.mk"; then
    cat >> "$BUILD_DIR/device/redroid/redroid_x86_64/device.mk" << 'EOF'

# Samsung Thai Configuration
$(call inherit-product, device/redroid/redroid_x86_64/samsung_thai.mk)

# MindTheGapps
$(call inherit-product, vendor/gapps/x86_64/x86_64-vendor.mk)
EOF
fi

echo "✅ Configuration created"
echo ""

echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Start build (3-6 hours):"
echo "   docker run -it --rm --hostname redroid-builder --name redroid-builder \\"
echo "     -v ~/redroid-samsung-thai:/src redroid-builder \\"
echo "     bash -c 'cd /src && . build/envsetup.sh && lunch redroid_x86_64-userdebug && m -j3'"
echo ""
echo "2. Or run the simplified build script:"
echo "   /root/start-build.sh"
echo ""
echo "================================================"
