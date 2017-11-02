## 参数
  -p 	#端口号
      ssh -p[port] [user]@[ip]        #远程连接 
      ssh -p[port] [user]@[ip] [命令]  #远程执行命令
  -e	#隧道
  -P  #（scp指定端口用大写）接端口，默认22端口时可以省略-P22
  -r  #递归，表示拷贝目录
  -p  #表示在拷贝前后保持文件或目录属性
  -l  #limit 限制速度
  
 ## scp
    加密安装，两台服务器之间，全量，推送拉取
 ### 推：PUSH
    scp -P22 -rp（p保持属性） /tmp/dog dog@10.0.0.143:/tmp		#全量，并且只能拷目录本身，效率不如rsync，不过第一次拷时他俩是一样的
    rsync：rsync -avz /topaz/ -e 'ssh -p 22' root@10.0.0.137:/topaz/	#增量，效率更高，可以不拷目录本身，只拷目录下文件，目录路径结尾加/，
### 拉：PULL
    scp -P22 -rp root@10.0.0.7:/tmp/dog /opt/
