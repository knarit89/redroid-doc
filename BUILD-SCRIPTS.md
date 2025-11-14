# 📜 Build Scripts สำหรับ Redroid Samsung Thai

## 📂 Scripts ทั้งหมด

### 🚀 Main Build Scripts

| Script | วัตถุประสงค์ | ใช้เมื่อ |
|--------|------------|---------|
| **`build-android13-samsung-thai.sh`** | Setup และเตรียม Android 13 build | เริ่มต้น build ใหม่ |
| **`start-build.sh`** | เริ่ม compile Android | หลังจาก setup เสร็จ |
| **`create-image.sh`** | สร้าง Docker image จาก build | หลัง build เสร็จ |
| **`continue-build.sh`** | Resume build ที่ล้มเหลว | เมื่อ build fail |
| **`finish-build.sh`** | Complete setup + build | Alternative script |

### 📝 Legacy Scripts

| Script | วัตถุประสงค์ | สถานะ |
|--------|------------|-------|
| **`auto-build-samsung-thai.sh`** | Build Android 14 (เก่า) | ❌ ใช้ไม่ได้ (พื้นที่ไม่พอ) |

---

## 🎯 Workflow ปัจจุบัน

### สถานะตอนนี้ (14 พ.ย. 2025 - 02:56 น.)

```
❌ Build หยุดเพราะพื้นที่ฮาร์ดดิสก์เต็ม
├─ Android 13 source: ~132GB
├─ Available space: 2.6GB
└─ Required: ~50GB เพิ่มเติม
```

---

## 🔧 วิธีแก้ปัญหาพื้นที่เต็ม

### ทางเลือกที่ 1: Build แบบ Minimal (No GApps) ⚠️

```bash
cd /root/redroid-doc

# ลบ GApps configuration
sed -i '/gapps/d' ~/redroid-samsung-thai/device/redroid/redroid_x86_64/device.mk

# Clean build output
docker exec redroid-builder bash -c "cd /src && rm -rf out"

# Restart build (No GApps)
./start-build.sh
```

**ผลลัพธ์:**
- ✅ ใช้พื้นที่น้อยกว่า (~100GB)
- ❌ ไม่มี Play Store, Gmail, Maps
- ℹ️ ต้องติดตั้ง GApps ด้วย APK ทีหลัง

---

### ทางเลือกที่ 2: ขยายพื้นที่ฮาร์ดดิสก์ ✅ (แนะนำ)

```bash
# 1. Stop container
docker stop redroid-builder

# 2. ขยาย disk ผ่าน hosting provider → 250-300GB

# 3. Resize filesystem
sudo resize2fs /dev/vda2

# 4. Resume build
docker start redroid-builder
docker exec redroid-builder bash -c "cd /src && . build/envsetup.sh && lunch redroid_x86_64-userdebug && m -j3"
```

**ผลลัพธ์:**
- ✅ Build ครบถ้วน พร้อม GApps
- ✅ Samsung Thai Edition
- ✅ MindTheGapps included

---

### ทางเลือกที่ 3: เริ่มใหม่ (Clean Slate)

```bash
# ลบทุกอย่างและเริ่มใหม่
docker stop redroid-builder
rm -rf ~/redroid-samsung-thai

# ขยาย disk ก่อน!

# เริ่มใหม่
cd /root/redroid-doc
./build-android13-samsung-thai.sh
```

---

## 📊 พื้นที่ที่ใช้

| Component | Size | Location |
|-----------|------|----------|
| **Android Source** | ~50GB | `~/redroid-samsung-thai` |
| **Build Output** | ~80GB | `~/redroid-samsung-thai/out` |
| **MindTheGapps** | ~2GB | `~/redroid-samsung-thai/vendor/gapps` |
| **Total** | **~132GB** | |

---

## ⚙️ Build Settings

### Current Configuration

```makefile
# Device: Samsung Galaxy A54 5G (Thai)
PRODUCT_MODEL=SM-A546E
PRODUCT_BRAND=samsung
PRODUCT_NAME=a54xdx

# Android Version
PLATFORM_VERSION=13
BUILD_ID=TQ3C.230901.001.B1

# GApps
GAPPS_VARIANT=mindthegapps (tau revision)

# Build Options
PARALLEL_JOBS=3 (-j3)
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES=true
```

---

## 🆘 Troubleshooting

### Error: No space left on device

**สาเหตุ:** Build ใช้พื้นที่ ~160GB แต่ disk มีแค่ 159GB

**วิธีแก้:**
1. ขยาย disk เป็น 250-300GB
2. หรือ build แบบไม่มี GApps

---

### Error: Build stopped/failed

**ตรวจสอบ:**
```bash
# Check container status
docker ps -a

# Check logs
docker logs redroid-builder | tail -100

# Check disk space
df -h /
```

**Resume build:**
```bash
docker exec redroid-builder bash -c "cd /src && . build/envsetup.sh && lunch redroid_x86_64-userdebug && m -j3"
```

---

### Error: Container not responding

**แก้:**
```bash
# Restart container
docker restart redroid-builder

# Or rebuild container
docker rm -f redroid-builder
cd ~/redroid-doc/android-builder-docker
docker build -t redroid-builder .
```

---

## 📝 Notes

### Build Time
- **Total time**: 6-8 ชั่วโมง (with 3 cores)
- **Sync code**: 1-2 ชั่วโมง
- **Compile**: 4-6 ชั่วโมง
- **Package**: 10-20 นาที

### System Requirements
- **CPU**: 3+ cores
- **RAM**: 16GB minimum (32GB recommended)
- **Storage**: **250GB minimum** (300GB recommended)
- **Internet**: Fast connection for source download

---

## 🎁 Final Output

เมื่อ build สำเร็จจะได้:

```
Docker Image: redroid-samsung-thai:13-mindthegapps
├── Android: 13 (API 33)
├── Device: Samsung Galaxy A54 5G (SM-A546E)
├── GApps: MindTheGapps (Play Store, Gmail, Maps, etc.)
├── Locale: Thai (th-TH)
├── Carrier: AIS Thailand
└── Features: Fake WiFi, GPS Bangkok, Thai keyboard
```

**Start command:**
```bash
~/start-samsung-thai.sh
```

---

## 📞 Support

ถ้าเจอปัญหา:
1. Check logs: `docker logs redroid-builder`
2. Check disk: `df -h /`
3. Resume build: `docker exec redroid-builder ...`

---

**Last Updated:** 14 Nov 2025, 02:56 AM  
**Status:** ⚠️ Build stopped - No space left on device  
**Next Action:** ขยายพื้นที่ฮาร์ดดิสก์เป็น 250-300GB
