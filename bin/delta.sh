#!/bin/bash
#author: zhangxinde

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

num=`ps -ef | grep "delta.sh" | grep -v grep | grep -v vim | grep -v vi | wc -l`
if [ $num -gt 3 ]; then
  echo delta.sh is still alive. The num is $num
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

  for var in 6 7 8 9 10
  do
    count2=`ps -ef | grep "${name}" | grep -v "grep" | grep -v "vim" | wc -l`
    if [ $count2 -gt 0 ]; then
      echo sleep $sec second the $var time, the $name thread is still alive
      sleep $sec
    else
      break
    fi
  done

  for var in 11 12 13 14 15
  do
    count3=`ps -ef | grep "${name}" | grep -v "grep" | grep -v "vim" | wc -l`
    if [ $count3 -gt 0 ]; then
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
cmdtype=$2

if [ $SPHINX_ENV -a $SPHINX_ENV = 'local' ]; then
  DISTCONF="$SEARCH_HOME/etc/${index}_distindex_local.ini"
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  DISTCONF="$SEARCH_HOME/etc/${index}_distindex_neibu.ini"
else 
  DISTCONF="$SEARCH_HOME/etc/${index}_distindex.ini"
fi

case "${index}@${node}" in
product@hr)
    ip="192.168.1.91"
    port="9307"
    ;;
product@tslj)
    ip="192.168.1.68"
    port="9307"
    ;;
product@ybq)
    ip="192.168.1.239"
    port="9307"
    ;;
product@zgkm)
    ip="192.168.1.83"
    port="9307"
    ;;
product@swk)
    ip="192.168.1.66"
    port="9307"
    ;;
product@dy)
    ip="192.168.1.115"
    port="9307"
    ;;

unproduct@tslj)
    ip="192.168.1.68"
    port="9308"
    ;;
unproduct@ybq)
    ip="192.168.1.239"
    port="9308"
    ;;
unproduct@zgkm)
    ip="192.168.1.83"
    port="9308"
    ;;
unproduct@swk)
    ip="192.168.1.66"
    port="9308"
    ;;
unproduct@dy)
    ip="192.168.1.115"
    port="9308"
    ;;

seoproduct@nmw)
    ip="192.168.1.103"
    port="9307"
    ;;
*)
    echo "Error."
    exit 1
    ;;
esac

case "${cmdtype}@${index}" in
product_m_to_d@product)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Truncate product_mindelta Tables."
    $PHP $SEARCH_HOME/tool/deltaTool.php -a truncateMin -c $DISTCONF -t product -l $SEARCH_HOME/logs/deltaTool.log
    sleep 1
    check_ok deltaTool.php 3
    echo "(2).    Gather Product Delta."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/gatherdelta.sh product
    sleep 1
    check_ok delta.php 5
    echo "(3).    Build product_mindelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh product product_mindelta --rotate
    sleep 1
    check_ok indexer 8
    echo "(4).    Merge product_mindelta To product_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/mergeindex.sh product product_m_to_d --rotate
    check_ok indexer 8
    ;;
product_d_to_main@product)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Merge product_daydelta To product_main Index."
    sh $SEARCH_HOME/bin/mergeindex.sh product product_d_to_main --rotate
    sleep 1
    check_ok indexer 60
    echo "(2).    Build product_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh product product_daydelta --rotate
    check_ok indexer 8
    ;;
product_delta@product)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Truncate product_mindelta Tables."
    $PHP $SEARCH_HOME/tool/deltaTool.php -a truncateMin -c $DISTCONF -t product -l $SEARCH_HOME/logs/deltaTool.log
    sleep 1
    check_ok deltaTool.php 3
    echo "(2).    Gather Product Delta."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/gatherdelta.sh product
    sleep 1
    check_ok delta.php 5
    echo "(3).    Build product_mindelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh product mindelta --rotate
    sleep 1
    check_ok indexer 8
    echo "(4).    Merge product_mindelta To product_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/mergeindex.sh product mindelta --rotate
    check_ok indexer 8
    ;;

seoproduct_m_to_d@seoproduct)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Truncate seoproduct_mindelta Tables."
    $PHP $SEARCH_HOME/tool/deltaTool.php -a truncateMin -c $DISTCONF -t seoproduct -l $SEARCH_HOME/logs/deltaTool.log
    sleep 1
    check_ok deltaTool.php 3
    echo "(2).    Gather SeoProduct Delta."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/gatherdelta.sh seoproduct
    sleep 1
    check_ok delta.php 5
    echo "(3).    Build seoproduct_mindelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh seoproduct seoproduct_mindelta --rotate
    sleep 1
    check_ok indexer 8
    echo "(4).    Merge seoproduct_mindelta To seoproduct_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/mergeindex.sh seoproduct seoproduct_m_to_d --rotate
    check_ok indexer 8
    ;;
seoproduct_d_to_main@seoproduct)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Merge seoproduct_daydelta To seoproduct_main Index."
    sh $SEARCH_HOME/bin/mergeindex.sh seoproduct seoproduct_d_to_main --rotate
    sleep 1
    check_ok indexer 60
    echo "(2).    Build seoproduct_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh seoproduct seoproduct_daydelta --rotate
    check_ok indexer 8
    ;;


unproduct_m_to_d@unproduct)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Truncate unproduct_mindelta Tables."
    $PHP $SEARCH_HOME/tool/deltaTool.php -a truncateMin -c $DISTCONF -t unproduct -l $SEARCH_HOME/logs/deltaTool.log
    sleep 1
    check_ok deltaTool.php 3
    echo "(2).    Gather unproduct Delta."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/gatherdelta.sh unproduct
    sleep 1
    check_ok delta.php 5
    echo "(3).    Build unproduct_mindelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh unproduct unproduct_mindelta --rotate
    sleep 1
    check_ok indexer 8
    echo "(4).    Merge unproduct_mindelta To unproduct_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/mergeindex.sh unproduct unproduct_m_to_d --rotate
    check_ok indexer 8
    ;;
unproduct_d_to_main@unproduct)
    echo "---------- Checking The Searchd Process. ----------"
    is_searchd $ip $port 0
    echo "(1).    Merge unproduct_daydelta To unproduct_main Index."
    sh $SEARCH_HOME/bin/mergeindex.sh unproduct unproduct_d_to_main --rotate
    sleep 1
    check_ok indexer 60
    echo "(2).    Build unproduct_daydelta Index."
    is_searchd $ip $port 1
    sh $SEARCH_HOME/bin/buildindex.sh unproduct unproduct_daydelta --rotate
    check_ok indexer 8
    ;;
*)
    echo "Error:Parameters can't identify."
    exit 1
    ;;
esac