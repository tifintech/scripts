echo "Install Redis"
sudo apt -y update
sudo apt install -y redis-server

echo "Update config"
sudo sed -i 's|bind.*|# bind 127.0.0.1 ::1|g' /etc/redis/redis.conf

sudo sed -i 's|protected-mode.*|protected-mode no|g' /etc/redis/redis.conf

sudo sed -i 's|tcp-backlog.*|tcp-backlog 65536|g' /etc/redis/redis.conf

sudo sed -i 's|supervised.*|supervised systemd|g' /etc/redis/redis.conf

sudo sed -i 's|save 900.*|# save 900 1|g' /etc/redis/redis.conf
sudo sed -i 's|save 300.*|# save 300 10|g' /etc/redis/redis.conf
sudo sed -i 's|save 60.*|# save 60 10000|g' /etc/redis/redis.conf

sudo sed -i 's|# maxclients.*|maxclients 100000|g' /etc/redis/redis.conf

echo "Config redis service"
sudo sed -i 's|LimitNOFILE.*|LimitNOFILE=1000000|g' /etc/systemd/system/redis.service
grep -qF "ExecStartPost" /etc/systemd/system/redis.service || sudo sed -i '/ExecStart.*/a ExecStartPost=/bin/sleep 0.1/' /etc/systemd/system/redis.service

echo "Update sysctl"
sudo sed -i 's|vm.swappiness.*|vm.swappiness = 0|g' /etc/sysctl.d/custom.conf
grep -qF "vm.overcommit_memory" /etc/sysctl.d/custom.conf || echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.d/custom.conf
sudo sysctl -p /etc/sysctl.d/custom.conf

echo "Config huge pages"
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

sudo service redis restart

echo "Allow private network access"
sudo ufw allow from 10.0.0.0/8 to any port 6379
