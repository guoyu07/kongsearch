#!/bin/bash
#author: zhangxinde

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

index=$1
export SPHINX_DISTINDEX=$index

args="--merge-killlists"

deltatype=$2

if [ $# -eq 3 ]; then
  if [ $3 = "--rotate" ] ; then
    rotate="--rotate"
  fi
fi

merge_index() {
    nohup $SPHINX_HOME/bin/indexer -c $SEARCH_HOME/etc/kfz_sphinx.conf --merge $1 $2 $args $3 >> $SEARCH_HOME/logs/mergeindex.log 2>&1 &
}

merge_index_mul() {
    main=$1
    delta=$2
    min=$3
    max=$4
    rotate=$5
    n=$min
    while [ $n -le $max ] 
    do
        if [ $rotate ] ; then
            merge_index ${main}_${n} ${delta}_${n} $rotate
        else
            merge_index ${main}_${n} ${delta}_${n}
        fi
        n=$(($n + 1)) 
        sleep 1
    done
} 

case "${deltatype}@${node}" in
product_m_to_d@local1)
    main="product_daydelta"
    delta="product_mindelta"
    min=0
    max=15
    merge_index_mul "$main" "$delta" $min $max $rotate
    ;;
product_d_to_main@local1)
    main="product"
    delta="product_daydelta"
    min=0
    max=15
    merge_index_mul "$main" "$delta" $min $max $rotate
    ;;
product_m_to_d@hr)
    main="product_daydelta"
    delta="product_mindelta"
    min=0
    max=31
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=0
    max2=7
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@hr)
    main="product"
    delta="product_daydelta"
    min=0
    max=31
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=0
    max2=7
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;

product_m_to_d@tslj)
    main="product_daydelta"
    delta="product_mindelta"
    min=0
    max=5
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=4
    max2=5
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@tslj)
    main="product"
    delta="product_daydelta"
    min=0
    max=5
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=4
    max2=5
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;

product_m_to_d@ybq)
    main="product_daydelta"
    delta="product_mindelta"
    min=6
    max=14
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=2
    max2=3
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@ybq)
    main="product"
    delta="product_daydelta"
    min=6
    max=14
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=2
    max2=3
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;

product_m_to_d@zgkm)
    main="product_daydelta"
    delta="product_mindelta"
    min=15
    max=23
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=0
    max2=1
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@zgkm)
    main="product"
    delta="product_daydelta"
    min=15
    max=23
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=0
    max2=1
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;

product_m_to_d@swk)
    main="product_daydelta"
    delta="product_mindelta"
    min=24
    max=27
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=7
    max2=7
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@swk)
    main="product"
    delta="product_daydelta"
    min=24
    max=27
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=7
    max2=7
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;

product_m_to_d@dy)
    main="product_daydelta"
    delta="product_mindelta"
    min=28
    max=31
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold_daydelta"
    delta2="product_sold_mindelta"
    min2=6
    max2=6
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
product_d_to_main@dy)
    main="product"
    delta="product_daydelta"
    min=28
    max=31
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="product_sold"
    delta2="product_sold_daydelta"
    min2=6
    max2=6
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;



mindelta@hr)
    main="product_daydelta_0"
    delta="product_mindelta_0"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_0"
    delta2="product_sold_mindelta_0"
    merge_index "$main2" "$delta2" $rotate
    ;;

mindelta@tslj)
    main="product_daydelta_0"
    delta="product_mindelta_0"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_0"
    delta2="product_sold_mindelta_0"
    merge_index "$main2" "$delta2" $rotate
    ;;

mindelta@ybq)
    main="product_daydelta_1"
    delta="product_mindelta_1"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_1"
    delta2="product_sold_mindelta_1"
    merge_index "$main2" "$delta2" $rotate
    ;;

mindelta@zgkm)
    main="product_daydelta_2"
    delta="product_mindelta_2"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_2"
    delta2="product_sold_mindelta_2"
    merge_index "$main2" "$delta2" $rotate
    ;;

mindelta@swk)
    main="product_daydelta_3"
    delta="product_mindelta_3"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_3"
    delta2="product_sold_mindelta_3"
    merge_index "$main2" "$delta2" $rotate
    ;;

mindelta@dy)
    main="product_daydelta_4"
    delta="product_mindelta_4"
    merge_index "$main" "$delta" $rotate

    main2="product_sold_daydelta_4"
    delta2="product_sold_mindelta_4"
    merge_index "$main2" "$delta2" $rotate
    ;;


seoproduct_m_to_d@nmw)
    main="seoproduct_daydelta"
    delta="seoproduct_mindelta"
    min=0
    max=3
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="seoproduct_sold_daydelta"
    delta2="seoproduct_sold_mindelta"
    min2=0
    max2=3
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;
seoproduct_d_to_main@nmw)
    main="seoproduct"
    delta="seoproduct_daydelta"
    min=0
    max=3
    merge_index_mul "$main" "$delta" $min $max $rotate

    main2="seoproduct_sold"
    delta2="seoproduct_sold_daydelta"
    min2=0
    max2=3
    merge_index_mul "$main2" "$delta2" $min2 $max2 $rotate
    ;;


unproduct_m_to_d@tslj)
    main="unproduct_daydelta_0"
    delta="unproduct_mindelta_0"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_d_to_main@tslj)
    main="unproduct_0"
    delta="unproduct_daydelta_0"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_m_to_d@ybq)
    main="unproduct_daydelta_1"
    delta="unproduct_mindelta_1"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_d_to_main@ybq)
    main="unproduct_1"
    delta="unproduct_daydelta_1"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_m_to_d@zgkm)
    main="unproduct_daydelta_2"
    delta="unproduct_mindelta_2"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_d_to_main@zgkm)
    main="unproduct_2"
    delta="unproduct_daydelta_2"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_m_to_d@swk)
    main="unproduct_daydelta_3"
    delta="unproduct_mindelta_3"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_d_to_main@swk)
    main="unproduct_3"
    delta="unproduct_daydelta_3"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_m_to_d@dy)
    main="unproduct_daydelta_4"
    delta="unproduct_mindelta_4"
    merge_index "$main" "$delta" $rotate
    ;;
unproduct_d_to_main@dy)
    main="unproduct_4"
    delta="unproduct_daydelta_4"
    merge_index "$main" "$delta" $rotate
    ;;
*)
    echo "Error:Parameters can't identify."
    exit 1
    ;;
esac
 