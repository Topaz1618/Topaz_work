#!/bin/bash
. /etc/init.d/functions				#调用函数，在后面判断是否成功时会调用它里面的模块
[ $# -ne 1 ] && {					#判断：如果参数不等于1
        echo "USAGE:sh $0 ARG"		就提示正确格式
        exit 1						然后退出
}
for n in 138 139					#赋值给多个主机ip，实现批量
do 
        scp -P22 $1 dog@10.0.0.$i:~ &>/dev/null	#执行脚本时传入一个参数给$1,分发$1给多个主机,并且不输出。直接用~，不需要用/home/oldgirl，因为连的是对方的oldgirl
		if [ $? -eq 0 ]				#判断脚本执行是否成功
        then
                action "10.0.0.$i fenfa $1 is ok" /bin/true		#成功的话提示，并调用成功模块
        else
                action "10.0.0.$i fenfa $1 is false" /bin/false	#失败的话提示，并调用失败模块
        fi
done
