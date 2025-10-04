#!/bin/bash
# setup-vcan.sh
# Script to set up a Virtual CAN interface (VCAN)

INFO="[INFO] :"
# Default VCAN interface name
VCAN_IF="vcan0"

# Helper function
check_command()
{
    # &> /dev/null - Supress output. Returns 0 if command exists, 1 if not
    command -v "$1" &> /dev/null
}

# Function to show existing VCAN interfaces
show_vcans() {
    echo "$INFO Existing VCAN interfaces:"
    ip link show | grep -E 'vcan[0-9]+' # only displays vcan that have the pattern vcan0, vcan1, vcan2, ... vcann
    exit 0
}

# Handle command line argument
if [ "$1" == "--list-vcan" ]; then
    show_vcans
elif [ -n "$1" ]; then
    # If argument is not empty, treat it as VCAN name
    VCAN_IF="$1"
fi

echo "VCAN interface to setup: $VCAN_IF"

# Check for modprobe
if ! check_command modprobe; then
    echo "$INFO modprobe not found.\n$INFO is needed to load kernel modules like vcan.\n$INFO Installing required kernel utilities..."
    sudo apt update
    sudo apt install -y kmod
else
    echo "$INFO modprobe found ..."
fi

# ensures vcan is available for simulation, even on minimal Linux installs.
if ! lsmod | grep -q vcan; then
    echo "$INFO Loading vcan module..."
    sudo modeprobe vcaon &> /dev/null
else
    echo "$INFO vcan module already loaded."
fi

# Checks if the virtual that we are trying to create $VCAN_IF="vcan0" is already there or not.
if ip link show "$VCAN_IF" &> /dev/null; then
    echo "$INFO Interface $VCAN_IF already exists."
else
    echo "$INFO Creating virtual CAN interface $VCAN_IF..."
    sudo ip link add dev "$VCAN_IF" type vcan
fi

echo "$INFO Bringing $VCAN_IF up..."
sudo ip link set up "$VCAN_IF"

echo "$INFO VCAN interface setup complete. Current interfaces:"
ip link show | grep "$VCAN_IF"

echo "$INFO You can now test using: candump $VCAN_IF"



