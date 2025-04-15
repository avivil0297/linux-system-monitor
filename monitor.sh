#!/bin/bash
#
# System Monitor Script (Universal Version)
# ---------------------
# Displays detailed information about the local Linux system
# Works both on Ubuntu and WSL environments
#
# Usage: ./monitor.sh [options]
#
# Options:
#   -h, --help      Display this help message
#   -c, --config    Use custom configuration file
#   -o, --output    Save output to file
#   -m, --minimal   Show only essential information
#   -n, --no-sudo   Run without attempting to use sudo
#

# Default settings
OUTPUT_FILE=""
CONFIG_FILE="$HOME/.config/sysmonitor/config"
MINIMAL_MODE=false
NO_SUDO=false
VERSION="1.2.0"

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help           Display this help message"
    echo "  -c, --config FILE    Use custom configuration file"
    echo "  -o, --output FILE    Save output to file"
    echo "  -m, --minimal        Show only essential information"
    echo "  -n, --no-sudo        Run without attempting to use sudo"
    echo "  -v, --version        Show version information"
    echo
}

# Function to show version
show_version() {
    echo "Linux System Monitor v$VERSION"
    echo "Universal version for both Ubuntu and WSL"
    echo "Visit: https://github.com/avivil0297/linux-system-monitor"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display a spinner during long operations
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to check sudo permissions with timeout
check_sudo() {
    echo -e "${YELLOW}Checking for sudo privileges...${NC}"
    
    # If script is already running as root/sudo, no need to check
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${GREEN}Script already running with sudo privileges.${NC}"
        SUDO_AVAILABLE=true
        return
    fi
    
    # Try once with -n to see if we have passwordless sudo
    if sudo -n true 2>/dev/null; then
        SUDO_AVAILABLE=true
        # Keep sudo alive
        (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null) &
        SUDO_PID=$!
        return
    fi
    
    # Otherwise, clearly inform user they'll need to enter sudo password
    echo -e "${YELLOW}Some commands require sudo privileges.${NC}"
    echo -e "${YELLOW}Please run this script with sudo to get full information:${NC}"
    echo -e "${GREEN}sudo $0 ${*}${NC}"
    SUDO_AVAILABLE=false
}

# Main header
print_header() {
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo
}

# Section header
print_section() {
    echo -e "${BLUE}----- $1 -----${NC}"
}

# Function to print information in a uniform format
print_info() {
    printf "${YELLOW}%-35s${NC} : %s\n" "$1" "$2"
}

# Function to check if running in WSL
check_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        echo -e "${YELLOW}Detected WSL environment - some hardware information may be limited${NC}"
    else
        IS_WSL=false
    fi
}

# Function to get disk information
get_disk_info() {
    # Additional disk information (called after the header is already printed)
    if command_exists lsblk; then
        print_info "Mounted partitions" "$(lsblk -f | grep -v loop | wc -l)"
    fi
    
    if $SUDO_AVAILABLE && command_exists smartctl; then
        # Get the main disk device (handle WSL differently)
        if $IS_WSL; then
            MAIN_DISK=$(mount | grep ' on / ' | cut -d' ' -f1 | cut -d'/' -f3)
        else
            MAIN_DISK=$(lsblk -d -o NAME,SIZE | sort -k 2 -hr | head -n 1 | awk '{print $1}')
        fi
        
        if [[ -n "$MAIN_DISK" ]]; then
            DISK_PATH="/dev/$MAIN_DISK"
            print_info "Main disk" "$MAIN_DISK ($(lsblk -d -o NAME,SIZE | grep $MAIN_DISK | awk '{print $2}' 2>/dev/null || echo "Unknown size"))"
            
            # Only try smartctl if not in WSL
            if ! $IS_WSL; then
                DISK_HEALTH=$(sudo smartctl -H $DISK_PATH 2>/dev/null | grep overall-health | cut -d: -f2 | xargs)
                if [[ -n "$DISK_HEALTH" ]]; then
                    print_info "Disk health" "$DISK_HEALTH"
                else
                    print_info "Disk health" "Cannot determine (try installing smartmontools)"
                fi
                
                DISK_SERIAL=$(sudo smartctl -a $DISK_PATH 2>/dev/null | grep "Serial Number" | cut -d: -f2 | xargs)
                if [[ -n "$DISK_SERIAL" ]]; then
                    print_info "Disk serial" "$DISK_SERIAL"
                fi
                
                POWER_HOURS=$(sudo smartctl -a $DISK_PATH 2>/dev/null | grep "Power_On_Hours" | tr -s ' ' | cut -d' ' -f10)
                if [[ -n "$POWER_HOURS" ]]; then
                    print_info "Power-on hours" "$POWER_HOURS"
                fi
            else
                print_info "Disk health" "Not available in WSL"
            fi
        fi
    else
        if ! command_exists smartctl; then
            print_info "Disk health" "Requires smartmontools package"
        else
            print_info "Disk health" "Requires sudo access"
        fi
    fi

    # Try to get I/O scheduler - but skip in WSL
    if ! $IS_WSL && command_exists lsblk; then
        FIRST_DISK=$(lsblk -d | awk 'NR==2 {print $1}')
        if [[ -n "$FIRST_DISK" ]]; then
            print_info "I/O scheduler" "$(cat /sys/block/$FIRST_DISK/queue/scheduler 2>/dev/null | tr -d '[]' || echo "Unknown")"
        fi
    fi
}

# Function to get temperature information
get_temperature_info() {
    if $IS_WSL; then
        # WSL doesn't have direct access to hardware sensors
        return
    elif command_exists sensors; then
        print_section "System Temperature"
        echo
        sensors | grep -E "Core|Package" | sed 's/^[ \t]*//'
        echo
    fi
}

# Function to get top processes information
get_top_processes() {
    print_section "Top processes"
    echo
    ps auxk-%cpu | head -6 | awk '{printf "%-20s %-15s %-10s %-10s\n", $11, $1, $3"% CPU", $4"% MEM"}'
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -m|--minimal)
            MINIMAL_MODE=true
            shift
            ;;
        -n|--no-sudo)
            NO_SUDO=true
            shift
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Load configuration if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Loaded configuration from $CONFIG_FILE"
fi

# Set up output redirection if needed
if [[ -n "$OUTPUT_FILE" ]]; then
    exec > >(tee -a "$OUTPUT_FILE") 2>&1
    echo "Saving output to $OUTPUT_FILE"
fi

# Main function
main() {
    # Display script banner
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║             LINUX SYSTEM MONITOR              ║"
    echo "║             Version: $VERSION                    ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check if running in WSL
    IS_WSL=false
    check_wsl
    
    # Check permissions for commands requiring sudo
    SUDO_AVAILABLE=false
    if [ "$NO_SUDO" = true ]; then
        echo -e "${YELLOW}Running in no-sudo mode. Some information will be limited.${NC}"
    else
        check_sudo
    fi

    # Basic system information
    print_header "BASIC SYSTEM INFORMATION"

    print_info "Hostname" "$(hostname)"
    print_info "Username" "$(whoami)"
    print_info "Kernel version" "$(uname -r)"
    print_info "Kernel release date" "$(stat -c %y /boot/vmlinuz-$(uname -r) 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
    
    if [[ -f /etc/os-release ]]; then
        print_info "OS version" "$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
        print_info "OS version codename" "$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 || echo "Unknown")"
    fi
    
    print_info "System uptime" "$(uptime -p)"
    print_info "Last boot" "$(who -b | awk '{print $3, $4}' 2>/dev/null || echo "Unknown")"
    
    # Show system model only if sudo available and not in WSL
    if $SUDO_AVAILABLE && ! $IS_WSL && command_exists dmidecode; then
        print_info "System model" "$(sudo dmidecode -s system-product-name 2>/dev/null || echo "N/A")"
        print_info "Manufacturer" "$(sudo dmidecode -s system-manufacturer 2>/dev/null || echo "N/A")"
    fi
    
    echo

    # Hardware information
    print_header "HARDWARE INFORMATION"

    print_info "CPU model" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    print_info "CPU cores" "$(grep -c processor /proc/cpuinfo) ($(grep -c 'physical id' /proc/cpuinfo | sort -u | wc -l || echo "?") physical, $(grep -c 'core id' /proc/cpuinfo | sort -u | wc -l || echo "?") cores per CPU)"
    
    # CPU frequency with fallback
    if command_exists lscpu; then
        CPU_FREQ=$(lscpu | grep 'CPU MHz' | cut -d: -f2 | xargs)
        if [[ -n "$CPU_FREQ" ]]; then
            print_info "CPU frequency" "$CPU_FREQ MHz"
        else
            print_info "CPU frequency" "$(grep 'cpu MHz' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs || echo "Unknown") MHz"
        fi
    else
        print_info "CPU frequency" "$(grep 'cpu MHz' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs || echo "Unknown") MHz"
    fi
    
    print_info "RAM size" "$(free -h | grep Mem | awk '{print $2}')"
    
    # Memory range if available
    if [ -f /proc/iomem ]; then
        MEMORY_RANGE=$(grep "System RAM" /proc/iomem | head -1 | cut -d ':' -f1 || echo "Unknown")
        if [ -n "$MEMORY_RANGE" ]; then
            print_info "Memory range" "$MEMORY_RANGE"
        fi
    fi
    
    # RAM usage calculation with fix for awk error
    RAM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
    RAM_USED=$(free -m | grep Mem | awk '{print $3}')
    if [[ -n "$RAM_TOTAL" && -n "$RAM_USED" && "$RAM_TOTAL" -gt 0 ]]; then
        RAM_PERCENT=$(( (RAM_USED * 100) / RAM_TOTAL ))
        print_info "RAM used" "$RAM_USED MB ($RAM_PERCENT%)"
    else
        print_info "RAM used" "$(free -h | grep Mem | awk '{print $3}')"
    fi
    
    # Get GPU information if available
    if ! $IS_WSL && command_exists nvidia-smi; then
        print_info "GPU" "$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Unknown")"
    elif command_exists lspci; then
        print_info "GPU" "$(lspci | grep -i vga | cut -d: -f3 | xargs 2>/dev/null || echo "Unknown")"
    fi
    
    # PCI devices
    if command_exists lspci; then
        print_info "Connected PCI devices" "$(lspci | wc -l)"
    fi
    
    # USB devices with fallback
    if command_exists lsusb; then
        print_info "Connected USB devices" "$(lsusb | wc -l)"
    else
        print_info "Connected USB devices" "Command lsusb not found (install usbutils package)"
    fi
    
    # Show temperature if available
    get_temperature_info
    
    echo

    # Network information
    print_header "NETWORK INFORMATION"

    # Get main interface with fallback
    MAIN_INTERFACE=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -1)
    if [[ -n "$MAIN_INTERFACE" ]]; then
        print_info "Main interface" "$MAIN_INTERFACE"
        print_info "IP address" "$(ip -o -4 addr show dev $MAIN_INTERFACE 2>/dev/null | awk '{print $4}' | cut -d/ -f1)"
        print_info "MAC address" "$(ip link show $MAIN_INTERFACE 2>/dev/null | grep -o 'link/ether [^ ]*' | cut -d' ' -f2)"
    else
        print_info "IP address" "$(hostname -I 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
    fi
    
    print_info "Gateway" "$(ip route | grep default | cut -d' ' -f3 2>/dev/null || echo "Unknown")"
    print_info "DNS servers" "$(grep nameserver /etc/resolv.conf 2>/dev/null | cut -d' ' -f2 | paste -sd ',' - || echo "Unknown")"
    
    # Only try to get public IP if curl exists
    if command_exists curl; then
        PUBLIC_IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s api.ipify.org 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
        if [[ -n "$PUBLIC_IP" && ${#PUBLIC_IP} -lt 40 ]]; then
            print_info "Public IP" "$PUBLIC_IP"
        else
            print_info "Public IP" "Not available (could not retrieve IP)"
        fi
    else
        # Try wget if curl doesn't exist
        if command_exists wget; then
            PUBLIC_IP=$(wget -qO- ipinfo.io/ip 2>/dev/null || wget -qO- api.ipify.org 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null)
            if [[ -n "$PUBLIC_IP" && ${#PUBLIC_IP} -lt 40 ]]; then
                print_info "Public IP" "$PUBLIC_IP"
            else
                print_info "Public IP" "Not available (could not retrieve IP)"
            fi
        else
            print_info "Public IP" "Not available (install curl or wget)"
        fi
    fi
    
    if $SUDO_AVAILABLE; then
        if command_exists ss; then
            print_info "Open ports (TCP)" "$(sudo ss -tlnp 2>/dev/null | grep LISTEN | wc -l)"
        elif command_exists netstat; then
            print_info "Open ports (TCP)" "$(sudo netstat -tlnp 2>/dev/null | grep LISTEN | wc -l)"
        fi
    fi
    
    # Network stats
    if [[ -n "$MAIN_INTERFACE" ]]; then
        RX_BYTES=$(cat /sys/class/net/$MAIN_INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
        TX_BYTES=$(cat /sys/class/net/$MAIN_INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
        
        # Only use bc if it exists
        if command_exists bc; then
            RX_MB=$(echo "scale=2; $RX_BYTES/1024/1024" | bc)
            TX_MB=$(echo "scale=2; $TX_BYTES/1024/1024" | bc)
        else
            RX_MB=$(( $RX_BYTES / 1024 / 1024 ))
            TX_MB=$(( $TX_BYTES / 1024 / 1024 ))
        fi
        
        print_info "Data received" "$RX_MB MB"
        print_info "Data sent" "$TX_MB MB"
    fi
    
    echo

    # Disk information
    print_header "DISK INFORMATION"
    
    print_info "Disk usage" "$(df -h / | awk 'NR==2 {print $5 " used, " $4 " free"}')"
    
    # Get additional disk information
    get_disk_info
    
    echo

    # Software and system information
    print_header "SOFTWARE AND SYSTEM INFORMATION"

    if command_exists dpkg; then
        print_info "Package manager" "dpkg ($(dpkg -l | grep ^ii | wc -l) packages installed)"
    elif command_exists rpm; then
        print_info "Package manager" "rpm ($(rpm -qa | wc -l) packages installed)"
    elif command_exists pacman; then
        print_info "Package manager" "pacman ($(pacman -Q | wc -l) packages installed)"
    fi
    
    print_info "Kernel modules" "$(lsmod | wc -l)"
    print_info "Total processes" "$(ps aux | wc -l)"
    print_info "Active processes" "$(ps --no-headers -A | wc -l)"
    print_info "User processes" "$(ps -U $(whoami) | wc -l)"
    print_info "Connected users" "$(who | wc -l)"
    print_info "System load avg" "$(uptime | grep -ohe 'load average[s:][: ].*' | cut -d: -f2 | xargs)"
    
    # Top processes
    get_top_processes
    
    echo

    echo -e "${GREEN}Script execution completed successfully!${NC}"
    
    # Kill sudo keepalive if it was started
    if [[ -n "$SUDO_PID" ]]; then
        kill -9 $SUDO_PID 2>/dev/null
    fi
}

# Run the main function
main
