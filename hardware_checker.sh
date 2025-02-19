#!/bin/bash

# Ultimate Linux Hardware Compatibility Checker - Interactive Version
# Author: ayumu
# Version: 2.0.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="hardware_check.log"

# Check for required commands
check_dependencies() {
    REQUIRED_CMDS=("lspci" "lsusb" "hwinfo" "dmidecode" "lsblk")
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}⚠️  $cmd not found. Installing...${NC}"
            sudo pacman -S --noconfirm $cmd || sudo apt install -y $cmd || sudo dnf install -y $cmd
        fi
    done
}

# Display Main Menu
main_menu() {
    OPTION=$(whiptail --title "Linux Hardware Checker" --menu "Choose an option:" 20 60 6 \
        "1" "Scan CPU, GPU, RAM, Storage" \
        "2" "Scan Network & USB Devices" \
        "3" "Check for Missing Drivers" \
        "4" "Export Report" \
        "5" "Exit" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) scan_core_hardware ;;
        2) scan_network_usb ;;
        3) check_drivers ;;
        4) export_report ;;
        5) exit ;;
    esac
}

# Scan CPU, GPU, RAM, and Storage
scan_core_hardware() {
    OUTPUT="🖥️ CPU Info:\n$(lscpu | grep -E 'Model name|Architecture|CPU MHz')\n\n"
    OUTPUT+="🎮 GPU Info:\n$(lspci | grep -E 'VGA|3D|Display')\n\n"
    OUTPUT+="🧠 RAM Details:\n$(sudo dmidecode -t memory | grep -E 'Size|Speed|Type')\n\n"
    OUTPUT+="💾 Storage Devices:\n$(lsblk -d -o NAME,MODEL,SIZE,ROTA)\n\n"

    echo -e "$OUTPUT" >> $LOG_FILE
    whiptail --title "Core Hardware Info" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Scan Network & USB Devices
scan_network_usb() {
    OUTPUT="🌐 Network Interfaces:\n$(lspci | grep -i 'network')\n\n"
    OUTPUT+="🔌 USB Devices:\n$(lsusb)\n\n"

    echo -e "$OUTPUT" >> $LOG_FILE
    whiptail --title "Network & USB Devices" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Check for Missing Drivers
check_drivers() {
    OUTPUT="🔍 Checking for missing drivers...\n"

    # Check for NVIDIA
    if lspci | grep -E 'VGA|3D|Display' | grep -qi 'NVIDIA'; then
        if ! lsmod | grep -qi 'nvidia'; then
            OUTPUT+="⚠️  NVIDIA GPU detected but drivers are missing.\n"
            OUTPUT+="🔧 Suggested Fix: sudo pacman -S nvidia OR sudo apt install nvidia-driver\n"
        fi
    fi

    # Check for AMD
    if lspci | grep -E 'VGA|3D|Display' | grep -qi 'AMD'; then
        if ! lsmod | grep -qi 'amdgpu'; then
            OUTPUT+="⚠️  AMD GPU detected but drivers are missing.\n"
            OUTPUT+="🔧 Suggested Fix: sudo pacman -S xf86-video-amdgpu OR sudo apt install firmware-amd-graphics\n"
        fi
    fi

    echo -e "$OUTPUT" >> $LOG_FILE
    whiptail --title "Driver Check" --msgbox "$OUTPUT" 20 80
    main_menu
}

# Export Report
export_report() {
    whiptail --title "Export Report" --msgbox "Report saved to $LOG_FILE" 10 50
    main_menu
}

# Start
check_dependencies
main_menu
