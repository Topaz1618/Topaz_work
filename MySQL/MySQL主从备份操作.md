## MySQL主从备份
### 主从 my.cnf 配置
    修改port与master不同	==> port=3307 port=3308
    修改servver-id与master不同 ==> server-id=1 server-id=2
    修改datadir与master不同 ==> datadir = /application/master/data/Data  datadir = /application/slave/data/Data 
    从库只读设置==> mysql>set global read_only=1;  #read_only=1只读模式，可以限定普通用户进行数据修改的操作，但不会限定具有super权限的用户（如超级管理员root用户）的数据修改操作
### 主从同步两种情况
#### 从0开始
    直接导入就ok
#### 主库内已有数据
    - 配置主从同步需要锁表，不要让外面再写了，记录binlog后就可以解锁
    - 让已有数据一致（数据拷到从库）
    - 从库根据binlog位置开始同步
    
## 操作
### 修改server-id
    [root@test ~]# egrep "log-bin|server-id" /data/3306/my.cnf 	#主库开log-bin
    log-bin = /data/3306/mysql-bin								
    server-id = 1											#所有server-id实例都不能一样
    [root@test ~]# egrep "log-bin|server-id" /data/3307/my.cnf 
    #log-bin = /data/3307/mysql-bin
    server-id = 3
    
### 主库操作
    mysql> show variables;		#主库查看数据库配置的参数，相当于my.cnf，但是更多
    mysql> show variables like "log_bin";	
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | log_bin       | ON    |
    +---------------+-------+
    mysql> show variables like "server_id";
    +---------------+-------+
    | Variable_name | Value |
    +---------------+-------+
    | server_id     | 1     |
    +---------------+-------+
    mysql> grant replication slave on *.* to 'rep'@'10.0.0.%' identified by 'dog123';	#授权所有库所有表10.0.0.网段rep用户才能过来连，密码dog123
    mysql> flush privileges;
    mysql> select user,host from mysql.user ;	#查看是否创建
    mysql> show grants for rep@'10.0.0.%';		#第二种方式查看是否创建
    mysql> flush table with read lock;			#锁表
    mysql> create database ll；					#锁表效果，不能写了，但是可以读
    ERROR 1223 (HY000): Can't execute the query because you have a conflicting read lock
    mysql> show master status;					#锁表就要记录这个
    +------------------+----------+--------------+------------------+
    | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
    +------------------+----------+--------------+------------------+
    | mysql-bin.000002 |      484 |              |                  |
    +------------------+----------+--------------+------------------+
    1 row in set (0.00 sec)
    mysqldump -uroot -pdog123 -S /data/3306/mysql.sock -A -B|gzip>/opt/bak_$(date +%F).sql.gz
    mysql> unlock tables;						#解锁
    
    
### 从库操作
    [root@test ~]# mysql -uroot -pdog123 -S /data/3306/mysql.sock </opt/bak_2015-10-21.sql 
    #了解下binlog
    [root@test ~]# ll /data/3306/			#000001就是binlog日志
    -rw-rw---- 1 mysql mysql  264 Oct 21 16:27 mysql-bin.000001
    -rw-rw---- 1 mysql mysql   84 Oct 21 20:54 mysql-bin.index	#index是binlog的索引，mysql通过这个索引才能读到这些文件
    [root@test ~]# cat /data/3306/mysql-bin.index 	#index内容
    /data/3306/mysql-bin.000001
    /data/3306/mysql-bin.000002
    /data/3306/mysql-bin.000003
    [root@test ~]# mysqlbinlog /data/3306/mysql-bin.000001 	#二进制文件，cat查看不了，要用mysqlbinlog，它是把binlog翻译成sql语句的工具
    /*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
    /*!40019 SET @@session.max_insert_delayed_threads=0*/;
    /*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
    DELIMITER /*!*/;
    [root@test data]# mysql -S 3307/mysql.sock -uroot -pdog123	#连接数据库，配置master.info内容
    CHANGE MASTER TO  	
    MASTER_HOST='10.0.0.141', 
    MASTER_PORT=3307,
    MASTER_USER='rep', 
    MASTER_PASSWORD='dog123', 
    MASTER_LOG_FILE='mysql-bin.000002',
    MASTER_LOG_POS=484;
    [root@test 3307]# cat data/master.info 	#可以看到有master.info了，查看下内容
    18
    mysql-bin.000002
    484
    10.0.0.141
    rep
    dog123
    3306 
    60
    0
    0
    1800.000
    0
    [root@test 3307]# ls		可以看到也有中继日志了
    relay-bin.000001  relay-bin.index
    mysql> start slave;			开启
    mysql> show slave status\G;	#查看状态
    			Slave_IO_State: Waiting for master to send event	#状态
                Slave_IO_Running: Yes		#io线程
    			Slave_SQL_Running: Yes		#sql线程
    			Seconds_Behind_Master: 0	#从库落后主库的秒数，延迟时间，这个时间，和那两个yes，都是将来要监控的，在主库人为写个时间戳，然后再主库看能不能读到
    #完成之后创建删除数据库测试			
    
    
    
    
