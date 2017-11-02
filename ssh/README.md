## ssh介绍
	对网络中传输的数据包进行加密
## ssh服务端
### 服务端的两个功能
	SSH服务
 	STFP服务（类似FTP的服务的stfp-server，区别于普通的vsftp，这是加密的,anyway只能系统用户使用）
### 服务端的主要软件
	[root@Topaz ~]# rpm -qa openssh openssl
	openssl-1.0.1e-30.el6.x86_64		#负责加密的
	openssh-5.3p1-104.el6.x86_64		#负责远程连接的
## ssh客户端
	ssh命令（类似crt，xshell）
  	scp 远程安全拷贝
## ssh连接认证类型
### 基于口令的认证（这不是重点）
### 基于秘钥的认证（私钥-留在本地，公钥-发给别人）


