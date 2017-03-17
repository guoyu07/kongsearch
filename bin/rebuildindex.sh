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

check_ok() {
  if [ $? -ne 0 ]; then
    exit 1
  fi
}

is_root

if [ $# -ne 2 ]; then
  printf 'Usage: %s {start|build|stop} INDEX\n' "$0"  
  exit 1
fi

cmd=$1
index=$2

case "$cmd" in
start)
  mysql -u sphinx -h taishanglaojun -P 3306 -psphinx123321 search < $SEARCH_HOME/conf/${index}.sql
  check_ok
  sh $SEARCH_HOME/bin/indexupdate.sh restart
  sh $SEARCH_HOME/bin/indexupdate.sh start-rebuild $index
  ssh taishanglaojun "export SPHINX_NODE=tslj; sh $SEARCH_HOME/bin/gather.sh $index"
  check_ok
  ssh yuebuqun "export SPHINX_NODE=ybq; sh $SEARCH_HOME/bin/gather.sh $index"
  check_ok
  ssh zhugekongming "export SPHINX_NODE=zgkm; sh $SEARCH_HOME/bin/gather.sh $index"
  check_ok
#  ssh sunwukong "export SPHINX_NODE=swk; sh $SEARCH_HOME/bin/gather.sh $index"
  ssh tangseng "export SPHINX_NODE=ts; sh $SEARCH_HOME/bin/gather.sh $index"
  check_ok
  ssh duanyu "export SPHINX_NODE=dy; sh $SEARCH_HOME/bin/gather.sh $index"
  check_ok
  ;;
build)
  if [ "$index" = 'orders' ]; then
    ssh taishanglaojun "export SPHINX_NODE=tslj; sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
    ssh sunwukong      "export SPHINX_NODE=swk;  sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
  elif [ "$index" = 'product' ]; then 
    ssh taishanglaojun "export SPHINX_NODE=tslj; sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
    ssh sunwukong      "export SPHINX_NODE=swk;  sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
    ssh zhugekongming  "export SPHINX_NODE=zgkm; sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
    ssh yuebuqun       "export SPHINX_NODE=ybq;  sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
    ssh duanyu         "export SPHINX_NODE=dy;   sh $SEARCH_HOME/bin/buildindex.sh $index $index --rotate"
  else
    echo "ERROR: no support index."
    exit
  fi
  ;;
stop)
  sh $SEARCH_HOME/bin/indexupdate.sh stop-rebuild $index
  sh $SEARCH_HOME/bin/indexupdate.sh redo $index
  sh $SEARCH_HOME/bin/indexupdate.sh redo $index
  sh $SEARCH_HOME/bin/indexupdate.sh redo $index
  ;;
  *)
  printf 'Usage: %s {start|build|stop} INDEX\n' "$0"  
  ;;
esac
