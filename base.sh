SYS_USER=$USER

echo "Install, update & upgrade"
sudo apt -y -q update
sudo apt -y -q upgrade
sudo apt -y -q install ufw fail2ban htop

echo "Increase file limits"
LIMITS=$(cat << 'EOF'
*           hard   nofile   1048576
*           soft   nofile   1048576
$SYS_USER   hard   nofile   1048576
$SYS_USER   soft   nofile   1048576
EOF
)
grep -qF "$SYS_USER" /etc/security/limits.conf || echo "$LIMITS" | sudo tee -a /etc/security/limits.conf

echo "Add sysctl tweaks"
sudo bash -c 'cat > /etc/sysctl.d/custom.conf' << EOF
### TUNING NETWORK PERFORMANCE ###
# Default Socket Receive Buffer
net.core.rmem_default = 31457280
# Maximum Socket Receive Buffer
net.core.rmem_max = 12582912
# Default Socket Send Buffer
net.core.wmem_default = 31457280
# Maximum Socket Send Buffer
net.core.wmem_max = 12582912
# Increase number of incoming connections
net.core.somaxconn = 65536
# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 65536
# Increase the maximum amount of option memory buffers
net.core.optmem_max = 25165824
# Increase the maximum total buffer-space allocatable
# This is measured in units of pages (4096 bytes)
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144
# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
vm.swappiness = 10
EOF
sudo sysctl -p /etc/sysctl.d/custom.conf

echo "Config ssh"
sudo bash -c 'cat > /etc/ssh/sshd_config' << EOF
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF

sudo service ssh restart

echo "Disable auto upgrades"
sudo bash -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades' << EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "Setup fail2ban jail"
sudo bash -c 'cat > /etc/fail2ban/jail.local' << EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
bantime = 86400
findtime = 3600
maxretry = 3
EOF

sudo systemctl start fail2ban

echo "Config firewall"
sudo sed -i 's|IPV6=yes|IPV6=no|g' /etc/default/ufw
sudo ufw allow proto tcp to 0.0.0.0/0 port 22
sudo ufw --force enable
