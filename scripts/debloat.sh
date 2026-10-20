#!/usr/bin/env bash
# ==============================================================================
# Firestick Hardened Toolkit - Automated Debloater
# ==============================================================================
# Safely disables 104 verified telemetry, ad-tracking, and bloatware packages
# without root using ADB user-space deactivation.
# ==============================================================================

set -eo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_LIST="${DIR}/../data/packages-bloat.txt"
LOG_DIR="${DIR}/../logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/debloat_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

echo -e "${CYAN}${BOLD}"
echo "  ======================================================="
echo "   ⚡ FIRESTICK HARDENED TOOLKIT - SYSTEM DEBLOATER ⚡   "
echo "  ======================================================="
echo -e "${NC}"

# Check ADB installation
if ! command -v adb &> /dev/null; then
    echo -e "${RED}[ERROR] 'adb' is not installed or not in your PATH.${NC}"
    echo "Install ADB via your package manager (e.g., 'brew install android-platform-tools' on macOS)."
    exit 1
fi

# Check connected device
echo -e "${BLUE}[*] Checking ADB connection...${NC}"
DEVICE=$(adb devices | grep -w "device" | awk 'NR==1{print $1}')

if [ -z "${DEVICE}" ]; then
    echo -e "${RED}[ERROR] No authorized ADB device found.${NC}"
    echo "Make sure ADB Debugging is enabled on your Fire TV Stick and accept the authorization prompt on screen."
    exit 1
fi

MODEL=$(adb -s "${DEVICE}" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
BUILD=$(adb -s "${DEVICE}" shell getprop ro.build.version.incremental 2>/dev/null || echo "Unknown")
FIREOS=$(adb -s "${DEVICE}" shell getprop ro.build.version.name 2>/dev/null || echo "Fire OS")

echo -e "${GREEN}[✓] Connected to: ${BOLD}${MODEL}${NC} (${FIREOS}, Build: ${BUILD})"
echo ""

# Handle flags
DRY_RUN=false
if [[ "$*" == *"--dry-run"* ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}[!] RUNNING IN DRY-RUN MODE: No changes will be made.${NC}"
fi

if [ ! -f "${PACKAGE_LIST}" ]; then
    echo -e "${RED}[ERROR] Package list not found at: ${PACKAGE_LIST}${NC}"
    exit 1
fi

# Count target packages
TOTAL=$(grep -v '^#' "${PACKAGE_LIST}" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
echo -e "${CYAN}[*] Loaded ${BOLD}${TOTAL}${NC}${CYAN} target bloat packages.${NC}"
echo ""

read -rp "Proceed with deactivation on ${MODEL}? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[*] Operation cancelled by user.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[*] Debloating system packages...${NC}"
COUNT=0
DISABLED=0
ALREADY_OFF=0
NOT_FOUND=0

while IFS= read -r PKG || [ -n "$PKG" ]; do
    # Skip comments and empty lines
    [[ "$PKG" =~ ^#.*$ ]] && continue
    [[ -z "${PKG// }" ]] && continue

    COUNT=$((COUNT + 1))
    printf "[%3d/%3d] Processing: %-45s " "${COUNT}" "${TOTAL}" "${PKG}"

    if [ "${DRY_RUN}" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC}"
        continue
    fi

    # Check if package exists
    EXISTS=$(adb -s "${DEVICE}" shell "pm list packages -u ${PKG}" 2>/dev/null || true)
    if [ -z "${EXISTS}" ]; then
        echo -e "${YELLOW}[NOT FOUND]${NC}"
        echo "${PKG}: NOT_FOUND" >> "${LOG_FILE}"
        NOT_FOUND=$((NOT_FOUND + 1))
        continue
    fi

    # Disable package
    OUT=$(adb -s "${DEVICE}" shell "pm disable-user --user 0 ${PKG}" 2>/dev/null || true)
    if [[ "${OUT}" == *"disabled-user"* ]] || [[ "${OUT}" == *"disabled"* ]]; then
        echo -e "${GREEN}[DISABLED]${NC}"
        echo "${PKG}: DISABLED" >> "${LOG_FILE}"
        DISABLED=$((DISABLED + 1))
    elif [[ "${OUT}" == *"already disabled"* ]]; then
        echo -e "${CYAN}[ALREADY OFF]${NC}"
        echo "${PKG}: ALREADY_DISABLED" >> "${LOG_FILE}"
        ALREADY_OFF=$((ALREADY_OFF + 1))
    else
        echo -e "${RED}[FAILED]${NC}"
        echo "${PKG}: FAILED (${OUT})" >> "${LOG_FILE}"
    fi
done < "${PACKAGE_LIST}"

echo ""
echo -e "${GREEN}${BOLD}=======================================================${NC}"
echo -e "${GREEN}${BOLD}               DEBLOAT COMPLETE!                       ${NC}"
echo -e "${GREEN}${BOLD}=======================================================${NC}"
echo -e " Newly Disabled:   ${GREEN}${DISABLED}${NC}"
echo -e " Already Disabled: ${CYAN}${ALREADY_OFF}${NC}"
echo -e " Not on Device:    ${YELLOW}${NOT_FOUND}${NC}"
echo -e " Log saved to:     ${BLUE}${LOG_FILE}${NC}"
echo ""
echo -e "${YELLOW}[TIP] Run './scripts/vibecheck.sh' to audit your RAM and storage gains!${NC}"
