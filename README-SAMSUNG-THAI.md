# 🇹🇭 Redroid Samsung Thailand Edition

> **Full-featured GMS (MindTheGapps) + Fake Network Simulation**

จำลองเครื่อง **Samsung Galaxy A54 5G** รุ่นไทย (SM-A546E) บน Docker พร้อม Google Mobile Services แบบเต็มรูปแบบและการจำลอง Cellular Network, WiFi ที่สมจริง

---

## ✨ Features

### 📱 Device Emulation
- **Model**: Samsung Galaxy A54 5G (SM-A546E)
- **Build**: A546EDXU3CXH3 (Official Thai Build)
- **Android**: Version 14 (API Level 34)
- **Architecture**: x86_64
- **Display**: 1080x2340 @ 420 DPI, 60 FPS

### 🌐 Network Simulation
- **Cellular**: AIS Thailand (MCC: 520, MNC: 01)
- **Network Type**: 5G/LTE with VoLTE
- **Signal**: Excellent (-53 dBm)
- **WiFi**: Connected @ 866 Mbps (WiFi 5)
- **MAC Address**: Samsung OUI (A8:5E:45:XX:XX:XX)
- **IMEI**: Random fake IMEI (352094XXXXXXXXX)

### 📍 Location
- **City**: Bangkok, Thailand
- **Coordinates**: Siam Paragon (13.746584, 100.534821)
- **Timezone**: Asia/Bangkok (UTC+7)
- **Locale**: Thai (th-TH)

### 📦 Pre-installed Apps (MindTheGapps)
**Essential Google Apps** including:
- Google Play Store & Services
- Gmail, Calendar, Drive, Docs/Sheets/Slides
- YouTube, YouTube Music, Photos
- Maps, Chrome, Assistant, Lens
- Messages, Dialer, Contacts
- And many more...

---

## 🚀 Quick Start

### Prerequisites
- **OS**: Ubuntu 20.04+ (or compatible Linux)
- **CPU**: 3+ cores (Build ใช้เวลา 3-6 ชั่วโมง)
- **RAM**: 16GB minimum (แนะนำ 32GB)
- **Storage**: 200GB free space
- **Docker**: Version 20.10+

### Option 1: Automated Build (แนะนำ)

```bash
cd /root/redroid-doc
./auto-build-samsung-thai.sh
```

สคริปต์จะทำทุกอย่างอัตโนมัติ:
1. ✅ ตรวจสอบสเปคเครื่อง
2. ✅ ติดตั้ง dependencies
3. ✅ ดาวน์โหลด AOSP + Redroid + Open GApps
4. ✅ Apply patches
5. ✅ สร้าง Samsung Thai configuration
6. ✅ Build Android (3-6 ชั่วโมง)
7. ✅ สร้าง Docker image
8. ✅ สร้าง startup scripts

### Option 2: Manual Build

ดูคู่มือละเอียดใน [`build-samsung-thai.md`](build-samsung-thai.md)

---

## 📖 Usage

### 1. Start Container
```bash
~/start-samsung-thai.sh
```

### 2. Setup Fake Network
```bash
# รอ 30 วินาที ให้ Android boot เสร็จ
sleep 30
./fake-network-advanced.sh
```

### 3. Connect & Use
```bash
# Connect ADB
adb connect localhost:5555

# View Screen
scrcpy -s localhost:5555
```

---

## 📂 Project Structure

```
redroid-doc/
├── README-SAMSUNG-THAI.md           # ไฟล์นี้
├── QUICKSTART-SAMSUNG-THAI.md       # คู่มือรวดเร็ว
├── build-samsung-thai.md            # คู่มือ build แบบละเอียด
│
├── auto-build-samsung-thai.sh       # 🚀 Build อัตโนมัติ (ใช้ไฟล์นี้!)
├── fake-network-advanced.sh         # Setup network จำลอง
│
└── android-builder-docker/          # Docker builder
    ├── Dockerfile
    └── README.md
```

---

## 📋 System Requirements Check

```bash
# ตรวจสอบ RAM
free -h
# ต้องการ: 16GB+ (แนะนำ 32GB)

# ตรวจสอบพื้นที่ว่าง
df -h
# ต้องการ: 200GB+

# ตรวจสอบ CPU cores
nproc
# ต้องการ: 3+ cores

# ตรวจสอบ Docker
docker --version
# ต้องการ: 20.10+
```

**เครื่องของคุณ**:
- ✅ CPU: 3 cores
- ✅ RAM: 31GB
- ⚠️ Storage: 126GB (แนะนำ 200GB+ แต่พอใช้ได้)
- ✅ Docker: 28.5.1

---

## 🎯 Common Commands

### Container Management
```bash
# Start
~/start-samsung-thai.sh

# Stop
docker stop redroid-samsung-thai

# Restart
docker restart redroid-samsung-thai

# Logs
docker logs -f redroid-samsung-thai
```

### Device Info
```bash
adb shell getprop ro.product.model      # SM-A546E
adb shell getprop gsm.operator.alpha    # AIS
adb shell getprop ro.boot.wifimacaddr   # A8:5E:45:XX:XX:XX
adb shell getprop ro.ril.oem.imei       # 352094XXXXXXXXX
```

### Network Status
```bash
adb shell dumpsys wifi | grep "Wi-Fi is"
adb shell dumpsys telephony.registry | grep mServiceState
```

---

## 🔧 Customization

### Change Display Resolution
Edit `~/start-samsung-thai.sh`:
```bash
androidboot.redroid_width=1440 \
androidboot.redroid_height=3088 \
androidboot.redroid_dpi=560 \
androidboot.redroid_fps=120
```

### Change Carrier (DTAC, True)
Edit `fake-network-advanced.sh`:
```bash
# For DTAC
setprop gsm.operator.alpha "DTAC"
setprop gsm.operator.numeric "52005"

# For True
setprop gsm.operator.alpha "TRUE-H"
setprop gsm.operator.numeric "52004"
```

### Change Location
```bash
adb shell setprop persist.sys.mock.location.latitude 18.788252
adb shell setprop persist.sys.mock.location.longitude 98.985367
```

---

## 🔍 Verification

### Test Device Identity
```bash
adb shell getprop | grep -E "product|build.finger"
```

Expected output:
```
[ro.product.brand]: [samsung]
[ro.product.model]: [SM-A546E]
[ro.product.name]: [a54xdx]
[ro.build.fingerprint]: [samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys]
```

### Test Network
```bash
adb shell getprop | grep -E "operator|carrier|wifi"
```

Expected output:
```
[gsm.operator.alpha]: [AIS]
[gsm.operator.numeric]: [52001]
[ro.carrier]: [AIS]
[ro.boot.wifimacaddr]: [A8:5E:45:XX:XX:XX]
```

### Test Google Play
```bash
adb shell pm list packages | grep -E "gms|vending|gsf"
```

Should show:
- `com.google.android.gms` (Play Services)
- `com.android.vending` (Play Store)
- `com.google.android.gsf` (Services Framework)

---

## 🐛 Troubleshooting

### Build Failed
```bash
# Clean and rebuild
rm -rf ~/redroid-samsung-thai/out
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)
```

### Container Won't Start
```bash
# Check kernel modules
sudo modprobe binder_linux devices="binder,hwbinder,vndbinder"
sudo modprobe ashmem_linux

# Check logs
docker logs redroid-samsung-thai
dmesg -T
```

### ADB Connection Issues
```bash
adb kill-server
adb start-server
adb connect localhost:5555
```

### Google Play Not Working
```bash
# Clear data
adb shell pm clear com.android.vending
adb shell pm clear com.google.android.gms

# Restart
docker restart redroid-samsung-thai
```

ดูเพิ่มเติมใน [`QUICKSTART-SAMSUNG-THAI.md`](QUICKSTART-SAMSUNG-THAI.md)

---

## 📚 Documentation

| ไฟล์ | รายละเอียด |
|------|-----------|
| [`README-SAMSUNG-THAI.md`](README-SAMSUNG-THAI.md) | Overview (ไฟล์นี้) |
| [`QUICKSTART-SAMSUNG-THAI.md`](QUICKSTART-SAMSUNG-THAI.md) | Quick Start Guide |
| [`build-samsung-thai.md`](build-samsung-thai.md) | Detailed Build Guide |
| [`auto-build-samsung-thai.sh`](auto-build-samsung-thai.sh) | Automated Build Script |
| [`fake-network-advanced.sh`](fake-network-advanced.sh) | Network Setup Script |

---

## ⚠️ Disclaimers

1. **Legal**: ใช้เพื่อการทดสอบและพัฒนาเท่านั้น
2. **Privacy**: ข้อมูลทั้งหมด (IMEI, MAC, etc.) เป็นการจำลองเท่านั้น
3. **Security**: อย่าเปิด ADB port (5555) ออก Internet
4. **Google**: Open GApps เป็น unofficial, ใช้ความเสี่ยงของคุณเอง
5. **Performance**: แนะนำใช้ GPU acceleration

---

## 🤝 Contributing

Found a bug or want to improve? 
- Open an issue on GitHub
- Join Slack: remote-android.slack.com
- Email: ziyang.zhou@outlook.com

---

## 📝 License

- **Redroid**: Apache 2.0
- **AOSP**: Apache 2.0
- **Open GApps**: Proprietary (Google Apps)
- **This Project**: MIT

---

## 🎉 Ready to Build?

```bash
cd /root/redroid-doc
./auto-build-samsung-thai.sh
```

**Build เสร็จแล้วจะได้:**
- ✅ Samsung Galaxy A54 5G (Thai) บน Docker
- ✅ Open GApps Stock (60+ apps)
- ✅ AIS Network Simulation
- ✅ Fake WiFi & GPS
- ✅ Full Thai Localization

**Happy Building! 🚀**

---

<div align="center">
Made with ❤️ for Thai Developers
</div>
