## 涉及的线程
    主库：Binglog Dump线程（会一直存活）
    从库：IO线程(对应函数handle_slave_io)、SQL线程
## 涉及到的文件
    主库：mysql-bin.00000X、mysql-bin.index
    从库：relay-log.00000X、master.info
## 主从原理简单版
    start slave之后，主从开始工作
    1.从库io线程读取master.info,拿到ip，用户名，密码，binglog位置点去连接主库
    2.主库binlogdump线程进行验证，验证通过去找binlog文件位置点，向下读取，并发送binlog内容，读到了哪个文件，以及下一个位置点
    3.从库io线程接到返回，把binlog内容写到relay-log里，把位置点写到master.info里
    4.sql线程实时观察relay-log里面是不是有新内容，有就解析成sql语句，按照主库写入的顺序写入到从库里
## 主从原理详细版
    从库start slave之后，主从开始工作
    1.从库io线程请求数据 (交由handle_slave_io()处理,以下是处理流程)：
    	1）my_thread_init()  ==> 线程初始化
    	2）safe_connect() ==> 以标准方式连接到数据库
    	3）register_slave_on_master() ==> 带着slave_id，IP，端口，用户名把自己注册到主库上
    	4）request_dump() ==> 判断是否为GTID(基于全局事务标识符复制)，不是就把master log file和Pos传给主库，请求binlog数据，并执行COM_BINLOG_DUMP命令
    2.主库发送数据  (由dispatch_command() 函数处理，以下是处理流程)
        1）接收到slave的COM_BINLOG_DUMP命令，找到COM_BINLOG_DUMP()，生成一个binlog dump线程
        2）kill_zombie_dump_threads() ==> 重复的slave_id来注册时移除它的binlog dump线程
        3）mysql_binlog_send()	==> 打开文件，根据slave发来的信息在指定位置读取文件，将event按照顺序发给slave(binlog dump线程的活儿)
    3.从库io线程接受数据 （由handle_slave_io()处理，以下是处理流程）
    	1）read_event() ==> 读取event并存放到本地relay log中,等待主库将binlog数据发过来
    	2）queue_event()  ==>  将接收到的event保存在relaylog中
    4.从库sql线程读取&应用日志（ handle_slave_sql()处理，以下是处理流程）
    	1）exec_relay_log_event() 读取 
    		- next_event()     ==> 从cache或者relaylog中读取event
    		- sql_slave_killed() ==> 只要线程未kill则一直执行 
    		- append_item_to_jobs() ==> 发送给workers线程
    	2）handle_slave_worker()应用      #实际是while循环slave_worker_exec_job_group()函数
    		- pop_jobs_item(worker, job_item)	==> 获得具体的event，会阻塞等待
    		- do_apply_event_worker() ==> 调用该函数应用event
    			- do_apply_event()   ==> 利用C++多态性执行对应的event，将不同的 event 操作在备机上重一遍（二进制解析成sql语句）
    PS:在主库一旦有新的binlog日志产生后，发送广播唤醒Binglog Dump线程，Binglog Dump线程在收到广播后，则会读取二进制日志并通过网络向从库传输日志，所以这是一个主库向从库不断推送的过程
## 主从同步中涉及到的文件&线程介绍	
### binlog
    binlog介绍：
    	- mysql通过读索引文件mysql-bin.index确定写到哪个binlog文件里
    	- binlog文件大小：默认1.1G
    	- 日志名格式，mysql-bin.00000X
    	- binlog只记录更改的内容：insert/update/delete/alter/create/alter						
    格式：
    	- binlog是由event组成，event是binlog的逻辑最小单元				
    	- 文件头的头四个字节为BINLOG_MAGIC（fe 62 69 6e）
    	- 紧接着这四个字节的是 descriptor event ： FORMAT_DESCRIPTION_EVENT	#记录了binlog的版本(MySQL 5.0以后binlog 的版本都是4)
    	- 文件的末尾是 log-rotation event: ROTATE_EVENT						#记录了切换到下一个binlog文件的文件名
    	- 这两个event中间是各种不同的event，每个event代表Master上不同的操作					
### relay-log
    - 日志名格式，relay-log.00000x(和主库的binlog文件类似，也自动切割)
    - 通过relay-index索引
### slave io
    slave io线程对应的入口函数为handle_slave_io()，这个函数主要是做了以下三个事情：
    - safe_connect(thd, mysql, mi)	#标准的连接方式连上master MySQL
    - register_slave_on_master(mysql, mi, &suppress_warnings)	#slave把自己的slave_id，IP，端口，用户名提交给Master，用于把自己注册到Master上去
    - request_dump(thd, mysql, mi, &suppress_warnings)			#做判断，如果不是GTID(基于全局事务标识符复制)，把master log file和Pos传给主库，主库根据这些信息发送binlog的event，如果是GTID(全局事务标识符)把本地GITD集合传给master
    - read_event(mysql, mi, &suppress_warnings);		#read_event调用了cli_safe_read()，cli_safe_read()调用了my_net_read()，等待主库将binlog数据发过来，也就是说，read_event被动的从网络中接受主库发过来的信息
### slave sql
    MySQL5.6 之前只会有一个SQL线程，就导致复制延迟，MySQL5.6版本中，提供了基于schema或者说是数据库的并行复制功能，所以它有两个入口
    - handle_slave_sql	#协调器，调用了slave_worker_exec_job，会启动和分配worker线程
    - slave_worker_exec_job的主要功能：
    	pop_jobs_item(worker, job_item); 	#handle_salve_sql()获得具体的event
    	do_apply_event_worker(worker);		#利用c++的多态特性，调用真正的event的do_apply_event，以便将不同的event的操作在本地做一遍	
    - handle_slave_worker	#主要干活的函数				
### master binlog dump 
    MySQL处理各种命令的核心函数为 dispatch_command，里面主要是个switch case 判断语句，根据用户的请求来确定做什么事情
    - COM_REGISTER_SLAVE则调用register_slave(thd, (uchar*)packet, packet_length)注册slave
    - COM_BINLOG_DUMP_GTID 则调用com_binlog_dump_gtid(thd, packet, packet_length);
    - COM_BINLOG_DUMP 则调用com_binlog_dump(thd, packet, packet_length);
    	核心代码为：
    	1）kill_zombie_dump_threads(&slave_uuid);	#如果新的server_id相同的slave注册上来，master会移除跟该slave的server_id匹配的的binlog dump线程
    	2）mysql_binlog_send(thd, thd->strdup(packet + 10), (my_off_t) pos, NULL)	#调用mysql_binlog_send()来打开文件，将文件指针挪到指定位置，读取文件，将一个个的event按照事件顺序发给slave
### event类型
    记录在Log_event_type{}
    Log_event_type { 
    	QUERY_EVENT= 2, 	#用于具体的SQL文本。如果binlog_format=statement方式下，insert，update，delete等各种SQL都是以Query event记录下来的
    	WRITE_ROWS_EVENT = 30,	#insert，update，delete操作的行信息分别以这三种event记录下来
    }

