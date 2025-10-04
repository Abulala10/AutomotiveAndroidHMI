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
IP_CMD=$(command -v ip)

# Variables
ACTION=""
VCAN_IF=""
NAME_IF=""
DELETE_IF=""

delete_all=false

# Function to show VCAN interfaces
show_vcans() {
    if $IP_CMD link show | grep -qE 'vcan[0-9]+'; then
        echo "Existing VCAN interfaces:"
        $IP_CMD link show | grep -E 'vcan[0-9]+'
        exit 0
    else
        echo "No existing interfaces ..."
        exit 0
    fi
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
            shift 1
            ;;
        --delete-all)
            delete_all=true
            shift 1
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--up|--down|--delete <vcan_name>] [--name <vcan_name>] | --show"
            exit 1
            ;;
    esac
done

# -----------------------------------------------------
# Delete all vcan interfaces if requested
# -----------------------------------------------------
if [ "$delete_all" = true ]; then
    echo "Deleting all vcan interfaces..."
    while read -r iface; do
        echo "   → Deleting $iface"
        sudo $IP_CMD link delete "$iface" type vcan 2>/dev/null
    done < <($IP_CMD -o link show | awk -F': ' '/vcan[0-9]+/ {print $2}')
    echo "All vcan interfaces deleted."
    exit 0
fi

# -----------------------------------------------------
# Load vcan module if not loaded
# -----------------------------------------------------
if ! lsmod | grep -q vcan; then
    echo "Loading vcan module..."
    sudo modprobe vcan
fi

# -----------------------------------------------------
# Handle --delete independently
# -----------------------------------------------------
if [[ -n "$DELETE_IF" ]]; then
    if $IP_CMD link show "$DELETE_IF" &> /dev/null; then
        echo "Deleting VCAN $DELETE_IF..."
        sudo $IP_CMD link delete "$DELETE_IF" type vcan
    else
        echo "VCAN $DELETE_IF does not exist."
    fi
fi

# -----------------------------------------------------
# Handle --name independently
# -----------------------------------------------------
if [[ -n "$NAME_IF" ]]; then
    if ! $IP_CMD link show "$NAME_IF" &> /dev/null; then
        echo "Creating VCAN $NAME_IF..."
        sudo $IP_CMD link add dev "$NAME_IF" type vcan
        echo "VCAN $NAME_IF created."
    else
        echo "VCAN $NAME_IF already exists. Describing it:"
        $IP_CMD -details link show "$NAME_IF"
    fi
fi

# -----------------------------------------------------
# Perform --up or --down if specified
# -----------------------------------------------------
if [[ -n "$ACTION" ]]; then
    echo "Setting $VCAN_IF $ACTION..."
    if [[ "$ACTION" == "up" ]] && ! $IP_CMD link show "$VCAN_IF" &> /dev/null; then
        echo "Creating VCAN $VCAN_IF..."
        sudo $IP_CMD link add dev "$VCAN_IF" type vcan
    fi
    sudo $IP_CMD link set "$VCAN_IF" "$ACTION"
    echo "Current state of $VCAN_IF:"
    $IP_CMD link show "$VCAN_IF"
fi

# -----------------------------------------------------
# If no action and no --name/--delete, do nothing to VCAN states
# -----------------------------------------------------
if [[ -z "$ACTION" && -z "$NAME_IF" && -z "$DELETE_IF" ]]; then
    echo "No action provided. All VCANs remain as they are."
fi
