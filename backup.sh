#!/bin/bash
 
# Author: Jalena
# Website: //jalena.bcsytv.com/archives/1099

# function
MYSQL_USER="root"
MYSQL_PASS="password"
BACK_DIR="backup"
 
# Create backup directory
if [ -d $BACK_DIR ] ;
   then
	rm -rf ~/$BACK_DIR/*
   else	
	mkdir -p "$BACK_DIR"
fi
 
# Enter the backup directory
cd $BACK_DIR
 
# Backup all database tables
# Use the (sed -e '/table/d') command to exclude unnecessary tables
for db in $(mysql -u$MYSQL_USER -p$MYSQL_PASS -B -N -e 'SHOW DATABASES' |sed -e '/schema/d' -e '/mysql/d')
    do
	mysqldump -u$MYSQL_USER -p$MYSQL_PASS ${db} | gzip -9 - > ${db}.sql.gz
done
 
# Pack all database tables
tar -zcf mysql_$(date +%Y%m%d).tar.gz *.sql.gz --remove-files

# Packing site data
for web in $(ls -1 /home/wwwroot |sed -e '/php/d')
    do
	tar -zcPf ${web}_$(date +%Y%m%d).tar.gz /home/wwwroot/$web/
done
 
# Package the Nginx configuration file
tar -zcPf nginx_$(date +%Y%m%d).tar.gz /usr/local/nginx/conf/vhost
 
# Upload data
for file in $(find *.tar.gz | grep $)
do
#	scp -P 28879 ${file} 111.222.333.444:/root/backup/${file}
	sh ~/dropbox_uploader.sh upload ${file} $(date +%Y%m%d)/${file}
done
 
exit 0
