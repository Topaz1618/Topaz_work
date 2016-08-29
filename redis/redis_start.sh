#!/bin/bash
. /etc/init.d/functions
Ip="10.0.0.111"
for i in {7000..7005} 
        do
        cd /data/recluster/$i
        rm -f appendonly.aof  dump.rdb  nodes.conf  #目录下残留这几个文件，集群会起不来。
        /usr/local/redis-3.2.0/src/redis-server ./redis.conf 
done
/usr/local/redis-3.2.0/src/redis-trib.rb create --replicas 1 10.0.0.111:7000 10.0.0.111:7001 10.0.0.111:7002 10.0.0.111:7003 10.0.0.111:7004 10.0.0.111:7005
