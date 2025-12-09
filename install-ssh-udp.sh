#!/bin/bash
# ===================================================
# SSH UDP CUSTOM AUTO INSTALL
# Menu: menu-udp
# Format: kanggacor.fun:1-65535@username:password
# ===================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
DOMAIN="kanggacor.fun"
PORTS="1-65535"
INSTALL_DIR="/root/ssh-udp-manager"
USER_DB="$INSTALL_DIR/users.db"
BAN_LIST="$INSTALL_DIR/banlist.db"
LOG_FILE="/var/log/ssh-udp.log"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[!] Run as root: sudo bash $0${NC}"
    exit 1
fi

# ==================== INSTALL DEPENDENCIES ====================

install_deps() {
    echo -e "${YELLOW}[1] Installing dependencies...${NC}"
    
    apt update -y
    apt upgrade -y
    
    apt install -y \
        curl wget git nano \
        ufw iptables-persistent \
        dropbear stunnel4 \
        screen tmux socat \
        python3 python3-pip \
        jq bc net-tools \
        build-essential cmake \
        supervisor fail2ban \
        netcat-openbsd vnstat
    
    timedatectl set-timezone Asia/Jakarta
    
    echo -e "${GREEN}[✓] Dependencies installed${NC}"
}

# ==================== OPEN ALL PORTS ====================

open_all_ports() {
    echo -e "${YELLOW}[2] Opening all ports 1-65535...${NC}"
    
    ufw --force disable
    ufw --force reset
    
    ufw default allow incoming
    ufw default allow outgoing
    ufw default allow routed
    
    echo "y" | ufw enable
    
    iptables -F
    iptables -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    netfilter-persistent save
    
    echo -e "${GREEN}[✓] All ports 1-65535 opened${NC}"
}

# ==================== INSTALL UDP CUSTOM ====================

install_udp_custom() {
    echo -e "${YELLOW}[3] Installing UDP Custom...${NC}"
    
    cd /tmp
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    source /etc/profile
    
    git clone https://github.com/ihciah/udp-custom.git
    cd udp-custom
    go build -o udp-custom
    cp udp-custom /usr/local/bin/
    chmod +x /usr/local/bin/udp-custom
    
    mkdir -p /etc/udp-custom
    
    cat > /etc/udp-custom/config.json << EOF
{
  "server": "0.0.0.0",
  "server_port": 7300,
  "password": "defaultpass",
  "method": "aes-256-gcm",
  "timeout": 0,
  "udp_timeout": 0,
  "udp": true,
  "fast_open": true,
  "mode": "tcp_and_udp",
  "no_delay": true,
  "keep_alive": true
}
EOF
    
    echo -e "${GREEN}[✓] UDP Custom installed${NC}"
}

# ==================== SETUP AUTO-RECONNECT ====================

setup_auto_reconnect() {
    echo -e "${YELLOW}[4] Setting up auto-reconnect...${NC}"
    
    cat > /etc/supervisor/conf.d/udp-custom.conf << EOF
[program:udp-custom]
command=/usr/local/bin/udp-custom -c /etc/udp-custom/config.json
directory=/etc/udp-custom
autostart=true
autorestart=true
startretries=999999
startsecs=0
stopwaitsecs=0
user=root
redirect_stderr=true
stdout_logfile=/var/log/udp-custom.log
stdout_logfile_maxbytes=10MB
killasgroup=true
stopasgroup=true
EOF
    
    systemctl enable supervisor
    systemctl start supervisor
    supervisorctl update
    
    # Buat watchdog untuk auto restart cepat
    cat > /usr/local/bin/udp-watchdog << 'EOF'
#!/bin/bash
while true; do
    if ! pgrep -x "udp-custom" > /dev/null; then
        echo "[$(date)] UDP Custom restarting..." >> /var/log/udp-watchdog.log
        systemctl restart supervisor
        sleep 1
    fi
    sleep 0.5
done
EOF
    
    chmod +x /usr/local/bin/udp-watchdog
    
    cat > /etc/systemd/system/udp-watchdog.service << EOF
[Unit]
Description=UDP Custom Watchdog
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/udp-watchdog
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable udp-watchdog
    systemctl start udp-watchdog
    
    echo -e "${GREEN}[✓] Auto-reconnect setup - NO DELAY${NC}"
}

# ==================== CREATE MENU-UDP ====================

create_menu_udp() {
    echo -e "${YELLOW}[5] Creating menu-udp...${NC}"
    
    cat > /usr/local/bin/menu-udp << 'EOF'
#!/bin/bash
# ===================================================
# SSH UDP MANAGER - menu-udp
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

DOMAIN="kanggacor.fun"
PORTS="1-65535"
INSTALL_DIR="/root/ssh-udp-manager"
USER_DB="$INSTALL_DIR/users.db"
BAN_LIST="$INSTALL_DIR/banlist.db"

mkdir -p "$INSTALL_DIR"
[ -f "$USER_DB" ] || echo "[]" > "$USER_DB"
[ -f "$BAN_LIST" ] || echo "[]" > "$BAN_LIST"

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║               SSH UDP CUSTOM MANAGER             ║"
    echo "║             Command: menu-udp                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}Server: $DOMAIN:$PORTS${NC}"
    echo -e "${YELLOW}IP: $(curl -s ifconfig.me) | Jakarta: $(date)${NC}"
    echo ""
}

# ==================== 1. BUAT AKUN ====================

create_account() {
    echo ""
    echo -e "${CYAN}[1] CREATE SSH UDP ACCOUNT${NC}"
    echo -e "${CYAN}═══════════════════════════${NC}"
    
    echo -n "Username: "
    read username
    
    echo -n "Password: "
    read -s password
    echo
    
    echo -n "Limit IP (max connections): "
    read limit_ip
    limit_ip=${limit_ip:-3}
    
    expiry=$(date -d "+30 days" '+%Y-%m-%d')
    
    # Buat user
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Save to DB
    jq --arg user "$username" \
       --arg pass "$password" \
       --arg limit "$limit_ip" \
       --arg exp "$expiry" \
       '. += [{
           "username": $user,
           "password": $pass,
           "limit_ip": $limit|tonumber,
           "expiry": $exp,
           "created": "'$(date '+%Y-%m-%d')'",
           "active": true,
           "locked": false,
           "connections": 0
       }]' "$USER_DB" > /tmp/db.tmp && mv /tmp/db.tmp "$USER_DB"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           ✅ ACCOUNT CREATED                     ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[MAIN CONFIG]${NC}"
    echo -e "${WHITE}$DOMAIN:$PORTS@$username:$password${NC}"
    echo ""
    
    echo -e "${CYAN}[DETAILS]${NC}"
    echo -e "${WHITE}Host: $DOMAIN"
    echo "Ports: $PORTS"
    echo "User: $username"
    echo "Pass: $password"
    echo "Limit: $limit_ip connections/IP"
    echo "Expiry: $expiry"
    echo ""
    
    echo -e "${YELLOW}[FOR CLIENT]${NC}"
    echo -e "${WHITE}Format: $DOMAIN:$PORTS@$username:$password"
    echo "Copy config di atas untuk digunakan!"
    echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
    
    # Set IP limit
    if [ "$limit_ip" -gt 0 ]; then
        iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above "$limit_ip" --connlimit-mask 32 -j DROP
    fi
}

# ==================== 2. HAPUS AKUN ====================

delete_account() {
    echo ""
    echo -e "${CYAN}[2] DELETE ACCOUNT${NC}"
    echo -e "${CYAN}══════════════════${NC}"
    
    echo -n "Username: "
    read username
    
    jq 'del(.[] | select(.username == "'$username'"))' "$USER_DB" > /tmp/db.tmp && mv /tmp/db.tmp "$USER_DB"
    userdel -r "$username" 2>/dev/null
    
    echo -e "${GREEN}[✓] Account $username deleted${NC}"
}

# ==================== 3. LIST SEMUA AKUN ====================

list_accounts() {
    echo ""
    echo -e "${CYAN}[3] LIST ALL ACCOUNTS${NC}"
    echo -e "${CYAN}══════════════════════${NC}"
    
    total=$(jq 'length' "$USER_DB")
    echo -e "${WHITE}Total Accounts: $total${NC}"
    echo ""
    
    if [ "$total" -eq 0 ]; then
        echo -e "${YELLOW}No accounts found${NC}"
        return
    fi
    
    echo -e "${WHITE}No. Username         Status   Limit IP  Expiry      ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    
    i=1
    jq -r '.[] | "\(.username)|\(.active)|\(.limit_ip)|\(.expiry)|\(.locked)"' "$USER_DB" | while IFS='|' read -r user active limit expiry locked; do
        if [ "$active" = "true" ] && [ "$locked" = "false" ]; then
            status="${GREEN}ACTIVE${NC}"
        elif [ "$locked" = "true" ]; then
            status="${RED}LOCKED${NC}"
        else
            status="${YELLOW}INACTIVE${NC}"
        fi
        
        printf "${WHITE}%-4s${NC} %-16s %-9s %-9s %-12s\n" "$i" "$user" "$status" "$limit" "$expiry"
        i=$((i+1))
    done
    
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
}

# ==================== 4. LOCK ACCOUNT ====================

lock_account() {
    echo ""
    echo -e "${CYAN}[4] LOCK ACCOUNT${NC}"
    echo -e "${CYAN}═════════════════${NC}"
    
    echo -n "Username: "
    read username
    
    passwd -l "$username" 2>/dev/null
    jq '(.[] | select(.username == "'$username'")).locked = true' "$USER_DB" > /tmp/db.tmp && mv /tmp/db.tmp "$USER_DB"
    
    echo -e "${GREEN}[✓] Account $username locked${NC}"
}

# ==================== 5. UNLOCK ACCOUNT ====================

unlock_account() {
    echo ""
    echo -e "${CYAN}[5] UNLOCK ACCOUNT${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
    
    echo -n "Username: "
    read username
    
    passwd -u "$username" 2>/dev/null
    jq '(.[] | select(.username == "'$username'")).locked = false' "$USER_DB" > /tmp/db.tmp && mv /tmp/db.tmp "$USER_DB"
    
    echo -e "${GREEN}[✓] Account $username unlocked${NC}"
}

# ==================== 6. AUTO-BAN SYSTEM ====================

auto_ban_system() {
    echo ""
    echo -e "${CYAN}[6] AUTO-BAN SYSTEM${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
    
    echo "1. Check Active Connections"
    echo "2. List Banned IPs"
    echo "3. Auto-ban Violators"
    echo "4. Manual Ban IP"
    echo "5. Unban IP"
    echo -n "Choice [1-5]: "
    read choice
    
    case $choice in
        1)
            echo ""
            echo -e "${YELLOW}Active SSH Connections:${NC}"
            netstat -tn | grep ':22' | grep 'ESTABLISHED' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn
            ;;
        2)
            echo ""
            echo -e "${YELLOW}Banned IPs:${NC}"
            jq -r '.[]' "$BAN_LIST" 2>/dev/null | nl
            ;;
        3)
            echo ""
            echo -e "${YELLOW}Auto-banning violators...${NC}"
            
            # Check semua user
            jq -r '.[] | select(.limit_ip > 0) | "\(.username)|\(.limit_ip)"' "$USER_DB" | while IFS='|' read -r user limit; do
                # Hitung connections per IP untuk user ini
                netstat -tn | grep ':22' | grep 'ESTABLISHED' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | while read count ip; do
                    if [ "$count" -gt "$limit" ]; then
                        echo "Banning $ip (user: $user, connections: $count, limit: $limit)"
                        iptables -A INPUT -s "$ip" -j DROP
                        # Add to ban list
                        jq --arg ip "$ip" '. += [$ip]' "$BAN_LIST" > /tmp/ban.tmp && mv /tmp/ban.tmp "$BAN_LIST"
                        # Lock user jika lebih dari 2x violation
                        jq '(.[] | select(.username == "'$user'")).locked = true' "$USER_DB" > /tmp/db.tmp && mv /tmp/db.tmp "$USER_DB"
                    fi
                done
            done
            
            echo -e "${GREEN}[✓] Auto-ban completed${NC}"
            ;;
        4)
            echo -n "IP to ban: "
            read ip
            iptables -A INPUT -s "$ip" -j DROP
            jq --arg ip "$ip" '. += [$ip]' "$BAN_LIST" > /tmp/ban.tmp && mv /tmp/ban.tmp "$BAN_LIST"
            echo -e "${GREEN}[✓] IP $ip banned${NC}"
            ;;
        5)
            echo -n "IP to unban: "
            read ip
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            jq 'del(.[] | select(. == "'$ip'"))' "$BAN_LIST" > /tmp/ban.tmp && mv /tmp/ban.tmp "$BAN_LIST"
            echo -e "${GREEN}[✓] IP $ip unbanned${NC}"
            ;;
    esac
}

# ==================== 7. MONITOR CONNECTIONS ====================

monitor_connections() {
    echo ""
    echo -e "${CYAN}[7] MONITOR CONNECTIONS${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    
    echo "1. Real-time Connections"
    echo "2. Bandwidth Usage"
    echo "3. UDP Custom Status"
    echo "4. Server Load"
    echo -n "Choice [1-4]: "
    read choice
    
    case $choice in
        1)
            echo ""
            echo -e "${YELLOW}Real-time SSH Connections:${NC}"
            watch -n 1 "netstat -tn | grep ':22' | grep 'ESTABLISHED' | awk '{print \$5}' | cut -d: -f1 | sort | uniq -c | sort -rn"
            ;;
        2)
            echo ""
            echo -e "${YELLOW}Bandwidth Usage:${NC}"
            ifconfig eth0 | grep -E "(RX|TX)" | grep bytes
            echo ""
            echo -e "${YELLOW}Top Connections:${NC}"
            ss -tun | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
            ;;
        3)
            echo ""
            echo -e "${YELLOW}UDP Custom Status:${NC}"
            if supervisorctl status udp-custom | grep -q "RUNNING"; then
                echo -e "${GREEN}[✓] UDP Custom: RUNNING${NC}"
            else
                echo -e "${RED}[✗] UDP Custom: STOPPED${NC}"
                echo -e "${YELLOW}Restarting...${NC}"
                supervisorctl restart udp-custom
            fi
            echo ""
            echo -e "${YELLOW}UDP Ports Listening:${NC}"
            ss -uln | grep -E "7300|7200|7100"
            ;;
        4)
            echo ""
            echo -e "${YELLOW}Server Load:${NC}"
            uptime
            echo ""
            echo -e "${YELLOW}Memory:${NC}"
            free -h
            echo ""
            echo -e "${YELLOW}Disk:${NC}"
            df -h /
            ;;
    esac
}

# ==================== 8. SPEED TEST ====================

speed_test() {
    echo ""
    echo -e "${CYAN}[8] SPEED TEST${NC}"
    echo -e "${CYAN}══════════════${NC}"
    
    echo -e "${YELLOW}Testing download speed...${NC}"
    
    if command -v speedtest-cli &> /dev/null; then
        speedtest-cli --simple
    else
        echo "Installing speedtest-cli..."
        apt install -y speedtest-cli
        speedtest-cli --simple
    fi
    
    echo ""
    echo -e "${YELLOW}Testing UDP speed...${NC}"
    echo "Use: iperf3 -c $DOMAIN -u -p 7300"
}

# ==================== 9. SERVER INFO ====================

server_info() {
    echo ""
    echo -e "${CYAN}[9] SERVER INFORMATION${NC}"
    echo -e "${CYAN}═══════════════════════${NC}"
    
    echo -e "${YELLOW}Basic Info:${NC}"
    echo -e "${WHITE}Hostname : $(hostname)"
    echo "IP Public: $(curl -s ifconfig.me)"
    echo "Domain   : $DOMAIN"
    echo "Ports    : $PORTS"
    echo "Timezone : $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo "Uptime   : $(uptime -p)"
    echo ""
    
    echo -e "${YELLOW}Services Status:${NC}"
    services=("ssh" "supervisor" "udp-custom" "fail2ban")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo -e "${GREEN}[✓] $svc: RUNNING${NC}"
        else
            echo -e "${RED}[✗] $svc: STOPPED${NC}"
        fi
    done
    echo ""
    
    echo -e "${YELLOW}Active Ports:${NC}"
    echo "SSH: 22"
    echo "UDP Custom: 7300"
    echo "All Ports: 1-65535 OPEN"
    echo ""
    echo -e "${YELLOW}How to Use:${NC}"
    echo "Command: menu-udp"
    echo "Config Format: $DOMAIN:$PORTS@username:password"
}

# ==================== MAIN MENU ====================

main_menu() {
    while true; do
        show_banner
        
        echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
        echo -e "${PURPLE}                    MAIN MENU - menu-udp                  ${NC}"
        echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}[1]  CREATE SSH UDP ACCOUNT                              ${NC}"
        echo -e "${CYAN}[2]  DELETE ACCOUNT                                      ${NC}"
        echo -e "${CYAN}[3]  LIST ALL ACCOUNTS                                   ${NC}"
        echo -e "${CYAN}[4]  LOCK ACCOUNT                                        ${NC}"
        echo -e "${CYAN}[5]  UNLOCK ACCOUNT                                      ${NC}"
        echo -e "${CYAN}[6]  AUTO-BAN SYSTEM                                     ${NC}"
        echo -e "${CYAN}[7]  MONITOR CONNECTIONS                                 ${NC}"
        echo -e "${CYAN}[8]  SPEED TEST                                          ${NC}"
        echo -e "${CYAN}[9]  SERVER INFO                                         ${NC}"
        echo -e "${CYAN}[10] RESTART SERVICES                                    ${NC}"
        echo -e "${RED}[0]  EXIT                                                ${NC}"
        echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
        echo -n "Select [0-10]: "
        read choice
        
        case $choice in
            1) create_account ;;
            2) delete_account ;;
            3) list_accounts ;;
            4) lock_account ;;
            5) unlock_account ;;
            6) auto_ban_system ;;
            7) monitor_connections ;;
            8) speed_test ;;
            9) server_info ;;
            10)
                systemctl restart supervisor ssh udp-watchdog
                echo -e "${GREEN}[✓] All services restarted${NC}"
                ;;
            0)
                echo ""
                echo -e "${GREEN}[*] Thank you for using SSH UDP Manager${NC}"
                echo -e "${YELLOW}[*] Type 'menu-udp' to open again${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid choice${NC}"
                sleep 1
                ;;
        esac
        
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Start
main_menu
EOF
    
    chmod +x /usr/local/bin/menu-udp
    
    # Buat alias juga
    ln -sf /usr/local/bin/menu-udp /usr/local/bin/udp-menu
    
    echo -e "${GREEN}[✓] menu-udp created${NC}"
}

# ==================== MAIN INSTALLATION ====================

main() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║      SSH UDP CUSTOM AUTO INSTALLER               ║"
    echo "║         Menu Command: menu-udp                   ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}[*] Starting installation...${NC}"
    echo ""
    
    install_deps
    open_all_ports
    install_udp_custom
    setup_auto_reconnect
    create_menu_udp
    
    # Setup fail2ban untuk auto-ban
    apt install -y fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           INSTALLATION COMPLETE!                 ║"
    echo "║         SSH UDP MANAGER READY                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            SSH UDP CUSTOM MANAGER                       ${NC}"
    echo -e "${WHITE}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[*] HOW TO USE:${NC}"
    echo -e "${GREEN}  Type: menu-udp${NC}"
    echo ""
    echo -e "${YELLOW}[*] FEATURES:${NC}"
    echo "  ✓ Create Account (Format: $DOMAIN:$PORTS@user:pass)"
    echo "  ✓ Delete Account"
    echo "  ✓ List All Accounts"
    echo "  ✓ Lock/Unlock Account"
    echo "  ✓ Auto-ban System"
    echo "  ✓ Monitor Connections"
    echo "  ✓ Speed Test"
    echo "  ✓ All Ports 1-65535 OPEN"
    echo "  ✓ Auto-Reconnect (NO DELAY)"
    echo ""
    echo -e "${YELLOW}[*] CONFIG FORMAT:${NC}"
    echo -e "${WHITE}  $DOMAIN:$PORTS@username:password${NC}"
    echo ""
    echo -e "${CYAN}Server IP: $(curl -s ifconfig.me)${NC}"
    echo -e "${CYAN}Domain: $DOMAIN${NC}"
    echo -e "${CYAN}Ports: $PORTS${NC}"
    echo ""
    echo -e "${RED}[!] Change default passwords!${NC}"
    echo -e "${YELLOW}[*] Run: menu-udp${NC}"
}

# Run
main