# VPS数据备份及数据库备份

<h3>使用方法</h3>
curl "https://raw.githubusercontent.com/jalena/vps-backup/master/backup.sh" -O backup.sh && chmod +x backup.sh && ./backup.sh init
Usage: ./backup.sh init|backup|db|Restore

<h3>备份数据如下</h3>
<ol>
<li>/home/wwwroot目录下所有站点目录（支持init配置备份目录），排除phpMyadmin</li>
<li>mysql全部数据库（排除的表：mysql、performance_schema、information_schema）</li>
<li>/usr/local/nginx/conf/vhost 全部文件</li>
</ol>

<h3>支持一键恢复</h3>
./backup.sh Restore
