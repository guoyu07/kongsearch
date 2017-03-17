#!/bin/bash

SEARCH_HOME=/data/project/kongsearch
SPHINX_HOME=/opt/app/sphinx

source /etc/profile

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

if [ $# -ne 1 -a $# -ne 2 -a $# -ne 3 ]; then
     printf 'Usage: %s INDEX [--rotate]\n' "$0"  
     exit 1
fi

if [ $# -eq 3 ]; then
  if [ $3 = "--rotate" ] ; then
    rotate="--rotate"
  fi
fi

index=$1
export SPHINX_DISTINDEX=$index

indextype=$2

build_index() {
    if [ $# -eq 2 ] ;then
        nohup $SPHINX_HOME/bin/indexer -c $SEARCH_HOME/etc/kfz_sphinx.conf $1 $2  > $SEARCH_HOME/logs/build.log 2>&1 &
    else
        nohup $SPHINX_HOME/bin/indexer -c $SEARCH_HOME/etc/kfz_sphinx.conf $1  > $SEARCH_HOME/logs/build.log 2>&1 &
    fi
}

#arg1=index_name, arg2=index_min, arg3=index_max, arg4=rotate
build_index_obo() {
    name=$1
    min=$2
    max=$3
    rotate=$4
    n=$min
    while [ $n -le $max ] 
    do
        if [ $rotate ] ; then
            build_index ${name}_${n} $rotate
        else
            build_index ${name}_${n}
        fi
        n=$(($n + 1)) 
        sleep 1
    done
} 

case "${indextype}@${node}" in
product_mindelta@local1)
    name="product_mindelta"
    min=0
    max=15
    build_index_obo "$name" $min $max $rotate
    ;;
product_daydelta@local1)
    name="product_daydelta"
    min=0
    max=15
    build_index_obo "$name" $min $max $rotate
    ;;
product_mindelta@hr)
    name="product_mindelta"
    min=0
    max=31
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=0
    max2=7
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@hr)
    name="product_daydelta"
    min=0
    max=31
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=0
    max2=7
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;

product_mindelta@tslj)
    name="product_mindelta"
    min=0
    max=5
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=4
    max2=5
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@tslj)
    name="product_daydelta"
    min=0
    max=5
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=4
    max2=5
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;

product_mindelta@ybq)
    name="product_mindelta"
    min=6
    max=14
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=2
    max2=3
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@ybq)
    name="product_daydelta"
    min=6
    max=14
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=2
    max2=3
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;

product_mindelta@zgkm)
    name="product_mindelta"
    min=15
    max=23
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=0
    max2=1
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@zgkm)
    name="product_daydelta"
    min=15
    max=23
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=0
    max2=1
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;

product_mindelta@swk)
    name="product_mindelta"
    min=24
    max=27
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=7
    max2=7
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@swk)
    name="product_daydelta"
    min=24
    max=27
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=7
    max2=7
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;

product_mindelta@dy)
    name="product_mindelta"
    min=28
    max=31
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_mindelta"
    min2=6
    max2=6
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
product_daydelta@dy)
    name="product_daydelta"
    min=28
    max=31
    build_index_obo "$name" $min $max $rotate

    name2="product_sold_daydelta"
    min2=6
    max2=6
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;


mindelta@hr)
    name="product_mindelta_0"
    build_index "$name" $rotate

    name2="product_sold_mindelta_0"
    build_index "$name2" $rotate
    ;;

mindelta@tslj)
    name="product_mindelta_0"
    build_index "$name" $rotate

    name2="product_sold_mindelta_0"
    build_index "$name2" $rotate
    ;;

mindelta@ybq)
    name="product_mindelta_1"
    build_index "$name" $rotate

    name2="product_sold_mindelta_1"
    build_index "$name2" $rotate
    ;;

mindelta@zgkm)
    name="product_mindelta_2"
    build_index "$name" $rotate

    name2="product_sold_mindelta_2"
    build_index "$name2" $rotate
    ;;

mindelta@swk)
    name="product_mindelta_3"
    build_index "$name" $rotate

    name2="product_sold_mindelta_3"
    build_index "$name2" $rotate
    ;;

mindelta@dy)
    name="product_mindelta_4"
    build_index "$name" $rotate

    name2="product_sold_mindelta_4"
    build_index "$name2" $rotate
    ;;

daydelta@hr)
    name="product_daydelta_0"
    build_index "$name" $rotate

    name2="product_sold_daydelta_0"
    build_index "$name2" $rotate
    ;;

daydelta@tslj)
    name="product_daydelta_0"
    build_index "$name" $rotate

    name2="product_sold_daydelta_0"
    build_index "$name2" $rotate
    ;;

daydelta@ybq)
    name="product_daydelta_1"
    build_index "$name" $rotate

    name2="product_sold_daydelta_1"
    build_index "$name2" $rotate
    ;;

daydelta@zgkm)
    name="product_daydelta_2"
    build_index "$name" $rotate

    name2="product_sold_daydelta_2"
    build_index "$name2" $rotate
    ;;

daydelta@swk)
    name="product_daydelta_3"
    build_index "$name" $rotate

    name2="product_sold_daydelta_3"
    build_index "$name2" $rotate
    ;;

daydelta@dy)
    name="product_daydelta_4"
    build_index "$name" $rotate

    name2="product_sold_daydelta_4"
    build_index "$name2" $rotate
    ;;


seoproduct_mindelta@nmw)
    name="seoproduct_mindelta"
    min=0
    max=3
    build_index_obo "$name" $min $max $rotate

    name2="seoproduct_sold_mindelta"
    min2=0
    max2=3
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
seoproduct_daydelta@nmw)
    name="seoproduct_daydelta"
    min=0
    max=3
    build_index_obo "$name" $min $max $rotate

    name2="seoproduct_sold_daydelta"
    min2=0
    max2=3
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;
seoproduct_dis@nmw)
    name="seoproduct"
    min=0
    max=3
    build_index_obo "$name" $min $max $rotate

    name2="seoproduct_sold"
    min2=0
    max2=3
    build_index_obo "$name2" $min2 $max2 $rotate
    ;;


unproduct_mindelta@tslj)
    name="unproduct_mindelta_0"
    build_index "$name" $rotate
    ;;
unproduct_daydelta@tslj)
    name="unproduct_daydelta_0"
    build_index "$name" $rotate
    ;;
unproduct_mindelta@ybq)
    name="unproduct_mindelta_1"
    build_index "$name" $rotate
    ;;
unproduct_daydelta@ybq)
    name="unproduct_daydelta_1"
    build_index "$name" $rotate
    ;;
unproduct_mindelta@zgkm)
    name="unproduct_mindelta_2"
    build_index "$name" $rotate
    ;;
unproduct_daydelta@zgkm)
    name="unproduct_daydelta_2"
    build_index "$name" $rotate
    ;;
unproduct_mindelta@swk)
    name="unproduct_mindelta_3"
    build_index "$name" $rotate
    ;;
unproduct_daydelta@swk)
    name="unproduct_daydelta_3"
    build_index "$name" $rotate
    ;;
unproduct_mindelta@dy)
    name="unproduct_mindelta_4"
    build_index "$name" $rotate
    ;;
unproduct_daydelta@dy)
    name="unproduct_daydelta_4"
    build_index "$name" $rotate
    ;;
*)
    build_index --all $rotate
    ;;
 esac
