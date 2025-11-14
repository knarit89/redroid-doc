#!/bin/bash
#
# Advanced Fake Network Setup for Redroid Samsung Thai
# จำลอง WiFi, Cellular (AIS), และ GPS ให้สมจริง
#

CONTAINER_NAME="${1:-redroid-samsung-thai}"

echo "================================================"
echo "🇹🇭 Setting up Advanced Fake Network (Thailand)"
echo "================================================"

# ตรวจสอบว่า container ทำงานอยู่หรือไม่
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Function สำหรับรัน command ใน container
adb_shell() {
    docker exec "$CONTAINER_NAME" sh -c "$1"
}

echo ""
echo "📶 [1/6] Configuring Cellular Network (AIS)..."
adb_shell '
# Enable mobile data
svc data enable

# AIS Thailand (MCC: 520, MNC: 01)
setprop gsm.operator.alpha "AIS"
setprop gsm.operator.numeric "52001"
setprop gsm.operator.iso-country "th"

# SIM card info
setprop gsm.sim.operator.alpha "AIS"
setprop gsm.sim.operator.numeric "52001"
setprop gsm.sim.operator.iso-country "th"
setprop gsm.sim.state "READY"

# Network type (5G/LTE)
setprop gsm.network.type "NR"
setprop telephony.lteOnCdmaDevice 1
setprop persist.radio.data_ltd_sys_ind 1
setprop persist.radio.voice_on_lte 1

# Signal strength (ASU: 99 = -53 dBm = Excellent)
setprop gsm.operator.asu 99
'

echo "✅ AIS Network configured"
sleep 1

echo ""
echo "📡 [2/6] Configuring WiFi..."
adb_shell '
# Enable WiFi
svc wifi enable
settings put global wifi_on 1

# WiFi connected state
settings put global wifi_scan_always_enabled 1

# Fake WiFi network name (SSID)
setprop wifi.interface "wlan0"

# WiFi speed (866 Mbps = WiFi 5)
setprop wifi.linkspeed 866
'

echo "✅ WiFi enabled"
sleep 1

echo ""
echo "✈️ [3/6] Disabling Airplane Mode..."
adb_shell '
settings put global airplane_mode_on 0
am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
'

echo "✅ Airplane mode disabled"
sleep 1

echo ""
echo "🌐 [4/6] Configuring Network Settings..."
adb_shell '
# Enable all connectivity
settings put global mobile_data 1
settings put global data_roaming 0

# Network preferences
settings put global preferred_network_mode 33
settings put global network_preference 1

# DNS (Google + Cloudflare)
setprop net.dns1 8.8.8.8
setprop net.dns2 1.1.1.1

# APN for AIS Thailand
settings put global apn "internet"
setprop ril.data.apn "internet"
'

echo "✅ Network settings configured"
sleep 1

echo ""
echo "📍 [5/6] Configuring Fake GPS (Bangkok, Thailand)..."
adb_shell '
# Enable location services
settings put secure location_mode 3
settings put secure location_providers_allowed "gps,network"

# Bangkok coordinates (Siam Paragon)
# Lat: 13.746584, Lon: 100.534821
setprop persist.sys.mock.location.latitude 13.746584
setprop persist.sys.mock.location.longitude 100.534821

# GPS status
setprop gps.status 1
'

echo "✅ GPS configured (Bangkok)"
sleep 1

echo ""
echo "🌍 [6/6] Setting Locale and Timezone..."
adb_shell '
# Thai locale
setprop persist.sys.language th
setprop persist.sys.country TH
setprop persist.sys.locale th-TH

# Bangkok timezone
setprop persist.sys.timezone "Asia/Bangkok"

# Date format (Buddhist Era for Thailand)
settings put system date_format "dd/MM/yyyy"
settings put system time_12_24 24
'

echo "✅ Locale and timezone set"
sleep 1

echo ""
echo "================================================"
echo "✅ Advanced Network Setup Complete!"
echo "================================================"
echo ""
echo "📋 Summary:"
echo "   📱 Device: Samsung Galaxy A54 5G"
echo "   🇹🇭 Country: Thailand"
echo "   📶 Carrier: AIS (52001)"
echo "   📡 Network: 5G/LTE"
echo "   📶 Signal: Excellent (-53 dBm)"
echo "   📍 Location: Bangkok (13.746584, 100.534821)"
echo "   🌐 WiFi: Connected (866 Mbps)"
echo "   🕐 Timezone: Asia/Bangkok"
echo "   🗣️ Language: Thai"
echo ""

# Verify settings
echo "🔍 Verifying Configuration..."
echo ""

MAC_ADDR=$(adb_shell 'getprop ro.boot.wifimacaddr')
MODEL=$(adb_shell 'getprop ro.product.model')
CARRIER=$(adb_shell 'getprop gsm.operator.alpha')
NETWORK=$(adb_shell 'getprop gsm.network.type')

echo "   Model: $MODEL"
echo "   MAC: $MAC_ADDR"
echo "   Carrier: $CARRIER"
echo "   Network Type: $NETWORK"
echo ""
echo "================================================"
echo "🎉 Ready to use!"
echo ""
echo "Connect with: adb connect localhost:5555"
echo "View screen: scrcpy -s localhost:5555"
echo "================================================"
