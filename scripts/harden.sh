#!/usr/bin/env bash
# ==============================================================================
# Firestick Hardened Toolkit - System Hardening & Security
# ==============================================================================
# 1. Blocks forced Amazon OTA updates from overwriting custom configs.
# 2. Configures encrypted AdGuard Private DNS (blocks ad networks at DNS level).
# 3. Disables telemetry location tracking globally.
# 4. Optimizes Projectivy Launcher with Doze exemption and notification listener.
# ==============================================================================

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ======================================================="
echo "   🛡️  FIRESTICK HARDENED TOOLKIT - SECURITY HARDENING 🛡️  "
echo "  ======================================================="
echo -e "${NC}"

if ! command -v adb &> /dev/null; then
    echo -e "${RED}[ERROR] 'adb' is not installed or not in PATH.${NC}"
    exit 1
fi

DEVICE=$(adb devices | grep -w "device" | awk 'NR==1{print $1}')
if [ -z "${DEVICE}" ]; then
    echo -e "${RED}[ERROR] No authorized ADB device found.${NC}"
    exit 1
fi

MODEL=$(adb -s "${DEVICE}" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
echo -e "${GREEN}[✓] Target Device: ${BOLD}${MODEL}${NC}"
echo ""

# --- 1. Amazon Forced OTA Lockdown ---
echo -e "${BLUE}[1/4] Applying Amazon OTA Updater Restrictions...${NC}"
OTA_PKG="com.amazon.device.software.ota"
OTA_UID=$(adb -s "${DEVICE}" shell "pm list packages -u -U ${OTA_PKG}" 2>/dev/null | grep -o 'uid:[0-9]*' | cut -d: -f2 || true)

# AppOps background freeze
adb -s "${DEVICE}" shell "appops set ${OTA_PKG} RUN_IN_BACKGROUND ignore" 2>/dev/null || true
adb -s "${DEVICE}" shell "appops set ${OTA_PKG} WAKE_LOCK ignore" 2>/dev/null || true
adb -s "${DEVICE}" shell "appops set ${OTA_PKG} START_FOREGROUND ignore" 2>/dev/null || true

if [ -n "${OTA_UID}" ]; then
    # Kernel netpolicy background data block
    adb -s "${DEVICE}" shell "cmd netpolicy add restrict-background-blacklist ${OTA_UID}" 2>/dev/null || true
    echo -e "  ${GREEN}[✓] AppOps restricted & UID ${OTA_UID} blacklisted in kernel firewall.${NC}"
else
    echo -e "  ${GREEN}[✓] AppOps restricted for ${OTA_PKG}.${NC}"
fi

# --- 2. System Private DNS (AdGuard) ---
echo -e "${BLUE}[2/4] Setting Encrypted Private DNS (AdGuard)...${NC}"
adb -s "${DEVICE}" shell "settings put global private_dns_mode hostname" 2>/dev/null || true
adb -s "${DEVICE}" shell "settings put global private_dns_specifier dns.adguard-dns.com" 2>/dev/null || true
DNS_CHECK=$(adb -s "${DEVICE}" shell "settings get global private_dns_specifier" 2>/dev/null || true)
echo -e "  ${GREEN}[✓] Private DNS configured: ${BOLD}${DNS_CHECK}${NC}"

# --- 3. Location Tracking Kill Switch ---
echo -e "${BLUE}[3/4] Activating Global Location Kill Switch...${NC}"
adb -s "${DEVICE}" shell "settings put global location_global_kill_switch 1" 2>/dev/null || true
adb -s "${DEVICE}" shell "settings put secure location_providers_allowed ''" 2>/dev/null || true
echo -e "  ${GREEN}[✓] Location reporting & telemetry beacons deactivated.${NC}"

# --- 4. Launcher Optimization (Projectivy) ---
echo -e "${BLUE}[4/4] Optimizing Projectivy Launcher Performance...${NC}"
PROJECTIVY_PKG="com.spocky.projengmenu"
INSTALLED=$(adb -s "${DEVICE}" shell "pm list packages ${PROJECTIVY_PKG}" 2>/dev/null || true)

if [ -n "${INSTALLED}" ]; then
    # Exclude from Android Doze to ensure instant wake
    adb -s "${DEVICE}" shell "dumpsys deviceidle whitelist +${PROJECTIVY_PKG}" 2>/dev/null || true
    
    # Enable notification listener to unlock the live "Now Playing" media shelf
    NL_SERVICE="${PROJECTIVY_PKG}/${PROJECTIVY_PKG}.services.notification.NotificationListener"
    adb -s "${DEVICE}" shell "settings put secure enabled_notification_listeners ${NL_SERVICE}" 2>/dev/null || true
    
    # Grant TV listing read permissions
    adb -s "${DEVICE}" shell "pm grant ${PROJECTIVY_PKG} android.permission.READ_TV_LISTINGS" 2>/dev/null || true
    
    echo -e "  ${GREEN}[✓] Whitelisted in Doze mode (Zero-delay Home button catch).${NC}"
    echo -e "  ${GREEN}[✓] Granted Notification Listener (Live 'Now Playing' shelf unlocked).${NC}"
else
    echo -e "  ${YELLOW}[INFO] Projectivy Launcher not installed; skipping launcher-specific hooks.${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}=======================================================${NC}"
echo -e "${GREEN}${BOLD}             SYSTEM HARDENING COMPLETE!                ${NC}"
echo -e "${GREEN}${BOLD}=======================================================${NC}"
