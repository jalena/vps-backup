#! /bin/bash
#===============================================================================================
#   System Required:  CentOS6.x (32bit/64bit)
#   Description: Server backup and restore script
#   Author: Jalena <jalena@bcsytv.com>
#   Intro:  https://jalena.bcsytv.com/archives/1358
#===============================================================================================

[[ $EUID -ne 0 ]] && echo 'Error: This script must be run as root!' && exit 1

# global variables
variables(){
	current_date=`date +%Y%m%d`
}

# Initialize the database of account information
function initialization(){
	if [[ ! -e '/root/.my.cnf' ]]; then
		echo "Please enter the MySQL user (Default : root):\n"
		read -p MYSQL_USER
		[[ -z "$MYSQL_USER" ]] && MYSQL_USER="root"
		echo "Please enter the MySQL password:\n"
		read -p MYSQL_PASS
		echo -e "---------------------------"
		echo -e "MySQL User = $MYSQL_USER"
		echo -e "MySQL Pass = $MYSQL_PASS"
		echo -e "---------------------------"
cat > /root/.my.cnf<<EOF
[client]
user=$MYSQL_USER
password=$MYSQL_PASS

[mysqldump]
user=$MYSQL_USER
password=$MYSQL_PASS
EOF
	fi

	if [[ ! -e '.backup.option' ]]; then
		echo "Please enter backup path:\n"
		read -p BACKUP
			[[ -z $BACKUP ]] && BACKUP = "/data/backup"
		echo "Please enter the web Path (Default : /data/wwwroot):\n"
		read -p WEB_PATH
			[[ -z $WEB_PATH ]] && WEB_PATH="/data/wwwroot"
		echo "Please enter the nginx configuration path (Default : /usr/local/nginx/conf/vhost):\n"
		read -p NGINX_PATH
			[[ -z $NGINX_PATH ]] && NGINX_PATH="/usr/local/nginx/conf/vhost"
		echo -e "---------------------------"
		echo -e "Backup directory = $WEB_PATH"
		echo -e "nginx directory = $NGINX_PATH"
		echo -e "---------------------------"
cat > /root/.backup.option<<EOF
BACKUP_DIR=$BACKUP
WEB_PATH=$WEB_PATH
NGINX_PATH=$NGINX_PATH
EOF
	fi
}

initialization_check(){
	if [[ ! -d $BACKUP_DIR ]]; then
		mkdir -p ${BACKUP_DIR}
	fi

	if [[ -s '/root/.backup.option']]; then
		source /root/.backup.option
	elif [[ -s '/root/.my.cnf' ]]; then
		source /root/.my.cnf
	else
		initialization
	fi
}

# Backup all database tables
backup_database(){
	for db in $(mysql -B -N -e 'SHOW DATABASES' |sed -e '/_schema/d' -e '/mysql/d' -e '/sys/d')
		do
			mysqldump ${db} | gzip -9 - > ${BACKUP_DIR}/${db}.sql.gz
			echo -e "\t\e[1;32m--- Backup data table \e[1;31m${db} \e[1;32msuccess! ---\e[0m"
	done

	# Pack all database tables
	tar zcf mysql_$current_date.tar.gz *.sql.gz --remove-files
}

# Packing site data
packing_data(){
	for web in $(ls -1 ${WEB_PATH} |sed -e '/phpMy/d')
	do
		tar zcPf ${BACKUP_DIR}/${web}_$current_date.tar.gz ${WEB_PATH}/${web}
		echo -e "\t\e[1;32m--- package \e[1;31m${web} \e[1;32msuccess! ---\e[0m"
	done
}

# package the nginx configuration file
configuration(){
	tar zcPf ${BACKUP_DIR}/nginx_$current_date.tar.gz $NGINX_PATH
	echo -e "\t\e[1;32m--- package \e[1;31mnginx_$current_date.tar.gz \e[1;32msuccess! ---\e[0m"
	find / -name nginx.conf |grep -v root | xargs tar rPf ${BACKUP_DIR}/nginx_$current_date.tar.gz
	echo -e "\t\e[1;32m--- Additional file successfully ---\e[0m"
}

# Upload data
upload_file(){
	variables
	for file in $(ls -1 ${BACKUP_DIR})
		do
			#scp ${file} root@23.239.196.3:/root/backup/${file}
			#sh /root/dropbox_uploader.sh upload ${file} backup/${file}
			./qshell fput backup ${file} ${BACKUP_DIR}/${file} http://up.qiniug.com
	done
}

# Restore all data
restore_all(){
	initialization_check
	cd ${BACKUP_DIR}
	tar zxf mysql*.tar.gz
	for db in $(find *.sql.gz | sed 's/.sql.gz//g')
		do
			mysqladmin create ${db}
			gunzip -f < ${db}.sql.gz | mysql ${db}
	done

	for web in $(ls -1 *.tar.gz| grep -v mysql |grep -v nginx)
		do
			tar zxPf ${web}
	done

	for nginx in $(ls -1 nginx*)
		do
			tar zxPf ${nginx}
	done
}

# Initialization settings
initial_setup(){
	initialization
}

backup_db(){
	initialization_check
	backup_database
}

# Full backup
backup_all(){
	initialization_check
	backup_database
	packing_data
	configuration
	upload_file
}

# Initialization step
action=$1
# [  -z $1 ] && action=backup
case "$action" in
init)
	initial_setup
	;;
backup)
	backup_all
	;;
db)
	backup_db
	;;
up)
	upload_file
	;;
Restore)
	restore_all
	;;
*)
	echo -e "\n\t\e[1;32mUsage: \e[1;33m./backup.sh init|backup|db|Restore\n\e[0m"
	;;
esac
