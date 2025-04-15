# Linux System Monitor

A local monitoring tool for Linux systems, supporting both standard Linux distributions and WSL (Windows Subsystem for Linux).

## What This Tool Does

This script collects and displays comprehensive information about your local Linux system, including:

- **Basic System Information**: hostname, username, kernel version and release date, uptime, etc.
- **Hardware Details**: CPU, memory usage, memory range, PCI devices, USB devices
- **Network Information**: IP addresses, MAC address, DNS servers, public IP, open ports, network traffic
- **Disk Information**: usage, health status, partitions, I/O scheduler
- **Software Data**: installed packages, processes, users, system load and more

## System Requirements

- Linux-based operating system (tested on Ubuntu 24.04.2)
- WSL support (automatically detected)
- Optional dependencies (automatically detected):
  - `smartmontools` - for disk health information
  - `lshw` - for detailed hardware information
  - `lsusb` - for USB device information
  - `sensors` - for temperature information
  - `curl` or `wget` - for public IP detection

## Installation

1. Clone the repository:
```bash
git clone https://github.com/avivil0297/linux-system-monitor.git
cd linux-system-monitor
```

2. Make the script executable:
```bash
chmod +x monitor.sh
```

## Usage

For full information (recommended):

```bash
sudo ./monitor.sh
```

Without sudo (limited information):

```bash
./monitor.sh
```

### Command Line Options

```
Options:
  -h, --help           Display this help message
  -c, --config FILE    Use custom configuration file
  -o, --output FILE    Save output to file
  -m, --minimal        Show only essential information
  -n, --no-sudo        Run without attempting to use sudo
  -v, --version        Show version information
```

## Features

- Automatically detects and adapts to WSL environments
- Graceful sudo handling (suggests running with sudo instead of prompting for password)
- Comprehensive system overview in a readable, color-coded format
- Hardware detection with fallbacks when tools are missing
- Detailed network statistics including public IP and traffic information
- Process monitoring with CPU and memory usage
- Disk health information (requires smartmontools)

## Example Output

```
╔═══════════════════════════════════════════════╗
║             LINUX SYSTEM MONITOR              ║
║             Version: 1.2.0                    ║
╚═══════════════════════════════════════════════╝

=====================================
BASIC SYSTEM INFORMATION
=====================================

Hostname                            : usercomputer
Username                            : user
Kernel version                      : 6.11.0-21-generic
Kernel release date                 : 2025-03-06
OS version                          : Ubuntu 24.04.2 LTS
OS version codename                 : noble
System uptime                       : up 38 minutes
Last boot                           : 2025-04-15 23:00

=====================================
HARDWARE INFORMATION
=====================================

CPU model                           : Intel(R) Core(TM) i5-9400F CPU @ 2.90GHz
CPU cores                           : 2 (1 physical, 1 cores per CPU)
CPU frequency                       : 2903.998 MHz
RAM size                            : 3.8Gi
Memory range                        : 00000000-00000000 
RAM used                            : 1222 MB (31%)
...
```

## What's New in v1.2.0

- Added WSL environment detection and support
- Improved sudo handling (suggests sudo instead of prompting for password)
- Fixed display issues with international character sets
- Improved error handling and robustness
- Added public IP retrieval with multiple fallback servers
- Enhanced disk health information display
- Added better detection of system components when commands are missing
- Fixed RAM usage calculation
- Improved formatting with color-coded output
- Added configuration file support
- Added output-to-file capability
- Added minimal mode option

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## Roadmap

- Add graphical output options
- Include system benchmarking capabilities
- Create configuration options for customized output
- Add historical data tracking

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
