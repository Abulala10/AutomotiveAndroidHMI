#!/bin/bash
# setup-vcan.sh
# Usage:
#   ./setup-vcan.sh --up <vcan_name>        -> bring VCAN up
#   ./setup-vcan.sh --down <vcan_name>      -> bring VCAN down
#   ./setup-vcan.sh --name <vcan_name>      -> create VCAN if missing, or describe if exists
#   ./setup-vcan.sh --delete <vcan_name>    -> delete VCAN if exists
#   ./setup-vcan.sh --show                   -> list all VCANs
#   ./setup-vcan.sh                            -> do nothing to VCAN states

# Default VCAN interface for --name
DEFAULT_VCAN="vcan_default"

# Variables
ACTION=""
VCAN_IF=""
NAME_IF=""
DELETE_IF=""

# Function to show VCAN interfaces
show_vcans() {
    echo "Existing VCAN interfaces:"
    ip link show | grep -E 'vcan[0-9]+'
    exit 0
}

# Parse arguments
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
        --delete)
            DELETE_IF="$2"
            if [[ -z "$DELETE_IF" ]]; then
                echo "Error: Provide VCAN name after --delete"
                exit 1
            fi
            shift 2
            ;;
        --show)
            show_vcans
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--up|--down|--delete <vcan_name>] [--name <vcan_name>] | --show"
            exit 1
            ;;
    esac
done

# Load vcan module if not loaded
if ! lsmod | grep -q vcan; then
    echo "Loading vcan module..."
    sudo modprobe vcan
fi

# Handle --delete independently
if [[ -n "$DELETE_IF" ]]; then
    if ip link show "$DELETE_IF" &> /dev/null; then
        echo "Deleting VCAN $DELETE_IF..."
        sudo ip link delete "$DELETE_IF" type vcan
    else
        echo "VCAN $DELETE_IF does not exist."
    fi
fi

# Handle --name independently
if [[ -n "$NAME_IF" ]]; then
    if ! ip link show "$NAME_IF" &> /dev/null; then
        echo "Creating VCAN $NAME_IF..."
        sudo ip link add dev "$NAME_IF" type vcan
        echo "VCAN $NAME_IF created."
    else
        echo "VCAN $NAME_IF already exists. Describing it:"
        ip -details link show "$NAME_IF"
    fi
fi

# Perform --up or --down if specified
if [[ -n "$ACTION" ]]; then
    echo "Setting $VCAN_IF $ACTION..."
    if [[ "$ACTION" == "up" ]] && ! ip link show "$VCAN_IF" &> /dev/null; then
        echo "Creating VCAN $VCAN_IF..."
        sudo ip link add dev "$VCAN_IF" type vcan
    fi
    sudo ip link set "$VCAN_IF" "$ACTION"
    echo "Current state of $VCAN_IF:"
    ip link show "$VCAN_IF"
fi

# If no action and no --name/--delete, do nothing to VCAN states
if [[ -z "$ACTION" && -z "$NAME_IF" && -z "$DELETE_IF" ]]; then
    echo "No action provided. All VCANs remain as they are."
fi
