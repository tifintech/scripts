# Scripts

## Base
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/base.sh | bash -s

## PHP LEMP

### Install PHP 7.4 and nginx
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php7.4.sh | bash -s

### Install PHP 8.0 and nginx
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php8.0.sh | bash -s

## PHP Haproxy

### Install HAProxy

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/haproxy_http.sh | bash -s

### Install PHP 8.0 and nginx for haproxy
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php8.0_haproxy.sh | bash -s

## Data stores

### Install Redis
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/redis.sh | bash -s

### Install MariaDB
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/mariadb.sh | bash -s

### Create DB and users users
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/mariadb_create_db_and_users.sh | bash -s

### Install lag check setup

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/lag.sh | bash -s

### Install SQL HAProxy

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/haproxy_sql.sh | bash -s

## KVM

### Run KVM Host prep

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/kvm_host_prep.sh | bash -s

### Run KVM add guest

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/kvm_host_create_guest.sh | bash -s
