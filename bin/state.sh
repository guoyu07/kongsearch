#!/bin/bash

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

usage() {
    printf 'Usage2: %s INDEX [TYPE] LEVEL [level]\n' "$1"  
    exit 1  
}

if [ $# -lt 1 -o $# -gt 3 ]; then
    usage $0
fi

type=$1

case "${type}" in
  99)
    curl '192.168.1.105:9900/_cat/nodes?v'
    curl '192.168.1.105:9900/_cat/indices?v'
    curl '192.168.1.105:9900/_cat/thread_pool?v'
    ;;
  98)
    curl '192.168.2.19:9800/_cat/nodes?v'
    curl '192.168.2.19:9800/_cat/indices?v'
    curl '192.168.2.19:9800/_cat/thread_pool?v'
    ;;
  97)
    curl '192.168.1.137:9700/_cat/nodes?v'
    curl '192.168.1.137:9700/_cat/indices?v'
    curl '192.168.1.137:9700/_cat/thread_pool?v'
    ;;
  96)
    curl '192.168.1.239:9600/_cat/nodes?v'
    curl '192.168.1.239:9600/_cat/indices?v'
    curl '192.168.1.239:9600/_cat/thread_pool?v'
    ;;
  95)
    curl '192.168.1.105:9500/_cat/nodes?v'
    curl '192.168.1.105:9500/_cat/indices?v'
    curl '192.168.1.105:9500/_cat/thread_pool?v'
    ;;
  94)
    curl '192.168.2.200:9400/_cat/nodes?v'
    curl '192.168.2.200:9400/_cat/indices?v'
    curl '192.168.2.200:9400/_cat/thread_pool?v'
    ;;
  *) 
    usage $0
    ;;
esac