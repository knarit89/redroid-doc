#!/bin/bash
#
# Continue Build Script after fixing GApps issue
#

set -e

ANDROID_VERSION="14"
BUILD_DIR="$HOME/redroid-samsung-thai"

echo "================================================"
echo "🔧 Fixing and Continuing Build"
echo "================================================"
echo ""

cd "$BUILD_DIR"

# ขั้นที่ 1: Apply Redroid Patches
echo "[1/5] Applying Redroid patches..."
if [ -d ~/redroid-patches ]; then
    rm -rf ~/redroid-patches
fi
git clone https://github.com/remote-android/redroid-patches.git ~/redroid-patches
~/redroid-patches/apply-patch.sh "$BUILD_DIR"
echo "✅ Patches applied"
echo ""

# ขั้นที่ 2: Create Samsung Thai Configuration
echo "[2/5] Creating Samsung Thai configuration..."
cat > "$BUILD_DIR/device/redroid/redroid_x86_64/samsung_thai.mk" << 'EOF'
# Samsung Galaxy A54 5G (Thailand Model SM-A546E)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.product.device=a54x \
    ro.build.fingerprint=samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys \
    ro.build.description=a54xdxm-user\ 14\ UP1A.231005.007\ A546EDXU3CXH3\ release-keys \
    ro.bootimage.build.fingerprint=samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys

# Thai Locale
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.locale=th-TH \
    persist.sys.language=th \
    persist.sys.country=TH \
    persist.sys.timezone=Asia/Bangkok

# WiFi MAC Address Template
PRODUCT_PROPERTY_OVERRIDES += \
    ro.boot.wifimacaddr=A8:5E:45:00:00:00

# IMEI Template
PRODUCT_PROPERTY_OVERRIDES += \
    ro.ril.oem.imei=352094000000000 \
    ro.ril.oem.meid=000000000000

# AIS Thailand Cellular Network
PRODUCT_PROPERTY_OVERRIDES += \
    ro.carrier=AIS \
    ro.telephony.default_network=33 \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    gsm.operator.iso-country=th \
    gsm.sim.operator.alpha=AIS \
    gsm.sim.operator.numeric=52001 \
    gsm.sim.operator.iso-country=th \
    persist.radio.multisim.config=dsds

# Network Features
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_cdma_sub=0 \
    persist.radio.data_ltd_sys_ind=1 \
    persist.radio.voice_on_lte=1 \
    persist.radio.volte.dan_support=true \
    ro.telephony.iwlan_operation_mode=legacy

# Samsung Build Info
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.PDA=A546EDXU3CXH3 \
    ro.build.changelist=28287709 \
    ro.build.official.release=true \
    ro.config.ringtone=Over_the_Horizon.ogg \
    ro.config.notification_sound=Skyline.ogg \
    ro.build.selinux=1

# Knox
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.knox.container=v30 \
    ro.config.knox=v30
EOF

# เพิ่มใน device.mk
if ! grep -q "samsung_thai.mk" "$BUILD_DIR/device/redroid/redroid_x86_64/device.mk"; then
    cat >> "$BUILD_DIR/device/redroid/redroid_x86_64/device.mk" << 'EOF'

# Samsung Thai Configuration
$(call inherit-product, device/redroid/redroid_x86_64/samsung_thai.mk)

# MindTheGapps - Full GApps Package
$(call inherit-product, vendor/gapps/x86_64/x86_64-vendor.mk)
EOF
fi

echo "✅ Samsung Thai configuration created"
echo ""

# ขั้นที่ 3: Build Docker Builder (ถ้ายังไม่มี)
echo "[3/5] Checking Docker builder..."
if ! docker images | grep -q "redroid-builder"; then
    echo "Building Docker builder image..."
    cd ~/redroid-doc/android-builder-docker
    docker build \
        --build-arg userid=$(id -u) \
        --build-arg groupid=$(id -g) \
        --build-arg username=$(id -un) \
        -t redroid-builder .
    echo "✅ Builder image created"
else
    echo "✅ Builder image already exists"
fi
echo ""

# ขั้นที่ 4: Start Build
echo "[4/5] Starting Android build..."
echo "⏱️  This will take 3-6 hours!"
echo ""
read -p "Continue with build? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled. You can run this script again later."
    exit 0
fi

# Create build script for container
cat > /tmp/build_redroid.sh << 'BUILDSCRIPT'
#!/bin/bash
set -e
cd /src
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
BUILDSCRIPT
chmod +x /tmp/build_redroid.sh

# Run build
docker run -it --rm \
    --hostname redroid-builder \
    --name redroid-builder \
    -v "$BUILD_DIR:/src" \
    -v /tmp/build_redroid.sh:/build.sh \
    redroid-builder \
    /build.sh

echo ""
echo "✅ Build completed!"
echo ""

# ขั้นที่ 5: Create Docker Image
echo "[5/5] Creating Docker image..."
cd "$BUILD_DIR/out/target/product/redroid_x86_64"

sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro

sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
    docker import \
    -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
    - redroid-samsung-thai:14-mindthegapps

sudo umount system vendor

echo "✅ Docker image created: redroid-samsung-thai:14-mindthegapps"
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
    ro.ril.oem.imei=$IMEI \
    ro.setupwizard.mode=DISABLED

echo "========================================"
echo "🇹🇭 Samsung Galaxy A54 5G (Thai Edition)"
echo "========================================"
echo "Model: SM-A546E"
echo "Carrier: AIS"
echo "MAC: $MAC_ADDR"
echo "IMEI: $IMEI"
echo "========================================"
echo "Connect: adb connect localhost:5555"
echo "View: scrcpy -s localhost:5555"
echo "========================================"
STARTSCRIPT

chmod +x ~/start-samsung-thai.sh

echo ""
echo "================================================"
echo "✅ BUILD COMPLETE!"
echo "================================================"
echo ""
echo "Image: redroid-samsung-thai:14-mindthegapps"
echo ""
echo "To start: ~/start-samsung-thai.sh"
echo "Setup network: ~/redroid-doc/fake-network-advanced.sh"
echo "Connect: adb connect localhost:5555"
echo ""
echo "================================================"
