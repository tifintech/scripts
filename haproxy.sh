PROXY_TYPE=$1

if [[ -z "$PROXY_TYPE" ]]; then
   printf "Proxy missing\n"
   exit 1
fi

if [[ ! "$PROXY_TYPE" =~ ^(http|sql)$ ]]; then 
   printf "Type must be http or sql\n"
   exit 1
fi

echo "Install HAProxy 2.1"
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:vbernat/haproxy-2.1 --yes
sudo apt -y update
sudo apt -y install haproxy

sudo cp /etc/haproxy/haproxy.cfg{,.original}

echo "Create default config"
sudo bash -c 'cat > /etc/haproxy/haproxy.cfg' << EOF
global
  log /dev/log    local0 notice
  log /dev/log    local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s
  user haproxy
  group haproxy
  daemon

defaults
  log     global
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http
        
EOF

if [[ "$PROXY_TYPE" = "sql" ]]; then 
sudo bash -c 'cat > /etc/haproxy/haproxy.cfg' << EOF
listen master
  bind :3306
  mode tcp
  balance roundrobin
        
        
listen slave
  bind :3307
  mode tcp
  option httpchk
  balance roundrobin

EOF
fi

if [[ "$PROXY_TYPE" = "http" ]]; then 
sudo bash -c 'cat > /etc/haproxy/haproxy.cfg' << EOF
EOF
fi
