#!/bin/bash

log=/data/kongsearch_logs/indexupdate.log
PHP=/opt/app/php/bin/php
HOME=/data/project/kongsearch
WORKNUM=25
date=$(date -d "today" +"%Y-%m-%d %H:%M:%S") 
if [ $SPHINX_ENV -a $SPHINX_ENV = 'local' ]; then
  REDIS=127.0.0.1:6379
  REDIS_SPIDER=127.0.0.1:6379
  CONF=$HOME/conf/indexupdateES_local.ini
  CONF_ERROR=$HOME/conf/indexupdateES_error_local.ini
  CONF_SPIDER=$HOME/conf/indexupdateES_spider_local.ini
  CONF_ERROR_SPIDER=$HOME/conf/indexupdateES_error_spider_local.ini
  OPTIMIZE_IP=127.0.0.1
  OPTIMIZE_PORT=9800
  OPTIMIZE_IP_SPIDER=127.0.0.1
  OPTIMIZE_PORT_SPIDER=9700
  WORKNUM=1
  ENV=local
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  REDIS=192.168.2.152:6369
  REDIS_SPIDER=192.168.2.152:6359
  CONF=$HOME/conf/indexupdateES_neibu.ini
  CONF_ERROR=$HOME/conf/indexupdateES_error_neibu.ini
  CONF_SPIDER=$HOME/conf/indexupdateES_spider_neibu.ini
  CONF_ERROR_SPIDER=$HOME/conf/indexupdateES_error_spider_neibu.ini
  OPTIMIZE_IP=192.168.2.152
  OPTIMIZE_PORT=9800
  OPTIMIZE_IP_SPIDER=192.168.2.152
  OPTIMIZE_PORT_SPIDER=9700
  WORKNUM=1
  ENV=neibu
else 
  REDIS=192.168.2.130:6379
  CONF=$HOME/conf/indexupdateES.ini
  CONF_ERROR=$HOME/conf/indexupdateES_error.ini
  OPTIMIZE_IP=192.168.2.19
  OPTIMIZE_PORT=9800

  REDIS_SPIDER=192.168.2.28:6379
  CONF_SPIDER=$HOME/conf/indexupdateES_spider.ini
  CONF_ERROR_SPIDER=$HOME/conf/indexupdateES_error_spider.ini
  OPTIMIZE_IP_SPIDER=192.168.1.137
  OPTIMIZE_PORT_SPIDER=9700

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
    printf 'Usage1: %s {start|stop|restart} INDEX\n' "$1"
    printf 'Usage2: %s {redo|retry|start-rebuild|stop-rebuild} INDEX TYPE\n' "$1"  
    exit 1  
}

if [ $# -lt 1 -o $# -gt 4 ]; then
    usage $0
fi

index=$2
type=$3
if [ $# -eq 4 ]; then
    REDIS=$4
fi

if [ "$index" = 'endauction' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6359
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'message' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.105
        OPTIMIZE_PORT=9500
        WORKNUM=5
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6359
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'booklog' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.105
        OPTIMIZE_PORT=9900
        WORKNUM=5
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6369
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9900
        WORKNUM=1
    fi
fi

if [ "$index" = 'footprint_shop' -o "$index" = 'footprint_pm' -o "$index" = 'footprint_searchword' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.200:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.2.200
        OPTIMIZE_PORT=9400
        WORKNUM=3
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6479
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'shop_recommend' -o "$index" = 'get_shop_recommend' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.201:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.2.200
        OPTIMIZE_PORT=9400
        WORKNUM=15
        if [ "$index" = 'get_shop_recommend' ]; then
            WORKNUM=1
        fi
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6479
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'searchlog' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
        WORKNUM=3
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6479
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'orders_shop_recommend' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.200:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.2.200
        OPTIMIZE_PORT=9400
        WORKNUM=10
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6479
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'member' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
        WORKNUM=5
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6359
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'booklib' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
        WORKNUM=3
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6359
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'auctioncom' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
        WORKNUM=1
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6369
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

if [ "$index" = 'shufang' ]; then
    if [ "$ENV" = 'online' ]; then
        REDIS=192.168.2.28:6379
        CONF=$HOME/conf/indexupdateES_common.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common.ini
        OPTIMIZE_IP=192.168.1.68
        OPTIMIZE_PORT=9600
        WORKNUM=1
    elif [ "$ENV" = 'neibu' ]; then
        REDIS=192.168.2.152:6369
        CONF=$HOME/conf/indexupdateES_common_neibu.ini
        CONF_ERROR=$HOME/conf/indexupdateES_error_common_neibu.ini
        OPTIMIZE_IP=192.168.2.152
        OPTIMIZE_PORT=9800
    fi
fi

echo $date >> $log

case "$1" in
start)
    echo "start indexupdateES service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF -i $index" -c start -n $WORKNUM -p $PHP
    ;;
stop)
    echo "stop indexupdateES service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF -i $index" -c stop -n $WORKNUM -p $PHP -s 1
    ;;
restart)
    echo "restart indexupdateES service." >> $log
    cd $HOME
    source /etc/profile
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF -i $index" -c restart -n $WORKNUM -p $PHP -s 1
    ;;
redo)
    echo "redo index: $index $type" >> $log
    echo "redo index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o redo -r $REDIS -u admin
    ;;
retry)
    echo "retry index: $index $type" >> $log
    echo "retry index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o retry -r $REDIS -u admin
    ;;
start-rebuild)
    echo "start rebuild index: $index $type" >> $log
    echo "start rebuild index: $index $type" 
    $PHP $HOME/indexEStool.php -i $index -t $type -o start-rebuild -r $REDIS -u admin
    ;;
stop-rebuild)
    echo "stop rebuild index: $index $type" >> $log
    echo "stop rebuild index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o stop-rebuild -r $REDIS -u admin
    ;;
optimize)
    echo "start optimize index: $index" >> $log
    echo "start optimize index: $index"
    $PHP $HOME/estool.php -i $index -o optimize -x $OPTIMIZE_IP -y $OPTIMIZE_PORT
    ;;
refresh)
    echo "start refresh index: $index" >> $log
    echo "start refresh index: $index"
    $PHP $HOME/estool.php -i $index -o refresh -x $OPTIMIZE_IP -y $OPTIMIZE_PORT
    ;;
resend_start)
    echo "start indexupdateES service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF_ERROR -i $index" -c start -n 1 -p $PHP
    ;;
start_spider)
    echo "start indexupdateESSpider service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF_SPIDER -i $index" -c start -n $WORKNUM -p $PHP
    ;;
stop_spider)
    echo "stop indexupdateESSpider service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF_SPIDER -i $index" -c stop -n $WORKNUM -p $PHP -s 1
    ;;
restart_spider)
    echo "restart indexupdateESSpider service." >> $log
    cd $HOME
    source /etc/profile
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF_SPIDER -i $index" -c restart -n $WORKNUM -p $PHP -s 1
    ;;
redo_spider)
    echo "redo spider index: $index $type" >> $log
    echo "redo spider index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o redo -r $REDIS_SPIDER -u admin
    ;;
retry_spider)
    echo "retry spider index: $index $type" >> $log
    echo "retry spider index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o retry -r $REDIS_SPIDER -u admin
    ;;
start-rebuild_spider)
    echo "start rebuild spider index: $index $type" >> $log
    echo "start rebuild spider index: $index $type" 
    $PHP $HOME/indexEStool.php -i $index -t $type -o start-rebuild -r $REDIS_SPIDER -u admin
    ;;
stop-rebuild_spider)
    echo "stop rebuild spider index: $index $type" >> $log
    echo "stop rebuild spider index: $index $type"
    $PHP $HOME/indexEStool.php -i $index -t $type -o stop-rebuild -r $REDIS_SPIDER -u admin
    ;;
optimize_spider)
    echo "start optimize spider index: $index" >> $log
    echo "start optimize spider index: $index"
    $PHP $HOME/estool.php -i $index -o optimize -x $OPTIMIZE_IP_SPIDER -y $OPTIMIZE_PORT_SPIDER
    ;;
refresh_spider)
    echo "start refresh spider index: $index" >> $log
    echo "start refresh spider index: $index"
    $PHP $HOME/estool.php -i $index -o refresh -x $OPTIMIZE_IP_SPIDER -y $OPTIMIZE_PORT_SPIDER
    ;;
resend_start_spider)
    echo "start indexupdateESSpider service." >> $log
    cd $HOME
    $PHP $HOME/gearworkctl.php -w  $HOME/indexupdateES.php -o "-c $CONF_ERROR_SPIDER -i $index" -c start -n 1 -p $PHP
    ;;
   *) 
    usage $0
    ;;
 esac
