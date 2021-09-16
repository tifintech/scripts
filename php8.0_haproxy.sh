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

echo "Create Delphi param"
sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048

echo "Add DNS to resolved"
sudo sed -i 's|#DNS=.*|DNS=8.8.8.8|g' /etc/systemd/resolved.conf
sudo sed -i 's|#FallbackDNS=.*|FallbackDNS=8.8.4.4|g' /etc/systemd/resolved.conf

echo "Confgure Nginx"
sudo mkdir /etc/nginx/ssl

sudo sed -i 's|#ULIMIT=.*|ULIMIT="-n 1048576"|g' /etc/default/nginx

sudo mkdir /etc/systemd/system/nginx.service.d
sudo chown -R $SYS_USER:$SYS_USER /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\nLimitNOFILE=1048576\n" > /etc/systemd/system/nginx.service.d/override.conf

sudo systemctl daemon-reload

sudo bash -c 'cat > /etc/nginx/nginx.conf' << EOF
user $SYS_USER;
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

    # Allow letsencrypt
    #location ~ /.well-known {
    #    root /var/www/repo/public;
    #    allow all;
    #}

    # Proxy letsencrypt to ssl server
    location ~ /.well-known {
        proxy_pass https://manager.tifintech.com;
    }

    # Github webhook
    #location /git_webhook.php {
    #    root /var/www;
    #    access_log off;
    #    allow all;
    #    fastcgi_pass 127.0.0.1:9000;
    #    fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
    #    include /etc/nginx/fastcgi_params;
    #}

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

sudo bash -c 'cat > /etc/nginx/snippets/slim.conf' << 'EOF'
index index.php;

charset utf-8;

# Strip trailing slash
rewrite ^/(.*)/$ /$1 permanent;

location / {
    try_files $uri $uri/ /index.php?$query_string;
}

location = /favicon.ico { access_log off; log_not_found off; }
location = /robots.txt  { access_log off; log_not_found off; }

error_page 404 /index.php;

location ~ \.php$ {
    include /etc/nginx/fastcgi_params;

    try_files $uri /index.php;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
    fastcgi_connect_timeout 300s;
    fastcgi_read_timeout 600s;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
    client_max_body_size 120M;
}
EOF

sudo bash -c 'cat > /etc/nginx/snippets/laravel.conf' << 'EOF'
index index.php;

charset utf-8;

# Strip trailing slash
rewrite ^/(.*)/$ /$1 permanent;

location / {
    try_files $uri $uri/ /index.php?$query_string;
}

location = /favicon.ico { access_log off; log_not_found off; }
location = /robots.txt  { access_log off; log_not_found off; }

error_page 404 /index.php;

location ~ \.php$ {
    include /etc/nginx/fastcgi_params;

    try_files $uri /index.php;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
    fastcgi_connect_timeout 300s;
    fastcgi_read_timeout 600s;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;
    client_max_body_size 120M;
}
EOF

sudo bash -c 'cat > /etc/nginx/snippets/ssl.conf' << 'EOF'
ssl_dhparam /etc/nginx/dhparam.pem;

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
ssl_prefer_server_ciphers on;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 30s;

add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload";
add_header X-XSS-Protection "1; mode=block";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
EOF

echo "Configure php-fpm"
sudo mkdir /etc/systemd/system/php8.0-fpm.service.d
sudo chown -R $SYS_USER:$SYS_USER /etc/systemd/system/php8.0-fpm.service.d

printf "[Service]\nExecStartPost=/bin/sleep 0.1\nLimitNOFILE=1048576\n" > /etc/systemd/system/php8.0-fpm.service.d/override.conf

sudo systemctl daemon-reload

sudo bash -c 'cat > /etc/php/8.0/fpm/pool.d/www.conf' << EOF
[www]
user = $SYS_USER
group = $SYS_USER

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
post_max_size = 128M
upload_max_filesize = 128M
EOF

sudo rm -f -R /var/www/html
sudo mkdir -p /var/www
sudo chown -R $SYS_USER:$SYS_USER /var/www

echo "Allow http and https"
sudo ufw allow proto tcp to 0.0.0.0/0 port 80
sudo ufw allow proto tcp to 0.0.0.0/0 port 443

