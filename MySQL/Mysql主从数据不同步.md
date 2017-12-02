## 原因
    1）网络的延迟:由于mysql主从复制是基于binlog的一种异步复制,通过网络传送binlog文件
    2）主从两台机器的负载不一致:由于mysql主从复制是主上面启动1个io线程,而从上面启动1个sql线程和1个io线程,当中任何一台机器的负载很高,忙不过来,导致其中的任何一个线程出现资源不足,都将出现主从不一致的情况;
    3）mysql本身的bug引起的主从不同步;（bug号：#58785 http://chuansong.me/n/366098）
    4）版本不一致,特别是高版本是主,低版本为从的情况下,主上面支持的功能,从上面不支持该功能（什么功能）
    5）max_allowed_packet设置不一致:主上面设置的max_allowed_packet比从大,当一个大的sql语句,能在主上面执行完毕,从上面设置过小,无法执行,导致的主从不一致;
    6）mysql异常宕机:如果未设置sync_binlog=1(默认为0:执行的语句向二进制日志一次不同步到硬盘,性能最好,宕机丢数据多;1:每写一次二进制日志都要与硬盘同步,性能最差,宕机丢数据少)或者innodb_flush_log_at_trx_commit=1(默认为1:每一次事务提交都需要把日志刷新到硬盘,性能差,丢数据少;2:写入缓存,日志每隔一秒刷新到硬盘,性能好,丢数据多)很有可能出现binlog或者relaylog文件出现损坏,导致主从不一致;
## 检查
    1）show slave status查看Slave_IO_Running和Slave_SQL_Running是否为yes，Seconds_Behind_Master是否为0;
    2）在主上面通过show master status查看File和Position跟从上执行show slave status,查看Master_Log_File和Read_Master_Log_Pos是否一致就能够得出;
## 解决
### 方法一：忽略错误后，继续同步
    适用于主从库数据相差不大，或者要求数据可以不完全统一的情况，数据要求不严格的情况				
    stop slave;
    set global sql_slave_skip_counter =1;	#表示跳过一步错误，后面的数字可变
    start slave;
    mysql> show slave status\G  			#查看	
    Slave_IO_Running: Yes
    Slave_SQL_Running: Yes
### 方法二：重新做主从，完全同步
    适用于主从库数据相差较大，或者要求数据完全统一的情况
    mysql> flush tables with read lock;		#先进入主库，进行锁表，防止数据写入，注意：该处是锁定为只读状态
    mysqldump -uroot -p -hlocalhost > mysql.bak.sql	#数据备份
    mysql> show master status;				#查看主库状态
    ok，现在主从同步状态正常了。。。
