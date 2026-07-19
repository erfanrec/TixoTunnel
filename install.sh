#!/usr/bin/env bash
set -Eeuo pipefail

GITHUB_REPO="YOUR_GITHUB_USERNAME/TixoTunnel"
INSTALL_DIR="/root/tixotunnel-core"
PANEL_PATH="/root/TixoTunnel.sh"
CORE_PATH="${INSTALL_DIR}/tixotunnel-core"
COMMAND_PATH="/usr/local/bin/tixotunnel"
PANEL_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/TixoTunnel.sh"
CORE_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/tixotunnel-core"

RED='\033[31m'; GREEN='\033[32m'; CYAN='\033[36m'; RESET='\033[0m'

[[ ${EUID} -eq 0 ]] || { echo -e "${RED}Run this installer as root.${RESET}"; exit 1; }
command -v curl >/dev/null 2>&1 || { apt-get update -y && apt-get install -y curl; }

clear
echo -e "${RED}        ▄▄▄▄▄▄▄"
echo "     ▄██████████▄"
echo "   ▄████▀▀  ▀████▄       T I X O"
echo "  ████▀  ▄▄  ▀████      T U N N E L"
echo "   ▀████▄▄▄▄████▀"
echo -e "      ▀██████▀${RESET}"
echo -e "${CYAN}Automated installer by @TixoCloud — TixoCloud.com${RESET}"
echo

mkdir -p "$INSTALL_DIR"
tmp_panel=$(mktemp)
tmp_core=$(mktemp)
trap 'rm -f "$tmp_panel" "$tmp_core"' EXIT

echo -e "${CYAN}[1/4] Downloading panel...${RESET}"
curl -fL --retry 3 --connect-timeout 15 -o "$tmp_panel" "$PANEL_URL"

echo -e "${CYAN}[2/4] Downloading core...${RESET}"
curl -fL --retry 3 --connect-timeout 15 -o "$tmp_core" "$CORE_URL"

echo -e "${CYAN}[3/4] Installing files and permissions...${RESET}"
install -m 0755 "$tmp_panel" "$PANEL_PATH"
install -m 0755 "$tmp_panel" "$COMMAND_PATH"
install -m 0755 "$tmp_core" "$CORE_PATH"

# Optional migration from the previous directory.
if [[ -d /root/backhaul-core ]]; then
  find /root/backhaul-core -maxdepth 1 -type f -name '*.toml' -exec cp -n {} "$INSTALL_DIR/" \; 2>/dev/null || true
fi

echo -e "${CYAN}[4/4] Installation completed.${RESET}"
echo -e "${GREEN}Command: tixotunnel${RESET}"
sleep 1
exec "$PANEL_PATH"
