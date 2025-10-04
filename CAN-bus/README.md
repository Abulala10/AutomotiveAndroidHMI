## 🧩 Dependencies

Before running `setup-vcan.sh`, ensure the following are installed and available in your system PATH:

| Dependency | Description | Install Command |
|-------------|--------------|----------------|
| bash | Shell interpreter | (pre-installed) |
| iproute2 | Provides the `ip` command to manage network interfaces | `sudo apt install iproute2` |
| can-utils | Useful CAN tools (`candump`, `cansend`, etc.) | `sudo apt install can-utils` |
| kmod | Provides `modprobe` for loading kernel modules | `sudo apt install kmod` |
| grep, awk | Used internally for text parsing | (pre-installed) |
| sudo | Required for privileged commands | (pre-installed) |
| vcan kernel module | Virtual CAN network interface support | `sudo modprobe vcan` |

### ✅ Verify Installation
```bash
ip --version
modinfo vcan
candump --help
