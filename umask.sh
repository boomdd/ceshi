#!/bin/bash
check_root(){
if [[ -z `id | awk -F "=" '{print $2}' | cut -d "(" -f1 ` ]]
then
        echo "user must root"
	exit 0
else
        echo "OK,active user root"
fi
}
check_ok(){
if [ $? != 0 ]
then
	echo "shell is wrong see error log"
	exit 0
fi
}
check_root

#备份基线修改umask-24
echo "修改系统umask,以做好备份"
sleep 3

list=`ls /etc/profile /etc/bashrc /etc/csh.login /etc/csh.cshrc /root/.bashrc /root/.cshrc`
for i in $list
do
	cp -p $i $i\_`date +%F`
	a=`grep "^umask" $i`
	num=`grep -n "^umask" $i | awk -F ":" '{print $1}' `
if [ "$a" == "umask 027" ]
then
	echo "已经配置umask" $i
elif [ "$a" != "mask 027" ] & [ ! -z "$num" ]  
then
	sed -i "${num}s/$a/umask 027/g" $i	
else	
	echo "写入umask 027 >> $i"
#	echo "if you don't please ctrl+c"
	echo umask 027 >> $i

fi
done
check_ok

sleep 5

#备份基线检查是否记录帐户登录日志-33 与检查是否记录su日志-40
echo "rsyslog.conf文件与syslog.conf文件的配置,以做好备份"
sleep 3

if [ `grep -o '[0-9]' /etc/redhat-release | head -n1` -le 6 ]
then
        echo "系统版本是6以下的"
	cp -p /etc/syslog.conf /etc/syslog.conf_`date +%F`
	echo "authpriv.* /var/log/authlog" >> /etc/syslog.conf && echo "加载authpriv.*策略到authlog"
	echo "auth.info	/var/log/authlog" >> /etc/syslog.conf  && echo "加载auth.info策略到authlog"
	service syslog restart
else
        echo "系统版本是6以上的"
	cp -p /etc/rsyslog.conf /etc/rsyslog.conf_`date +%F`
	echo "authpriv.* /var/log/authlog" >> /etc/rsyslog.conf
	echo "auth.info /var/log/authlog" >> /etc/rsyslog.conf
	service rsyslog restart
fi
check_ok

sleep 5

#备份基线防syn攻击优化检查主机访问控制-26
echo "查看hosts文件的信息"
sleep 3

if [ `grep -Ev "^#|^$" /etc/hosts.allow | wc -l` -eq 0 ]
then
        echo "/etc/hosts.allow 需要修改配置文件，添加可访问IP"
else
        echo "/etc/hosts.allow,已经有`cat /etc/hosts.allow | grep sshd | wc -l`相关配置"
fi
if [ `grep -Ev "^#|^$" /etc/hosts.deny | wc -l` -eq 0 ]
then
        echo "/etc/hosts.deny 需要修改配置文件，添加拒绝IP"
else
        echo "/etc/hosts.deny 已经有`grep -v "#" /etc/hosts.deny | wc -l`相关配置"
fi

check_ok


#备份基线检查是否删除或锁定无关账号-7
echo "修改无用用户锁定与无法登录任何服务"
sleep 3

cp -p /etc/passwd /etc/passwd_`date +%F`
userlist=`grep -E 'lp|nobody|uucp|games|rpm|smmsp|nfsnobody' /etc/passwd | awk -F : '{print $1}'`
for user in $userlist
do
        sed -i "/$user/ {s/\/bin\/bash/\/bin\/false/g;}" /etc/passwd
        sed -i "/$user/ {s/\/sbin\/nologin/\/bin\/false/g;}" /etc/passwd
                if [ `grep lp /etc/passwd | awk -F : '{ print $NF }'` == "/bin/false" ]
                then
                        echo "$user 用户已经无法登录任何服务与机器"
                else
                        echo "$user 用户更改错误"
                fi
        echo "由于必须要有密码才能锁定用户，脚本自动修改密码为各个用户"
        echo $user | passwd --stdin $user && passwd -l $user  &> /dev/null
        echo "$user 用户已经被锁定"
done


#备份基线检查口令锁定策略-45
echo "修改口令锁定策略"
sleep 3

cp -p /etc/pam.d/system-auth /etc/pam.d/system-auth_`date +%F`
systemauth=`grep -n '^auth' /etc/pam.d/system-auth | tail -n 1 | awk -F : '{ print $1 }'`
sed -i "$systemauth a\auth      required        pam_tally2.so   deny=6 onerr=fail no_magic_root unlock_time=120" /etc/pam.d/system-auth
if [ $systemauth -le `grep -n '^auth' /etc/pam.d/system-auth | tail -n 1 | awk -F : '{ print $1 }' ` ]
then
        echo "成功加载策略到system-auth文件"
else
        echo "加载策略失败"
if
check_ok

#备份基线检查FTP配置-限制用户FTP登录

Check_ftpusers2(){
if [ -f /etc/vsftpd.conf ]
then
	FTPCONF="/etc/vsftpd.conf"
elif [ -f /etc/vsftpd/vsftpd.conf ]
then
	FTPCONF="/etc/vsftpd/vsftpd.conf"
else
   echo "/etc/vsftpd.conf or /etc/vsftpd/vsftpd.conf is not exist,scripts exit now"
   return 0
fi
}

