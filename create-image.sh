#!/bin/bash
#
# Create Redroid Docker Image
#

set -e

BUILD_DIR="$HOME/redroid-samsung-thai"

echo "================================================"
echo "📦 Creating Redroid Docker Image"
echo "================================================"
echo ""

cd "$BUILD_DIR/out/target/product/redroid_x86_64"

# Mount images
echo "Mounting images..."
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro

# Create Docker image
echo "Creating Docker image..."
sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
    docker import \
    -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
    - redroid-samsung-thai:13-mindthegapps

# Unmount
sudo umount system vendor

echo "✅ Image created: redroid-samsung-thai:13-mindthegapps"
echo ""

# Create startup script
echo "Creating startup script..."
cat > ~/start-samsung-thai.sh << 'STARTSCRIPT'
#!/bin/bash
MAC_ADDR="A8:5E:45:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/:$//')"
IMEI="352094$(openssl rand -hex 4 | tr '[:lower:]' '[:upper:]')"

docker run -itd --rm --privileged \
    --name redroid-samsung-thai \
    --pull never \
    -v ~/data-samsung-thai:/data \
    -p 5555:5555 \
    redroid-samsung-thai:13-mindthegapps \
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
echo "🇹🇭 Samsung Galaxy A54 5G (Thai Edition)"
echo "========================================"
echo "Model: SM-A546E"
echo "Android: 13"
echo "Carrier: AIS"
echo "MAC: $MAC_ADDR"
echo "IMEI: $IMEI"
echo "========================================"
echo "adb connect localhost:5555"
echo "scrcpy -s localhost:5555"
echo "========================================"
STARTSCRIPT

chmod +x ~/start-samsung-thai.sh

echo "✅ Startup script: ~/start-samsung-thai.sh"
echo ""
echo "================================================"
echo "✅ ALL DONE!"
echo "================================================"
echo ""
echo "Start container: ~/start-samsung-thai.sh"
echo "Setup network: ~/redroid-doc/fake-network-advanced.sh"
echo ""
