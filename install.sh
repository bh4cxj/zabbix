#!/bin/bash

rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent

cd /usr/share/doc/zabbix-server-mysql-`zabbix_server -V | head -1 | cut -d" " -f3`
expect << EOF
spawn zcat create.sql.gz | mysql -uroot zabbix -p
expect "password: "
send "zabbix"
expect eof
EOF

mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak
cat > /etc/zabbix/zabbix_server.conf << EOF
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
EOF

service zabbix-server start

sed -i 's/# php_value date.timezone Europe\/Riga/php_value date.timezone Asia\/Shanghai/' /etc/httpd/conf.d/zabbix.conf
sed -i 's/Listen 80/Listen 9000/' /etc/httpd/conf/httpd.conf
systemctl start httpd
