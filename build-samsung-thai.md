# Build Redroid - Samsung Thailand Edition with MindTheGapps

## สเปคเครื่องของคุณ
- **CPU**: 3 cores (Intel Broadwell)
- **RAM**: 31GB ✅
- **Storage**: 126GB free ✅
- **OS**: Ubuntu 5.15
- **Docker**: 28.5.1 ✅

## ข้อกำหนดสำหรับ Build AOSP
- RAM: อย่างน้อย 16GB (คุณมี 31GB ✅)
- Storage: อย่างน้อย 200GB (แนะนำให้เคลียร์พื้นที่เพิ่ม)
- เวลา Build: ประมาณ 3-6 ชั่วโมง (ขึ้นกับ CPU)

---

## ขั้นตอนที่ 1: ติดตั้ง Dependencies

```bash
# ติดตั้ง repo tool
sudo apt-get update
sudo apt-get install -y git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
  lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev \
  libxml2-utils xsltproc unzip python3 python-is-python3

# ติดตั้ง repo
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH
```

---

## ขั้นตอนที่ 2: ดาวน์โหลด Source Code

```bash
# สร้างโฟลเดอร์สำหรับ build
mkdir -p ~/redroid-samsung-thai
cd ~/redroid-samsung-thai

# เลือก Android version (แนะนำ Android 14)
# Android 14 (ใช้ r2 เพราะมี redroid patches รองรับ):
repo init -u https://android.googlesource.com/platform/manifest \
  --git-lfs --depth=1 -b android-14.0.0_r2

# เพิ่ม redroid manifests
git clone https://github.com/remote-android/local_manifests.git \
  .repo/local_manifests -b 14.0.0

# ดาวน์โหลด MindTheGapps (แทน Open GApps ที่ไม่สามารถดาวน์โหลดได้แล้ว)
cat > .repo/local_manifests/mindthegapps.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="mtg" fetch="https://gitlab.com/MindTheGapps/" />
  <project path="vendor/gapps" name="vendor_gapps" revision="upsilon" remote="mtg" />
</manifest>
EOF

# หมายเหตุ: MindTheGapps มี sources สำหรับทุก architecture แต่เราจะใช้เฉพาะ x86_64

# Sync code (ใช้เวลานาน! ~1-2 ชั่วโมง ขึ้นกับความเร็วอินเทอร์เน็ต)
repo sync -c -j$(nproc)

# ตรวจสอบว่า MindTheGapps ดาวน์โหลดสำเร็จ
ls -la vendor/gapps/
```

---

## ขั้นตอนที่ 3: Apply Redroid Patches

```bash
cd ~/redroid-samsung-thai

# Clone redroid patches
git clone https://github.com/remote-android/redroid-patches.git ~/redroid-patches

# Apply patches
~/redroid-patches/apply-patch.sh ~/redroid-samsung-thai
```

---

## ขั้นตอนที่ 4: ปรับแต่งเป็น Samsung Thailand

สร้างไฟล์ปรับแต่ง device properties:

```bash
# สร้างไฟล์ custom properties
cat > ~/redroid-samsung-thai/device/redroid/redroid_x86_64/samsung_thai.mk << 'EOF'
# Samsung Galaxy A54 5G (Thailand Model)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.product.device=a54x \
    ro.build.fingerprint=samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys \
    ro.build.description=a54xdxm-user 14 UP1A.231005.007 A546EDXU3CXH3 release-keys \
    ro.bootimage.build.fingerprint=samsung/a54xdxm/a54x:14/UP1A.231005.007/A546EDXU3CXH3:user/release-keys

# Thai Locale
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.locale=th-TH \
    persist.sys.language=th \
    persist.sys.country=TH \
    persist.sys.timezone=Asia/Bangkok

# WiFi MAC Address (Fake)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.boot.wifimacaddr=A8:5E:45:XX:XX:XX

# IMEI (Fake for testing - 15 digits starting with 35)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.ril.oem.imei=352094XXXXXXXXX \
    ro.ril.oem.meid=AABBCCDDEEFF

# Cellular Network - AIS Thailand
PRODUCT_PROPERTY_OVERRIDES += \
    ro.carrier=AIS \
    ro.telephony.default_network=10 \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    gsm.operator.iso-country=th \
    gsm.sim.operator.alpha=AIS \
    gsm.sim.operator.numeric=52001 \
    gsm.sim.operator.iso-country=th \
    persist.radio.multisim.config=dsds

# Network Type (5G capable)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_cdma_sub=0 \
    persist.radio.data_ltd_sys_ind=1 \
    persist.radio.voice_on_lte=1 \
    persist.radio.volte.dan_support=true \
    ro.telephony.iwlan_operation_mode=legacy

# Build info
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.version.release=14 \
    ro.build.version.sdk=34 \
    ro.bootimage.build.date=$(shell date -u +"%a %b %d %H:%M:%S UTC %Y") \
    ro.bootimage.build.date.utc=$(shell date -u +%s)

# Samsung features
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.PDA=A546EDXU3CXH3 \
    ro.build.changelist=28287709 \
    ro.build.official.release=true \
    ro.config.ringtone=Over_the_Horizon.ogg \
    ro.config.notification_sound=Skyline.ogg \
    ro.build.selinux=1
EOF
```

---

## ขั้นตอนที่ 5: เพิ่ม Open GApps Configuration

```bash
# แก้ไข device.mk ให้รวม GApps และ Samsung config
nano ~/redroid-samsung-thai/device/redroid/redroid_x86_64/device.mk
```

เพิ่มบรรทัดเหล่านี้ที่ท้ายไฟล์:

```makefile
# Include Samsung Thai customization
$(call inherit-product, device/redroid/redroid_x86_64/samsung_thai.mk)

# Include MindTheGapps - Full GApps Package (เฉพาะ x86_64)
$(call inherit-product, vendor/gapps/x86_64/x86_64-vendor.mk)
```

---

## ขั้นตอนที่ 6: สร้าง Docker Builder

```bash
cd ~/redroid-doc/android-builder-docker

# Build docker image สำหรับ build
docker build --build-arg userid=$(id -u) \
  --build-arg groupid=$(id -g) \
  --build-arg username=$(id -un) \
  -t redroid-builder .
```

---

## ขั้นตอนที่ 7: เริ่ม Build (ใช้เวลานาน!)

```bash
# เริ่ม builder container
docker run -it --rm \
  --hostname redroid-builder \
  --name redroid-builder \
  -v ~/redroid-samsung-thai:/src \
  redroid-builder

# ใน container:
cd /src
. build/envsetup.sh

# เลือก build target
lunch redroid_x86_64-userdebug

# เริ่ม build (ใช้เวลา 3-6 ชั่วโมง)
m -j$(nproc)
```

---

## ขั้นตอนที่ 8: สร้าง Docker Image จาก Build Output

หลังจาก build เสร็จ (ใน HOST ไม่ใช่ใน container):

```bash
cd ~/redroid-samsung-thai/out/target/product/redroid_x86_64

# Mount และสร้าง docker image
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro

sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
  docker import \
  -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
  - redroid-samsung-thai:14-mindthegapps

sudo umount system vendor
```

---

## ขั้นตอนที่ 9: รัน Redroid Container พร้อม Fake Network

สร้าง startup script:

```bash
cat > ~/start-samsung-thai.sh << 'EOF'
#!/bin/bash

# Generate random MAC address (Samsung OUI: A8:5E:45)
MAC_ADDR="A8:5E:45:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/:$//')"

docker run -itd --rm --privileged \
    --name redroid-samsung-thai \
    --pull never \
    -v ~/data-samsung:/data \
    -p 5555:5555 \
    redroid-samsung-thai:14-mindthegapps \
    androidboot.hardware=redroid \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=2340 \
    androidboot.redroid_dpi=420 \
    androidboot.redroid_fps=60 \
    androidboot.redroid_gpu_mode=auto \
    ro.product.brand=samsung \
    ro.product.manufacturer=samsung \
    ro.product.model=SM-A546E \
    ro.product.name=a54xdx \
    ro.product.device=a54x \
    ro.carrier=AIS \
    gsm.operator.alpha=AIS \
    gsm.operator.numeric=52001 \
    ro.boot.wifimacaddr=$MAC_ADDR \
    ro.setupwizard.mode=DISABLED

echo "==================================="
echo "Samsung Galaxy A54 5G (Thai) started"
echo "MAC Address: $MAC_ADDR"
echo "Carrier: AIS"
echo "Connect: adb connect localhost:5555"
echo "==================================="
EOF

chmod +x ~/start-samsung-thai.sh
```

---

## ขั้นตอนที่ 10: จำลอง WiFi และ Cellular Signal

สร้าง script สำหรับจำลอง network:

```bash
cat > ~/setup-fake-network.sh << 'EOF'
#!/bin/bash

CONTAINER_NAME="redroid-samsung-thai"

echo "Setting up fake network for Samsung Thai..."

# เข้า container และ setup
docker exec -it $CONTAINER_NAME sh << 'DOCKER_COMMANDS'

# Enable WiFi
svc wifi enable

# Set WiFi connected state
settings put global wifi_on 1
settings put global airplane_mode_on 0

# Set mobile data
svc data enable
settings put global mobile_data 1

# Set AIS network info
setprop gsm.operator.alpha "AIS"
setprop gsm.operator.numeric "52001"
setprop gsm.operator.iso-country "th"
setprop gsm.sim.operator.alpha "AIS"
setprop gsm.sim.operator.numeric "52001"

# Fake signal strength (excellent signal)
setprop gsm.network.type "LTE"
setprop telephony.lteOnCdmaDevice 1

# Set timezone
setprop persist.sys.timezone "Asia/Bangkok"

echo "✅ Fake network configured"
echo "📱 Carrier: AIS (52001)"
echo "📶 Signal: Excellent"
echo "📡 WiFi: Connected"

DOCKER_COMMANDS

echo "Done!"
EOF

chmod +x ~/setup-fake-network.sh
```

---

## วิธีใช้งาน

### 1. Start Container:
```bash
~/start-samsung-thai.sh
```

### 2. Setup Fake Network:
```bash
# รอ container boot เสร็จ (ประมาณ 30 วินาที)
sleep 30
~/setup-fake-network.sh
```

### 3. เชื่อมต่อ ADB:
```bash
adb connect localhost:5555
adb shell getprop | grep -E "product|operator|wifi"
```

### 4. ดูหน้าจอด้วย scrcpy:
```bash
scrcpy -s localhost:5555 --window-title "Samsung A54 Thai"
```

---

## ตรวจสอบข้อมูลเครื่อง

```bash
# ตรวจสอบ Device info
adb shell getprop ro.product.model
# Output: SM-A546E

# ตรวจสอบ Carrier
adb shell getprop gsm.operator.alpha
# Output: AIS

# ตรวจสอบ WiFi MAC
adb shell cat /sys/class/net/wlan0/address

# ตรวจสอบ Build fingerprint
adb shell getprop ro.build.fingerprint
```

---

## หมายเหตุสำคัญ

1. **พื้นที่ดิสก์**: Build จะใช้พื้นที่ประมาณ 100-150GB
2. **เวลา Build**: 3-6 ชั่วโมง ขึ้นกับความเร็ว CPU
3. **RAM**: ระหว่าง build จะใช้ RAM 16-24GB
4. **Open GApps**: แพ็คเกจ `stock` รวม Gmail, Maps, YouTube, Drive ฯลฯ
5. **Legal**: ใช้เพื่อการทดสอบเท่านั้น

---

## Troubleshooting

### Build ล้มเหลว:
```bash
# เคลียร์ cache
rm -rf ~/redroid-samsung-thai/out
# Build ใหม่
```

### Container ไม่ boot:
```bash
# ดู logs
docker logs redroid-samsung-thai
```

### Network ไม่ทำงาน:
```bash
# รัน setup script อีกครั้ง
~/setup-fake-network.sh
```
