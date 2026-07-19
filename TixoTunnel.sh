#!/usr/bin/env bash
set -o pipefail

SCRIPT_VERSION="NOVA-5.1"
ENGINE_EDITION="AETHER-X1"
BRAND_NAME="TixoTunnel"
BRAND_CHANNEL="@TixoCloud"
BRAND_WEBSITE="TixoCloud.com"
GITHUB_REPO="erfanrec/TixoTunnel"

INSTALL_DIR="/root/tixotunnel-core"
PANEL_PATH="/root/TixoTunnel.sh"
COMMAND_PATH="/usr/local/bin/tixotunnel"
CLOUD_COMMAND_PATH="/usr/local/bin/tixocloud"
CORE_DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/tixotunnel-core"
PANEL_DOWNLOAD_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/TixoTunnel.sh"

bootstrap_install() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "TixoTunnel must be run as root."
        exit 1
    fi

    # Running from curl/process substitution or an arbitrary local path:
    # install the canonical copy first, then continue from it.
    local current_path="${BASH_SOURCE[0]:-}"
    if [[ "$current_path" != "$PANEL_PATH" && "$current_path" != "$COMMAND_PATH" && "$current_path" != "$CLOUD_COMMAND_PATH" ]]; then
        command -v curl >/dev/null 2>&1 || {
            apt-get update -y && apt-get install -y curl ca-certificates
        }

        mkdir -p "$INSTALL_DIR"
        local tmp_panel tmp_core
        tmp_panel=$(mktemp)
        tmp_core=$(mktemp)
        trap 'rm -f "$tmp_panel" "$tmp_core"' RETURN

        clear
        printf '\033[31m%s\033[0m\n' '       ▄████▄   ▄████▄'
        printf '\033[31m%s\033[0m\n' '    ▄██████████████████▄'
        printf '\033[31m%s\033[0m\n' '   ███████▀      ▀███████       T I X O C L O U D'
        printf '\033[31m%s\033[0m\n' '   ██████   ▄██▄   ██████       T U N N E L'
        printf '\033[31m%s\033[0m\n' '    ▀██████████████████▀'
        printf '\033[31m%s\033[0m\n' '       ▀████████████▀'
        printf '\033[36mSecure deployment powered by @TixoCloud — TixoCloud.com\033[0m\n\n'

        echo '[1/4] Downloading TixoTunnel panel...'
        curl -fL --retry 3 --connect-timeout 15 -o "$tmp_panel" "$PANEL_DOWNLOAD_URL" || {
            echo 'Panel download failed.'
            exit 1
        }

        echo '[2/4] Downloading TixoTunnel core...'
        curl -fL --retry 3 --connect-timeout 15 -o "$tmp_core" "$CORE_DOWNLOAD_URL" || {
            echo 'Core download failed. Make sure tixotunnel-core exists in the latest GitHub Release.'
            exit 1
        }

        echo '[3/4] Creating directories and setting permissions...'
        install -m 0755 "$tmp_panel" "$PANEL_PATH"
        install -m 0755 "$tmp_panel" "$COMMAND_PATH"
        install -m 0755 "$tmp_panel" "$CLOUD_COMMAND_PATH"
        install -m 0755 "$tmp_core" "$INSTALL_DIR/tixotunnel-core"

        echo '[4/4] Installation completed.'
        echo 'Run later with: tixotunnel  (or: tixocloud)'
        sleep 1
        exec "$PANEL_PATH"
    fi

    mkdir -p "$INSTALL_DIR"
    chmod 0755 "$PANEL_PATH" "$COMMAND_PATH" "$CLOUD_COMMAND_PATH" 2>/dev/null || true
}

bootstrap_install

service_dir="/etc/systemd/system"
config_dir="/root/tixotunnel-core"
CORE_FILE="${config_dir}/tixotunnel-core"
CERT_DIR="${config_dir}/cert_files"
CERT_FILE="${CERT_DIR}/cert.crt"
KEY_FILE="${CERT_DIR}/cert.key"
mkdir -p "$CERT_DIR"
if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root"
sleep 1
exit 1
fi
colorize() {
local color="$1"
local text="$2"
local style="${3:-normal}"
local black="\033[30m" red="\033[31m" green="\033[32m" yellow="\033[33m"
local blue="\033[34m" magenta="\033[35m" cyan="\033[36m" white="\033[37m"
local reset="\033[0m" normal="\033[0m" bold="\033[1m" underline="\033[4m"
local color_code
case $color in
black) color_code=$black ;; red) color_code=$red ;;
green) color_code=$green ;; yellow) color_code=$yellow ;;
blue) color_code=$blue ;; magenta) color_code=$magenta ;;
cyan) color_code=$cyan ;; white) color_code=$white ;;
*) color_code=$reset ;;
esac
local style_code
case $style in
bold) style_code=$bold ;; underline) style_code=$underline ;;
normal | *) style_code=$normal ;;
esac
echo -e "${style_code}${color_code}${text}${reset}"
}
section_header() {
local title="$1"
echo -e "\033[38;5;245m────────────────────────────────────────────────────────────────────\033[0m"
echo -e "\033[97m ${title}\033[0m"
echo -e "\033[38;5;245m────────────────────────────────────────────────────────────────────\033[0m"
}
wizard_header() {
local step="$1" title="$2" subtitle="${3:-}"
echo -e "\033[38;5;245m────────────────────────────────────────────────────────────────────\033[0m"
printf "\033[38;5;51m STEP %-5s\033[0m  \033[97m%s\033[0m\n" "$step" "$title"
[[ -n "$subtitle" ]] && printf " \033[38;5;245m%s\033[0m\n" "$subtitle"
echo -e "\033[38;5;245m────────────────────────────────────────────────────────────────────\033[0m"
}
select_option() {
local prompt="$1" default="$2" var_name="$3"; shift 3
local options=("$@") choice i
for i in "${!options[@]}"; do
    printf "  \033[38;5;51m[%d]\033[0m %s\n" "$((i+1))" "${options[$i]}"
done
while true; do
    read -r -p "$prompt [${default}]: " choice
    choice="${choice:-$default}"
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
        printf -v "$var_name" '%s' "${options[$((choice-1))]}"
        return 0
    fi
    colorize red "Invalid selection. Choose 1-${#options[@]}."
done
}
press_key() {
read -r -p "Press Enter to continue..."
}
prompt_with_default() {
local prompt="$1"
local default="$2"
local var_name="$3"
local input
echo -ne "[-] $prompt (default: $default): "
read -r input
eval "$var_name=\"${input:-$default}\""
}
prompt_boolean() {
local prompt="$1"
local default="$2"
local var_name="$3"
while true; do
prompt_with_default "$prompt [true/false]" "$default" "$var_name"
local value="${!var_name}"
if [[ "$value" == "true" || "$value" == "false" ]]; then
break
fi
colorize red "Invalid input. Please enter 'true' or 'false'."
done
}
validate_cidr() {
local cidr="$1"
if [[ ! "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]{1,2})$ ]]; then
return 1
fi
IFS='/' read -r ip mask <<< "$cidr"
IFS='.' read -r a b c d <<< "$ip"
if (( a<0 || a>255 || b<0 || b>255 || c<0 || c>255 || d<0 || d>255 )); then
return 1
fi
if (( mask < 1 || mask > 32 )); then
return 1
fi
local ip_int=$(( (a << 24) | (b << 16) | (c << 8) | d ))
local mask_int
if (( mask == 32 )); then
mask_int=0xFFFFFFFF
else
mask_int=$(( (0xFFFFFFFF << (32 - mask)) & 0xFFFFFFFF ))
fi
local net_int=$(( ip_int & mask_int ))
local broadcast_int=$(( net_int | (~mask_int & 0xFFFFFFFF) ))
if (( ip_int == net_int )); then
return 1
fi
if (( ip_int == broadcast_int )); then
return 1
fi
return 0
}
valid_ipv4() {
local ip="$1" a b c d
[[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
IFS='.' read -r a b c d <<< "$ip"
for octet in "$a" "$b" "$c" "$d"; do
    [[ "$octet" =~ ^[0-9]+$ ]] || return 1
    (( 10#$octet >= 0 && 10#$octet <= 255 )) || return 1
done
return 0
}

generate_shared_key() {
if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 32 | tr -d '\n'
else
    head -c 32 /dev/urandom | base64 | tr -d '\n'
fi
}

prompt_shared_key() {
local input generated
colorize yellow "Use exactly the same shared key on both tunnel endpoints."
echo -ne "[-] Shared Encryption Key (paste existing key, or press Enter to generate): "
read -r input
if [[ -z "$input" ]]; then
    generated=$(generate_shared_key)
    CONFIG[psk]="$generated"
    colorize green "Generated key: $generated" bold
    colorize yellow "Save this key; enter it on the opposite server."
else
    CONFIG[psk]="$input"
fi
}

install_jq() {
if ! command -v jq &> /dev/null; then
if command -v apt-get &> /dev/null; then
colorize yellow "Installing jq..."
sudo apt-get update && sudo apt-get install -y jq
else
colorize red "Error: Unsupported package manager. Please install jq manually."
press_key
exit 1
fi
fi
}
download_tixo_engine() {
local source_url="https://github.com/${GITHUB_REPO}/releases/latest/download/tixotunnel-core"
if [[ "$1" == "menu" ]]; then
rm -f "$CORE_FILE" >/dev/null 2>&1
colorize cyan "Existing tunnel services may need a restart after the engine update." bold
sleep 1
fi
[[ -x "$CORE_FILE" ]] && return 0
mkdir -p "$config_dir"
local tmp_file
 tmp_file=$(mktemp)
colorize cyan "Downloading Tixo Aether Engine..." bold
if ! curl -fL --retry 3 --connect-timeout 15 -o "$tmp_file" "$source_url"; then
colorize red "Core download failed: $source_url"
rm -f "$tmp_file"
return 1
fi
install -m 0755 "$tmp_file" "$CORE_FILE"
rm -f "$tmp_file"
colorize green "Tixo Aether Engine installed successfully." bold
}
install_jq
download_tixo_engine
declare -A CONFIG
reset_config() {
CONFIG=()
}
prompt_connection_section() {
local mode="$1"  # server or client
section_header "Link Endpoint"
if [[ "$mode" == "server" ]]; then
prompt_with_default "Bind Address" ":8443" CONFIG[bind_addr]
if [[ -n "${CONFIG[bind_addr]}" && "${CONFIG[bind_addr]}" != *:* ]]; then
CONFIG[bind_addr]=":${CONFIG[bind_addr]}"
fi
else
while true; do
echo -ne "[*] IRAN Server Address [IP:Port] or [Domain:Port]: "
read -r CONFIG[remote_addr]
if [[ -z "${CONFIG[remote_addr]}" ]]; then
colorize red "Server address cannot be empty."
continue
fi
if [[ "${CONFIG[remote_addr]}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}$ || \
"${CONFIG[remote_addr]}" =~ ^[a-zA-Z0-9.-]+:[0-9]{1,5}$ ]]; then
break
else
colorize red "Invalid format. Use IP:Port or Domain:Port."
fi
done
if [[ "${CONFIG[transport_type]}" == "ws" || "${CONFIG[transport_type]}" == "wss" || "${CONFIG[transport_type]}" == "wsmux" || "${CONFIG[transport_type]}" == "wssmux" || "${CONFIG[transport_type]}" == "xwsmux" ]]; then
echo -ne "[-] Edge IP/Domain (optional, press Enter to skip): "
read -r CONFIG[edge_ip]
fi
CONFIG[dial_timeout]="10"
CONFIG[retry_interval]="3"
fi
echo ""
}
VALID_ALGORITHMS=("aes-256-gcm" "chacha20-poly1305" "aes-128-gcm")
is_valid_algorithm() {
local input="$1"
for alg in "${VALID_ALGORITHMS[@]}"; do
if [[ "$input" == "$alg" ]]; then
return 0
fi
done
return 1
}
prompt_security_section() {
local is_ipx="$1"
wizard_header "5/8" "ENCRYPTION & IDENTITY" "Secure both endpoints with one shared key"
if [[ "$is_ipx" == "true" ]]; then
prompt_boolean "Enable Encryption" "true" CONFIG[enable_encryption]
if [[ "${CONFIG[enable_encryption]}" == "true" ]]; then
echo
while true; do
colorize magenta "Available algorithms: aes-256-gcm, chacha20-poly1305, aes-128-gcm"
prompt_with_default "Algorithm" "aes-256-gcm" CONFIG[algorithm]
if is_valid_algorithm "${CONFIG[algorithm]}"; then
break
else
colorize red "Invalid algorithm selected. Please choose one from the list."
echo
fi
done
prompt_shared_key
prompt_with_default "KDF Iterations" "100000" CONFIG[kdf_iterations]
fi
else
prompt_with_default "Security Token" "your_token" CONFIG[token]
CONFIG[enable_encryption]="false"
fi
echo ""
}
prompt_transport_section() {
local mode="$1"
local is_ipx="false"
wizard_header "1/8" "TRANSPORT FABRIC" "Choose the carrier used between both endpoints"
local valid_transports=(tcp tcpmux xtcpmux ws wss wsmux wssmux xwsmux anytls tun)
select_option "Transport" "10" CONFIG[transport_type] "${valid_transports[@]}"
if [[ "${CONFIG[transport_type]}" == "tun" ]]; then
    echo
    wizard_header "2/8" "TUN ENCAPSULATION" "Select standard TCP or native IPX packet mode"
    local encapsulations=(tcp ipx)
    select_option "Encapsulation" "2" CONFIG[tun_encapsulation] "${encapsulations[@]}"
fi
echo
[[ "${CONFIG[tun_encapsulation]}" == "ipx" ]] && is_ipx="true"
if [[ "$is_ipx" != "true" ]]; then
    prompt_boolean "Enable TCP_NODELAY" "true" CONFIG[nodelay]
fi
if [[ "$mode" == "server" ]]; then
    if [[ "${CONFIG[transport_type]}" == "tcp" ]]; then
        prompt_boolean "Accept UDP over TCP" "false" CONFIG[accept_udp]
    fi
    if [[ ! "${CONFIG[transport_type]}" =~ ^(tun|ws)$ ]] && [[ "$is_ipx" != "true" ]]; then
        prompt_boolean "Enable Proxy Protocol" "false" CONFIG[proxy_protocol]
    fi
else
    if [[ "${CONFIG[transport_type]}" != "tun" ]]; then
        prompt_with_default "Connection Pool" "8" CONFIG[connection_pool]
    fi
fi
CONFIG[heartbeat_interval]="10"
CONFIG[heartbeat_timeout]="25"
[[ "$is_ipx" != "true" ]] && CONFIG[keepalive_period]="40"
echo ""
}
prompt_mux_section() {
local transport="$1"
if [[ ! "$transport" =~ mux$ ]]; then
return
fi
section_header "Mux Configuration"
prompt_with_default "Mux Version [1 or 2]" "2" CONFIG[mux_version]
prompt_with_default "Mux Concurrency" "8" CONFIG[mux_concurrency]
CONFIG[mux_framesize]="32768"
CONFIG[mux_recievebuffer]="4194304"
CONFIG[mux_streambuffer]="2097152"
echo ""
}
prompt_tun_section() {
local transport="$1"
local mode="$2"
local is_ipx="$3"
[[ "$transport" != "tun" ]] && return
section_header "Virtual Interface"
prompt_with_default "TUN Device Name" "tixo" CONFIG[tun_name]
local default_local default_remote
if [[ "$mode" == "server" ]]; then
default_local="10.10.10.1/24"
default_remote="10.10.10.2/24"
else
default_local="10.10.10.2/24"
default_remote="10.10.10.1/24"
fi
while true; do
prompt_with_default "TUN Local Address (CIDR)" "$default_local" CONFIG[tun_local_addr]
if validate_cidr "${CONFIG[tun_local_addr]}"; then
break
fi
local suggested=$(validate_cidr "${CONFIG[tun_local_addr]}" 2>&1)
colorize red "Invalid CIDR. Network address should be: $suggested"
done
while true; do
prompt_with_default "TUN Remote Address (CIDR)" "$default_remote" CONFIG[tun_remote_addr]
if validate_cidr "${CONFIG[tun_remote_addr]}"; then
break
fi
colorize red "Invalid CIDR format."
done
prompt_with_default "Health Port" "101" CONFIG[tun_health_port]
if [[ "$is_ipx" == "true" ]]; then
prompt_with_default "MTU" "1320" CONFIG[tun_mtu]
else
prompt_with_default "MTU" "1500" CONFIG[tun_mtu]
fi
echo ""
}
prompt_tls_section() {
local mode="$1"
local transport="$2"
if [[ ! "$transport" =~ ^(anytls|wss|wssmux)$ ]]; then
return
fi
section_header "TLS Configuration"
if [[ "$transport" == "anytls" ]]; then
prompt_with_default "SNI" "www.digikala.com" CONFIG[tls_sni]
fi
if [[ "$mode" == "client" ]]; then
echo
return
fi
if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
colorize red "[*] TLS certificate or key missing, generating self-signed Ed25519 cert..."
openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -x509 -days 365 -sha256 -keyout "$KEY_FILE" -out  "$CERT_FILE" -subj "/CN=tixocloud.com"
colorize green "[*] Generated $CERT_FILE and $KEY_FILE"
echo
fi
prompt_with_default "TLS Certificate Path" "$CERT_FILE" CONFIG[tls_cert]
prompt_with_default "TLS Key Path" "$KEY_FILE" CONFIG[tls_key]
echo ""
}
prompt_tuning_section() {
local is_ipx="$1"
local is_tun="$2"
wizard_header "6/8" "PERFORMANCE PROFILE" "Tune kernel buffers and worker behavior"
prompt_boolean "Enable Auto Tuning" "true" CONFIG[auto_tuning]
echo
colorize magenta "Profiles: balanced, fast, latency, resource" normal
prompt_with_default "Kernel Tuning Profile" "balanced" CONFIG[tuning_profile]
prompt_with_default "Workers (0 = auto)" "0" CONFIG[workers]
if [[ "$is_tun" != "true" ]]; then
prompt_with_default "Channel Size" "4096" CONFIG[channel_size]
fi
if [[ "$is_tun" == "true" ]]; then
CONFIG[channel_size]="10_000"
fi
if [[ "$is_ipx" == "true" ]]; then
prompt_with_default "Batch Size" "2048" CONFIG[batch_size]
prompt_with_default "SO_SNDBUF (0 = auto)" "0" CONFIG[so_sndbuf]
else
prompt_with_default "TCP MSS (0 = auto)" "0" CONFIG[tcp_mss]
prompt_with_default "SO_RCVBUF (0 = auto)" "0" CONFIG[so_rcvbuf]
prompt_with_default "SO_SNDBUF (0 = auto)" "0" CONFIG[so_sndbuf]
fi
if [[ "$is_tun" != "true" ]] && [[ "$is_ipx" != "true" ]]; then
echo
colorize magenta "Buffer Profiles: extreme_low_cpu, ultra_low_cpu, low_cpu, balanced, low_memory" normal
prompt_with_default "Buffer Profile" "balanced" CONFIG[buffer_profile]
prompt_with_default "Read Timeout" "120" CONFIG[read_timeout]
fi
echo ""
}
prompt_logging_section() {
wizard_header "7/8" "TELEMETRY" "Choose the amount of runtime detail"
colorize magenta "Levels: panic, fatal, error, warn, info, debug, trace"
prompt_with_default "Log Level" "info" CONFIG[log_level]
echo ""
}
prompt_accept_udp_section() {
local accept_udp="$1"
[[ "$accept_udp" != "true" ]] && return
CONFIG[ring_size]="64"
CONFIG[frame_size]="2048"
CONFIG[peer_idle_timeout_s]="120"
CONFIG[write_timeout_ms]="3"
}
prompt_ports_section() {
local mode="$1"
local is_tun="$2"
[[ "$mode" != "server" ]] && return
if [[ "$is_tun" != "true" ]]; then
section_header "Route Mapping"
colorize green "Supported formats:"
echo "  1. 443           - Listen on 443, forward to 443"
echo "  2. 443=5000      - Listen on 443, forward to 5000"
echo "  3. 443-600       - Listen on range 443-600"
echo "  4. 443-600:5201  - Range forwarding to 5201"
echo ""
echo -ne "Enter port mappings (comma-separated): "
read -r CONFIG[ports_mapping]
echo ""
else
wizard_header "8/8" "ROUTE MAPPING" "Map public ports to destination services"
colorize magenta "Choose the forwarding engine:"
echo "  1) Tixo TCP Relay       — optimized TCP forwarding"
echo "  2) Netfilter Gateway    — TCP + UDP forwarding"
while true; do
    read -r -p "Forwarding engine [1-2] (default: 1): " forwarder_choice
    forwarder_choice="${forwarder_choice:-1}"
    case "$forwarder_choice" in
        1) CONFIG[forwarder]="back""haul"; break ;;
        2) CONFIG[forwarder]="iptables"; break ;;
        *) colorize red "Invalid choice. Enter 1 or 2." ;;
    esac
done
echo ""
colorize green "Supported formats:"
echo "  1. 443           - Listen on 443, forward to 443"
echo "  2. 443=5000      - Listen on 443, forward to 5000"
echo ""
echo -ne "Enter port mappings (comma-separated): "
read -r CONFIG[ports_mapping]
echo ""
fi
}
prompt_ipx_section() {
local is_ipx="$1"
local mode="$2"
[[ "$is_ipx" != "true" ]] && return
wizard_header "3/8" "PACKET FABRIC" "Build the IPX path and packet profile"
CONFIG[ipx_mode]="$mode"
AVAILABLE_PROFILES=("icmp" "ipip" "udp" "tcp" "gre" "bip")
select_option "IPX Profile" "4" CONFIG[ipx_profile] "${AVAILABLE_PROFILES[@]}"
prompt_with_default "Listen IP" $SERVER_IP CONFIG[ipx_listen_ip]
while :; do
prompt_with_default "Destination IPv4" "" CONFIG[ipx_dst_ip]
if valid_ipv4 "${CONFIG[ipx_dst_ip]}" && [[ "${CONFIG[ipx_dst_ip]}" != "0.0.0.0" ]]; then
break
fi
colorize red "Invalid destination IPv4. Example: 203.0.113.10"
done
interface=$(ip route show default | awk '{print $5}')
prompt_with_default "Network Interface" "$interface" CONFIG[ipx_interface]

echo ""
wizard_header "4/8" "IP SPOOFING" "Optional custom packet identity for advanced routes"
prompt_boolean "Enable Custom Packet" "false" CONFIG[custom_packet]
if [[ "${CONFIG[custom_packet]}" == "true" ]]; then
    if [[ "$mode" == "server" ]]; then
        while :; do
            prompt_with_default "SRC Spoof IP" "" CONFIG[spoof_src_ip]
            if valid_ipv4 "${CONFIG[spoof_src_ip]}" && [[ "${CONFIG[spoof_src_ip]}" != "0.0.0.0" ]]; then
                break
            fi
            colorize red "Invalid SRC spoof IPv4. Example: 185.143.234.120"
        done
        while :; do
            prompt_with_default "DST Spoof IP" "" CONFIG[spoof_dst_ip]
            if valid_ipv4 "${CONFIG[spoof_dst_ip]}" && [[ "${CONFIG[spoof_dst_ip]}" != "0.0.0.0" ]]; then
                break
            fi
            colorize red "Invalid DST spoof IPv4. Example: 185.143.234.122"
        done
    else
        # On KHAREJ (client), ask in the reverse order requested by the panel flow.
        while :; do
            prompt_with_default "DST Spoof IP" "" CONFIG[spoof_dst_ip]
            if valid_ipv4 "${CONFIG[spoof_dst_ip]}" && [[ "${CONFIG[spoof_dst_ip]}" != "0.0.0.0" ]]; then
                break
            fi
            colorize red "Invalid DST spoof IPv4. Example: 185.143.234.120"
        done
        while :; do
            prompt_with_default "SRC Spoof IP" "" CONFIG[spoof_src_ip]
            if valid_ipv4 "${CONFIG[spoof_src_ip]}" && [[ "${CONFIG[spoof_src_ip]}" != "0.0.0.0" ]]; then
                break
            fi
            colorize red "Invalid SRC spoof IPv4. Example: 185.143.234.122"
        done
    fi
fi

if [[ "${CONFIG[ipx_profile]}" == "icmp" ]]; then
prompt_with_default "ICMP Type" "0" CONFIG[ipx_icmp_type]
prompt_with_default "ICMP Code" "0" CONFIG[ipx_icmp_code]
fi
echo ""
}
generate_toml_config() {
local mode="$1"
local output_file="$2"
local is_tun="$3"
local is_ipx="$4"
{
if [[ "$mode" == "server" ]] && [[ "$is_ipx" == "false" ]]; then
echo "[listener]"
echo "bind_addr = \"${CONFIG[bind_addr]}\""
echo ""
elif [[ "$is_ipx" == "false" ]]; then
echo "[dialer]"
echo "remote_addr = \"${CONFIG[remote_addr]}\""
[[ -n "${CONFIG[edge_ip]}" ]] && echo "edge_ip = \"${CONFIG[edge_ip]}\""
echo "dial_timeout = ${CONFIG[dial_timeout]}"
echo "retry_interval = ${CONFIG[retry_interval]}"
echo ""
fi
echo "[transport]"
echo "type = \"${CONFIG[transport_type]}\""
[[ -n "${CONFIG[nodelay]}" ]] && echo "nodelay = ${CONFIG[nodelay]}"
[[ -n "${CONFIG[keepalive_period]}" ]] && echo "keepalive_period = ${CONFIG[keepalive_period]}"
if [[ "$mode" == "server" ]]; then
[[ -n "${CONFIG[accept_udp]}" ]] && echo "accept_udp = ${CONFIG[accept_udp]}"
[[ -n "${CONFIG[proxy_protocol]}" ]] && echo "proxy_protocol = ${CONFIG[proxy_protocol]}"
else
[[ -n "${CONFIG[connection_pool]}" ]] && [[ "${CONFIG[connection_pool]}" != "0" ]] && \
echo "connection_pool = ${CONFIG[connection_pool]}"
fi
[[ -n "${CONFIG[heartbeat_interval]}" ]] && echo "heartbeat_interval = ${CONFIG[heartbeat_interval]}"
[[ -n "${CONFIG[heartbeat_timeout]}" ]] && echo "heartbeat_timeout = ${CONFIG[heartbeat_timeout]}"
echo ""
if [[ "$is_tun" == "true" ]]; then
echo "[tun]"
echo "encapsulation = \"${CONFIG[tun_encapsulation]}\""
echo "name = \"${CONFIG[tun_name]}\""
echo "local_addr = \"${CONFIG[tun_local_addr]}\""
echo "remote_addr = \"${CONFIG[tun_remote_addr]}\""
echo "health_port = ${CONFIG[tun_health_port]}"
echo "mtu = ${CONFIG[tun_mtu]}"
echo ""
fi
if [[ "$is_ipx" == "true" ]]; then
echo "[ipx]"
echo "mode = \"${CONFIG[ipx_mode]}\""
echo "profile = \"${CONFIG[ipx_profile]}\""
echo "listen_ip = \"${CONFIG[ipx_listen_ip]}\""
echo "dst_ip = \"${CONFIG[ipx_dst_ip]}\""
echo "interface = \"${CONFIG[ipx_interface]}\""
if [[ "${CONFIG[custom_packet]}" == "true" ]]; then
    if [[ "$mode" == "server" ]]; then
        echo "spoof_src_ip = \"${CONFIG[spoof_src_ip]}\""
        echo "spoof_dst_ip = \"${CONFIG[spoof_dst_ip]}\""
    else
        echo "spoof_dst_ip = \"${CONFIG[spoof_dst_ip]}\""
        echo "spoof_src_ip = \"${CONFIG[spoof_src_ip]}\""
    fi
    echo "custom_packet = true"
fi
[[ -n "${CONFIG[ipx_icmp_type]}" ]] && echo "icmp_type = ${CONFIG[ipx_icmp_type]}"
[[ -n "${CONFIG[ipx_icmp_code]}" ]] && echo "icmp_code = ${CONFIG[ipx_icmp_code]}"
echo ""
fi
if [[ "${CONFIG[transport_type]}" =~ mux$ ]]; then
echo "[mux]"
echo "mux_version = ${CONFIG[mux_version]}"
echo "mux_framesize = ${CONFIG[mux_framesize]}"
echo "mux_recievebuffer = ${CONFIG[mux_recievebuffer]}"
echo "mux_streambuffer = ${CONFIG[mux_streambuffer]}"
[[ -n "${CONFIG[mux_concurrency]}" ]] && echo "mux_concurrency = ${CONFIG[mux_concurrency]}"
echo ""
fi
echo "[security]"
if [[ "$is_ipx" == "true" ]]; then
echo "enable_encryption = ${CONFIG[enable_encryption]}"
[[ "${CONFIG[enable_encryption]}" == "true" ]] && {
echo "algorithm = \"${CONFIG[algorithm]}\""
echo "psk = \"${CONFIG[psk]}\""
echo "kdf_iterations = ${CONFIG[kdf_iterations]}"
}
else
echo "token = \"${CONFIG[token]}\""
fi
echo ""
if [[ -n "${CONFIG[tls_sni]}" || -n "${CONFIG[tls_cert]}" ]]; then
echo "[tls]"
[[ -n "${CONFIG[tls_sni]}" ]]  && echo "sni = \"${CONFIG[tls_sni]}\""
[[ -n "${CONFIG[tls_cert]}" ]] && echo "tls_cert = \"${CONFIG[tls_cert]}\""
[[ -n "${CONFIG[tls_key]}" ]]  && echo "tls_key = \"${CONFIG[tls_key]}\""
echo ""
fi
echo "[tuning]"
[[ -n "${CONFIG[auto_tuning]}" ]]     && echo "auto_tuning = ${CONFIG[auto_tuning]}"
[[ -n "${CONFIG[tuning_profile]}" ]]  && echo "tuning_profile = \"${CONFIG[tuning_profile]}\""
[[ -n "${CONFIG[workers]}" ]]         && echo "workers = ${CONFIG[workers]}"
[[ -n "${CONFIG[channel_size]}" ]]    && echo "channel_size = ${CONFIG[channel_size]}"
[[ -n "${CONFIG[tcp_mss]}" ]]         && echo "tcp_mss = ${CONFIG[tcp_mss]}"
[[ -n "${CONFIG[so_rcvbuf]}" ]]       && echo "so_rcvbuf = ${CONFIG[so_rcvbuf]}"
[[ -n "${CONFIG[so_sndbuf]}" ]]       && echo "so_sndbuf = ${CONFIG[so_sndbuf]}"
[[ -n "${CONFIG[buffer_profile]}" ]]  && echo "buffer_profile = \"${CONFIG[buffer_profile]}\""
[[ -n "${CONFIG[batch_size]}" ]]      && echo "batch_size = ${CONFIG[batch_size]}"
[[ -n "${CONFIG[read_timeout]}" ]]    && echo "read_timeout = ${CONFIG[read_timeout]}"
echo ""
if [[ "${CONFIG[accept_udp]}" == "true" ]]; then
echo "[accept_udp]"
echo "ring_size = ${CONFIG[ring_size]}"
echo "frame_size = ${CONFIG[frame_size]}"
echo "peer_idle_timeout_s = ${CONFIG[peer_idle_timeout_s]}"
echo "write_timeout_ms = ${CONFIG[write_timeout_ms]}"
echo ""
fi
echo "[logging]"
echo "log_level = \"${CONFIG[log_level]}\""
echo ""
if [[ "$mode" == "server" ]] ; then
echo "[ports]"
[[ -n "${CONFIG[forwarder]}" ]]  && echo "forwarder = \"${CONFIG[forwarder]}\""
echo "mapping = ["
IFS=',' read -r -a ports <<< "${CONFIG[ports_mapping]}"
for port in "${ports[@]}"; do
[[ -n "$port" ]] && echo "    \"${port// /}\","
done
echo "]"
fi
} > "$output_file"
}
configure_server() {
local mode="$1"  # server or client
local mode_name
if [[ "$mode" == "server" ]]; then
mode_name="IRAN (Server)"
else
mode_name="KHAREJ (Client)"
fi
clear
colorize cyan "Configuring $mode_name" bold
echo ""
reset_config
prompt_transport_section "$mode"
local is_tun="false"
local is_ipx="false"
[[ "${CONFIG[transport_type]}" == "tun" ]] && is_tun="true"
[[ "${CONFIG[tun_encapsulation]}" == "ipx" ]] && is_ipx="true"
prompt_tun_section "${CONFIG[transport_type]}" "$mode" "$is_ipx"
prompt_ipx_section "$is_ipx" "$mode"
if [[ "$is_ipx" != "true" ]]; then
prompt_connection_section "$mode"
fi
prompt_security_section "$is_ipx"
prompt_accept_udp_section "${CONFIG[accept_udp]}"
prompt_mux_section "${CONFIG[transport_type]}"
prompt_tls_section "$mode" "${CONFIG[transport_type]}"
prompt_tuning_section "$is_ipx" "$is_tun"
prompt_logging_section
prompt_ports_section "$mode" "$is_tun"
local tunnel_port
if [[ "$mode" == "server" ]]; then
tunnel_port=$(echo "${CONFIG[bind_addr]}" | grep -oP ':\K[0-9]+$')
else
tunnel_port=$(echo "${CONFIG[remote_addr]}" | grep -oP ':\K[0-9]+$')
fi
if [[ -z "$tunnel_port" ]]; then
tunnel_port=$(echo "${CONFIG[tun_health_port]}")
fi
section_header "Review"
printf "  Role        : %s\n" "$mode_name"
printf "  Transport   : %s\n" "${CONFIG[transport_type]}"
[[ "$is_tun" == "true" ]] && printf "  Interface   : %s (%s)\n" "${CONFIG[tun_name]}" "${CONFIG[tun_encapsulation]}"
if [[ "$is_ipx" == "true" ]]; then
    printf "  IPX Profile : %s\n" "${CONFIG[ipx_profile]}"
    printf "  Destination : %s\n" "${CONFIG[ipx_dst_ip]}"
    printf "  IP Spoofing : %s\n" "${CONFIG[custom_packet]}"
fi
printf "  Encryption  : %s\n" "${CONFIG[enable_encryption]:-token}"
if [[ "${CONFIG[enable_encryption]}" == "true" && -n "${CONFIG[psk]}" ]]; then
    echo
    printf "  Shared Key  : \033[1;33m%s\033[0m\n" "${CONFIG[psk]}"
    printf "  \033[38;5;245mCopy this key and use the exact same value on the peer server.\033[0m\n"
fi
echo
read -r -p "Create this tunnel? [Y/n]: " confirm_create
confirm_create="${confirm_create:-Y}"
[[ "$confirm_create" =~ ^[Yy]$ ]] || { colorize yellow "Configuration cancelled."; press_key; return 0; }

local config_file
if [[ "$mode" == "server" ]]; then
config_file="${config_dir}/iran${tunnel_port}.toml"
else
config_file="${config_dir}/kharej${tunnel_port}.toml"
fi
generate_toml_config "$mode" "$config_file" "$is_tun" "$is_ipx"
local service_type
[[ "$mode" == "server" ]] && service_type="iran" || service_type="kharej"
create_systemd_service "$service_type" "$tunnel_port" "$config_file"
echo ""
colorize green "✔ Configuration completed successfully!" bold
echo ""
press_key
}
create_systemd_service() {
local type="$1"
local port="$2"
local config_file="$3"
local service_file="${service_dir}/tixotunnel-${type}${port}.service"
local desc_type="$(tr '[:lower:]' '[:upper:]' <<< "${type:0:1}")${type:1}"
cat > "$service_file" <<EOF
[Unit]
Description=TixoTunnel $desc_type Port $port
After=network.target
[Service]
Type=simple
User=root
ExecStart=${CORE_FILE} -c $config_file
Restart=always
RestartSec=3
LimitNOFILE=1048576
TasksMax=infinity
LimitMEMLOCK=infinity
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now "tixotunnel-${type}${port}.service" >/dev/null 2>&1
colorize green "✔ Service tixotunnel-${type}${port} created and started" bold
}
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_COUNTRY=$(curl -sS --max-time 1 "http://ipwhois.app/json/$SERVER_IP" 2>/dev/null | jq -r '.country')
SERVER_ISP=$(curl -sS --max-time 1 "http://ipwhois.app/json/$SERVER_IP" 2>/dev/null | jq -r '.isp')
display_logo() {
clear
local red="\033[38;5;196m" white="\033[97m" gray="\033[38;5;245m"
local cyan="\033[38;5;51m" green="\033[38;5;46m" reset="\033[0m"
echo -e "${red}"
echo "___________.__             _________ .__                   .___"
echo "\\__    ___/|__|__  _______ \\_   ___ \\|  |   ____  __ __  __| _/"
echo "  |    |   |  \\  \\/  /  _ \\/    \\  \\/|  |  /  _ \\|  |  \\/ __ |"
echo "  |    |   |  |>    <  <_> )     \\___|  |_(  <_> )  |  / /_/ |"
echo "  |____|   |__/__/\\_ \\____/ \\______  /____/\\____/|____/\\____ |"
echo "                    \\/             \\/                       \\/"
echo -e "${reset}"
echo -e "${gray}════════════════════════════════════════════════════════════════════${reset}"
printf "${white} %-10s${reset} ${cyan}%-15s${reset} ${white}%-10s${reset} ${green}%s${reset}\n" \
    "Console" "$SCRIPT_VERSION" "Engine" "$ENGINE_EDITION"
printf "${white} %-10s${reset} ${green}%-15s${reset} ${white}%-10s${reset} ${cyan}%s${reset}\n" \
    "Status" "● Operational" "Channel" "$BRAND_CHANNEL"
printf "${white} %-10s${reset} ${gray}%s${reset}\n" "Features" "TUN • IPX • Encryption • Auto Tuning • IP Spoofing"
echo -e "${gray}════════════════════════════════════════════════════════════════════${reset}"
}

get_active_tunnel_count() {
local count=0 service
for service in "$service_dir"/tixotunnel-*.service; do
    [[ -e "$service" ]] || continue
    systemctl is-active --quiet "$(basename "$service")" && ((count++))
done
echo "$count"
}
get_total_tunnel_count() {
find "$config_dir" -maxdepth 1 -type f \( -name 'iran*.toml' -o -name 'kharej*.toml' \) 2>/dev/null | wc -l | tr -d ' '
}
get_cpu_usage() {
local a b idle total prev_idle prev_total diff_idle diff_total
read -r _ a b _ _ idle _ _ _ _ _ < /proc/stat
prev_idle=$idle; prev_total=$((a+b+idle)); sleep 0.12
read -r _ a b _ _ idle _ _ _ _ _ < /proc/stat
idle=$idle; total=$((a+b+idle)); diff_idle=$((idle-prev_idle)); diff_total=$((total-prev_total))
(( diff_total > 0 )) && echo $((100-(100*diff_idle/diff_total))) || echo 0
}
display_server_info() {
local gray="\033[38;5;245m" cyan="\033[38;5;51m" green="\033[38;5;46m" reset="\033[0m"
local active total cpu ram disk uptime_short
active=$(get_active_tunnel_count); total=$(get_total_tunnel_count)
cpu=$(get_cpu_usage)
ram=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
disk=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
uptime_short=$(uptime -p 2>/dev/null | sed 's/^up //' || true)
[[ -z "$SERVER_COUNTRY" || "$SERVER_COUNTRY" == "null" ]] && SERVER_COUNTRY="Unknown"
[[ -z "$SERVER_ISP" || "$SERVER_ISP" == "null" ]] && SERVER_ISP="Unknown"
echo -e "${cyan} SERVER${reset}"
printf "  %-12s : %s\n" "IP Address" "$SERVER_IP"
printf "  %-12s : %s\n" "Location" "$SERVER_COUNTRY"
printf "  %-12s : %s\n" "Provider" "$SERVER_ISP"
printf "  %-12s : %s active / %s total\n" "Tunnels" "$active" "$total"
echo -e "${gray}────────────────────────────────────────────────────────────────────${reset}"
echo -e "${cyan} SYSTEM${reset}"
printf "  CPU %-4s%%    RAM %-4s%%    DISK %-4s%%    UPTIME %s\n" "$cpu" "$ram" "$disk" "${uptime_short:-Unknown}"
echo -e "${gray}════════════════════════════════════════════════════════════════════${reset}"
}
display_engine_status() {
if [[ -x "$CORE_FILE" ]]; then
    echo -e "\033[38;5;46m ● Engine ready\033[0m  \033[38;5;245mTUN • IPX • Spoof Support\033[0m"
else
    echo -e "\033[38;5;196m ● Engine missing\033[0m"
fi
}

check_config_backup() {
missing_services=()
for config in "${config_dir}"/iran*.toml "${config_dir}"/kharej*.toml; do
[ -e "$config" ] || continue
fname=$(basename "$config")
if [[ "$fname" =~ ^(iran|kharej)([0-9]+)\.toml$ ]]; then
location="${BASH_REMATCH[1]}"
tunnel_port="${BASH_REMATCH[2]}"
service_file="${service_dir}/tixotunnel-${location}${tunnel_port}.service"
if [[ ! -f "$service_file" ]]; then
missing_services+=("$service_file:$location:$tunnel_port")
fi
fi
done
[[ ${#missing_services[@]} -eq 0 ]] && return 0
echo
colorize red "Missing service files:" bold
for entry in "${missing_services[@]}"; do
service_file="${entry%%:*}"
location="${entry#*:}"; location="${location%%:*}"
tunnel_port="${entry##*:}"
echo "- $service_file (type: $location, port: $tunnel_port)"
done
echo
read -r -p "Do you want to create missing service files? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
for entry in "${missing_services[@]}"; do
service_file="${entry%%:*}"
location="${entry#*:}"; location="${location%%:*}"
tunnel_port="${entry##*:}"
config_file="${config_dir}/${location}${tunnel_port}.toml"
desc_loc="$(tr '[:lower:]' '[:upper:]' <<< "${location:0:1}")${location:1}"
cat > "$service_file" <<EOF
[Unit]
Description=TixoTunnel $desc_loc Port $tunnel_port
After=network.target
[Service]
Type=simple
User=root
ExecStart=${CORE_FILE} -c $config_file
Restart=always
RestartSec=3
LimitNOFILE=1048576
TasksMax=infinity
LimitMEMLOCK=infinity
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now "$(basename "$service_file")"
echo "Created and started $(basename "$service_file")"
done
fi
sleep 2
}
check_config_backup
check_tunnel_status() {
if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
colorize red "No config files found." bold
press_key
return 1
fi
clear
colorize yellow "Checking TixoTunnel services..." bold
sleep 1
echo
for config_path in "$config_dir"/{iran,kharej}*.toml; do
[ -f "$config_path" ] || continue
config_name=$(basename "$config_path")
config_name="${config_name%.toml}"
service_name="tixotunnel-${config_name}.service"
if [[ "$config_name" =~ ^iran([0-9]+)$ ]]; then
port="${BASH_REMATCH[1]}"
if systemctl is-active --quiet "$service_name"; then
colorize green "Iran service (port $port) is running"
else
colorize red "Iran service (port $port) is not running"
fi
elif [[ "$config_name" =~ ^kharej([0-9]+)$ ]]; then
port="${BASH_REMATCH[1]}"
if systemctl is-active --quiet "$service_name"; then
colorize green "Kharej service (port $port) is running"
else
colorize red "Kharej service (port $port) is not running"
fi
fi
done
echo
press_key
}
scheduler_unit_base() {
local service="${1%.service}"
printf "/etc/systemd/system/%s-auto-restart" "$service"
}
restart_scheduler() {
local service="$1" base timer_file service_file current="Disabled" choice value unit
base=$(scheduler_unit_base "$service")
timer_file="${base}.timer"
service_file="${base}.service"
[[ -f "$timer_file" ]] && current=$(grep -E '^OnUnitActiveSec=' "$timer_file" | cut -d= -f2-)
while true; do
    clear
    section_header "Restart Scheduler"
    printf "  Service     : %s\n" "$service"
    printf "  Schedule    : %s\n\n" "$current"
    echo "  [1] Set interval"
    echo "  [2] Disable scheduler"
    echo "  [0] Back"
    echo
    read -r -p "Select an option [0-2]: " choice
    case "$choice" in
        1)
            echo
            echo "  [1] Minutes"
            echo "  [2] Hours"
            read -r -p "Interval unit [1-2]: " unit
            [[ "$unit" == "1" || "$unit" == "2" ]] || { colorize red "Invalid unit."; sleep 1; continue; }
            read -r -p "Restart every how many $([[ "$unit" == "1" ]] && echo minutes || echo hours)? " value
            [[ "$value" =~ ^[1-9][0-9]*$ ]] || { colorize red "Enter a positive whole number."; sleep 1; continue; }
            [[ "$unit" == "1" ]] && interval="${value}min" || interval="${value}h"
            cat > "$service_file" <<EOF
[Unit]
Description=Scheduled restart for $service

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart $service
EOF
            cat > "$timer_file" <<EOF
[Unit]
Description=Auto restart timer for $service

[Timer]
OnBootSec=$interval
OnUnitActiveSec=$interval
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF
            systemctl daemon-reload
            systemctl enable --now "$(basename "$timer_file")" >/dev/null 2>&1
            current="$interval"
            colorize green "Scheduler enabled: every $interval" bold
            sleep 2
            ;;
        2)
            systemctl disable --now "$(basename "$timer_file")" >/dev/null 2>&1 || true
            rm -f "$timer_file" "$service_file"
            systemctl daemon-reload
            current="Disabled"
            colorize green "Scheduler disabled." bold
            sleep 2
            ;;
        0) return ;;
        *) colorize red "Invalid option."; sleep 1 ;;
    esac
done
}

tunnel_management() {
if ! ls "$config_dir"/*.toml 1> /dev/null 2>&1; then
colorize red "No config files found." bold
press_key
return 1
fi
clear
colorize cyan "TixoTunnel Manager" bold
echo
local index=1
declare -a configs
for config_path in "$config_dir"/{iran,kharej}*.toml; do
[ -f "$config_path" ] || continue
config_name=$(basename "$config_path")
if [[ "$config_name" =~ ^iran([0-9]+)\.toml$ ]]; then
port="${BASH_REMATCH[1]}"
configs+=("$config_path")
service_name="tixotunnel-iran${port}.service"
if systemctl is-active --quiet "$service_name"; then status="\033[38;5;46m● Running\033[0m"; else status="\033[38;5;245m○ Stopped\033[0m"; fi
echo -e "\033[35m${index}\033[0m) Iran · Port \033[33m$port\033[0m · $status"
((index++))
elif [[ "$config_name" =~ ^kharej([0-9]+)\.toml$ ]]; then
port="${BASH_REMATCH[1]}"
configs+=("$config_path")
service_name="tixotunnel-kharej${port}.service"
if systemctl is-active --quiet "$service_name"; then status="\033[38;5;46m● Running\033[0m"; else status="\033[38;5;245m○ Stopped\033[0m"; fi
echo -e "\033[35m${index}\033[0m) Kharej · Port \033[33m$port\033[0m · $status"
((index++))
fi
done
echo
echo -ne "Enter your choice (0 to return): "
read -r choice
[[ "$choice" == "0" ]] && return
while ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#configs[@]} )); do
colorize red "Invalid choice."
echo -ne "Enter your choice (0 to return): "
read -r choice
[[ "$choice" == "0" ]] && return
done
selected_config="${configs[$((choice - 1))]}"
config_name=$(basename "${selected_config%.toml}")
service_name="tixotunnel-${config_name}.service"
clear
colorize cyan "Tunnel Control — $config_name" bold
echo
colorize red "1) Remove Tunnel"
colorize yellow "2) Restart Tunnel"
echo "3) Live Monitor"
echo "4) Service Details"
echo "5) Restart Scheduler"
echo
read -r -p "Enter your choice (0 to return): " choice
case $choice in
1) destroy_tunnel "$selected_config" ;;
2) restart_service "$service_name" ;;
3) view_service_logs "$service_name" ;;
4) view_service_status "$service_name" ;;
5) restart_scheduler "$service_name" ;;
0) return ;;
*) colorize red "Invalid option!" && sleep 1 ;;
esac
}
destroy_tunnel() {
config_path="$1"
config_name=$(basename "${config_path%.toml}")
service_name="tixotunnel-${config_name}.service"
service_path="$service_dir/$service_name"
[ -f "$config_path" ] && rm -f "$config_path"
local scheduler_base
scheduler_base=$(scheduler_unit_base "$service_name")
systemctl disable --now "$(basename "${scheduler_base}.timer")" >/dev/null 2>&1 || true
rm -f "${scheduler_base}.timer" "${scheduler_base}.service"
if [[ -f "$service_path" ]]; then
systemctl is-active --quiet "$service_name" && systemctl disable --now "$service_name" >/dev/null 2>&1
rm -f "$service_path"
fi
systemctl daemon-reload
echo
colorize green "Tunnel destroyed successfully!" bold
echo
press_key
}
restart_service() {
echo
colorize yellow "Restarting $1" bold
if systemctl list-units --type=service | grep -q "$1"; then
systemctl restart "$1"
colorize green "Service restarted successfully" bold
echo
else
colorize red "Service not found"
fi
press_key
}
brand_engine_output() {
sed -u -E \
  -e '/^[[:space:]]*[╔║╚].*[╗║╝][[:space:]]*$/d' \
  -e '/Backhaul v[0-9]/d' \
  -e '/High-Performance Reverse Network Tunnel/d' \
  -e '/^[[:space:]]*root[[:space:]]*:[[:space:]]*PWD=/d' \
  -e '/pam_unix\(sudo:session\)/d' \
  -e '/^[[:space:]]*🌐 IP Address:/d' \
  -e '/^[[:space:]]*📋 Configuration Summary:/d' \
  -e '/^[[:space:]]*🔧 General Settings:/d' \
  -e '/^[[:space:]]*🚀 Starting /d' \
  -e '/^[[:space:]]*Mode: /d' \
  -e '/^[[:space:]]*Log Level: /d' \
  -e '/^[[:space:]]*Transport: /d' \
  -e '/^[[:space:]]*TCP Optimization: /d' \
  -e '/^═+$/d' \
  -e 's/Backhaul/Tixo Aether/g' \
  -e 's/bbackhaul/Tixo TCP Relay/g' \
  -e 's/backhaul/tixo-engine/g' \
  -e 's/Starting Ipx/Starting IPX Fabric/g' \
  -e 's/custom packet status:/IP spoofing:/g'
}
show_live_header() {
local service="$1"
echo -e "\033[38;5;51m════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[97m TixoTunnel Live Monitor\033[0m"
printf  "\033[38;5;245m Service  %-36s Engine  %s\033[0m\n" "$service" "$ENGINE_EDITION"
echo -e "\033[38;5;51m════════════════════════════════════════════════════════════════════\033[0m"
}

view_service_logs() {
clear
show_live_header "$1"
colorize yellow "Press Ctrl+C to return"
journalctl -eu "$1" -f -o cat | brand_engine_output
}
view_service_status() {
clear
show_live_header "$1"
systemctl status "$1" --no-pager | brand_engine_output
press_key
}
remove_core() {
if find "$config_dir" -type f -name "*.toml" | grep -q .; then
colorize red "Delete all services first."
sleep 3
return 1
fi
colorize yellow "Remove the Tixo Aether Engine and its files? (y/n)"
read -r confirm
if [[ $confirm == [yY] ]]; then
[[ -d "$config_dir" ]] && rm -rf "$config_dir"
colorize green "Tixo Aether Engine removed successfully." bold
fi
press_key
}
update_script() {
local url="https://raw.githubusercontent.com/${GITHUB_REPO}/main/TixoTunnel.sh"
local tmp_file
 tmp_file=$(mktemp)
colorize cyan "Updating TixoTunnel panel..." bold
if curl -fL --retry 3 -o "$tmp_file" "$url"; then
install -m 0755 "$tmp_file" "/root/TixoTunnel.sh"
install -m 0755 "$tmp_file" "/usr/local/bin/tixotunnel"
install -m 0755 "$tmp_file" "/usr/local/bin/tixocloud"
rm -f "$tmp_file"
colorize green "Panel updated successfully." bold
sleep 2
exec /root/TixoTunnel.sh
else
rm -f "$tmp_file"
colorize red "Panel update failed."
press_key
fi
}
configure_tunnel() {
[[ ! -d "$config_dir" ]] && {
colorize red "Install the Tixo Aether Engine first."
press_key
return 1
}
clear
section_header "Create Tunnel"
echo -e "  \033[38;5;51m[1]\033[0m IRAN   \033[38;5;245mServer / Listener\033[0m"
echo -e "  \033[38;5;51m[2]\033[0m KHAREJ \033[38;5;245mClient / Connector\033[0m"
echo -e "  \033[38;5;245m[0] Back\033[0m"
echo
read -r -p "Select endpoint role [0-2]: " configure_choice
case "$configure_choice" in
1) configure_server "server" ;;
2) configure_server "client" ;;
0) return ;;
*) colorize red "Invalid option!" && sleep 1 ;;
esac
}
display_menu() {
display_logo
display_server_info
display_engine_status
echo
colorize green   " [1] Create Tunnel" bold
colorize cyan    " [2] Tunnel Manager" bold
colorize yellow  " [3] Dashboard" bold
colorize magenta " [4] Update Engine" bold
echo              " [5] Update Console"
colorize red      " [6] Remove Engine" bold
echo              " [0] Exit"
echo -e "\033[38;5;245m────────────────────────────────────────────────────────────────────\033[0m"
}

read_option() {
read -r -p "Select an option [0-6]: " choice
case $choice in
1) configure_tunnel ;;
2) tunnel_management ;;
3) check_tunnel_status ;;
4) download_tixo_engine "menu" ;;
5) update_script ;;
6) remove_core ;;
0) clear; exit 0 ;;
*) colorize red "Invalid option." && sleep 1 ;;
esac
}
while true; do
display_menu
read_option
done