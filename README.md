# Linux System Monitor

A local monitoring tool for Linux systems, originally developed for Ubuntu 24.04.2.

## What This Tool Does

This script collects and displays comprehensive information about your local Linux system, including:

- **Basic System Information**: hostname, username, kernel version, uptime, etc.
- **Hardware Details**: CPU, memory, connected devices
- **Network Information**: IP addresses, DNS servers, open ports
- **Software Data**: installed packages, processes, users, and more

## System Requirements

- Linux-based operating system (tested on Ubuntu 24.04.2)
- `sudo` privileges for certain commands
- Optional dependencies:
  - `lshw`
  - `smartmontools`

## Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/linux-system-monitor.git
cd linux-system-monitor
```

2. Make the script executable:
```bash
chmod +x monitor.sh
```

## Usage

Simply run the script:

```bash
./monitor.sh
```

Provide your sudo password when prompted, if necessary.

## Features

- Displays detailed system information in a readable format
- Organized into logical categories
- Automatically checks for sudo permissions
- Basic error handling
- Comprehensive system overview in a single run

## Example Output

```
=====================================
BASIC SYSTEM INFORMATION
=====================================

Hostname                           : ubuntu-desktop
Hostname (uppercase)               : UBUNTU-DESKTOP
Username                           : user
...

=====================================
HARDWARE INFORMATION
=====================================

CPU model                          : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
RAM size                           : 16 GiB
...
```

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## Roadmap

- Add graphical output options
- Include system benchmarking capabilities
- Create configuration options for customized output
- Add historical data tracking

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
