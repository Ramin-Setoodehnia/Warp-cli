#!/bin/bash

# ========== Auto-install on first run ==========
SCRIPT_PATH="/usr/local/bin/warp-menu"
if [[ "$0" != "$SCRIPT_PATH" ]]; then
  echo -e "\033[0;33m[!] Installing warp-menu to /usr/local/bin ...\033[0m"
  cp "$0" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
  echo -e "\033[0;32m[✓] Installed! Now run with: sudo warp-menu\033[0m"
  exit 0
fi

# ========== Colors & Version ==========
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
VERSION="1.0"

# [[ $EUID -ne 0 ]] && echo -e "${RED}Run this script as root.${NC}" && exit 1

# ========== Core Checks ==========
dvhost_warp_is_installed() {
    command -v warp-cli &>/dev/null
}

dvhost_warp_is_connected() {
    warp-cli status 2>/dev/null | grep -iq "Connected"
}

# ========== Core Functions ==========
dvhost_warp_install() {
    if dvhost_warp_is_installed && dvhost_warp_is_connected; then
        echo -e "${GREEN}WARP is already installed and connected.${NC}"
        read -p "Do you want to reinstall it? [y/N]: " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && return
    fi

    echo -e "${CYAN}Installing WARP-CLI...${NC}"
    local codename=$(lsb_release -cs)
    [[ "$codename" == "oracular" ]] && codename="jammy"

    apt update
    apt install -y curl gpg lsb-release apt-transport-https ca-certificates sudo
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $codename main" > /etc/apt/sources.list.d/cloudflare-client.list
    apt update
    apt install -y cloudflare-warp
    dvhost_warp_connect
}

dvhost_warp_connect() {
    echo -e "${BLUE}Connecting to WARP Proxy...${NC}"
    yes | warp-cli registration new
    warp-cli mode proxy
    warp-cli proxy port 10808
    warp-cli connect
    sleep 1
}

dvhost_warp_status() {
    warp-cli status
}

dvhost_warp_test_proxy() {
    echo -e "${CYAN}Testing SOCKS5 proxy (127.0.0.1:10808)...${NC}"
    curl --socks5 127.0.0.1:10808 https://ifconfig.me && echo ""
}

dvhost_warp_remove() {
    echo -e "${RED}Removing WARP...${NC}"
    apt remove --purge -y cloudflare-warp
    rm -f /etc/apt/sources.list.d/cloudflare-client.list
    rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    apt autoremove -y
    echo -e "${GREEN}WARP removed.${NC}"
}

# ========== Menu ==========
dvhost_warp_draw_menu() {
    clear
    local proxy_ip="127.0.0.1"
    local proxy_port="10808"
    local is_connected=$(dvhost_warp_is_connected && echo "yes" || echo "no")
    local socks5_ip="N/A"
    [[ "$is_connected" == "yes" ]] && socks5_ip=$(curl -s --socks5 "${proxy_ip}:${proxy_port}" https://ifconfig.me || echo "N/A")

    cat << "EOF"
+-------------------------------------------------------------------+
|   ██╗    ██╗ █████╗ ██████╗ ██████╗        ██████╗██╗     ██╗     |
|   ██║    ██║██╔══██╗██╔══██╗██╔══██╗      ██╔════╝██║     ██║     |
|   ██║ █╗ ██║███████║██████╔╝██████╔╝█████╗██║     ██║     ██║     |
|   ██║███╗██║██╔══██║██╔══██╗██╔═══╝ ╚════╝██║     ██║     ██║     |
|   ╚███╔███╔╝██║  ██║██║  ██║██║           ╚██████╗███████╗██║     |
|    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝            ╚═════╝╚══════╝╚═╝     |
+-------------------------------------------------------------------+
EOF
echo -e "|Telegram Channel:${YELLOW}@DVHOST_CLOUD${NC} |YouTube:${RED}@dvhost_cloud${NC} | Version:${GREEN}${VERSION}${NC} "
    echo +-------------------------------------------------------------------+
    # echo -e "| IPv4        : ${YELLOW}$(curl -s ipv4.icanhazip.com)${NC}"
    if [[ "$is_connected" == "yes" ]]; then
        echo -e "|WARP Status: ${GREEN}CONNECTED${NC} |Proxy:${proxy_ip}:${proxy_port} |Out IP:${socks5_ip}"
    else
        echo -e "|WARP Status: ${RED}NOT CONNECTED${NC}"
    fi
    echo +-------------------------------------------------------------------+
    echo -e "| ${YELLOW}Choose an option:${NC}"
    echo +-------------------------------------------------------------------+
    echo -e "| 1 - Install WARP"
    # echo -e "| 2 - Connect to WARP Proxy"
    echo -e "| 2 - Show Status"
    echo -e "| 3 - Test Proxy"
    echo -e "| 4 - Remove WARP"
    echo -e "| 0 - Exit"
    echo +-------------------------------------------------------------------+
    echo -ne "${YELLOW}Select option: ${NC}"
}

dvhost_warp_main_menu() {
    while true; do
        dvhost_warp_draw_menu
        read -r choice
        case $choice in
            1) dvhost_warp_install ;;
            # 2) dvhost_warp_connect ;;
            2) dvhost_warp_status ;;
            3) dvhost_warp_test_proxy ;;
            4) dvhost_warp_remove ;;
            0) echo -e "${GREEN}Exiting...${NC}"; exit ;;
            *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
        esac
        echo -e "\nPress Enter to return to menu..."
        read -r
    done
}

# ========== Run Menu ==========
dvhost_warp_main_menu
