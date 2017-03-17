#!/bin/bash

log=/data/project/kongsearch/logs/indexupdate.log
PHP=/opt/app/php/bin/php
HOME=/data/project/kongsearch
WORKNUM=4
date=$(date -d "today" +"%Y-%m-%d %H:%M:%S") 
if [ $SPHINX_ENV -a $SPHINX_ENV = 'local' ]; then
  JOBSERVER=127.0.0.1:4730
  REDIS=127.0.0.1:6379
  CONF=$HOME/conf/indexupdate_local.ini
  ENV=local
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  JOBSERVER=192.168.2.152:4730
  REDIS=192.168.2.152:6379
  CONF=$HOME/conf/indexupdate_neibu.ini
  ENV=neibu
else 
  JOBSERVER=192.168.1.132:4730
  REDIS=192.168.1.137:6379
  CONF=$HOME/conf/indexupdate.ini
  ENV=online
fi

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

usage() {
    printf 'Usage1: %s {start|stop|restart}\n' "$1"
    printf 'Usage2: %s {redo|retry|start-rebuild|stop-rebuild} INDEX [TYPE]\n' "$1"  
    exit 1  
}

if [ $# -lt 1 -o $# -gt 3 ]; then
    usage $0
fi

index=$2
type=$index
if [ $# -eq 3 ]; then
    type=$3
fi

if [ "$index" = 'product' ]; then
  type='shop'
fi

if [ "$index" = 'product_sold' ]; then
  type='shopsold'
fi

if [ "$index" = 'endauction' ]; then
    if [ "$ENV" = 'online' ]; then
        JOBSERVER=192.168.1.124:4730
        REDIS=192.168.1.137:6379
        CONF=$HOME/conf/indexupdate_endauction.ini
    fi
fi

echo $date >> $log

case "$1" in
start)
    echo "start indexupdate service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdate.php -o "-c $CONF" -c start -n $WORKNUM -p $PHP
    ;;
stop)
    echo "stop indexupdate service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdate.php -o "-c $CONF" -c stop -n $WORKNUM -p $PHP
    ;;
restart)
    echo "restart indexupdate service." >> $log
    cd $HOME
    source /etc/profile
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdate.php -o "-c $CONF" -c restart -n $WORKNUM -p $PHP
    ;;
redo)
    echo "redo index: $index $type" >> $log
    echo "redo index: $index $type"
    $PHP $HOME/indextool.php -i $index -o redo -j $JOBSERVER -r $REDIS -u admin -t $type -s 1  
    if [ "$index" = 'product' ]; then
      index='product_sold'
      type='shopsold'
      echo "redo index: $index $type" >> $log
      echo "redo index: $index $type"
      $PHP $HOME/indextool.php -i $index -o redo -j $JOBSERVER -r $REDIS -u admin -t $type -s 1  
    fi
    ;;
retry)
    echo "retry index: $index $type" >> $log
    echo "retry index: $index $type"
    $PHP $HOME/indextool.php -i $index -o retry -j $JOBSERVER -r $REDIS -u admin -t $type -s 1
    if [ "$index" = 'product' ]; then
      index='product_sold'
      type='shopsold'
      echo "retry index: $index $type" >> $log
      echo "retry index: $index $type"
      $PHP $HOME/indextool.php -i $index -o retry -j $JOBSERVER -r $REDIS -u admin -t $type -s 1  
    fi
    ;;
start-rebuild)
    echo "start rebuild index: $index $type" >> $log
    echo "start rebuild index: $index $type" 
    $PHP $HOME/indextool.php -i $index -o rebuild-start -j $JOBSERVER -r $REDIS -u admin -t $type -s 1
    if [ "$index" = 'product' ]; then
      index='product_sold'
      type='shopsold'
      echo "start rebuild index: $index $type" >> $log
      echo "start rebuild index: $index $type"
      $PHP $HOME/indextool.php -i $index -o rebuild-start -j $JOBSERVER -r $REDIS -u admin -t $type -s 1  
    fi
    ;;
stop-rebuild)
    echo "stop rebuild index: $index $type" >> $log
    echo "stop rebuild index: $index $type"
    $PHP $HOME/indextool.php -i $index -o rebuild-stopped -j $JOBSERVER -r $REDIS -u admin -t $type -s 1
    if [ "$index" = 'product' ]; then
      index='product_sold'
      type='shopsold'
      echo "stop rebuild index: $index $type" >> $log
      echo "stop rebuild index: $index $type"
      $PHP $HOME/indextool.php -i $index -o rebuild-stopped -j $JOBSERVER -r $REDIS -u admin -t $type -s 1  
    fi
    ;;
   *) 
    usage $0
    ;;
 esac
