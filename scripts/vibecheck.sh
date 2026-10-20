#!/usr/bin/env bash
# ==============================================================================
# Firestick Hardened Toolkit - System Vibecheck & Audit Profiler
# ==============================================================================
# Audits hardware health, RAM pressure, storage, disabled bloat count,
# security hardening, and launcher performance.
# ==============================================================================

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_LIST="${DIR}/../data/packages-bloat.txt"

echo -e "${MAGENTA}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║         🔥 FIRESTICK HARDENED SYSTEM VIBECHECK 🔥     ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
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

# --- 1. Device Hardware Identification ---
MODEL=$(adb -s "${DEVICE}" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
NAME=$(adb -s "${DEVICE}" shell getprop ro.product.name 2>/dev/null || echo "Unknown")
FIREOS=$(adb -s "${DEVICE}" shell getprop ro.build.version.name 2>/dev/null || echo "Fire OS")
ANDROID=$(adb -s "${DEVICE}" shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
BUILD=$(adb -s "${DEVICE}" shell getprop ro.build.version.incremental 2>/dev/null || echo "Unknown")
SOC=$(adb -s "${DEVICE}" shell getprop ro.board.platform 2>/dev/null || echo "Unknown")
UPTIME=$(adb -s "${DEVICE}" shell uptime 2>/dev/null | awk -F'( |,|:)+' '{print $5" hours, "$6" min"}' || echo "Unknown")

echo -e "${CYAN}${BOLD}[1. HARDWARE & PLATFORM SPECS]${NC}"
echo -e "  • Model:            ${BOLD}${MODEL}${NC} (${NAME})"
echo -e "  • SoC Chipset:      ${BOLD}${SOC}${NC}"
echo -e "  • OS Version:       ${BOLD}${FIREOS}${NC} (Android ${ANDROID}, Build ${BUILD})"
echo -e "  • Device Uptime:    ${UPTIME}"
echo ""

# --- 2. Real-Time RAM & Memory Pressure Audit ---
MEMINFO=$(adb -s "${DEVICE}" shell dumpsys meminfo 2>/dev/null || true)
TOTAL_RAM_KB=$(echo "${MEMINFO}" | grep "Total RAM:" | awk '{print $3}' | tr -d 'Kk, ' || echo "0")
FREE_RAM_KB=$(echo "${MEMINFO}" | grep "Free RAM:" | awk '{print $3}' | tr -d 'Kk, ' || echo "0")
USED_RAM_KB=$(echo "${MEMINFO}" | grep "Used RAM:" | awk '{print $3}' | tr -d 'Kk, ' || echo "0")
ZRAM_KB=$(echo "${MEMINFO}" | grep "ZRAM:" | awk '{print $2}' | tr -d 'Kk, ' || echo "0")

TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
FREE_RAM_MB=$((FREE_RAM_KB / 1024))
USED_RAM_MB=$((USED_RAM_KB / 1024))
ZRAM_MB=$((ZRAM_KB / 1024))

PRESSURE_STATE=$(adb -s "${DEVICE}" shell dumpsys activity memory 2>/dev/null | grep -i "mLastMemoryLevel=" | head -n 1 || echo "Normal")
if [[ "${PRESSURE_STATE}" == *"CRITICAL"* ]] || [[ "${PRESSURE_STATE}" == *"critical"* ]]; then
    PRESSURE_COLOR="${RED}"
    PRESSURE_LABEL="CRITICAL (High Lag Risk)"
elif [[ "${PRESSURE_STATE}" == *"LOW"* ]] || [[ "${PRESSURE_STATE}" == *"low"* ]]; then
    PRESSURE_COLOR="${YELLOW}"
    PRESSURE_LABEL="LOW (Moderate Pressure)"
else
    PRESSURE_COLOR="${GREEN}"
    PRESSURE_LABEL="NORMAL (Optimal / Healthy Headroom)"
fi

echo -e "${CYAN}${BOLD}[2. MEMORY (RAM) & PRESSURE AUDIT]${NC}"
echo -e "  • Total Physical:   ${BOLD}${TOTAL_RAM_MB} MB${NC}"
echo -e "  • Free Headroom:    ${GREEN}${BOLD}${FREE_RAM_MB} MB${NC}"
echo -e "  • Active Used:      ${BOLD}${USED_RAM_MB} MB${NC}"
echo -e "  • Swap/ZRAM Used:   ${BOLD}${ZRAM_MB} MB${NC}"
echo -e "  • Memory Pressure:  ${PRESSURE_COLOR}${BOLD}${PRESSURE_LABEL}${NC}"
echo ""

# --- 3. Storage Health ---
STORAGE=$(adb -s "${DEVICE}" shell df -h /data 2>/dev/null | tail -n 1 || true)
DATA_TOTAL=$(echo "${STORAGE}" | awk '{print $2}')
DATA_USED=$(echo "${STORAGE}" | awk '{print $3}')
DATA_FREE=$(echo "${STORAGE}" | awk '{print $4}')
DATA_PERCENT=$(echo "${STORAGE}" | awk '{print $5}')

echo -e "${CYAN}${BOLD}[3. INTERNAL STORAGE AUDIT]${NC}"
echo -e "  • /data Total:      ${DATA_TOTAL}"
echo -e "  • /data Used:       ${DATA_USED} (${DATA_PERCENT})"
echo -e "  • Available Space:  ${GREEN}${BOLD}${DATA_FREE}${NC}"
echo ""

# --- 4. Bloatware & Telemetry Status ---
DISABLED_COUNT=0
TOTAL_TARGETS=0

# Fetch all currently disabled packages once for instant comparison
CURRENT_DISABLED=$(adb -s "${DEVICE}" shell "pm list packages -d -u" 2>/dev/null || true)

if [ -f "${PACKAGE_LIST}" ]; then
    while IFS= read -r PKG <&3 || [ -n "$PKG" ]; do
        [[ "$PKG" =~ ^#.*$ ]] && continue
        [[ -z "${PKG// }" ]] && continue
        TOTAL_TARGETS=$((TOTAL_TARGETS + 1))
        
        if echo "${CURRENT_DISABLED}" | grep -q "package:${PKG}$"; then
            DISABLED_COUNT=$((DISABLED_COUNT + 1))
        fi
    done 3< "${PACKAGE_LIST}"
fi

echo -e "${CYAN}${BOLD}[4. BLOATWARE DEACTIVATION STATUS]${NC}"
if [ "${DISABLED_COUNT}" -eq "${TOTAL_TARGETS}" ]; then
    BLOAT_COLOR="${GREEN}"
    BLOAT_VERDICT="100% Fully Debloated"
elif [ "${DISABLED_COUNT}" -gt 50 ]; then
    BLOAT_COLOR="${YELLOW}"
    BLOAT_VERDICT="Partially Debloated"
else
    BLOAT_COLOR="${RED}"
    BLOAT_VERDICT="Unoptimized / Stock Bloat Active"
fi
echo -e "  • Disabled Bloat:   ${BLOAT_COLOR}${BOLD}${DISABLED_COUNT} / ${TOTAL_TARGETS}${NC} (${BLOAT_VERDICT})"
echo ""

# --- 5. Security & Privacy Hardening ---
DNS_SPECIFIER=$(adb -s "${DEVICE}" shell "settings get global private_dns_specifier" 2>/dev/null || true)
LOC_KILL=$(adb -s "${DEVICE}" shell "settings get global location_global_kill_switch" 2>/dev/null || true)
OTA_UID=$(adb -s "${DEVICE}" shell "pm list packages -u -U com.amazon.device.software.ota" 2>/dev/null | grep -o 'uid:[0-9]*' | cut -d: -f2 || true)
NETPOLICY_BLOCKED=false
if [ -n "${OTA_UID}" ]; then
    IS_BLOCKED=$(adb -s "${DEVICE}" shell "cmd netpolicy list" 2>/dev/null | grep -w "${OTA_UID}" || true)
    if [ -n "${IS_BLOCKED}" ]; then NETPOLICY_BLOCKED=true; fi
fi

echo -e "${CYAN}${BOLD}[5. SECURITY & PRIVACY AUDIT]${NC}"
if [ -n "${DNS_SPECIFIER}" ] && [ "${DNS_SPECIFIER}" != "null" ]; then
    echo -e "  • Private DNS:      ${GREEN}[ACTIVE] ${DNS_SPECIFIER}${NC}"
else
    echo -e "  • Private DNS:      ${RED}[DISABLED] Using unencrypted ISP DNS${NC}"
fi

if [ "${LOC_KILL}" = "1" ]; then
    echo -e "  • Location Beacons: ${GREEN}[KILLED] Global kill switch active${NC}"
else
    echo -e "  • Location Beacons: ${YELLOW}[ACTIVE] Location reporting enabled${NC}"
fi

if [ "${NETPOLICY_BLOCKED}" = true ]; then
    echo -e "  • OTA Lockdown:     ${GREEN}[SECURE] OTA UID ${OTA_UID} blacklisted in kernel firewall${NC}"
else
    echo -e "  • OTA Lockdown:     ${YELLOW}[OPEN] Background firmware updates not firewalled${NC}"
fi
echo ""

# --- 6. Custom Launcher Status ---
PROJECTIVY_PKG="com.spocky.projengmenu"
PROJ_INSTALLED=$(adb -s "${DEVICE}" shell "pm list packages ${PROJECTIVY_PKG}" 2>/dev/null || true)

echo -e "${CYAN}${BOLD}[6. LAUNCHER ENVIRONMENT]${NC}"
if [ -n "${PROJ_INSTALLED}" ]; then
    DOZE_WHITE=$(adb -s "${DEVICE}" shell "dumpsys deviceidle whitelist" 2>/dev/null | grep -w "${PROJECTIVY_PKG}" || true)
    NL_LISTEN=$(adb -s "${DEVICE}" shell "settings get secure enabled_notification_listeners" 2>/dev/null | grep -w "${PROJECTIVY_PKG}" || true)
    
    echo -e "  • Active Launcher:  ${GREEN}${BOLD}Projectivy Launcher${NC}"
    if [ -n "${DOZE_WHITE}" ]; then
        echo -e "  • Doze Whitelist:   ${GREEN}[YES] Instant Home button catch enabled${NC}"
    else
        echo -e "  • Doze Whitelist:   ${YELLOW}[NO] Subject to background freezing${NC}"
    fi
    if [ -n "${NL_LISTEN}" ]; then
        echo -e "  • Media Session:    ${GREEN}[UNLOCKED] Live 'Now Playing' shelf active${NC}"
    else
        echo -e "  • Media Session:    ${YELLOW}[LOCKED] Notification listener disabled${NC}"
    fi
else
    echo -e "  • Active Launcher:  ${YELLOW}Stock Amazon Home${NC}"
fi

echo ""
echo -e "${MAGENTA}${BOLD}=======================================================${NC}"
echo -e "${MAGENTA}${BOLD}               VIBECHECK AUDIT FINISHED                ${NC}"
echo -e "${MAGENTA}${BOLD}=======================================================${NC}"
