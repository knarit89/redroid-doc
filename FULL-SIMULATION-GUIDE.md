# 🎯 Full Simulation Guide: WiFi HWSim + Virtual SIM

## Overview

คู่มือการใช้งาน **Redroid Samsung Thai** แบบเต็มรูปแบบ พร้อม:
- ✅ Virtual WiFi (wlan0 interface จริง)
- ✅ Virtual SIM (RIL daemon จริง)
- ✅ เลือกค่ายมือถือได้ (AIS, DTAC, True, NT)
- ✅ กำหนดเบอร์โทรได้

---

## 🚀 Quick Start

### วิธีที่ 1: Interactive Mode (แนะนำสำหรับผู้เริ่มต้น)

```bash
~/start-samsung-thai-full.sh
```

จะถามคำถาม:
1. เลือกค่าย: AIS, DTAC, TRUE, หรือ NT
2. ใส่เบอร์โทร (หรือ Enter ให้สุ่มอัตโนมัติ)

### วิธีที่ 2: Command Line Mode

```bash
# รูปแบบ: ./start-samsung-thai-full.sh [CARRIER] [PHONE_NUMBER]

# ตัวอย่างที่ 1: AIS กับเบอร์ 0812345678
~/start-samsung-thai-full.sh AIS 0812345678

# ตัวอย่างที่ 2: DTAC ให้สุ่มเบอร์
~/start-samsung-thai-full.sh DTAC

# ตัวอย่างที่ 3: True กับเบอร์ 0987654321
~/start-samsung-thai-full.sh TRUE 0987654321
```

---

## 📱 ค่ายมือถือที่รองรับ

| ค่าย | MCC/MNC | เบอร์เริ่มต้น | ตัวอย่างเบอร์ |
|------|---------|--------------|--------------|
| **AIS** | 520-01 | 08x | 081-234-5678 |
| **DTAC** | 520-05 | 06x | 062-345-6789 |
| **TRUE** | 520-04 | 09x | 098-765-4321 |
| **NT/CAT** | 520-99 | 02 | 02-123-4567 |

---

## 🎮 ตัวอย่างการใช้งาน

### ตัวอย่าง 1: AIS Auto
```bash
~/start-samsung-thai-full.sh
# เลือก: 1 (AIS)
# เบอร์: [Enter] (สุ่มอัตโนมัติ)
```

**Output:**
```
📋 Configuration Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Carrier:      Advanced Info Service (AIS)
📞 Phone:        0812345678
🔢 MCC/MNC:      52001
📲 IMSI:         520011234567890
📟 IMEI:         352094123456789
🌐 WiFi MAC:     A8:5E:45:12:34:56
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ตัวอย่าง 2: DTAC Custom
```bash
~/start-samsung-thai-full.sh DTAC 0623456789
```

### ตัวอย่าง 3: True Move H
```bash
~/start-samsung-thai-full.sh TRUE 0987654321
```

---

## ✅ Verification

### หลัง container boot เสร็จ (รอ 30-60 วินาที):

```bash
# 1. Connect ADB
adb connect localhost:5555

# 2. Check carrier
adb shell getprop gsm.operator.alpha
# Output: AIS (หรือค่ายที่เลือก)

# 3. Check phone number
adb shell getprop gsm.sim.msisdn
# Output: 0812345678

# 4. Check WiFi interface
adb shell ip link show wlan0
# Output: wlan0 interface

# 5. Check SIM state
adb shell getprop gsm.sim.state
# Output: READY

# 6. Check IMEI
adb shell getprop ro.ril.oem.imei
# Output: 352094XXXXXXXXX
```

---

## 🔧 Post-Boot Configuration

Script จะสร้างไฟล์ configure อัตโนมัติ:

```bash
# รันหลัง boot เสร็จ
/tmp/configure-phone-redroid-samsung-thai.sh
```

**สิ่งที่ script ทำ:**
- ตั้งค่าเบอร์โทรในระบบ
- Enable WiFi และ Mobile Data
- Verify configuration

---

## 📊 Features Matrix

| Feature | Supported | Details |
|---------|-----------|---------|
| **WiFi Simulation** | ✅ Yes | Real wlan0 interface |
| **SIM Card** | ✅ Yes | Virtual SIM via RIL |
| **Carrier Selection** | ✅ Yes | AIS, DTAC, TRUE, NT |
| **Custom Phone Number** | ✅ Yes | Any Thai number |
| **IMEI** | ✅ Yes | Random Samsung IMEI |
| **IMSI** | ✅ Yes | Based on carrier |
| **Phone App** | ✅ Yes | Fully functional |
| **SMS** | ✅ Yes | Simulated |
| **Mobile Data** | ✅ Yes | Simulated 5G/LTE |
| **Signal Strength** | ✅ Yes | Excellent |
| **Network Type** | ✅ Yes | 5G/LTE/3G |

---

## 🎯 Use Cases

### 1. App Testing
```bash
# Test banking app with AIS
~/start-samsung-thai-full.sh AIS 0812345678

# Test with different carriers
~/start-samsung-thai-full.sh DTAC 0623456789
```

### 2. Multiple Instances
```bash
# Instance 1: AIS
docker run ... --name redroid-ais -p 5555:5555 ...

# Instance 2: DTAC  
docker run ... --name redroid-dtac -p 5556:5555 ...
```

### 3. Automated Testing
```bash
#!/bin/bash
carriers=("AIS" "DTAC" "TRUE")
for carrier in "${carriers[@]}"; do
    ~/start-samsung-thai-full.sh "$carrier"
    # Run tests
    docker stop redroid-samsung-thai
done
```

---

## 🔬 Advanced Configuration

### Custom Network Properties

```bash
# Start container with custom properties
docker exec redroid-samsung-thai sh -c '
  # 5G Network
  setprop gsm.network.type "NR"
  setprop telephony.lteOnCdmaDevice 1
  
  # Signal strength (ASU: 99 = Excellent)
  setprop gsm.operator.asu 99
  
  # Data roaming
  setprop gsm.data.roaming false
'
```

### Dual SIM Configuration

Edit script to add:
```bash
# SIM 2 properties
gsm.operator.alpha.2="DTAC" \
gsm.operator.numeric.2="52005" \
persist.radio.multisim.config=dsds
```

---

## 🐛 Troubleshooting

### Problem: Phone number not showing

```bash
# Manually set
adb shell setprop gsm.sim.msisdn "0812345678"
adb shell setprop ril.msisdn "0812345678"
adb shell am start -a android.intent.action.DIAL
```

### Problem: Wrong carrier displayed

```bash
# Check properties
adb shell getprop | grep operator

# Reset
adb shell setprop gsm.operator.alpha "AIS"
adb shell setprop gsm.operator.numeric "52001"
```

### Problem: SIM not ready

```bash
# Check logs
adb logcat | grep -E "RIL|SIM|rild"

# Restart container
docker restart redroid-samsung-thai
```

---

## 📋 Integration Steps

### สำหรับผู้ที่ยังไม่ได้ integrate:

```bash
# 1. Add WiFi HWSim
cd /root/redroid-doc
./add-wifi-hwsim.sh

# 2. Add Virtual SIM
./add-virtual-sim.sh

# 3. Rebuild AOSP
cd ~/redroid-samsung-thai
. build/envsetup.sh
lunch redroid_x86_64-userdebug
m -j$(nproc)

# 4. Create Docker image
cd ~/redroid-samsung-thai/out/target/product/redroid_x86_64
sudo mount system.img system -o ro
sudo mount vendor.img vendor -o ro
sudo tar --xattrs -c vendor -C system --exclude="./vendor" . | \
  docker import \
  -c 'ENTRYPOINT ["/init", "androidboot.hardware=redroid"]' \
  - redroid-samsung-thai:14-full
sudo umount system vendor

# 5. Use the new startup script
~/start-samsung-thai-full.sh
```

---

## 🎉 Complete Feature List

### Network Simulation:
- ✅ Real WiFi interface (wlan0)
- ✅ WPA Supplicant
- ✅ Virtual SIM card
- ✅ RIL daemon
- ✅ 4 Thai carriers
- ✅ Custom phone numbers
- ✅ 5G/LTE network

### Device Simulation:
- ✅ Samsung Galaxy A54 5G
- ✅ Thai localization
- ✅ Bangkok location
- ✅ Samsung MAC address
- ✅ Valid IMEI
- ✅ Carrier IMSI

### Apps Working:
- ✅ Phone app (100%)
- ✅ SMS app (100%)
- ✅ WiFi Settings (100%)
- ✅ SIM Settings (100%)
- ✅ All apps requiring WiFi/SIM

---

## 📚 Documentation

- **WiFi HWSim:** `/root/redroid-doc/WIFI-HWSIM-GUIDE.md`
- **Virtual SIM:** `/root/redroid-doc/VIRTUAL-SIM-GUIDE.md`
- **This Guide:** `/root/redroid-doc/FULL-SIMULATION-GUIDE.md`

---

## 💡 Tips & Best Practices

### 1. Use realistic phone numbers
```bash
# AIS: 08x-xxx-xxxx
~/start-samsung-thai-full.sh AIS 0812345678

# DTAC: 06x-xxx-xxxx  
~/start-samsung-thai-full.sh DTAC 0623456789
```

### 2. Match carrier prefix
แต่ละค่ายมี prefix เฉพาะ - script จะสุ่มให้ถูกต้องอัตโนมัติ

### 3. Save configuration
```bash
# Export settings
adb shell getprop > my-device-config.txt
```

### 4. Script automation
```bash
# Create wrapper script
#!/bin/bash
CARRIER="AIS"
PHONE="0812345678"
~/start-samsung-thai-full.sh "$CARRIER" "$PHONE"
sleep 60
/tmp/configure-phone-redroid-samsung-thai.sh
```

---

<div align="center">

## 🇹🇭 Perfect Thai Mobile Simulation! 🎉

**WiFi ✅ + SIM ✅ + Custom Settings ✅ = Complete!**

</div>
