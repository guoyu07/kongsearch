#!/bin/bash
#author: zhangxinde

SEARCH_HOME=/data/project/kongsearch
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
    echo "Notice: Current Search Node is $node"
else
    echo "Error: this machine isn't Search Node."
    exit 1
fi

num=`ps -ef | grep "deltaES.sh" | grep -v grep | grep -v vim | grep -v vi | wc -l`
if [ $num -gt 3 ]; then
  echo deltaES.sh is still alive. The num is $num
  exit 1
fi

check_ok() {
  name=$1
  sec=$2
  for var in 1 2 3 4 5
  do
    count=`ps -ef | grep "${name}" | grep -v "grep" | grep -v "vim" | wc -l`
    if [ $count -gt 0 ]; then
      echo sleep $sec second the $var time, the $name thread is still alive
      sleep $sec
    else
      break
    fi
  done

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

is_root

index=$1

case "$index" in
product)
    echo "---------- Checking The Delta Process. ----------"
    check_ok deltaES.php 60
    echo "    Gather Product Elastic Delta."
    sleep 1
    sh $SEARCH_HOME/bin/gatherdeltaES.sh product
    ;;
*)
    echo "Error:Parameters can't identify."
    exit 1
    ;;
esac