#!/bin/bash
#this create bytopaz
#date: 2016-7-29

################int################
Rsync_proc=`netstat -lntup|grep rsync|wc -l`
Check_rpm=`rpm -qa rsync|wc -l`
Rsync_user=rsync_backup
Password="123456"
Password_file=/etc/rsync.password


################Check Rsync################
[ -f /etc/init.d/functions ]&& . /etc/init.d/functions
[ $Rsync_proc -ne 0 ]&&{
action "/var/run/rsyncd.pid: File exists" /bin/false
exit 1
}

################Rsync yum################
if [ $Check_rpm -eq 1 ]
then
 action "Package rsync already installed and latest version" /bin/false
else
 echo "YUM INSTALL RSYNC..."
 yum -y install rsync >>/tmp/rsync_install.log &&\
 echo ==================`date +%F`=================== >>/tmp/rsync_install.log &&\
 [ $? -eq 0 ] && action "Complete!" /bin/true
fi

################Rsync configure################
if [ ! -f /etc/rsyncd.conf ]
then
cat >/etc/rsyncd.conf <<EOF 
 #Rsync server
 ##rsyncd.conf start##
 uid = rsync
 gid = rsync
 use chroot = no
 max connections = 200
 timeout = 600
 pid file = /var/run/rsyncd.pid
 lock file = /var/run/rsync.lock
 log file = /var/log/rsyncd.log
 ignore errors
 read only = false
 list = false
 hosts allow = 192.168.0.0/24
 hosts deny = 0.0.0.0/32
 auth users = $Rsync_user
 secrets file = $Password_file
 #####################################
 [backup]
 path = /Release/rsync
EOF
 [ $? -eq 0 ] && action "configure is Complete" /bin/true
 fi

################Create################
rsync --daemon && action "rsync --daemon is success!!" /bin/true
[ ! -f /Release/rsync ] && /bin/mkdir /Release/rsync
id rsync &>/dev/null
if [ $? -eq 1 ]
then
 useradd rsync -s /sbin/nologin -M &&\
 action "useradd 'rsync' is ok" /bin/true
else
 action "useradd: user 'rsync' already exists" /bin/false
fi
echo "$Rsync_user:$Password" >$Password_file &&\
chmod 600 $Password_file &&\
chown -R rsync.rsync /Release/rsync &&\
action "Welcome to the Rsync!!" /bin/true

#####（对，客户端的配置，写在了这里。只有两步操作：配权限和写个只有密码的文件）#########
#ll /etc/rsync.password 
#-rw------- 1 root root 7 Jul 29 10:07 /etc/rsync.password
#cat /etc/rsync.password 
#123456

