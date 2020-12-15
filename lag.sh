echo "Create lag script"

sudo bash -c 'cat > /usr/local/bin/lag.sh' << 'EOF'
#!/bin/bash

DB_USER="haproxy"
DB_PASS="password"
ACCEPTABLE_LAG=5

# Status ok, return 'HTTP 200'
http_200 () {
/bin/echo -e "HTTP/1.1 200 OK\r\n"
/bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
/bin/echo -e "\r\n"
/bin/echo -e "$1"
/bin/echo -e "\r\n"
}

# Status not ok, return 'HTTP 503'
http_503 () {
/bin/echo -e "HTTP/1.1 503 Service Unavailable\r\n"
/bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
/bin/echo -e "\r\n"
/bin/echo -e "$1"
/bin/echo -e "\r\n"
}

# Server not found, maybe MySQL is down, return 'HTTP 404'
http_404 () {
  /bin/echo -e "HTTP/1.1 404 Not Found\r\n"
  /bin/echo -e "Content-Type: Content-Type: text/plain\r\n"
  /bin/echo -e "\r\n"
  /bin/echo -e "$1"
  /bin/echo -e "\r\n"
}

# Run query against the local MySQL host
SECONDS_BEHIND_MASTER=$(mysql -u$DB_USER -p$DB_PASS -e "SHOW SLAVE STATUS\G"| grep "Seconds_Behind_Master" | awk '{ print $2 }')

if [ "$SECONDS_BEHIND_MASTER" == "NULL" ] ; then
http_404 "Error $SECONDS_BEHIND_MASTER"
elif [ "$SECONDS_BEHIND_MASTER" -gt "$ACCEPTABLE_LAG" ] ; then
http_503 "Lag $SECONDS_BEHIND_ERROR"
else
http_200 "OK $SECONDS_BEHIND_MASTER"
fi
EOF

sudo chmod +x /usr/local/bin/lag.sh

echo "Create lag service"
sudo bash -c 'cat > /etc/systemd/system/mysqlchk@.service' << EOF
[Unit]
Description=Check lag service for HAProxy
After=network.target systemfoo.socket
Requires=mysqlchk.socket

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lag.sh
TimeoutStopSec=5
StandardInput=socket

[Install]
WantedBy=multi-user.target
EOF

sudo bash -c 'cat > /etc/systemd/system/mysqlchk.socket' << EOF
[Unit]
Description=Check lag socket for HAProxy
PartOf=mysqlchk@.service

[Socket]
ListenStream=0.0.0.0:9876
Accept=true

[Install]
WantedBy=sockets.target
EOF

sudo systemctl daemon-reload
