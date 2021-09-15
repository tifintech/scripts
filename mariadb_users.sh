APP_NAME=$1
PASSWORD=$2
DATABASE_USER="'${APP_NAME}_user'@'10.%'"
NETWORK_REPLICATION_USER="'${APP_NAME}_replication'@'10.%'"
LOCAL_REPLICATION_USER="'${APP_NAME}_replication'@'127.0.0.1'"

if [[ -z "$APP_NAME" ]]; then
   printf "App Name missing\n"
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

echo "Starting MariaDB"
sudo mysql << EOF
CREATE USER $DATABASE_USER IDENTIFIED BY '$PASSWORD';
GRANT CREATE, DELETE, INSERT, SELECT, UPDATE, DROP, ALTER ON  *.* to $DATABASE_USER;
CREATE USER $NETWORK_REPLICATION_USER IDENTIFIED BY 'replication';
GRANT REPLICATION SLAVE ON *.* TO $NETWORK_REPLICATION_USER;
CREATE USER $LOCAL_REPLICATION_USER IDENTIFIED BY 'replication';
GRANT REPLICATION SLAVE ON *.* TO $LOCAL_REPLICATION_USER;
FLUSH PRIVILEGES;
EOF
echo "goodbye"
