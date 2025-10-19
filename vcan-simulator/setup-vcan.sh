#!/bin/bash
# setup-vcan.sh
# Usage:
#   ./setup-vcan.sh --up <vcan_name>        -> bring VCAN up
#   ./setup-vcan.sh --down <vcan_name>      -> bring VCAN down
#   ./setup-vcan.sh --name <vcan_name>      -> create VCAN if missing, or describe if exists
#   ./setup-vcan.sh --delete <vcan_name>    -> delete VCAN if exists
#   ./setup-vcan.sh --show                   -> list all VCANs
#   ./setup-vcan.sh                            -> do nothing to VCAN states


## 💬 **Add as Header Comments in Script**
# Here’s what you can add right after the shebang:
# ================================================================
# setup-vcan.sh — Manage virtual CAN interfaces (vcan)
# 
# 🧩 Dependencies:
#   - bash (default shell)
#   - iproute2 → provides `ip` command
#   - kmod → provides `modprobe`
#   - grep, awk → text parsing utilities
#   - sudo → for privileged network operations
#   - can-utils (optional, for testing)
#   - vcan kernel module (usually built-in; load via `modprobe vcan`)
#
# 🛠️ Install missing packages:
#   sudo apt update
#   sudo apt install iproute2 can-utils kmod
#
# 🧠 Notes:
#   - Run with sudo or root privileges for add/delete operations
#   - Tested on Ubuntu/Debian systems
# ================================================================



IP_CMD=$(command -v ip) # Finds the full path for ip (manages network interfaces)

# Variable
delete_all=false

# Function to show VCAN interfaces
show_vcans() 
{
    if $IP_CMD link show | grep -qE 'vcan[0-9]+'; then
        echo "Existing VCAN interfaces:"
        $IP_CMD link show | grep -E 'vcan[0-9]+'
        exit 0
    else
        echo "No existing interfaces ..."
        exit 0
    fi
}

load_vcan_module()
{
    if ! lsmod | grep -q vcan; then
        echo "Loading vcan kernel module..."
        sudo modprobe vcan
    fi
}

# --- Argument parsing ---
NAME_IFS=()
DELETE_IFS=()
UP_IFS=()
DOWN_IFS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            shift
            while [[ $# -gt 0 && $1 != --* ]]; do
                NAME_IFS+=("$1")
                shift
            done
            ;;
        --delete)
            shift
            while [[ $# -gt 0 && $1 != --* ]]; do
                DELETE_IFS+=("$1")
                shift
            done
            ;;
        --up)
            shift
            while [[ $# -gt 0 && $1 != --* ]]; do
                UP_IFS+=("$1")
                shift
            done
            ;;
        --down)
            shift
            while [[ $# -gt 0 && $1 != --* ]]; do
                DOWN_IFS+=("$1")
                shift
            done
            ;;
        --show)
            show_vcans
            exit 0
            ;;
        --delete-all)
            delete_all=true
            shift 1
            ;;
        --help)
            echo "Usage:"
            echo "  --name vcan0 vcan1 ...     Create VCAN interfaces"
            echo "  --delete vcan0 vcan1 ...   Delete VCAN interfaces"
            echo "  --up vcan0 vcan1 ...       Bring up VCAN interfaces"
            echo "  --down vcan0 vcan1 ...     Bring down VCAN interfaces"
            echo "  --show                     Show all VCAN interfaces"
            echo "  --delete-all               Delete all VCAN interfaces"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Try '--help' for usage."
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
load_vcan_module

# -----------------------------------------------------
# Handle deletion independently
# -----------------------------------------------------
for iface in "${DELETE_IFS[@]}"; do
    if $IP_CMD link show "$iface" &>/dev/null; then
        echo "Deleting VCAN $iface..."
        sudo $IP_CMD link delete "$iface" type vcan
        echo "Deleted $iface."
    else
        echo "VCAN $iface does not exist."
    fi
done

# -----------------------------------------------------
# Handle creation independently
# -----------------------------------------------------
for iface in "${NAME_IFS[@]}"; do
    if ! $IP_CMD link show "$iface" &>/dev/null; then
        echo "Creating VCAN $iface..."
        sudo $IP_CMD link add dev "$iface" type vcan
        echo "Created $iface."
    else
        echo "VCAN $iface already exists."
    fi
done

# -----------------------------------------------------
# Bring UP interfaces
# -----------------------------------------------------
for iface in "${UP_IFS[@]}"; do
    if ! $IP_CMD link show "$iface" &>/dev/null; then
        echo "Creating missing VCAN $iface..."
        sudo $IP_CMD link add dev "$iface" type vcan
    fi
    sudo $IP_CMD link set "$iface" up
    echo "$iface is now UP."
done

# -----------------------------------------------------
# Bring DOWN interfaces
# -----------------------------------------------------
for iface in "${DOWN_IFS[@]}"; do
    if $IP_CMD link show "$iface" &>/dev/null; then
        sudo $IP_CMD link set "$iface" down
        echo "$iface is now DOWN."
    else
        echo "VCAN $iface does not exist."
    fi
done

# -----------------------------------------------------
# If no action and no --name/--delete, do nothing to VCAN states
# -----------------------------------------------------
if [[ ${#NAME_IFS[@]} -eq 0 && ${#DELETE_IFS[@]} -eq 0 && \
      ${#UP_IFS[@]} -eq 0 && ${#DOWN_IFS[@]} -eq 0 && $delete_all = false ]]; then
    echo "No action provided. Use --help for options."
fi
