#VPS数据备份及数据库备份

####初始配置
```sh 
curl "https://raw.githubusercontent.com/jalena/vps-backup/master/backup.sh" -O backup.sh 
chmod +x backup.sh
./backup.sh init
```

####使用方法
```sh
Usage: ./backup.sh init|backup|db|Restore
```

####备份数据如下
* `/home/wwwroot`目录下所有站点目录（支持init配置备份目录），排除phpMyadmin
* mysql全部数据库（排除的表：`mysql`、`performance_schema`、`information_schema`）
* `/usr/local/nginx/conf/vhost` 全部文件

####支持一键恢复
```Bash 
./backup.sh Restore
```
