#!/bin/bash
#
# System Monitor Script
# ---------------------
# Displays detailed information about the local Linux system
# Originally written for Ubuntu 24.04.2
#
# Usage: ./monitor.sh
#

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check sudo permissions
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo "Some commands require sudo privileges. Enter your password if prompted."
        sudo true
    fi
}

# Main header
print_header() {
    echo "====================================="
    echo "$1"
    echo "====================================="
    echo
}

# Section header
print_section() {
    echo "----- $1 -----"
}

# Function to print information in a uniform format
print_info() {
    printf "%-35s : %s\n" "$1" "$2"
}

# Check permissions for commands requiring sudo
check_sudo

# Basic system information
print_header "BASIC SYSTEM INFORMATION"

print_info "Hostname" "$(hostname)"
print_info "Hostname (uppercase)" "$(hostname | tr '[a-z]' '[A-Z]')"
print_info "Username" "$(whoami)"
print_info "Username (reversed)" "$(whoami | rev)"
print_info "Kernel version" "$(uname -r)"
print_info "Kernel details" "$(uname -a | cut -d"_" -f2 | cut -d " " -f2,3,4,5)"
print_info "OS version codename" "$(grep VERSION_CODENAME /etc/os-release | cut -d"=" -f2)"
print_info "System uptime" "$(uptime -p)"
print_info "Chassis type" "$(hostnamectl | grep Chassis | cut -d":" -f2 | sed 's/^ *//')"
print_info "Computer UUID" "$(sudo dmidecode | grep UUID | head -1 | cut -d" " -f2)"
echo

# Hardware information
print_header "HARDWARE INFORMATION"

print_info "CPU model" "$(lscpu | grep 'Model name' | sed 's/Model name: *//g')"
if command_exists lshw; then
    print_info "RAM size" "$(sudo lshw | grep GiB | cut -d":" -f2 | cut -d" " -f2 | head -n 1) GiB"
else
    print_info "RAM size" "$(free -m | grep Mem | tr -s " " | cut -d" " -f2) MB"
fi
print_info "Memory range" "$(lsmem | grep 0x | cut -d" " -f1)"

print_info "Connected PCI devices" "$(lspci | wc -l)"
print_info "Connected USB devices" "$(lsusb | wc -l)"

if command_exists smartctl; then
    print_info "Disk serial number" "$(sudo smartctl -a /dev/sda 2>/dev/null | grep Serial | tr -s " " | cut -d" " -f3)"
else
    print_info "Disk serial number" "Requires smartmontools package"
fi

print_info "CD-ROM size" "$(lsblk | grep sr0 | tr -s " " | cut -d" " -f4 2>/dev/null || echo "Not found")"
print_info "Network driver in use" "$(sudo dmesg | grep -i 'Network.*Driver' | cut -d":" -f2 | sed 's/^ *//' | head -1)"
print_info "VBox drivers loaded" "$(lsmod | grep vbox | wc -l)"
echo

# Network information
print_header "NETWORK INFORMATION"

print_info "IP address" "$(ip a | grep 'inet ' | grep -v '127.0.0.1' | head -1 | tr -s " " | cut -d" " -f3)"
print_info "DNS servers" "$(grep nameserver /etc/resolv.conf | cut -d" " -f2 | paste -sd ',')"
print_info "Open ports" "$(sudo ss -anlpt | grep LISTEN | head -5 | tr -s " " | cut -d" " -f4,5,6)"
echo

# Software and system information
print_header "SOFTWARE AND SYSTEM INFORMATION"

print_info "PATH environment variable" "$(echo $PATH)"
print_info "Installed packages" "$(dpkg -l | grep ^ii | wc -l)"
print_info "Packages starting with 'lib'" "$(dpkg -l | grep ^ii | grep lib | wc -l)"
print_info "Available commands" "$(compgen -c | wc -l)"
print_info "Whoami license" "$(whoami --version | grep License | cut -d":" -f1 | sed 's/^ *//')"
print_info "System users" "$(cat /etc/passwd | wc -l)"
print_info "Connected users" "$(who | wc -l)"
print_info "My group ID" "$(id | grep gid | cut -d"=" -f2 | cut -d"(" -f1)"
print_info "Active processes" "$(ps aux | wc -l)"
print_info "User processes" "$(ps aux | grep "^$(whoami) " | wc -l)"
echo

echo "Script execution completed successfully!"
