# 📐 WiFi HWSim Architecture for Redroid

## 🎯 Overview

เอกสารนี้อธิบายสถาปัตยกรรมของ WiFi Hardware Simulator (wifi_hwsim) ใน Redroid และวิธีการทำงาน

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Host Linux System                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Kernel Space                                        │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │   mac80211_hwsim Module                      │   │   │
│  │  │   - Simulates WiFi hardware                  │   │   │
│  │  │   - Creates virtual radio(s)                 │   │   │
│  │  │   - Implements 802.11 protocol               │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │            │                                         │   │
│  │            ↓                                         │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │   nl80211 / cfg80211 Interface               │   │   │
│  │  │   - Kernel WiFi configuration layer          │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                         │                                    │
│                         ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Docker Container (Redroid)                          │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │ Android System (System Partition)          │     │   │
│  │  │                                            │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │  Android Framework                  │   │     │   │
│  │  │  │  - ConnectivityManager              │   │     │   │
│  │  │  │  - WifiManager                      │   │     │   │
│  │  │  │  - NetworkStack                     │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │              │                              │     │   │
│  │  └──────────────│──────────────────────────────┘     │   │
│  │                 ↓                                     │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │ Vendor Partition (APEX)                    │     │   │
│  │  │                                            │     │   │
│  │  │  ┌─────────────────────────────────────┐   │     │   │
│  │  │  │  com.google.cf.wifi_hwsim APEX     │   │     │   │
│  │  │  │                                    │   │     │   │
│  │  │  │  ├─ wpa_supplicant_cf              │   │     │   │
│  │  │  │  │  - WiFi authentication daemon   │   │     │   │
│  │  │  │  │                                 │   │     │   │
│  │  │  │  ├─ hostapd_cf                     │   │     │   │
│  │  │  │  │  - WiFi AP daemon               │   │     │   │
│  │  │  │  │                                 │   │     │   │
│  │  │  │  ├─ android.hardware.wifi@1.0      │   │     │   │
│  │  │  │  │  - WiFi HAL (Hardware Layer)    │   │     │   │
│  │  │  │  │                                 │   │     │   │
│  │  │  │  ├─ mac80211_create_radios         │   │     │   │
│  │  │  │  │  - Creates virtual radios       │   │     │   │
│  │  │  │  │                                 │   │     │   │
│  │  │  │  └─ init.wifi.sh                   │   │     │   │
│  │  │  │     - WiFi initialization script   │   │     │   │
│  │  │  │                                    │   │     │   │
│  │  │  └─────────────────────────────────────┘   │     │   │
│  │  │                 │                           │     │   │
│  │  └─────────────────│───────────────────────────┘     │   │
│  │                    ↓                                  │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │  wlan0 Network Interface                   │     │   │
│  │  │  - Virtual WiFi interface                  │     │   │
│  │  │  - MAC: A8:5E:45:XX:XX:XX (Samsung OUI)    │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Boot Sequence

### 1. Container Start
```
docker run ... \
  androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim \
  ro.vendor.wifi_impl=mac8011_hwsim_virtio
```

### 2. Init Process
```
1. Android init loads /init.rc
2. Mounts /vendor/apex/com.google.cf.wifi_hwsim
3. Loads init.wifi.rc configuration
```

### 3. WiFi HWSim Initialization
```
on post-fs-data:
  1. mkdir /data/vendor/wifi (for WPA Supplicant)
  2. start mac80211_create_radios service
     → Creates virtual wlan0 interface via nl80211
```

### 4. WPA Supplicant Start
```
1. Android framework detects wlan0 interface
2. Starts wpa_supplicant_cf service
3. Connects to Android WiFi framework via AIDL
```

### 5. WiFi Ready
```
1. WiFi Manager initializes
2. Apps can use WiFi API
3. WiFi Settings shows "WiFi On"
```

---

## 🧩 Component Details

### 1. **mac80211_hwsim** (Kernel Module)
- **Location**: Host kernel `/lib/modules/.../mac80211_hwsim.ko`
- **Purpose**: Simulates IEEE 802.11 compatible WiFi hardware
- **Features**:
  - Supports multiple radios
  - Full 802.11 a/b/g/n/ac/ax support
  - Monitor mode, AP mode, STA mode
  - Packet injection

**Load command:**
```bash
sudo modprobe mac80211_hwsim radios=1
```

### 2. **com.google.cf.wifi_hwsim APEX**
- **Type**: Android Apex Package
- **Location**: `/vendor/apex/com.google.cf.wifi_hwsim/`
- **Size**: ~5-10MB
- **Contains**:
  - WiFi HAL binaries
  - WPA Supplicant
  - Hostapd
  - Configuration files
  - Init scripts

### 3. **wpa_supplicant_cf**
- **Purpose**: WiFi authentication daemon
- **Protocol**: WPA/WPA2/WPA3
- **Interface**: nl80211 (to kernel)
- **API**: AIDL (to Android framework)
- **Socket**: `/data/vendor/wifi/wpa/sockets/wlan0`

### 4. **WiFi HAL (Hardware Abstraction Layer)**
- **Interface**: `android.hardware.wifi@1.0-1.5`
- **Purpose**: Bridge between Android Framework and hardware
- **Implementation**: `libwifi-hal_cf.so`

### 5. **wlan0 Interface**
- **Type**: Virtual network interface
- **Driver**: mac80211_hwsim
- **MAC Address**: Configurable (Samsung OUI: A8:5E:45:XX:XX:XX)
- **Modes**: STA (Station), AP (Access Point), P2P

---

## 📊 Data Flow

### WiFi Scan Request Flow:
```
[Android App]
    ↓
[WifiManager API]
    ↓
[Android Framework (Java)]
    ↓
[WifiService (System Server)]
    ↓
[WiFi HAL (HIDL/AIDL Interface)]
    ↓
[android.hardware.wifi@1.0-service_cf]
    ↓
[wpa_supplicant_cf]
    ↓
[nl80211 netlink]
    ↓
[cfg80211 (Kernel)]
    ↓
[mac80211_hwsim driver]
    ↓
[Virtual Radio Hardware Simulation]
```

### Response Flow (Scan Results):
```
[mac80211_hwsim]
    ↓ (netlink events)
[wpa_supplicant_cf]
    ↓ (AIDL callbacks)
[WiFi HAL]
    ↓
[WifiService]
    ↓ (Broadcast)
[Android App receives scan results]
```

---

## 🔐 Security & Permissions

### Required Capabilities:
```
Docker: --privileged
  ├─ NET_ADMIN (network configuration)
  ├─ NET_RAW (raw sockets)
  └─ SYS_MODULE (access kernel modules)

Android Permissions:
  ├─ android.permission.ACCESS_WIFI_STATE
  ├─ android.permission.CHANGE_WIFI_STATE
  └─ android.permission.ACCESS_FINE_LOCATION (for WiFi scan)
```

### File Permissions:
```
/data/vendor/wifi/         → wifi:wifi 0770
/data/vendor/wifi/wpa/     → wifi:wifi 0770
/sys/class/net/wlan0/      → root:root 0755
```

---

## ⚙️ Configuration Files

### 1. **apex_manifest.json**
```json
{
  "name": "com.google.cf.wifi_hwsim",
  "version": 1
}
```

### 2. **com.google.cf.wifi_hwsim.rc** (Init Script)
```
service wpa_supplicant /apex/com.android.wifi.hal/bin/hw/wpa_supplicant_cf
    interface aidl android.hardware.wifi.supplicant.ISupplicant/default
    socket wpa_wlan0 dgram 660 wifi wifi
    disabled
    oneshot
```

### 3. **BoardConfig.mk** (Build Configuration)
```makefile
BOARD_BOOTCONFIG += \
    androidboot.vendor.apex.com.android.wifi.hal=com.google.cf.wifi_hwsim
```

---

## 🔬 Debugging

### Check APEX Mount:
```bash
adb shell ls -la /apex/com.android.wifi.hal/
# Should show symlink to com.google.cf.wifi_hwsim
```

### Check WiFi HAL Service:
```bash
adb shell ps -A | grep wifi
# Should show: android.hardware.wifi@1.0-service_cf
```

### Check WPA Supplicant:
```bash
adb shell ps -A | grep wpa
# Should show: wpa_supplicant_cf
```

### Check Netlink Communication:
```bash
adb shell iw dev
# Should show wlan0 interface details
```

### WiFi Logs:
```bash
adb logcat | grep -E "wifi|wpa_supplicant|WifiService"
```

---

## 🆚 Comparison: Mocked WiFi vs WiFi HWSim

| Component | Mocked WiFi | WiFi HWSim |
|-----------|-------------|------------|
| **Kernel Module** | None | mac80211_hwsim |
| **wlan0 Interface** | ❌ No | ✅ Yes |
| **WPA Supplicant** | ❌ No | ✅ Yes |
| **WiFi HAL** | Stub only | Full implementation |
| **Network Stack** | Redirected to eth0 | Real WiFi stack |
| **802.11 Protocol** | ❌ No | ✅ Yes |
| **App Compatibility** | ~80% | 100% |
| **Performance** | Fast | Slightly slower |
| **Resource Usage** | Low | Medium |

---

## 🎓 Learning Resources

### Official Documentation:
- [Android WiFi Architecture](https://source.android.com/devices/tech/connect/wifi)
- [mac80211_hwsim Kernel Doc](https://wireless.wiki.kernel.org/en/users/drivers/mac80211_hwsim)
- [WPA Supplicant](https://w1.fi/wpa_supplicant/)

### Related Code:
- `device/google/cuttlefish/` - Cuttlefish WiFi implementation
- `external/wpa_supplicant_8/` - WPA Supplicant source
- `hardware/interfaces/wifi/` - WiFi HAL definitions
- `packages/modules/Wifi/` - Android WiFi framework

---

## 💡 Advanced Topics

### Creating Virtual AP (Access Point)
```bash
# On host, create virtual WiFi network
sudo create_ap wlan0 eth0 TestAP password123

# Android can now scan and connect!
```

### Monitor Mode
```bash
# Put wlan0 in monitor mode to capture packets
adb shell ip link set wlan0 down
adb shell iw dev wlan0 set type monitor
adb shell ip link set wlan0 up

# Use tcpdump to capture 802.11 frames
adb shell tcpdump -i wlan0 -w /sdcard/capture.pcap
```

### Packet Injection
```bash
# Inject custom 802.11 frames
adb shell iw dev wlan0 set type managed
# Use scapy or other tools for injection
```

---

## 🔮 Future Enhancements

Potential improvements:
- [ ] Multiple radios (for testing roaming)
- [ ] WiFi Direct (P2P) support
- [ ] Bluetooth coexistence simulation
- [ ] 5GHz/6GHz bands
- [ ] WiFi 6 (802.11ax) features
- [ ] Rate limiting and packet loss simulation

---

## 🤝 Credits

- **Redroid Project**: https://github.com/remote-android/redroid-doc
- **Cuttlefish**: Google's virtual Android device
- **mac80211_hwsim**: Linux wireless community
- **WPA Supplicant**: Jouni Malinen and contributors

---

<div align="center">
Made with ❤️ for understanding virtual WiFi
</div>
