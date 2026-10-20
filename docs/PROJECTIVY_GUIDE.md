# 🚀 Projectivy Launcher: The Ultimate Firestick Setup Guide

This guide walks through configuring **Projectivy Launcher** on Amazon Fire TV / Firestick devices to achieve an ad-free, snappy, instant-wake television experience.

---

## 1. Why Projectivy on Fire TV?

Amazon’s default home screen on Fire OS is heavily congested with auto-playing video trailers, sponsored banners, and rows of promoted content you don't own. On a 1 GB RAM device (like Fire TV Stick Lite or 3rd Gen), rendering this bloated home screen consumes up to **35% of system memory** and causes sluggish navigation.

Projectivy replaces this with a clean, hardware-accelerated app grid that idles at under **45 MB of RAM**.

---

## 2. Preventing Home Button Latency & Background Kills

By default, Android’s battery saver (Doze) can freeze third-party launchers in the background. When you press the remote’s Home button, you might see a 1–2 second delay while the launcher reloads.

### The Fix (Included in `harden.sh`):
```bash
# Whitelist Projectivy in Android Doze / DeviceIdle
adb shell dumpsys deviceidle whitelist +com.spocky.projengmenu
```

---

## 3. Remote Catch: Setting Up Accessibility Service

Because Fire OS attempts to force the Amazon launcher when you press the physical Home button, Projectivy uses an Accessibility service to detect the Home button event and immediately redirect focus:

1. Open **Settings** on Fire TV > **My Fire TV** (or **Device & Software**) > **Accessibility**.
2. Scroll to **Projectivy Launcher** and toggle it **ON**.
3. Inside Projectivy Launcher:
   * Open **Projectivy Settings** (gear icon) > **General**.
   * Toggle **"Override current launcher"** to **ON**.
   * Select **"Alternate Remote Detection"** if prompted.

---

## 4. Unlocking the Live "Now Playing" Shelf

On Fire OS, Amazon removed the Google Android TV Leanback Channels framework (`TvContract.PreviewChannels`), which prevents third-party launchers from drawing static recommendation carousels.

However, Projectivy includes a **Media Session Shelf** that displays live resume/playback cards whenever you pause or stream media across legal apps (Netflix, Prime Video, Just Player).

### Enabling Notification Listener via ADB:
```bash
adb shell settings put secure enabled_notification_listeners \
  "com.spocky.projengmenu/com.spocky.projengmenu.services.notification.NotificationListener"
```

Once granted, go to **Projectivy Settings** > **Edit Categories** > toggle **Now Playing** to **ON**.

---

## 5. Recommended Category Layout

To keep your TV clean and modern, organize your rows into three categories:

* **Row 1: Favorites / Daily Media** (Netflix, Prime Video, SmartTube, Just Player)
* **Row 2: Streaming Apps** (All subscribed video apps)
* **Row 3: System & Tools** (Settings, Downloader, File Manager)

You can hide empty or default Amazon system categories by toggling their visibility under **Edit Categories**.
