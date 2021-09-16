# Scripts

## Base
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/base.sh | bash -s

## PHP LEMP

### PHP 7.4
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php7.4.sh | bash -s

### PHP 8.0
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php8.0.sh | bash -s

## PHP Haproxy

### Run HAProxy Http setup

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/haproxy_http.sh | bash -s

### Run PHP 8.0 haproxy setup
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/php8.0_haproxy.sh | bash -s

## Data stores

### Redis
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/redis.sh | bash -s

### MariaDB
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/mariadb.sh | bash -s

### Run MariaDB users
curl -s https://raw.githubusercontent.com/tifintech/scripts/main/mariadb_users.sh | bash -s

### Run lag check setup

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/lag.sh | bash -s

### SQL HAProxy

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/haproxy_sql.sh | bash -s

## KVM

### Run KVM Host prep

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/kvm_host_prep.sh | bash -s

### Run KVM add guest

curl -s https://raw.githubusercontent.com/tifintech/scripts/main/kvm_host_create_guest.sh | bash -s
