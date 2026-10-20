#!/usr/bin/env bash
# ==============================================================================
# Firestick Hardened Toolkit - Rollback & Restoration
# ==============================================================================
# Safely re-enables any or all previously disabled packages.
# ==============================================================================

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_LIST="${DIR}/../data/packages-bloat.txt"

echo -e "${CYAN}${BOLD}"
echo "  ======================================================="
echo "   ⚡ FIRESTICK HARDENED TOOLKIT - RESTORATION TOOL ⚡   "
echo "  ======================================================="
echo -e "${NC}"

# Check ADB
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
echo -e "${GREEN}[✓] Connected to: ${BOLD}${MODEL}${NC}"
echo ""

# Specific package restoration
if [ -n "$1" ]; then
    TARGET_PKG="$1"
    echo -e "${BLUE}[*] Restoring specific package: ${TARGET_PKG}${NC}"
    adb -s "${DEVICE}" shell "pm enable ${TARGET_PKG}" || true
    echo -e "${GREEN}[✓] Package re-enabled.${NC}"
    exit 0
fi

echo -e "${YELLOW}[!] WARNING: This will re-enable all 104 default bloatware packages.${NC}"
read -rp "Do you want to proceed with full restoration? [y/N]: " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}[*] Restoration aborted.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[*] Re-enabling packages...${NC}"
RESTORED=0

while IFS= read -r PKG || [ -n "$PKG" ]; do
    [[ "$PKG" =~ ^#.*$ ]] && continue
    [[ -z "${PKG// }" ]] && continue

    printf "Enabling: %-45s " "${PKG}"
    OUT=$(adb -s "${DEVICE}" shell "pm enable ${PKG}" 2>/dev/null || true)
    if [[ "${OUT}" == *"enabled"* ]]; then
        echo -e "${GREEN}[RESTORED]${NC}"
        RESTORED=$((RESTORED + 1))
    else
        echo -e "${YELLOW}[SKIPPED/NOT INSTALLED]${NC}"
    fi
done < "${PACKAGE_LIST}"

echo ""
echo -e "${GREEN}[✓] Restoration finished. ${RESTORED} packages restored.${NC}"
