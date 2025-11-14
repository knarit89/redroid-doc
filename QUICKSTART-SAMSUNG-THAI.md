# 🇹🇭 Quick Start Guide - Samsung Thailand Edition

## ภาพรวม
Build Redroid จำลองเครื่อง **Samsung Galaxy A54 5G** (รุ่นไทย SM-A546E) พร้อม:
- ✅ **MindTheGapps** - Gmail, Maps, YouTube, Drive, Photos ฯลฯ
- ✅ **AIS Thailand** - เครือข่าย Cellular จำลอง
- ✅ **Fake WiFi** - พร้อม MAC Address แบบ Samsung
- ✅ **GPS Bangkok** - พิกัดกรุงเทพฯ
- ✅ **Thai Locale** - ภาษาไทย, เขต Asia/Bangkok

---

## 🚀 วิธีใช้งานแบบเร็ว (3 ขั้นตอน)

### ขั้นที่ 1: Build อัตโนมัติ
```bash
cd ~/redroid-doc
chmod +x auto-build-samsung-thai.sh
./auto-build-samsung-thai.sh
```

**⏱️ ใช้เวลา**: 3-6 ชั่วโมง (ขึ้นกับ CPU)

### ขั้นที่ 2: เริ่มต้น Redroid
```bash
~/start-samsung-thai.sh
```

### ขั้นที่ 3: Setup Network จำลอง
```bash
# รอ 30 วินาที ให้ boot เสร็จ
sleep 30

# Setup fake network
chmod +x ~/redroid-doc/fake-network-advanced.sh
~/redroid-doc/fake-network-advanced.sh
```

### เชื่อมต่อและใช้งาน
```bash
# เชื่อมต่อ ADB
adb connect localhost:5555

# ดูหน้าจอ
scrcpy -s localhost:5555 --window-title "Samsung A54 Thai"
```

---

## 📋 ข้อมูลเครื่องที่จำลอง

| รายการ | ค่า |
|--------|-----|
| **รุ่น** | Samsung Galaxy A54 5G |
| **Model** | SM-A546E (Thailand) |
| **Build** | A546EDXU3CXH3 |
| **Android** | 14 (API 34) |
| **Carrier** | AIS (52001) |
| **Network** | 5G/LTE |
| **Display** | 1080x2340, 420 DPI, 60 FPS |
| **Location** | Bangkok (Siam Paragon) |
| **Language** | Thai (th-TH) |
| **Timezone** | Asia/Bangkok |

---

## 🎯 คำสั่งที่ใช้บ่อย

### จัดการ Container
```bash
# Start
~/start-samsung-thai.sh

# Stop
docker stop redroid-samsung-thai

# Restart
docker restart redroid-samsung-thai

# ดู logs
docker logs -f redroid-samsung-thai

# เข้า shell
docker exec -it redroid-samsung-thai sh
```

### ตรวจสอบข้อมูล
```bash
# เชื่อมต่อ
adb connect localhost:5555

# ดูข้อมูลเครื่อง
adb shell getprop ro.product.model
# Output: SM-A546E

# ดู Carrier
adb shell getprop gsm.operator.alpha
# Output: AIS

# ดู MAC Address
adb shell getprop ro.boot.wifimacaddr
# Output: A8:5E:45:XX:XX:XX

# ดู IMEI
adb shell getprop ro.ril.oem.imei

# ดู Build Fingerprint
adb shell getprop ro.build.fingerprint

# ดูข้อมูลทั้งหมด
adb shell getprop | grep -E "product|carrier|operator|wifi"
```

### จัดการแอป
```bash
# ติดตั้งแอป
adb install app.apk

# ถอนแอป
adb uninstall com.example.app

# ดูแอปที่ติดตั้ง
adb shell pm list packages

# เปิดแอป
adb shell am start -n com.example.app/.MainActivity
```

### Screenshot & Recording
```bash
# Screenshot
adb exec-out screencap -p > screenshot.png

# Screen recording (30 วินาที)
adb shell screenrecord /sdcard/video.mp4
# กด Ctrl+C เมื่อเสร็จ
adb pull /sdcard/video.mp4
```

---

## 🔧 Configuration พิเศษ

### เปลี่ยน Display Resolution
```bash
docker run -itd --rm --privileged \
    --name redroid-samsung-thai \
    -v ~/data-samsung-thai:/data \
    -p 5555:5555 \
    redroid-samsung-thai:14-mindthegapps \
    androidboot.redroid_width=1440 \
    androidboot.redroid_height=3088 \
    androidboot.redroid_dpi=560 \
    androidboot.redroid_fps=120
```

### เปลี่ยน Carrier (ใช้ DTAC แทน AIS)
```bash
# เพิ่มตอน start container
gsm.operator.alpha=DTAC \
gsm.operator.numeric=52005 \
gsm.sim.operator.alpha=DTAC \
gsm.sim.operator.numeric=52005
```

### เปลี่ยน Location (เช่น Chiang Mai)
```bash
adb shell setprop persist.sys.mock.location.latitude 18.788252
adb shell setprop persist.sys.mock.location.longitude 98.985367
```

---

## 📦 GApps Apps ที่รวมอยู่ (MindTheGapps)

### Core Apps
- ✅ Google Play Store
- ✅ Google Play Services
- ✅ Google Services Framework

### Communication
- ✅ Gmail
- ✅ Google Messages
- ✅ Google Dialer
- ✅ Google Contacts

### Productivity
- ✅ Google Calendar
- ✅ Google Drive
- ✅ Google Docs/Sheets/Slides
- ✅ Google Keep

### Media & Entertainment
- ✅ YouTube
- ✅ YouTube Music
- ✅ Google Photos
- ✅ Google Play Movies & TV

### Utilities
- ✅ Google Maps
- ✅ Google Chrome
- ✅ Google Files
- ✅ Google Calculator
- ✅ Google Clock

### Additional
- ✅ Google Duo (Meet)
- ✅ Google Assistant
- ✅ Google Lens
- ✅ Android Auto

---

## 🐛 Troubleshooting

### Container หยุดทำงานทันที
```bash
# ดู logs
docker logs redroid-samsung-thai

# ตรวจสอบ kernel modules
lsmod | grep -E "binder|ashmem"

# ติดตั้ง modules (ถ้าจำเป็น)
sudo apt install linux-modules-extra-$(uname -r)
sudo modprobe binder_linux devices="binder,hwbinder,vndbinder"
sudo modprobe ashmem_linux
```

### ADB เชื่อมต่อไม่ได้
```bash
# ตรวจสอบ container ทำงานหรือไม่
docker ps | grep redroid

# Restart adb
adb kill-server
adb start-server
adb connect localhost:5555

# ตรวจสอบ port
sudo netstat -tlnp | grep 5555
```

### Google Play ไม่ทำงาน
```bash
# ล้าง cache
adb shell pm clear com.android.vending
adb shell pm clear com.google.android.gms

# Restart container
docker restart redroid-samsung-thai
```

### Network ไม่แสดง
```bash
# รัน setup script อีกครั้ง
~/redroid-doc/fake-network-advanced.sh

# หรือ manual setup
adb shell svc wifi enable
adb shell svc data enable
adb shell settings put global airplane_mode_on 0
```

### Build ล้มเหลว
```bash
# เคลียร์และ build ใหม่
rm -rf ~/redroid-samsung-thai/out
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
```

---

## 💡 Tips & Tricks

### 1. เพิ่ม Root Access
```bash
docker run ... \
    ro.secure=0 \
    ro.debuggable=1
```

### 2. Share Folder กับ Host
```bash
docker run ... \
    -v ~/shared:/sdcard/shared
```

### 3. เพิ่ม RAM สำหรับ Container
```bash
docker run ... \
    --memory="4g" \
    --memory-swap="6g"
```

### 4. ใช้ GPU Hardware Acceleration
```bash
docker run ... \
    --device /dev/dri \
    androidboot.redroid_gpu_mode=host
```

### 5. Multiple Instances
```bash
# Instance 1
docker run ... --name redroid-1 -p 5555:5555 ...

# Instance 2
docker run ... --name redroid-2 -p 5556:5555 ...

# Connect
adb connect localhost:5555
adb connect localhost:5556
```

---

## 📚 ไฟล์สำคัญ

- **`build-samsung-thai.md`** - คู่มือ build แบบละเอียด
- **`auto-build-samsung-thai.sh`** - สคริปต์ build อัตโนมัติ
- **`fake-network-advanced.sh`** - Setup network จำลอง
- **`start-samsung-thai.sh`** - Start container (สร้างหลัง build)

---

## ⚠️ ข้อควรระวัง

1. **ลิขสิทธิ์**: ใช้เพื่อการทดสอบเท่านั้น
2. **ความเป็นส่วนตัว**: ข้อมูลจำลอง (IMEI, MAC) เพื่อการทดสอบ
3. **Security**: อย่าเปิด ADB port (5555) ไปยัง Internet
4. **Performance**: ใช้ GPU acceleration เพื่อประสิทธิภาพที่ดี

---

## 📞 ช่วยเหลือ

- **Redroid Docs**: https://github.com/remote-android/redroid-doc
- **Slack**: remote-android.slack.com
- **Issues**: https://github.com/remote-android/redroid-doc/issues

---

## 🎉 สนุกกับการใช้งาน!

Build เสร็จแล้ว คุณมี **Samsung Galaxy A54 5G (Thailand Edition)** พร้อม GApps เต็มรูปแบบบน Docker แล้ว! 🚀
