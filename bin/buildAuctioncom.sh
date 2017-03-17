#!/bin/bash
#author: liguizhi
#exec:nohup bash buildAuctioncom.sh auctioncom > /data/project/kongsearch/logs/autoBuildAuctioncom.log 2>&1 &

SEARCH_HOME=/data/project/kongsearch
SPHINX_HOME=/opt/app/sphinx
PHP=/opt/app/php/bin/php

source /etc/profile

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

if [ $SPHINX_NODE ]; then
    node=$SPHINX_NODE
    echo "Notice: Current Sphinx Node is $node"
else
    echo "Error: this machine isn't Sphinx Node."
    exit 1
fi

num=`ps -ef | grep "buildAuctioncom.sh" | grep -v grep | grep -v vim | grep -v vi | wc -l`
if [ $num -gt 3 ]; then
  echo buildAuctioncom.sh is still alive. The num is $num
  exit 1
fi

is_searchd() {
  ip=$1
  port=$2
  checktype=$3
  if [ $checktype -eq 0 ]; then
    count=`netstat -tlnp | grep "${ip}:${port}" | wc -l`
    if [ $count -lt 1 ]; then
      echo The Searchd $ip:$port Is Down.
      exit 1
    fi
  else
    while [ 1 ]
    do
      count=`netstat -tlnp | grep "${ip}:${port}" | wc -l`
      if [ $count -lt 1 ];then
        echo The Searchd $ip:$port Is Down.Sleep 10 second.
        sleep 10
      else
        break
      fi
    done
  fi
}

check_ok() {
  name=$1

  while [ 1 ]
  do
    count=`ps -ef | grep "${name}" | grep -v "grep" | grep -v "vim" | wc -l`
    if [ $count -gt 0 ];then
      echo $name is still alive.
      sleep 10
    else
      echo $name is finish.
      break
    fi
  done
}

truncateDb(){
    type=$1
    if [ $type = 'zxd' ] ;then
        mysql -u sphinx -h192.168.2.152 -P 3306 -psphinx123321 search < /data/project/kongsearch/conf/auctioncom.sql
    else
        mysql -u sphinx -h192.168.1.137 -P 3306 -psphinx123321 search < /data/project/kongsearch/conf/auctioncom.sql
    fi
}

is_root

index=$1

case "${index}@${node}" in
auctioncom@zxd)
    ip="192.168.2.152"
    port="9310"
    ;;
auctioncom@ts)
    ip="192.168.1.132"
    port="9310"
    ;;
*)
    echo "Error."
    exit 1
    ;;
esac

echo "(1).    Truncate search tables." $(date '+%F %T')
truncateDb $node
sleep 1
echo "(2).    Gather data."$(date '+%F %T')
sh $SEARCH_HOME/bin/gather.sh auctioncom
sleep 1
check_ok gather.php
echo "(3).    Build auctioncom Index."$(date '+%F %T')
is_searchd $ip $port 1
sh $SEARCH_HOME/bin/buildindex.sh auctioncom auctioncom --rotate
sleep 1
check_ok indexer
echo "(4).    Finish buildindex."$(date '+%F %T')
