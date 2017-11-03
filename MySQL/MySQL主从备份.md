## MySQL主从备份原理

### 主从同步两种情况
#### 从0开始
    不需要管了
#### 主库内已有数据
    - 配置主从同步需要锁表，不要让外面再写了，记录binlog，解锁
    - 让已有数据一致（数据拷到从库）
    - 从库根据binlog位置开始同步
### 主库
    1.用户写入数据到数据，同时也会写到binlog文件里(从库要打开binlog才会写)
      - mysql通过读索引文件mysql-index确定写到哪个binlog文件里
      - binlog文件大小：默认1.1G
      - 日志名格式，mysql-bin.00000X
      - binlog只记录更改的内容：insert/update/delete/alter/create/alter
    2.主库创建用于同步的用户 rep@10.0.0.0/24，只赋同步权限
    3.主库有个io线程
 ### 从库
    1.从库有两个线程io,sql
    2.从库有个master.info文件
      - 同步change master 设置io线程连接主库的用户名，密码，binlog位置点
    3.start slave 从库开始同步主库
    4.从库有个relay-log.00000x(和主库的binlog文件类似，也自动切割)，通过relay-index索引

### 主从同步工作过程
    start slave之后，主从开始工作
    1.从库io线程读取master.info,拿到ip，用户名，密码，binglog位置点去连接主库
    2.主库io线程进行验证，验证通过去找binlog文件位置点，向下读取，并发送binlog内容，读到了哪个文件，以及下一个位置点
    3.从库io线程接到返回，把binlog内容写到relay-log里，把位置点写到master.info里
    4.sql线程实时观察relay-log里面是不是有新内容，有就解析成sql语句，按照主库写入的顺序写入到从库里
    
    
## 操作



