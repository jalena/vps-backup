#! /bin/bash

#===============================================================================================
#   System Required:  CentOS6.x (32bit/64bit)
#   Description: Server backup and restore script
#   Author: Jalena <jalena@bcsytv.com>
#   Intro:  https://jalena.bcsytv.com/archives/1358
#===============================================================================================

# Initialize the database of account information
function initialization(){
	if [[ ! -e '/root/.my.cnf' ]]; then
		echo -e "\033[032mPlease enter the MySQL user:"
		read -p "(Default user: root):" MYSQL_USER
		[[ -z "$MYSQL_USER" ]] && MYSQL_USER="root"
	    read -p "(Please enter the MySQL password:)" MYSQL_PASS
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
		echo -e "\033[032mDefault web Path: /home/wwwroot"
		read -p "(Please enter the web Path:)" WEB_PATH
			[[ -z $WEB_PATH ]] && WEB_PATH="/home/wwwroot"
		echo -e "\033[032mnginx configuration path: /usr/local/nginx/conf/vhost"
		read -p "Please enter the nginx configuration path:" NGINX_PATH
			[[ -z $NGINX_PATH ]] && NGINX_PATH="/usr/local/nginx/conf/vhost"
	    echo -e "---------------------------"
	    echo -e "Backup directory = $WEB_PATH"
	    echo -e "nginx directory = $NGINX_PATH"
	    echo -e "---------------------------"
cat > /root/.backup.option<<EOF
WEB_PATH=$WEB_PATH
NGINX_PATH=$NGINX_PATH
EOF
	fi
}

function initialization_check(){
	if [[ -e '/root/.backup.option' ]]; then
		. .backup.option
	else
		echo -e "Not initialized, Please enter: \033[032m./backup.sh init"
		exit 1
	fi

	if [[ -d '/root/backup' ]]; then
		cd /root/backup
	else
		mkdir -p "/root/backup"
		cd /root/backup
	fi
	
	if [[ ! -e '/root/.my.cnf' ]]; then
		echo -e "Not initialized, Please enter: \033[032m./backup.sh init"
		exit 1
	fi
}

# Backup all database tables
function backup_database(){
	for db in $(mysql -B -N -e 'SHOW DATABASES' |sed -e '/schema/d' -e '/mysql/d')
		do
			mysqldump ${db} | gzip -9 - > ${db}.sql.gz
	done

	# Pack all database tables
	tar zcf mysql_$(date +%Y%m%d).tar.gz *.sql.gz --remove-files
}
 
# Packing site data
function packing_data(){
	for web in $(ls -1 ${WEB_PATH} |sed -e '/phpMy/d')
	do
		tar zcPf ${web}_$(date +%Y%m%d).tar.gz /home/wwwroot/$web
	done
}

# package the nginx configuration file
function configuration(){
	nginx_cnf='find / -name nginx.conf |grep -v root'
	tar cPf nginx_$(date +%Y%m%d).tar.gz $NGINX_PATH
	tar rPf nginx_$(date +%Y%m%d).tar.gz $nginx_cnf
}

# Upload data
function upload_file(){
	# Upload data
	for file in $(find *.tar.gz | grep $)
		do
			#scp ${file} root@23.239.196.3:/root/backup/${file}
			#sh /root/dropbox_uploader.sh upload ${file} backup/${file}
			echo -e package ${file} ok! 
	done
}

# Restore all data
function restore_all(){
	initialization_check

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
function initial_setup(){
	initialization
}

function backup_db(){
	initialization_check
	backup_database
}

# Full backup
function backup_all(){
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
Restore)
    restore_all
    ;;
*)
    echo "Usage: ./backup.sh init|backup|db|Restore"
    ;;
esac
