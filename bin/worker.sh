#!/bin/bash

PHP=/opt/app/php/bin/php
HOME=/data/project/kongsearch

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

usage() {
    printf 'Usage1: %s \n' "$1"
    printf 'Usage2: %s start\n' "$1"
    printf 'Usage3: %s {stop|restart} SERVER\n' "$1"
    exit 1  
}

if [ $# -gt 2 ]; then
    usage $0
fi

action=$1
server=$2

if [ $# -eq 0 ]; then
    $PHP $HOME/tool/manageIndexUpdateWorker.php
else
    $PHP $HOME/tool/manageIndexUpdateWorker.php -a $action -i $server
fi
