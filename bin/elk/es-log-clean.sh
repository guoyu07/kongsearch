#!/bin/bash

ROTATE=10

ES_HOST=192.168.2.42
ES_PORT=9191
DATEPATTERN="[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}"
ENDDATE=`date +%Y-%m-%d -d ''${ROTATE}' days ago'`

for index in `curl $ES_HOST:$ES_PORT/_cat/indices?v | awk '{print $3}'`
do
    if [[ "$index" =~ $DATEPATTERN ]];then
        echo $index
        logdate=`echo $index | sed 's/.*\([0-9]\{4\}-[0-9]\{1,2\}-[0-9]\{1,2\}\)/\1/'`
        t1=`date -d "$logdate" +%s`
        t2=`date -d "$ENDDATE" +%s`
        if [ $t2 -gt $t1 ];then
            echo "delete..."
            curl -XDELETE "${ES_HOST}:${ES_PORT}/${index}/"
        fi
        echo 
    fi
done

curl -XPUT "${ES_HOST}:${ES_PORT}/_settings" -d '{"index" : {"number_of_replicas" : 0}}'
echo 