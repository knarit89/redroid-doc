#!/bin/bash
#
# WiFi HWSim Verification Script
# Checks if WiFi Hardware Simulator is working correctly
#

set -e

CONTAINER_NAME="${1:-redroid-samsung-thai-wifi}"

echo "================================================"
echo "🔍 WiFi HWSim Verification Script"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing: $test_name ... "
    
    if eval "$test_command" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Check if container is running
echo "📦 Checking container status..."
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Error: Container '$CONTAINER_NAME' is not running${NC}"
    echo ""
    echo "Start container with:"
    echo "  ~/start-samsung-thai-wifi-hwsim.sh"
    exit 1
fi
echo -e "${GREEN}✅ Container is running${NC}"
echo ""

# Check ADB connection
echo "🔌 Checking ADB connection..."
if ! adb devices | grep -q "localhost:5555"; then
    echo -e "${YELLOW}⚠️  ADB not connected. Connecting...${NC}"
    adb connect localhost:5555 >/dev/null 2>&1
    sleep 2
fi

if adb devices | grep -q "localhost:5555.*device$"; then
    echo -e "${GREEN}✅ ADB connected${NC}"
else
    echo -e "${RED}❌ Failed to connect ADB${NC}"
    exit 1
fi
echo ""

# Host Tests
echo "================================================"
echo "🖥️  Host System Tests"
echo "================================================"
echo ""

run_test "mac80211_hwsim kernel module loaded" \
    "lsmod" \
    "mac80211_hwsim"

echo ""

# Container Tests
echo "================================================"
echo "📱 Android Container Tests"
echo "================================================"
echo ""

run_test "wlan0 interface exists" \
    "docker exec $CONTAINER_NAME ip link show wlan0" \
    "wlan0"

run_test "WiFi HAL service running" \
    "docker exec $CONTAINER_NAME ps -A" \
    "android.hardware.wifi"

run_test "WPA Supplicant running" \
    "docker exec $CONTAINER_NAME ps -A" \
    "wpa_supplicant"

run_test "APEX mounted correctly" \
    "docker exec $CONTAINER_NAME ls /apex/" \
    "com.android.wifi.hal"

run_test "WiFi data directory exists" \
    "docker exec $CONTAINER_NAME ls /data/vendor/" \
    "wifi"

echo ""

# Android Tests (via ADB)
echo "================================================"
echo "🤖 Android Framework Tests"
echo "================================================"
echo ""

run_test "WiFi service accessible" \
    "adb shell dumpsys wifi" \
    "Wi-Fi"

run_test "WiFi can be enabled" \
    "adb shell svc wifi enable && sleep 2 && adb shell dumpsys wifi" \
    "Wi-Fi is enabled"

run_test "WiFi MAC address configured" \
    "adb shell getprop ro.boot.wifimacaddr" \
    "A8:5E:45"

run_test "WiFi interface in Android" \
    "adb shell ip link show" \
    "wlan0"

run_test "nl80211 driver available" \
    "adb shell iw dev" \
    "wlan0"

echo ""

# Summary
echo "================================================"
echo "📊 Test Summary"
echo "================================================"
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "================================================"
    echo -e "${GREEN}🎉 All tests passed! WiFi HWSim is working!${NC}"
    echo "================================================"
    echo ""
    echo "✅ You now have:"
    echo "   - Real wlan0 interface"
    echo "   - Working WPA Supplicant"
    echo "   - Functional WiFi HAL"
    echo "   - Full WiFi framework support"
    echo ""
    echo "Try these:"
    echo "   adb shell am start -a android.settings.WIFI_SETTINGS"
    echo "   adb shell dumpsys wifi"
    echo "   adb shell iw dev wlan0 info"
    echo ""
    exit 0
else
    echo "================================================"
    echo -e "${RED}⚠️  Some tests failed${NC}"
    echo "================================================"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check container logs:"
    echo "   docker logs $CONTAINER_NAME"
    echo ""
    echo "2. Check Android logs:"
    echo "   adb logcat | grep -E 'wifi|wpa_supplicant|WiFi'"
    echo ""
    echo "3. Check kernel module:"
    echo "   lsmod | grep mac80211_hwsim"
    echo "   sudo modprobe mac80211_hwsim radios=1"
    echo ""
    echo "4. Restart container:"
    echo "   docker restart $CONTAINER_NAME"
    echo ""
    echo "5. See documentation:"
    echo "   /root/redroid-doc/WIFI-HWSIM-GUIDE.md"
    echo ""
    exit 1
fi
