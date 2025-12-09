#!/bin/bash
# ============================================
# SSH KCP OVER UDP AUTO INSTALLER
# Must run as ROOT
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERROR: Script must be run as root!${NC}"
        echo -e "${YELLOW}Please use: sudo bash install.sh${NC}"
        exit 1
    fi
}

# Check OS
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${GREEN}[*] Detected OS: $OS $VER${NC}"
    
    # Check if Ubuntu/Debian
    if [[ "$OS" != *"Ubuntu"* ]] && [[ "$OS" != *"Debian"* ]]; then
        echo -e "${YELLOW}[!] Warning: This script is tested on Ubuntu/Debian${NC}"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Install dependencies
install_deps() {
    echo -e "${GREEN}[1] Updating system...${NC}"
    apt-get update -y
    apt-get upgrade -y
    
    echo -e "${GREEN}[2] Installing dependencies...${NC}"
    apt-get install -y \
        wget curl git build-essential cmake \
        net-tools iptables ufw \
        supervisor golang \
        libssl-dev libsodium-dev mbedtls-dev
}

# Install KCPTUN
install_kcptun() {
    echo -e "${GREEN}[3] Installing KCPTUN...${NC}"