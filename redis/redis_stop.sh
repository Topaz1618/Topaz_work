#!/bin/bash
Ip="10.0.0.111"
Redis="/usr/local/redis-3.2.0/src"
for i in {7004..7005}
        do
        $Redis/redis-cli  -h $Ip -p $i shutdown
done
