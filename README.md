# ⚡ FireDebloat

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Fire%20OS%206%20%7C%207%20%7C%208-orange.svg)](https://developer.amazon.com/docs/fire-tv/fire-os-overview.html)
[![Requirements](https://img.shields.io/badge/Requirements-ADB%20(No%20Root)-blue.svg)](#prerequisites)
[![Safety](https://img.shields.io/badge/Safety-100%25%20Reversible-success.svg)](#safety--restoration)
[![Stars](https://img.shields.io/github/stars/krishkatyal/FireDebloat?style=social)](https://github.com/krishkatyal/FireDebloat)

**The ultimate open-source debloating, privacy hardening, and performance optimization suite for Amazon Fire TV & Firestick devices.**

[Quick Start](#-quick-start) • [Vibecheck Audit](#-live-vibecheck-benchmark) • [Package List](#-what-gets-disabled) • [Projectivy Setup](docs/PROJECTIVY_GUIDE.md) • [Safety Guarantee](#-safety-guarantee)

</div>

---

## 🚀 Overview

Out of the box, Amazon Fire TV devices dedicate **up to 75% of their available memory and background CPU cycles** to telemetry daemons, sponsored ad carousels, Alexa audio wake-word listeners, and background analytics. For devices with 1 GB or 1.5 GB of RAM (such as the Fire TV Stick Lite, 3rd Gen, or 4K), this causes severe UI stutter, app evictions, and sluggish launcher navigation.

**FireDebloat** is a zero-risk, no-root automation suite that transforms sluggish Fire TV sticks into sleek, lightweight streaming hubs.

### 🌟 Key Highlights

- 🧹 **104 Curated Bloatware Targets:** Disables ad injection, telemetry trackers, shopping daemons, and background recommendations without breaking device control, Wi-Fi, audio, or HDMI-CEC.
- 🔒 **Dual-Layer OTA Lockdown:** Shields your custom launcher and performance tweaks from being wiped by stealth Amazon system updates using Android AppOps and network policy restrictions.
- 🛡️ **Encrypted AdGuard Private DNS:** Enforces system-wide DoT (DNS over TLS) on port 853 to block tracking pixels and telemetry at the socket layer.
- ⚡ **Projectivy Launcher Optimization:** Configures zero-latency home button intercept and whitelists Projectivy from aggressive background Doze eviction.
- 📊 **Firestick Vibecheck Diagnostic Tool:** Terminal-based live system audit reporting RAM headroom, memory pressure, storage, active processes, and hardening status.
- 🔄 **1-Click Rollback:** 100% reversible via `restore.sh`. No partitions are modified, and no system files are deleted.

---

## 📊 Live Vibecheck Benchmark

Real-world metrics captured from a retail **Fire TV Stick 3rd Gen (Model AFTSSS, Fire OS 7.7.1.6)**:

| Metric | Factory Stock (Out of Box) | Hardened & Debloated | Improvement |
| :--- | :--- | :--- | :--- |
| **Active Bloat Packages** | 104 running / idle | **0** (Disabled via User 0) | **100% eliminated** |
| **Available Free RAM** | ~92 MB - 110 MB | **275 MB - 310 MB** | **+180% to +200% free memory** |
| **Kernel Memory Pressure** | Moderate to Critical (frequent app kills) | **Normal** (stable headroom) | **Zero UI lag or stutter** |
| **Home Screen Ads** | Full-screen video previews & banners | **0** (Projectivy custom launcher) | **Clean, instant boot** |
| **Forced OTA Updates** | Auto-downloads in background | **Blocked** (AppOps & NetPolicy) | **Preserves customizations** |
| **Background Telemetry** | Active reporting to Amazon analytics | **Blocked** (DNS + services killed) | **Complete telemetry blackout** |

*(Read the full forensic audit in [VIBECHECK_REPORT.md](docs/VIBECHECK_REPORT.md))*

---

## 🛠️ Prerequisites

1. **Enable Developer Options on Fire TV:**
   - Go to **Settings** > **My Fire TV** > **About**.
   - Hover over your device name and click the **Select** button **7 times** until you see *"You are now a developer."*
2. **Enable ADB Debugging:**
   - Go back to **Settings** > **My Fire TV** > **Developer Options**.
   - Turn **ADB Debugging** to **ON**.
3. **Computer with ADB Installed:**
   - **macOS:** `brew install android-platform-tools`
   - **Debian / Ubuntu:** `sudo apt install adb`
   - **Windows:** Download [Google Platform Tools](https://developer.android.com/tools/releases/platform-tools) or run `winget install Google.PlatformTools`

---

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/krishkatyal/FireDebloat.git
cd FireDebloat
```

### 2. Connect to Your Fire TV via ADB
Find your Fire TV's IP address in **Settings** > **My Fire TV** > **About** > **Network**:
```bash
adb connect <FIRE_STICK_IP>:5555
```
*(Check your TV screen and select **"Always allow from this computer"** when prompted).*

### 3. Run the Diagnostic Audit (Vibecheck)
Verify your device state before making any changes:
```bash
./scripts/vibecheck.sh
```

### 4. Apply Hardening & Debloat
Run the scripts in sequence:
```bash
# 1. Debloat 104 verified tracking and bloatware packages
./scripts/debloat.sh

# 2. Apply OTA updates block, AdGuard DNS, and Projectivy optimizations
./scripts/harden.sh

# 3. Verify changes with a post-run Vibecheck
./scripts/vibecheck.sh
```

---

## 📦 What Gets Disabled?

Packages are categorized inside [`data/packages-bloat.txt`](data/packages-bloat.txt):

1. **Amazon Ads & Sponsored Recommendations:** `com.amazon.device.controllermanager`, `com.amazon.bueller.music`, `com.amazon.tv.recommendations`, `com.amazon.advertising.*`
2. **Telemetry & Behavioral Analytics:** `com.amazon.device.crashmanager`, `com.amazon.analytics.deviceeventclient`, `com.amazon.dp.fbauth`, metrics collectors.
3. **Background Alexa Listeners & Shopping:** Alexa wake-word voice shopping services and search query listeners (remote Alexa button voice search remains fully functional).
4. **OTA System Update Daemons:** `com.amazon.device.software.ota`, `com.amazon.settings.systemupdates`.
5. **Amazon Retail Store & Cloud Sync:** Photos cloud uploader, Amazon shopping, Kindle sync, game circle daemons.
6. **Unnecessary Hardware Services:** Cellular and ethernet dummy drivers for non-cellular Fire TV sticks.

### 🛡️ Safety Whitelist
Critical system services are explicitly protected in [`data/packages-safe.txt`](data/packages-safe.txt):
- Wi-Fi & Bluetooth Stack (`com.android.bluetooth`, `com.android.settings`)
- HDMI-CEC & Volume / Power Device Control (`com.amazon.device.control`)
- Official Remote Pairing (`com.amazon.btdeviceservice`)
- Widevine L1 & DRM Playback Engines (`com.amazon.drm.*`)

---

## 🖥️ Projectivy Launcher Setup

Pair this toolkit with **Projectivy Launcher** for a clean, zero-ad home screen experience:

1. Install **Projectivy Launcher** via ADB or the Google Play / F-Droid store.
2. Follow our step-by-step setup guide in [`docs/PROJECTIVY_GUIDE.md`](docs/PROJECTIVY_GUIDE.md) to:
   - Enable Accessibility Service for instant home button interception.
   - Whitelist Projectivy from battery Doze memory kills.
   - Configure category rows and customized wallpaper.

---

## 🔒 Safety & Restoration

All changes use Android's native `pm disable-user --user 0` mechanism. **No system files are deleted**, and root permissions are not required.

### 1-Click Rollback
To restore every disabled package back to factory state:
```bash
./scripts/restore.sh
```

To restore a specific package individually:
```bash
./scripts/restore.sh com.amazon.tv.recommendations
```

---

## 🤝 Contributing

Contributions, bug reports, and device-specific package testing are welcome!

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/NewDeviceSupport`).
3. Commit your Changes (`git commit -m 'feat: add support for Fire OS 8 4K Max 2nd Gen'`).
4. Push to the Branch (`git push origin feature/NewDeviceSupport`).
5. Open a Pull Request.

---

## ⚖️ Disclaimer & License

This project is open-source software provided under the [MIT License](LICENSE). 
It is intended for privacy enhancement, research, and educational purposes. This project is not affiliated with, endorsed by, or associated with Amazon.com, Inc. All trademarks belong to their respective owners.
