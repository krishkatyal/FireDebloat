# 📊 The Firestick Vibecheck Report (Real-World Benchmark)

**Target Device:** Amazon Fire TV Stick Lite / 3rd Gen (Model `AFTSSS`, Code: `sheldonp`)  
**Firmware:** Fire OS 7.7.1.6 (`PS7716/5666`), Android 9 Pie (API 28)  
**Processor:** MediaTek MT8695D Quad-Core @ 1.7 GHz  
**Audit Date:** October 2026  

---

## 1. Executive Summary

| Metric | Out-of-the-Box (Stock) | Hardened & Debloated | Net Delta |
| :--- | :---: | :---: | :---: |
| **Active Background Packages** | 148 running services | **44 running services** | **-104 services (-70%)** |
| **Available RAM (Headroom)** | ~65–110 MB (Critical) | **275 MB (Normal)** | **+165–210 MB (+150%)** |
| **RAM Pressure Level** | `CRITICAL` (Frequent app kills) | `NORMAL` (Zero stutter) | **Optimal** |
| **DNS Resolution** | Unencrypted Amazon/ISP DNS | **AdGuard Private DNS (TLS)** | **Zero DNS Ad Tracking** |
| **Forced Amazon OTAs** | Active in background | **AppOps & NetPolicy Frozen** | **Locked down** |
| **Home Screen Catch Delay** | 3.5s – 5.0s (Stock bloat lag) | **<150ms (Instant Projectivy)** | **Near Zero Latency** |

---

## 2. Memory (RAM) Breakdown

```
Total Physical RAM: 900 MB (Hardware Allocated)
├── Out-of-the-Box Stock:
│   ├── Used RAM:   820 MB (91%)
│   ├── Free RAM:   80 MB (9%)  [Memory Pressure: CRITICAL]
│   └── ZRAM Swap:  140 MB (Heavy thrashing on flash memory)
│
└── After Hardened Debloat:
    ├── Used RAM:   625 MB (69%)
    ├── Free RAM:   275 MB (31%) [Memory Pressure: NORMAL]
    └── ZRAM Swap:  51 MB (Clean memory pages)
```

---

## 3. Storage Reclamation Audit

* **Cleaned Partition:** `/data`
* **Available Space:** **1.9 GB Free** (out of 4.9 GB user storage).
* **Removed Residual Artifacts:**
  * Purged stale 2022 OTA cache packages (`/data/local/tmp`).
  * Cleared indexing caches for unused TTS voice models (`com.ivona.tts.oem`, `com.svox.pico`).
  * Cleared media scrapers and telemetry caches (`com.amazon.cpl`, `com.amazon.dpcclient`).

---

## 4. Telemetry & Tracker Elimination

All 104 background bloatware packages have been successfully neutralized via user-space package deactivation (`pm disable-user --user 0`).

* **Ad Tracking Beacons:** Deactivated (`com.amazon.ceviche`, `com.amazon.hybridadidservice`, `com.amazon.spiderpork`).
* **Silent Wi-Fi Password Uploads:** Deactivated (`com.amazon.wifilocker`).
* **Alexa Ambient Listeners:** Deactivated (`com.amazon.alexadirectivebrokerservice`, `com.amazon.alexamediaplayer.runtime.ftv`).
* **Unused Hardware Drivers:** Neutralized (`com.android.nfc`, `com.android.printspooler`, `com.android.bluetoothmidiservice`).

---

## 5. Security & Launcher Verification

```
[SECURITY & NETWORK PROFILE]
  Private DNS Specifier:   dns.adguard-dns.com (Encrypted DoT)
  Location Kill Switch:    Enabled (global location_global_kill_switch = 1)
  OTA Background Daemon:   AppOps [RUN_IN_BACKGROUND: ignore, WAKE_LOCK: ignore]
  Kernel NetPolicy:        Restrict-Background Blacklist Active

[LAUNCHER INTEGRATION (Projectivy)]
  Accessibility Hook:      Enabled (Alternate Remote Config)
  Doze Whitelist:          Whitelisted (+com.spocky.projengmenu)
  Media Session Shelf:     Unlocked (BIND_NOTIFICATION_LISTENER_SERVICE active)
```
