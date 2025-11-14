# 🎨 Google Pixel Theme Guide

## Overview

เปลี่ยนธีม UI จาก **Samsung One UI** เป็น **Google Pixel Material You** พร้อมคงความสามารถอื่นๆไว้:
- ✅ Google Pixel 7 Pro look & feel
- ✅ Material You design
- ✅ Thai localization (ยังเป็นภาษาไทย)
- ✅ WiFi HWSim (wlan0)
- ✅ Virtual SIM (RIL daemon)
- ✅ AIS Thailand carrier

---

## 🎯 ความแตกต่าง

### Samsung Theme vs Pixel Theme

| Feature | Samsung | Pixel |
|---------|---------|-------|
| **Brand** | Samsung | Google |
| **Model** | Galaxy A54 5G | Pixel 7 Pro |
| **UI** | One UI | Material You |
| **Launcher** | One UI Home | Pixel Launcher |
| **Icons** | Samsung Icons | Pixel Icons |
| **Colors** | Samsung Palette | Material You |
| **Settings** | Samsung Settings | Pixel Settings |
| **Fonts** | Samsung One | Google Sans |
| **Locale** | ✅ Thai | ✅ Thai |
| **Carrier** | ✅ AIS | ✅ AIS |

---

## 🚀 Quick Switch (3 Steps)

### Step 1: Switch Theme Configuration
```bash
cd /root/redroid-doc
./switch-to-pixel-theme.sh
```

### Step 2: Rebuild AOSP
```bash
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
```

### Step 3: Create Image
```bash
cd ~/redroid-samsung-thai/out/target/product/redroid_x86_64
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro
sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
  docker import \
  -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
  - redroid-pixel-thai:14-full
sudo umount system vendor
```

---

## 🎨 Material You Features

### ที่ได้รับ:
- ✅ **Dynamic Color** - สีที่ปรับตาม wallpaper
- ✅ **Rounded Corners** - มุมมนสไตล์ Pixel
- ✅ **Pixel Launcher** - Home screen แบบ Pixel
- ✅ **Material You Icons** - ไอคอนแบบ Material 3
- ✅ **Google Sans Font** - ฟอนต์ Google Sans
- ✅ **Pixel Settings** - หน้า Settings แบบ Pixel
- ✅ **Quick Settings** - Panel แบบ Pixel

### Thai Localization ยังคงอยู่:
- ✅ ภาษาไทย (th-TH)
- ✅ เขต Asia/Bangkok
- ✅ ค่าย AIS Thailand
- ✅ รูปแบบวันที่แบบไทย

---

## 📊 Comparison

### Device Info

**Before (Samsung):**
```
Brand: samsung
Model: SM-A546E
Name: Galaxy A54 5G
Build: A546EDXU3CXH3
```

**After (Pixel):**
```
Brand: google
Model: Pixel 7 Pro
Name: cheetah
Build: TQ3A.230805.001
```

### UI Look

**Samsung One UI:**
- สีน้ำเงิน/เขียว Samsung
- ไอคอนแบบ Samsung
- One UI Home launcher
- Settings แบบ Samsung

**Pixel Material You:**
- สีตาม wallpaper (Dynamic)
- ไอคอนแบบ Material You
- Pixel Launcher
- Settings แบบ Pixel

---

## 🔧 Manual Configuration

ถ้าอยากแก้ด้วยตัวเอง:

### Edit device.mk
```bash
nano ~/redroid-samsung-thai/device/redroid/redroid_x86_64/device.mk
```

**เปลี่ยนจาก:**
```makefile
# Samsung Thai Configuration
$(call inherit-product, device/redroid/redroid_x86_64/samsung_thai.mk)
```

**เป็น:**
```makefile
# Google Pixel Thai Configuration
$(call inherit-product, device/redroid/redroid_x86_64/pixel_thai.mk)
```

---

## 🎮 Running with Pixel Theme

### Start Container
```bash
~/start-samsung-thai-full.sh
```

**Output จะเป็น:**
```
📱 Device Information:
   Model:       Google Pixel 7 Pro
   Carrier:     Advanced Info Service
   Phone:       0812345678
```

### Verify Pixel Theme
```bash
adb connect localhost:5555

# Check device model
adb shell getprop ro.product.model
# Output: Pixel 7 Pro

# Check brand
adb shell getprop ro.product.brand
# Output: google

# Check build fingerprint
adb shell getprop ro.build.fingerprint
# Output: google/cheetah/cheetah:13/...
```

---

## 🔄 Switch Back to Samsung

### Option 1: Use script (create it)
```bash
# Revert changes in device.mk
cd ~/redroid-samsung-thai/device/redroid/redroid_x86_64
nano device.mk

# Comment pixel_thai.mk
# Uncomment samsung_thai.mk
```

### Option 2: Manual edit
```makefile
# Comment this
# $(call inherit-product, device/redroid/redroid_x86_64/pixel_thai.mk)

# Uncomment this
$(call inherit-product, device/redroid/redroid_x86_64/samsung_thai.mk)
```

Then rebuild.

---

## 🎯 Best of Both Worlds

### Pixel Theme + Thai Features:
```
✅ Google Pixel 7 Pro UI
✅ Material You design
✅ ภาษาไทย
✅ เขตเวลา Asia/Bangkok
✅ ค่าย AIS Thailand
✅ Virtual WiFi (wlan0)
✅ Virtual SIM card
✅ Custom phone number
```

---

## 💡 Tips

### 1. Pixel Launcher
หลัง boot เสร็จ:
- Swipe up → App Drawer แบบ Pixel
- Hold on Home → Wallpaper & Style (Material You)
- Settings → Wallpaper & Style → Theme colors

### 2. Material You Colors
เปลี่ยน wallpaper แล้วสีทั้งระบบจะเปลี่ยนตาม!

### 3. Google Apps
ทุก Google Apps จะมีลุค Material You:
- Chrome
- Gmail
- Google Photos
- Google Maps

### 4. Thai Keyboard
Google Keyboard จะมีภาษาไทย:
```bash
adb shell ime list -s
# Should show: com.google.android.inputmethod.latin
```

---

## 📱 Supported Pixel Models

คุณสามารถเปลี่ยนเป็น Pixel รุ่นอื่นได้:

### Pixel 7 Pro (Default)
```makefile
ro.product.model=Pixel 7 Pro
ro.product.device=cheetah
```

### Pixel 8 Pro
```makefile
ro.product.model=Pixel 8 Pro
ro.product.device=husky
ro.build.fingerprint=google/husky/husky:14/...
```

### Pixel 6 Pro
```makefile
ro.product.model=Pixel 6 Pro
ro.product.device=raven
```

แก้ไขใน `pixel_thai.mk` และ rebuild

---

## 🐛 Troubleshooting

### Problem: Launcher แสดงแปลกๆ
```bash
# Clear launcher data
adb shell pm clear com.google.android.apps.nexuslauncher
adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME
```

### Problem: สีไม่เปลี่ยน (Material You)
```bash
# Enable dynamic colors
adb shell cmd uimode night no
# Go to Settings → Wallpaper & Style → Theme colors
```

### Problem: ยังแสดงเป็น Samsung
```bash
# Check if pixel_thai.mk is being used
cat ~/redroid-samsung-thai/device/redroid/redroid_x86_64/device.mk | grep pixel_thai

# If not, run switch script again
cd /root/redroid-doc
./switch-to-pixel-theme.sh
```

---

## 🎉 Final Result

**Device:**
```
Google Pixel 7 Pro
Android 13/14
Material You Theme
Thai Localization
```

**Network:**
```
Carrier: AIS Thailand
WiFi: wlan0 (HWSim)
SIM: Virtual SIM (RIL)
Phone: Your custom number
```

**UI:**
```
Launcher: Pixel Launcher
Theme: Material You
Colors: Dynamic
Icons: Material You
Font: Google Sans
```

---

<div align="center">

## 🎨 Perfect Pixel Experience in Thai! 🇹🇭

**Material You + Thai + Full Simulation = Complete!**

</div>
