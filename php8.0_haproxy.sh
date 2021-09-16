SYS_USER=$USER

RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
CORES=$(nproc | awk '{print int($1)}')

MAX_CHILDREN=$(echo "$RAM_MB" | awk '{print int($1 / 60)}')
START_SERVERS=$(($CORES * 4))
MIN_SPARE_SERVERS=$(($CORES * 2))
MAX_SPARE_SERVERS=$START_SERVERS

echo "Install PHP"
sudo apt -y update
sudo apt -y upgrade
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php

sudo apt -q -y install nginx php8.0-{common,cli,fpm,redis,mysql,bcmath,bz2,curl,gd,intl,mbstring,readline,xml,zip,gmp} cabextract supervisor

echo "Install composer"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "Add DNS to resolved"
sudo sed -i 's|#DNS=.*|DNS=8.8.8.8|g' /etc/systemd/resolved.conf
sudo sed -i 's|#FallbackDNS=.*|FallbackDNS=8.8.4.4|g' /etc/systemd/resolved.conf

echo "Confgure Nginx"
sudo sed -i 's|#ULIMIT=.*|ULIMIT="-n 1048576"|g' /etc/default/nginx

sudo mkdir /etc/systemd/system/nginx.service.d
sudo chown -R $(whoami):$(whoami) /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\nLimitNOFILE=1048576\n" > /etc/systemd/system/nginx.service.d/override.conf

sudo systemctl daemon-reload

sudo bash -c 'cat > /etc/nginx/nginx.conf' << EOF
user $(whoami);
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

worker_rlimit_nofile 1048576;

events {
    worker_connections 16384;
    multi_accept       on;
    use                epoll;
}

http {
    ##
    # Basic Settings
    ##

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    # server_tokens off;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##

    gzip on;

    # gzip_vary on;
    # gzip_proxied any;
    # gzip_comp_level 6;
    # gzip_buffers 16 8k;
    # gzip_http_version 1.1;
    # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    ##
    # Virtual Host Configs
    ##

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

sudo bash -c 'cat > /etc/nginx/sites-enabled/default' << 'EOF'
server {
    listen 80 default_server;

    # Php-fpm status page
    location ~ ^/(status|ping)$ {
        access_log off;
        allow all;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    # Nginx status page
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }

    # Deny the rest
    location / {
        deny all;
    }
}
EOF

echo "Configure php-fpm"
sudo mkdir /etc/systemd/system/php8.0-fpm.service.d
sudo chown -R $(whoami):$(whoami) /etc/systemd/system/php8.0-fpm.service.d

printf "[Service]\nExecStartPost=/bin/sleep 0.1\nLimitNOFILE=1048576\n" > /etc/systemd/system/php8.0-fpm.service.d/override.conf

sudo systemctl daemon-reload

sudo bash -c 'cat > /etc/php/8.0/fpm/pool.d/www.conf' << EOF
[www]
user = $(whoami)
group = $(whoami)

listen = 9000
listen.backlog = 65536

listen.owner = www-data
listen.group = www-data

pm = dynamic

pm.max_children = $MAX_CHILDREN
pm.start_servers = $START_SERVERS
pm.min_spare_servers = $MIN_SPARE_SERVERS
pm.max_spare_servers = $MAX_SPARE_SERVERS

pm.status_path = /status

ping.path = /ping
ping.response = pong

rlimit_files = 1048576

catch_workers_output = yes

php_admin_value[error_log] = /var/log/fpm-php.www.log
php_admin_flag[log_errors] = on
EOF

sudo bash -c 'cat > /etc/php/8.0/fpm/conf.d/my.ini' << 'EOF'
post_max_size = 512M
upload_max_filesize = 512M
EOF

echo "Allow http"
sudo ufw allow proto tcp to 0.0.0.0/0 port 80

