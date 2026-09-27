#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

section() {
    echo -e "\n${BLUE}========== $1 ==========${NC}"
}

highlight() {
    echo -e "${RED}[!] $1${NC}"
}

echo -e "${GREEN}[+] Linux Enumeration Script - HTB style${NC}"
echo -e "${YELLOW}[+] Running as: $(whoami) @ $(hostname)${NC}"
echo -e "${YELLOW}[+] Date: $(date)${NC}"

# ====================== SYSTEM INFO ======================
section "SYSTEM INFO"
echo -e "${GREEN}[*] Kernel & OS${NC}"
uname -a
cat /etc/os-release 2>/dev/null || cat /etc/*-release 2>/dev/null
echo
echo -e "${GREEN}[*] Hostname & Uptime${NC}"
hostname
uptime

# ====================== CONTAINER / VM DETECTION ======================
section "CONTAINER / VM DETECTION"
echo -e "${GREEN}[*] Checking for container environment${NC}"
if [ -f /.dockerenv ]; then
    highlight "RUNNING IN DOCKER CONTAINER"
fi
if [ -f /run/.containerenv ]; then
    highlight "RUNNING IN PODMAN CONTAINER"
fi
if grep -qi "docker" /proc/1/cgroup 2>/dev/null; then
    highlight "Docker detected in cgroup"
fi
if grep -qi "lxc" /proc/1/cgroup 2>/dev/null; then
    highlight "LXC container detected in cgroup"
fi
if grep -qi "kubepods" /proc/1/cgroup 2>/dev/null; then
    highlight "Kubernetes detected in cgroup"
fi
echo

echo -e "${GREEN}[*] Checking for VM environment${NC}"
if grep -qi "vmware\|virtualbox\|qemu\|xen\|hyperv" /proc/cpuinfo 2>/dev/null; then
    highlight "VM hypervisor detected in CPU info"
fi
if grep -qi "vmware\|virtualbox\|qemu\|xen\|hyperv" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
    highlight "VM detected via DMI"
fi
if [ -d /sys/hypervisor/type ]; then
    highlight "Hypervisor detected: $(cat /sys/hypervisor/type 2>/dev/null)"
fi
dmesg 2>/dev/null | grep -i "hypervisor\|vmware\|virtualbox\|qemu" | head -5

# ====================== CURRENT USER ======================
section "CURRENT USER"
id
echo
groups
echo
echo -e "${GREEN}[*] Sudo rights${NC}"
sudo -l 2>/dev/null || echo "No sudo or password required"
echo
echo -e "${GREEN}[*] Checking for NOPASSWD sudo entries${NC}"
if sudo -l 2>/dev/null | grep -i "nopasswd"; then
    highlight "NOPASSWD sudo entries found!"
fi
if [ -d /etc/sudoers.d ]; then
    echo -e "${GREEN}[*] Sudoers.d files${NC}"
    ls -la /etc/sudoers.d 2>/dev/null
    echo
    if grep -r "NOPASSWD" /etc/sudoers.d 2>/dev/null; then
        highlight "NOPASSWD entries found in sudoers.d!"
    fi
fi

# ====================== USERS ======================
section "USERS"
echo -e "${GREEN}[*] All users with shells${NC}"
getent passwd | grep -E '/bin/(bash|sh|zsh|fish)' | cut -d: -f1,3,6,7
echo
echo -e "${GREEN}[*] Users with UID >= 1000${NC}"
getent passwd | awk -F: '$3 >= 1000 {print $1":"$3":"$6":"$7}'
echo
echo -e "${GREEN}[*] /etc/passwd${NC}"
cat /etc/passwd
echo
echo -e "${GREEN}[*] /etc/group (interesting groups)${NC}"
grep -E 'sudo|admin|docker|lxd|adm|wheel' /etc/group 2>/dev/null

# ====================== HOME & INTERESTING FILES ======================
section "HOME DIRECTORIES & FILES"
echo -e "${GREEN}[*] Listing /home${NC}"
ls -la /home 2>/dev/null
echo
echo -e "${GREEN}[*] Current user home${NC}"
ls -la ~/ 2>/dev/null
echo
echo -e "${GREEN}[*] Bash history${NC}"
cat ~/.bash_history 2>/dev/null | tail -50
echo
echo -e "${GREEN}[*] Looking for interesting files in /home${NC}"
find /home -type f \( -name "*.txt" -o -name "*.conf" -o -name "*.bak" -o -name "*.old" -o -name "*.orig" -o -name "*pass*" -o -name "*cred*" -o -name "*.key" -o -name "*.pem" -o -name "id_rsa*" -o -name "*.env" -o -name "*.sqlite" -o -name "*.db" \) 2>/dev/null
echo
echo -e "${GREEN}[*] Interesting files in /opt${NC}"
find /opt -type f \( -name "*.txt" -o -name "*.conf" -o -name "*.bak" -o -name "*.old" -o -name "*.orig" -o -name "*pass*" -o -name "*cred*" -o -name "*.key" -o -name "*.pem" -o -name "id_rsa*" -o -name "*.env" -o -name "*.sqlite" -o -name "*.db" \) 2>/dev/null
echo
echo -e "${GREEN}[*] Interesting files in /var/www${NC}"
find /var/www -type f \( -name "*.txt" -o -name "*.conf" -o -name "*.bak" -o -name "*.old" -o -name "*.orig" -o -name "*pass*" -o -name "*cred*" -o -name "*.key" -o -name "*.pem" -o -name "id_rsa*" -o -name "*.env" -o -name "*.sqlite" -o -name "*.db" \) 2>/dev/null
echo
echo -e "${GREEN}[*] SSH keys and authorized_keys${NC}"
find /home -type f -name "authorized_keys" -o -name "id_rsa*" -o -name "id_dsa*" 2>/dev/null
echo
echo -e "${GREEN}[*] Environment files (.env)${NC}"
find / -path /proc -prune -o -path /sys -prune -o -type f -name ".env" 2>/dev/null | head -20

# ====================== PROCESSES & SERVICES ======================
section "PROCESSES & SERVICES"
echo -e "${GREEN}[*] Running processes (user context)${NC}"
ps aux --sort=-%mem | head -20
echo
echo -e "${GREEN}[*] Listening ports${NC}"
ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null
echo
echo -e "${GREEN}[*] Systemd timers${NC}"
systemctl list-timers --all 2>/dev/null | head -20
echo
echo -e "${GREEN}[*] Running systemd services${NC}"
systemctl list-units --type=service --state=running 2>/dev/null | head -20

# ====================== CRON ======================
section "CRON JOBS"
echo -e "${GREEN}[*] User crontab${NC}"
crontab -l 2>/dev/null || echo "No user crontab"
echo
echo -e "${GREEN}[*] /etc/cron*${NC}"
ls -la /etc/cron* 2>/dev/null
echo
echo -e "${GREEN}[*] Cron files content (interesting)${NC}"
grep -r . /etc/cron* 2>/dev/null | grep -v ":#" | head -30

# ====================== SUID / CAPABILITIES ======================
section "SUID / SGID / CAPABILITIES"
echo -e "${GREEN}[*] SUID binaries${NC}"
find / -perm -4000 -type f 2>/dev/null | head -40
echo
echo -e "${GREEN}[*] SGID binaries${NC}"
find / -perm -2000 -type f 2>/dev/null | head -20
echo
echo -e "${GREEN}[*] Capabilities${NC}"
getcap -r / 2>/dev/null | head -20

# ====================== WRITABLE LOCATIONS ======================
section "WRITABLE LOCATIONS"
echo -e "${GREEN}[*] World-writable directories${NC}"
find / -type d -perm -0002 2>/dev/null | grep -v proc | head -20
echo
echo -e "${GREEN}[*] Writable files owned by root (careful)${NC}"
find / -type f -writable -user root 2>/dev/null | head -15

# ====================== NETWORK ======================
section "NETWORK"
echo -e "${GREEN}[*] IP addresses${NC}"
ip a 2>/dev/null || ifconfig 2>/dev/null
echo
echo -e "${GREEN}[*] Routing table${NC}"
ip route 2>/dev/null || route -n 2>/dev/null
echo
echo -e "${GREEN}[*] ARP / neighbors${NC}"
ip neigh 2>/dev/null || arp -a 2>/dev/null

# ====================== INTERESTING CONFIGS ======================
section "INTERESTING CONFIGS / SECRETS"
echo -e "${GREEN}[*] Searching for password-like strings (quick)${NC}"
grep -r -i -E 'password|passwd|pwd|secret|key|token|api_key' /home /opt /var/www /etc 2>/dev/null | grep -v Binary | head -30

echo -e "\n${GREEN}[+] Enumeration finished${NC}"
echo -e "${YELLOW}[+] Review the output carefully, especially sudo -l, NOPASSWD entries, SUID, cron, and home directories${NC}"
