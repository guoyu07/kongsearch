#!/bin/bash
#author: liuxingzhi@2014.3

SEARCH_HOME=/data/project/kongsearch
SPHINX_HOME=/opt/app/sphinx

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

if [ $SPHINX_NODE ]; then
    node=$SPHINX_NODE
    echo "Notice: Current Sphinx Node is $node"
else
    echo "Error: this machine isn't Sphinx Node."
    exit 1
fi

if [ $# -ne 2 ]; then
     printf 'Usage: %s {start|stop|restart} INDEX\n' "$0"  
     exit 1
fi

cmd=$1
index=$2
export SPHINX_DISTINDEX=$index

case "$cmd" in
start)
    $SPHINX_HOME/bin/searchd -c $SEARCH_HOME/etc/kfz_sphinx.conf
    ;;
stop)
    $SPHINX_HOME/bin/searchd -c $SEARCH_HOME/etc/kfz_sphinx.conf --stop
    ;;
restart)
    $SPHINX_HOME/bin/searchd -c $SEARCH_HOME/etc/kfz_sphinx.conf --stop
    sleep 8
    $SPHINX_HOME/bin/searchd -c $SEARCH_HOME/etc/kfz_sphinx.conf
    ;;
*)
    printf 'Usage: %s {start|stop|restart} INDEX\n' "$0"  
    exit 1
    ;;
esac
