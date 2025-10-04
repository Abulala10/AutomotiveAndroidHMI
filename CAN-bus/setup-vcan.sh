#!/bin/bash
# setup-vcan.sh
# Usage:
#   ./setup-vcan.sh --up <vcan_name>      -> bring VCAN up
#   ./setup-vcan.sh --down <vcan_name>    -> bring VCAN down
#   ./setup-vcan.sh --name <vcan_name>    -> create VCAN if missing
#   ./setup-vcan.sh --show                 -> list VCANs
#   ./setup-vcan.sh                        -> bring all VCANs down (default)

# Default VCAN interface for --name
DEFAULT_VCAN="vcan_default"

# Variables
ACTION=""
VCAN_IF=""
NAME_IF="$DEFAULT_VCAN"

# Function to show VCAN interfaces
show_vcans() {
    echo "Existing VCAN interfaces:"
    ip link show | grep -E 'vcan[0-9]+'
    exit 0
}

# Parse arguments using while + case
while [[ $# -gt 0 ]]; do
    case "$1" in
        --up)
            ACTION="up"
            VCAN_IF="$2"
            if [[ -z "$VCAN_IF" ]]; then
                echo "Error: Provide VCAN name after --up"
                exit 1
            fi
            shift 2
            ;;
        --down)
            ACTION="down"
            VCAN_IF="$2"
            if [[ -z "$VCAN_IF" ]]; then
                echo "Error: Provide VCAN name after --down"
                exit 1
            fi
            shift 2
            ;;
        --name)
            NAME_IF="$2"
            if [[ -z "$NAME_IF" ]]; then
                echo "Error: Provide VCAN name after --name"
                exit 1
            fi
            shift 2
            ;;
        --show)
            show_vcans
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--up|--down <vcan_name>] [--name <vcan_name>] | --show"
            exit 1
            ;;
    esac
done

# Load vcan module if not loaded
if ! lsmod | grep -q vcan; then
    echo "Loading vcan module..."
    sudo modprobe vcan
fi

# Create VCAN from --name if it doesn't exist
if ! ip link show "$NAME_IF" &> /dev/null; then
    echo "Creating VCAN $NAME_IF from --name..."
    sudo ip link add dev "$NAME_IF" type vcan
fi

# Perform --up or --down action if specified
if [[ -n "$ACTION" ]]; then
    echo "Setting $VCAN_IF $ACTION..."
    # Create interface if it doesn’t exist (optional safety)
    if [[ "$ACTION" == "up" ]] && ! ip link show "$VCAN_IF" &> /dev/null; then
        echo "Creating VCAN $VCAN_IF..."
        sudo ip link add dev "$VCAN_IF" type vcan
    fi
    sudo ip link set "$VCAN_IF" "$ACTION"
    echo "Current state of $VCAN_IF:"
    ip link show "$VCAN_IF"
else
    # No --up or --down provided → bring all VCANs down
    echo "No action provided. Bringing all VCANs down..."
    VCANS=$(ip link show | grep -E 'vcan[0-9]+' | awk -F: '{print $2}' | tr -d ' ')
    for v in $VCANS; do
        echo "Bringing $v down..."
        sudo ip link set "$v" down
    done
    echo "All VCANs are now down."
fi
