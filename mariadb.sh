SERVER_ID=$1
PASSWORD=$2

RAM_GB=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')

BUFFER_POOL_SIZE=$(echo "$RAM_GB" | awk '{print int($1*0.65)"G"}')
LOG_FILE_SIZE=$(echo "$RAM_GB" | awk '{print int($1*0.15)"G"}')

IO_THREADS=$(nproc | awk '{print int($1/2)}')

SUPERUSER="superuser@'127.0.0.1'";

if [[ -z "$SERVER_ID" ]]; then
   printf "Server ID missing\n"
   exit 1
fi

if [[ -z "$PASSWORD" ]]; then
   printf "Password missing\n"
   exit 1
fi

if [[ ${#PASSWORD} -lt 10 ]]; then
   printf "Password too short\n"
   exit 1
fi

echo "Install MariaDB 10.4"
sudo apt -y install software-properties-common

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"

sudo apt -y install mariadb-server mariadb-client

echo "Config MariaDB"
sudo bash -c 'cat > /etc/mysql/mariadb.conf.d/my.cnf' << EOF
[mysqld]

server-id=$SERVER_ID

bind-address=0.0.0.0
skip_name_resolve=1

log_basename=db

log_error=/var/log/mysql/error.log

slow_query_log=1
long_query_time=10
slow_query_log_file=/var/log/mysql/slow.log

log_slave_updates=1
sync_binlog=1
#slave_parallel_threads=20

expire_logs_days=7

sql-mode=NO_ENGINE_SUBSTITUTION

## CACHES AND LIMITS

max_connections=10000
max_allowed_packet=1G

## INNODB

innodb_buffer_pool_size=$BUFFER_POOL_SIZE
innodb_log_file_size=$LOG_FILE_SIZE
innodb_write_io_threads=$IO_THREADS
innodb_read_io_threads=$IO_THREADS
innodb_flush_log_at_trx_commit=2
EOF

echo "Prep MariaDB";
sudo mysql -u root << EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo "Set swappiness to 0"
sudo sed -i 's|vm.swappiness.*|vm.swappiness = 0|g' /etc/sysctl.d/custom.conf
sudo sysctl -p /etc/sysctl.d/custom.conf

echo "Increase tasks limit"
grep -qF "TasksMax" /etc/systemd/system/mysqld.service || echo "TasksMax=100000" | sudo tee -a /etc/systemd/system/mysqld.service

echo "Create super user"
sudo mysql -u root -e "create user $SUPERUSER identified by '$PASSWORD'; grant all privileges on *.* TO $SUPERUSER with grant option; flush privileges;"

echo "Restart MariaDB"
sudo systemctl daemon-reload
sudo service mysql restart

echo "Allow private network access"
sudo ufw allow from 10.0.0.0/8 to any port 3306