#!/bin/bash
#
# Start Android Build
#

set -e

BUILD_DIR="$HOME/redroid-samsung-thai"

echo "================================================"
echo "🚀 Starting Android 13 Build"
echo "================================================"
echo ""
echo "⏱️  This will take 3-6 hours"
echo "💡 Monitor: docker logs -f redroid-builder (new terminal)"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Create build script
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

# Start build
docker run -it --rm \
    --hostname redroid-builder \
    --name redroid-builder \
    -v "$BUILD_DIR:/src" \
    -v /tmp/build.sh:/build.sh \
    redroid-builder \
    /build.sh

echo ""
echo "================================================"
echo "✅ Build Completed!"
echo "================================================"
echo ""
echo "Next: Create Docker image"
echo "Run: /root/create-image.sh"
echo ""
