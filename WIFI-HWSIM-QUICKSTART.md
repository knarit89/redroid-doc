# 📡 WiFi HWSim Quick Start

## 🚀 3-Step Setup

### Step 1: Integrate WiFi HWSim
```bash
cd /root/redroid-doc
./add-wifi-hwsim.sh
```

### Step 2: Rebuild AOSP
```bash
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
```

### Step 3: Create Docker Image
```bash
cd ~/redroid-samsung-thai/out/target/product/redroid_x86_64
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro
sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
  docker import \
  -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
  - redroid-samsung-thai:14-wifi-hwsim
sudo umount system vendor
```

---

## 🎮 Usage

### Start Container
```bash
~/start-samsung-thai-wifi-hwsim.sh
```

### Connect & Test
```bash
# Wait 30 seconds for boot
sleep 30

# Connect ADB
adb connect localhost:5555

# Check WiFi interface (should show wlan0)
adb shell ip link show wlan0

# Enable WiFi
adb shell svc wifi enable

# Check WiFi status
adb shell dumpsys wifi | grep "Wi-Fi is"
```

---

## 🔍 Quick Checks

### Check if wlan0 exists
```bash
adb shell ip link show wlan0
# ✅ Good: Shows wlan0 interface
# ❌ Bad: Device not found
```

### Check WPA Supplicant
```bash
adb shell ps -A | grep wpa_supplicant
# Should show: wifi ... wpa_supplicant_cf
```

### Check WiFi Settings
```bash
adb shell am start -a android.settings.WIFI_SETTINGS
# WiFi settings should work properly
```

---

## 🐛 Common Issues

### Issue: mac80211_hwsim not found
**Solution:**
```bash
# Check kernel support
modinfo mac80211_hwsim

# If not found, kernel doesn't support it
# Need kernel with CONFIG_MAC80211_HWSIM=m
```

### Issue: wlan0 not created
**Solution:**
```bash
# Check container logs
docker logs redroid-samsung-thai-wifi

# Check if APEX mounted
adb shell ls -la /apex/com.android.wifi.hal
```

### Issue: WiFi stuck on "Turning on..."
**Solution:**
```bash
# Restart container
docker restart redroid-samsung-thai-wifi

# Or restart WiFi service
adb shell stop
adb shell start
```

---

## 📊 Comparison

| Feature | Before (Mocked) | After (HWSim) |
|---------|-----------------|---------------|
| wlan0 interface | ❌ No | ✅ Yes |
| WiFi Settings | ⚠️ Fake | ✅ Real |
| WPA Supplicant | ❌ No | ✅ Yes |
| App Compatibility | ⚠️ Some apps fail | ✅ All work |
| WiFi Scan | ❌ No | ✅ Yes (with AP) |

---

## 📚 Full Documentation

For detailed guide: `/root/redroid-doc/WIFI-HWSIM-GUIDE.md`

---

## ⚡ One-Liner Test

After container starts:
```bash
adb connect localhost:5555 && \
adb shell "ip link show wlan0 && svc wifi enable && dumpsys wifi | head -20"
```

Expected output should show:
- ✅ wlan0 interface exists
- ✅ WiFi is enabled
- ✅ WPA Supplicant running

---

<div align="center">
🎉 Enjoy your virtual WiFi! 🎉
</div>
