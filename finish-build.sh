#!/bin/bash
#
# Finish Build - Create Samsung Config and Start Build
#

set -e

BUILD_DIR="$HOME/redroid-samsung-thai"

echo "================================================"
echo "🚀 Finishing Setup and Starting Build"
echo "================================================"
echo ""

# ขั้นที่ 1: Create Samsung Thai Configuration
echo "[1/4] Creating Samsung Thai configuration..."
cat > "$BUILD_DIR/device/redroid/redroid_x86_64/samsung_thai.mk" << 'EOF'
# Samsung Galaxy A54 5G (Thailand Model SM-A546E)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.product.device=a54x \
    ro.build.fingerprint=samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys

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

echo "✅ Samsung Thai configuration created"
echo ""

# ขั้นที่ 2: Build Docker Builder
echo "[2/4] Checking Docker builder..."
if ! docker images | grep -q "redroid-builder"; then
    echo "Building Docker builder image..."
    cd ~/redroid-doc/android-builder-docker
    docker build \
        --build-arg userid=$(id -u) \
        --build-arg groupid=$(id -g) \
        --build-arg username=$(id -un) \
        -t redroid-builder .
    echo "✅ Builder created"
else
    echo "✅ Builder exists"
fi
echo ""

# ขั้นที่ 3: Start Build
echo "[3/4] Starting Android build..."
echo "⏱️  This will take 3-6 hours!"
echo "💡 You can monitor progress: docker logs -f redroid-builder"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. Run this script again when ready."
    exit 0
fi

# Build script
cat > /tmp/build.sh << 'BUILDSCRIPT'
#!/bin/bash
set -e
cd /src
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
echo ""
echo "✅✅✅ BUILD COMPLETED! ✅✅✅"
BUILDSCRIPT
chmod +x /tmp/build.sh

# Run build
docker run -it --rm \
    --hostname redroid-builder \
    --name redroid-builder \
    -v "$BUILD_DIR:/src" \
    -v /tmp/build.sh:/build.sh \
    redroid-builder \
    /build.sh

echo ""
echo "✅ Build completed!"
echo ""

# ขั้นที่ 4: Create Docker Image
echo "[4/4] Creating Docker image..."
cd "$BUILD_DIR/out/target/product/redroid_x86_64"

sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro

sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
    docker import \
    -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
    - redroid-samsung-thai:14-mindthegapps

sudo umount system vendor

echo "✅ Image: redroid-samsung-thai:14-mindthegapps"
echo ""

# Create startup script
cat > ~/start-samsung-thai.sh << 'STARTSCRIPT'
#!/bin/bash
MAC_ADDR="A8:5E:45:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/:$//')"
IMEI="352094$(openssl rand -hex 4 | tr '[:lower:]' '[:upper:]')"

docker run -itd --rm --privileged \
    --name redroid-samsung-thai \
    --pull never \
    -v ~/data-samsung-thai:/data \
    -p 5555:5555 \
    redroid-samsung-thai:14-mindthegapps \
    androidboot.hardware=redroid \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=2340 \
    androidboot.redroid_dpi=420 \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=auto \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.carrier=AIS \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    ro.boot.wifimacaddr=$MAC_ADDR \
    ro.setupwizard.mode=DISABLED

echo "========================================"
echo "🇹🇭 Samsung Galaxy A54 5G (Thai)"
echo "========================================"
echo "Model: SM-A546E"
echo "Carrier: AIS"
echo "MAC: $MAC_ADDR"
echo "IMEI: $IMEI"
echo "========================================"
echo "adb connect localhost:5555"
echo "scrcpy -s localhost:5555"
echo "========================================"
STARTSCRIPT

chmod +x ~/start-samsung-thai.sh

echo ""
echo "================================================"
echo "✅ ALL DONE!"
echo "================================================"
echo ""
echo "Image: redroid-samsung-thai:14-mindthegapps"
echo ""
echo "Start: ~/start-samsung-thai.sh"
echo "Network: ~/redroid-doc/fake-network-advanced.sh"
echo "Connect: adb connect localhost:5555"
echo ""
echo "================================================"
