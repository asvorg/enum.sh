# Linux Enum Script (HTB)

Simple post-foothold enumeration script for Linux boxes on Hack The Box.

## What it does

Runs the most useful commands after you get a shell (RDP, SSH, etc.):

- System & kernel info
- Current user / groups / sudo rights
- Local users
- Home directories & interesting files
- Bash history
- Running processes & listening ports
- Cron jobs & systemd timers
- SUID / SGID binaries
- Capabilities
- World-writable directories
- Network info
- Quick password/secret search

## Usage

```bash
# Make executable
chmod +x enum.sh

# Run and save output
./enum.sh | tee enum_output.txt
```
