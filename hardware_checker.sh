#!/bin/bash

# InfoNix - Ultimate Linux Hardware Compatibility Checker
# Version: 2.0.0
# Author: ayumu
# Description: Professional-grade hardware scanner with enhanced UI, driver detection, temperature monitoring, and export options.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="infonix_report.log"
EXPORT_DIR="infonix_exports"

# Required Commands
REQUIRED_CMDS=("lspci" "lsusb" "hwinfo" "dmidecode" "lsblk" "sensors" "nvme" "dialog")

# Function to check and install missing commands
check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}⚠️  $cmd not found. Installing...${NC}"
            sudo pacman -S --noconfirm $cmd || sudo apt install -y $cmd || sudo dnf install -y $cmd
        else
            echo -e "${GREEN}✅ $cmd is installed.${NC}"
        fi
    done
}

# Display Main Menu
main_menu() {
    OPTION=$(dialog --clear --title "InfoNix - Ultimate Hardware Checker" \
        --menu "Choose an option:" 20 60 8 \
        "1" "Core Hardware Scan" \
        "2" "Network & USB Devices" \
        "3" "Driver Check" \
        "4" "Temperature Monitoring" \
        "5" "Battery Status" \
        "6" "Export Report" \
        "7" "Exit" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) scan_core_hardware ;;
        2) scan_network_usb ;;
        3) check_drivers ;;
        4) monitor_temperature ;;
        5) battery_status ;;
        6) export_report ;;
        7) exit ;;
    esac
}

# Core Hardware Scan
scan_core_hardware() {
    OUTPUT="🖥️ CPU Info:\n$(lscpu | grep -E 'Model name|Architecture|CPU MHz')\n\n"
    OUTPUT+="🎮 GPU Info:\n$(lspci | grep -E 'VGA|3D|Display')\n\n"
    OUTPUT+="🧠 RAM Details:\n$(sudo dmidecode -t memory | grep -E 'Size|Speed|Type')\n\n"
    OUTPUT+="💾 Storage Devices:\n$(lsblk -d -o NAME,MODEL,SIZE,ROTA)\n\n"

    echo -e "$OUTPUT" >> $LOG_FILE
    dialog --title "Core Hardware Info" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Network & USB Devices
scan_network_usb() {
    OUTPUT="🌐 Network Interfaces:\n$(lspci | grep -i 'network')\n\n"
    OUTPUT+="🔌 USB Devices:\n$(lsusb)\n\n"

    echo -e "$OUTPUT" >> $LOG_FILE
    dialog --title "Network & USB Devices" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Driver Check
check_drivers() {
    OUTPUT="🔍 Checking for missing drivers...\n"

    if lspci | grep -E 'VGA|3D|Display' | grep -qi 'NVIDIA'; then
        if ! lsmod | grep -qi 'nvidia'; then
            OUTPUT+="⚠️  NVIDIA GPU detected but drivers are missing.\n"
            OUTPUT+="🔧 Suggested Fix: sudo pacman -S nvidia OR sudo apt install nvidia-driver\n"
        fi
    fi

    if lspci | grep -E 'VGA|3D|Display' | grep -qi 'AMD'; then
        if ! lsmod | grep -qi 'amdgpu'; then
            OUTPUT+="⚠️  AMD GPU detected but drivers are missing.\n"
            OUTPUT+="🔧 Suggested Fix: sudo pacman -S xf86-video-amdgpu OR sudo apt install firmware-amd-graphics\n"
        fi
    fi

    echo -e "$OUTPUT" >> $LOG_FILE
    dialog --title "Driver Check" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Temperature Monitoring
monitor_temperature() {
    OUTPUT="🌡️ Temperature Monitoring:\n\n"
    OUTPUT+="$(sensors)\n"
    echo -e "$OUTPUT" >> $LOG_FILE
    dialog --title "Temperature Monitoring" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Battery Status
battery_status() {
    OUTPUT="🔋 Battery Status:\n\n"
    OUTPUT+="$(upower -i $(upower -e | grep BAT) | grep -E 'state|to\ full|percentage|time')\n"
    echo -e "$OUTPUT" >> $LOG_FILE
    dialog --title "Battery Status" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Export Report
export_report() {
    mkdir -p $EXPORT_DIR
    cp $LOG_FILE $EXPORT_DIR/infonix_report.txt
    dialog --title "Export Report" --msgbox "Report saved to $EXPORT_DIR" 10 50
    main_menu
}

# Start the Script
check_dependencies
main_menu
