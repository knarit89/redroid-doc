# 📡 Redroid WiFi Hardware Simulator (wifi_hwsim) Integration Guide

## 🎯 Overview

คู่มือนี้จะแสดงวิธีการเพิ่ม **WiFi Hardware Simulator** ให้กับ redroid-samsung-thai ของคุณ เพื่อให้มี virtual WiFi interface ที่สมจริงมากขึ้น แทนที่จะใช้การ mock ผ่าน properties เพียงอย่างเดียว

### ความแตกต่างระหว่าง Mocked WiFi vs WiFi HWSim

| Feature | Mocked WiFi (ปัจจุบัน) | WiFi HWSim |
|---------|------------------------|------------|
| **WiFi Interface** | ไม่มี wlan0 จริง | มี wlan0 interface |
| **Network Stack** | Redirect ไป Ethernet | WiFi stack แบบเต็ม |
| **Apps Compatibility** | บางแอพไม่รู้จัก | รองรับทุกแอพ |
| **WPA Supplicant** | ไม่มี | มีการทำงานจริง |
| **WiFi Settings** | แสดงแต่ไม่ทำงาน | ทำงานได้จริง |

---

## 📋 Prerequisites

- ✅ redroid-samsung-thai source code (Android 14)
- ✅ Build environment พร้อม
- ✅ Kernel ต้องมี **mac80211_hwsim** module

---

## 🔍 Step 1: ตรวจสอบ Kernel Module

```bash
# ตรวจสอบว่า host kernel รองรับ mac80211_hwsim หรือไม่
modinfo mac80211_hwsim

# ถ้ามี output แสดงว่ารองรับแล้ว ✅
# ถ้าไม่มี ต้อง compile kernel ใหม่ หรือใช้ kernel ที่รองรับ
```

---

## 🛠️ Step 2: แก้ไข Redroid Device Configuration

### 2.1 เพิ่ม WiFi HWSim APEX

แก้ไขไฟล์ `device/redroid/redroid_x86_64/device.mk`:

```makefile
# เพิ่มบรรทัดเหล่านี้หลังจากบรรทัด inherit-product

# WiFi Hardware Simulator (from Cuttlefish)
PRODUCT_SOONG_NAMESPACES += device/google/cuttlefish/apex/com.google.cf.wifi_hwsim
PRODUCT_PACKAGES += com.google.cf.wifi_hwsim

# WiFi Configuration
$(call add_soong_config_namespace, wpa_supplicant)
$(call add_soong_config_var_value, wpa_supplicant, platform_version, $(PLATFORM_VERSION))
$(call add_soong_config_var_value, wpa_supplicant, nl80211_driver, CONFIG_DRIVER_NL80211_QCA)

# Set WiFi implementation to mac80211_hwsim
PRODUCT_VENDOR_PROPERTIES += ro.vendor.wifi_impl=mac8011_hwsim_virtio

# Enable mac80211_hwsim enforcement
$(call soong_config_append,cvdhost,enforce_mac80211_hwsim,true)
```

### 2.2 เพิ่ม Bootconfig

แก้ไขไฟล์ `device/redroid/redroid_x86_64/BoardConfig.mk`:

```makefile
# เพิ่มบรรทัดนี้เข้าไปใน BOARD_BOOTCONFIG

BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim
```

---

## 🔧 Step 3: สร้าง Init Script สำหรับ WiFi

สร้างไฟล์ `device/redroid/redroid_x86_64/init.wifi.rc`:

```bash
# WiFi Hardware Simulator Init Script
service mac80211_create_radios /vendor/bin/mac80211_create_radios
    class late_start
    user root
    group root
    oneshot
    disabled

service init_wifi /vendor/bin/init.wifi.sh
    class late_start
    user root
    group root wakelock wifi
    oneshot
    disabled

on post-fs-data
    # Create WiFi directories
    mkdir /data/vendor/wifi 0770 wifi wifi
    mkdir /data/vendor/wifi/wpa 0770 wifi wifi
    mkdir /data/vendor/wifi/wpa/sockets 0770 wifi wifi
    
    # Start WiFi initialization
    start mac80211_create_radios
    start init_wifi
```

จากนั้นเพิ่มใน `device.mk`:

```makefile
# WiFi Init Script
PRODUCT_COPY_FILES += \
    device/redroid/redroid_x86_64/init.wifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.wifi.rc
```

---

## 🏗️ Step 4: Rebuild AOSP

```bash
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug

# Clean WiFi modules
m clean-wifi
m clean-com.google.cf.wifi_hwsim

# Rebuild
m -j$(nproc)
```

---

## 🐳 Step 5: สร้าง Docker Image ใหม่

```bash
cd ~/redroid-samsung-thai/out/target/product/redroid_x86_64

# Unmount if already mounted
sudo umount system vendor 2>/dev/null || true

# Mount
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro

# Create new Docker image with WiFi HWSim
sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
  docker import \
  -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
  - redroid-samsung-thai:14-wifi-hwsim

sudo umount system vendor

echo "✅ Image created: redroid-samsung-thai:14-wifi-hwsim"
```

---

## 🚀 Step 6: รัน Container พร้อม WiFi HWSim

### 6.1 โหลด Kernel Module (บน Host)

```bash
# โหลด mac80211_hwsim module
sudo modprobe mac80211_hwsim radios=1

# ตรวจสอบ
lsmod | grep mac80211_hwsim
```

### 6.2 สร้าง Startup Script

สร้างไฟล์ `~/start-samsung-thai-wifi-hwsim.sh`:

```bash
#!/bin/bash

# Load mac80211_hwsim module
echo "Loading mac80211_hwsim kernel module..."
sudo modprobe mac80211_hwsim radios=1

# Generate MAC address
MAC_ADDR="A8:5E:45:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/:$//')"

echo "Starting redroid with WiFi Hardware Simulator..."

docker run -itd --rm --privileged \
    --name redroid-samsung-thai \
    --pull never \
    -v ~/data-samsung-thai:/data \
    -p 5555:5555 \
    redroid-samsung-thai:14-wifi-hwsim \
    androidboot.hardware=redroid \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=2340 \
    androidboot.redroid_dpi=420 \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=auto \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.carrier=AIS \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    ro.boot.wifimacaddr=$MAC_ADDR \
    ro.vendor.wifi_impl=mac8011_hwsim_virtio \
    ro.setupwizard.mode=DISABLED

echo "=========================================="
echo "✅ Samsung Galaxy A54 5G (Thai) with WiFi HWSim"
echo "📡 WiFi: Hardware Simulated (wlan0)"
echo "📱 Carrier: AIS"
echo "🌐 MAC: $MAC_ADDR"
echo "🔌 Connect: adb connect localhost:5555"
echo "=========================================="
```

```bash
chmod +x ~/start-samsung-thai-wifi-hwsim.sh
```

---

## 🧪 Step 7: Testing & Verification

### 7.1 Start Container

```bash
~/start-samsung-thai-wifi-hwsim.sh
sleep 30  # รอ Android boot เสร็จ
```

### 7.2 Connect ADB

```bash
adb connect localhost:5555
```

### 7.3 ตรวจสอบ WiFi Interface

```bash
# ตรวจสอบว่ามี wlan0 interface จริง
adb shell ip link show wlan0

# Expected output:
# 3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
```

### 7.4 ตรวจสอบ WPA Supplicant

```bash
# ตรวจสอบว่า wpa_supplicant ทำงานอยู่
adb shell ps -A | grep wpa_supplicant

# ดู logs
adb logcat | grep -i wifi
```

### 7.5 ทดสอบ WiFi Settings

```bash
# เปิด WiFi Settings ใน Android
adb shell am start -a android.settings.WIFI_SETTINGS

# หรือใช้ command line
adb shell svc wifi enable
adb shell dumpsys wifi
```

---

## 📊 Comparison: Before vs After

### Before (Mocked WiFi):
```bash
adb shell ip link show wlan0
# Error: Device not found
```

### After (WiFi HWSim):
```bash
adb shell ip link show wlan0
# 3: wlan0: <BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state UP
```

---

## 🐛 Troubleshooting

### Problem 1: mac80211_hwsim module not found

```bash
# ตรวจสอบ kernel config
zcat /proc/config.gz | grep MAC80211_HWSIM

# ถ้าไม่มี ต้อง compile kernel ใหม่ด้วย:
# CONFIG_MAC80211_HWSIM=m
```

### Problem 2: wlan0 interface ไม่ปรากฏ

```bash
# ตรวจสอบ logs
docker logs redroid-samsung-thai
adb logcat | grep -E "wifi|wlan"

# ตรวจสอบว่า APEX ถูก mount
adb shell ls -la /apex/com.android.wifi.hal
```

### Problem 3: WiFi ไม่สามารถ scan ได้

```bash
# Restart WiFi services
adb shell stop
adb shell start

# หรือ restart container
docker restart redroid-samsung-thai
```

---

## 🎯 Advanced: Simulating Real WiFi Networks

หลังจากมี wlan0 จริงแล้ว คุณสามารถจำลอง WiFi networks ได้:

```bash
# สร้าง fake WiFi AP (ต้องใช้ hostapd บน host)
sudo create_ap wlan0 eth0 "AIS_Fibre_5G" "password123"

# Android จะสามารถ scan และ connect ได้จริง!
```

---

## 📚 References

- [Cuttlefish WiFi Documentation](https://android.googlesource.com/device/google/cuttlefish/)
- [mac80211_hwsim Kernel Module](https://wireless.wiki.kernel.org/en/users/drivers/mac80211_hwsim)
- [WPA Supplicant Configuration](https://w1.fi/wpa_supplicant/)

---

## ⚠️ Important Notes

1. **Performance**: WiFi HWSim จะใช้ทรัพยากรมากกว่า mocked WiFi เล็กน้อย
2. **Compatibility**: ต้องการ kernel ที่รองรับ mac80211_hwsim (Linux 5.10+)
3. **Security**: WiFi HWSim ทำงานในโหมด monitor/managed ได้จริง
4. **Container**: ต้องรัน container ในโหมด `--privileged`

---

## 🎉 Summary

หลังจากทำตามขั้นตอนนี้เสร็จ คุณจะได้:

- ✅ Virtual WiFi interface (wlan0) ที่ทำงานจริง
- ✅ WPA Supplicant ที่ทำงานได้
- ✅ สามารถ scan และ connect WiFi networks ได้
- ✅ Apps ที่ต้องการ WiFi จริงจะทำงานได้ทั้งหมด
- ✅ WiFi Settings ใช้งานได้เต็มรูปแบบ

**Happy Building! 🚀**

---

<div align="center">
Made with ❤️ for Thai Developers
</div>
