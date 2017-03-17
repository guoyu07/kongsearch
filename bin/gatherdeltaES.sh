#!/bin/bash
#author: zhangxinde

GATHER_HOME=/data/project/kongsearch
PHP=/opt/app/php/bin/php
KONGSEARCH_LOG_HOME=/data/kongsearch_logs

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

if [ $# -ne 1 ]; then
     printf 'Usage: %s INDEX\n' "$0"  
     exit 1
fi

index=$1

if [ $SPHINX_ENV -a $SPHINX_ENV = 'local' ]; then
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES_delta_local.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES_delta_local.ini"
  fi
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES_delta_neibu.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES_delta_neibu.ini"
  fi
else 
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES_delta.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES_delta.ini"
  fi
fi

start_gather_productDelta() {
    itemA1="item_[1-25] item_[102-105] item_[121-125] item_[10019-10023] item_[10031-10040] item_10001 item_10003 item_10007 item_10012"
    itemA2="item_[26-50] item_[106-110] item_[126-130] item_[10015-10016] item_[10024-10030] item_10002 item_10005 item_10011"
    itemB1="item_[51-75] item_[111-115] item_[131-135] item_101 item_10006 item_10008 item_10014"
    itemB2="item_[76-100] item_[116-120] item_[136-140] item_[10009-10010] item_10004 item_10013 item_10017 item_10018"
    saledItemA1="saledItem_[1-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[10031-10040] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012"
    saledItemA2="saledItem_[26-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011"
    saledItemB1="saledItem_[51-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014"
    saledItemB2="saledItem_[76-100] saledItem_[116-120] saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018"

    case "$1" in
    shop1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[1-8]" -l $KONGSEARCH_LOG_HOME/ES_delta1.log > /dev/null 2>&1 &
    ;;
    shop2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[9-16]" -l $KONGSEARCH_LOG_HOME/ES_delta2.log  > /dev/null 2>&1 &
    ;;
    shop3)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[17-24]" -l $KONGSEARCH_LOG_HOME/ES_delta3.log > /dev/null 2>&1  &
    ;;
    shop4)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[25-32]" -l $KONGSEARCH_LOG_HOME/ES_delta4.log  > /dev/null 2>&1 &
    ;;
    shop5)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[33-36]" -l $KONGSEARCH_LOG_HOME/ES_delta5.log > /dev/null 2>&1  &
    ;;
    shop6)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[41-46]" -l $KONGSEARCH_LOG_HOME/ES_delta6.log  > /dev/null 2>&1 &
    ;;
    shop7)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[49-52]" -l $KONGSEARCH_LOG_HOME/ES_delta7.log  > /dev/null 2>&1 &
    ;;
    shop8)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[57-64]" -l $KONGSEARCH_LOG_HOME/ES_delta8.log  > /dev/null 2>&1 &
    ;;
    shop9)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[65-68]" -l $KONGSEARCH_LOG_HOME/ES_delta9.log  > /dev/null 2>&1 &
    ;;
    shop10)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[73-76]" -l $KONGSEARCH_LOG_HOME/ES_delta10.log  > /dev/null 2>&1 &
    ;;
    shop11)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[81-88]" -l $KONGSEARCH_LOG_HOME/ES_delta11.log  > /dev/null 2>&1 &
    ;;
    shop12)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[89-94]" -l $KONGSEARCH_LOG_HOME/ES_delta12.log  > /dev/null 2>&1 &
    ;;
    shop13)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[97-100]" -l $KONGSEARCH_LOG_HOME/ES_delta13.log  > /dev/null 2>&1 &
    ;;
    shop14)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[105-110]" -l $KONGSEARCH_LOG_HOME/ES_delta14.log  > /dev/null 2>&1 &
    ;;
    shop15)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[113-120]" -l $KONGSEARCH_LOG_HOME/ES_delta15.log  > /dev/null 2>&1 &
    ;;
    shop16)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[121-128]" -l $KONGSEARCH_LOG_HOME/ES_delta16.log  > /dev/null 2>&1 &
    ;;
    shop17)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[129-136]" -l $KONGSEARCH_LOG_HOME/ES_delta17.log  > /dev/null 2>&1 &
    ;;
    shop18)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[137-140]" -l $KONGSEARCH_LOG_HOME/ES_delta18.log  > /dev/null 2>&1 &
    ;;
    shop19)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10001-10008]" -l $KONGSEARCH_LOG_HOME/ES_delta19.log  > /dev/null 2>&1 &
    ;;
    shop20)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10009-10016]" -l $KONGSEARCH_LOG_HOME/ES_delta20.log  > /dev/null 2>&1 &
    ;;
    shop21)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10017-10024]" -l $KONGSEARCH_LOG_HOME/ES_delta21.log  > /dev/null 2>&1 &
    ;;
    shop22)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10025-10032]" -l $KONGSEARCH_LOG_HOME/ES_delta22.log  > /dev/null 2>&1 &
    ;;
    shop23)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10033-10040]" -l $KONGSEARCH_LOG_HOME/ES_delta23.log  > /dev/null 2>&1 &
    ;;
    shop24)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[53-56]" -l $KONGSEARCH_LOG_HOME/ES_delta24.log  > /dev/null 2>&1 &
    ;;
    shop25)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[77-80]" -l $KONGSEARCH_LOG_HOME/ES_delta25.log  > /dev/null 2>&1 &
    ;;
    shop26)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[37-40]" -l $KONGSEARCH_LOG_HOME/ES_delta26.log  > /dev/null 2>&1 &
    ;;
    shop27)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[69-72]" -l $KONGSEARCH_LOG_HOME/ES_delta27.log  > /dev/null 2>&1 &
    ;;
    shop28)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[101-104]" -l $KONGSEARCH_LOG_HOME/ES_delta28.log  > /dev/null 2>&1 &
    ;;
    shop29)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[47-48] item_[111-112] item_[95-96]" -l $KONGSEARCH_LOG_HOME/ES_delta29.log  > /dev/null 2>&1 &
    ;;
    shopsold_a1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemA1" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_a1.log  > /dev/null 2>&1 &
    ;;
    shopsold_a2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemA2" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_a2.log  > /dev/null 2>&1 &
    ;;
    shopsold_b1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemB1" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_b1.log  > /dev/null 2>&1 &
    ;;
    shopsold_b2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemB2" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_b2.log  > /dev/null 2>&1 &
    ;;
    bookstall_a1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemA1" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_a1.log  > /dev/null 2>&1 &
    ;;
    bookstall_a2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemA2" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_a2.log  > /dev/null 2>&1 &
    ;;
    bookstall_b1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemB1" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_b1.log  > /dev/null 2>&1 &
    ;;
    bookstall_b2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemB2" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_b2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemA1" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_a1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemA2" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_a2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemB1" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_b1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemB2" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_b2.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_productDelta_less_process() {
    itemA="item_[1-25] item_[102-105] item_[121-125] item_[10019-10023] item_[10031-10040] item_10001 item_10003 item_10007 item_10012 item_[26-50] item_[106-110] item_[126-130] item_[10015-10016] item_[10024-10030] item_10002 item_10005 item_10011 item_[141-190] item_[10041-10069]"
    itemB="item_[51-75] item_[111-115] item_[131-135] item_101 item_10006 item_10008 item_10014 item_[76-100] item_[116-120] item_[136-140] item_[10009-10010] item_10004 item_10013 item_10017 item_10018 item_[191-260] item_[10070-10120]"
    saledItemA="saledItem_[1-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[10031-10040] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[26-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[141-190] saledItem_[10041-10069]"
    saledItemB="saledItem_[51-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[76-100] saledItem_[116-120] saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[191-260] saledItem_[10070-10120]"

    case "$1" in
    shop1)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[1-20] item_[141-150] item_[231-240]" -l $KONGSEARCH_LOG_HOME/ES_delta1.log > /dev/null 2>&1 &
    ;;
    shop2)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[21-40] item_[151-160] item_[241-250]" -l $KONGSEARCH_LOG_HOME/ES_delta2.log  > /dev/null 2>&1 &
    ;;
    shop3)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[41-60] item_[161-170] item_[251-260]" -l $KONGSEARCH_LOG_HOME/ES_delta3.log > /dev/null 2>&1  &
    ;;
    shop4)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[61-80] item_[171-180] item_[10041-10050]" -l $KONGSEARCH_LOG_HOME/ES_delta4.log  > /dev/null 2>&1 &
    ;;
    shop5)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[81-100] item_[181-190] item_[10051-10060]" -l $KONGSEARCH_LOG_HOME/ES_delta5.log > /dev/null 2>&1  &
    ;;
    shop6)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[101-120] item_[191-200] item_[10061-10075]" -l $KONGSEARCH_LOG_HOME/ES_delta6.log  > /dev/null 2>&1 &
    ;;
    shop7)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[121-140] item_[201-210] item_[10076-10090]" -l $KONGSEARCH_LOG_HOME/ES_delta7.log  > /dev/null 2>&1 &
    ;;
    shop8)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10001-10020] item_[211-220] item_[10091-10105]" -l $KONGSEARCH_LOG_HOME/ES_delta8.log  > /dev/null 2>&1 &
    ;;
    shop9)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shop  -p "item_[10021-10040] item_[221-230] item_[10106-10120]" -l $KONGSEARCH_LOG_HOME/ES_delta9.log  > /dev/null 2>&1 &
    ;;
    shopsold_a)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemA" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_a.log  > /dev/null 2>&1 &
    ;;
    shopsold_b)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t shopsold  -p "$saledItemB" -l $KONGSEARCH_LOG_HOME/ES_delta_shopsold_b.log  > /dev/null 2>&1 &
    ;;
    bookstall_a)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemA" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_a.log  > /dev/null 2>&1 &
    ;;
    bookstall_b)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstall  -p "$itemB" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstall_b.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemA" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_a.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b)
      nohup $PHP $GATHER_HOME/deltaES.php -c $CONF -t bookstallsold  -p "$saledItemB" -l $KONGSEARCH_LOG_HOME/ES_delta_bookstallsold_b.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

case "${index}@${node}" in
#  product@tslj)
#    b=1
#    while [ $b -le 6 ]
#    do
#        start_gather_productDelta "shop${b}"
#        b=$(($b + 1))
#        sleep 1
#    done
#
#    for data in shopsold_a1 shopsold_a2
#    do
#        start_gather_productDelta $data
#        sleep 1
#    done 
#    ;;
#  product@ybq)
#    b=7
#    while [ $b -le 12 ]
#    do
#        start_gather_productDelta "shop${b}"
#        b=$(($b + 1))
#        sleep 1
#    done
#
#    for data in shopsold_b1 shopsold_b2
#    do
#        start_gather_productDelta $data
#        sleep 1
#    done 
#    ;;
#  product@zgkm)
#    b=13
#    while [ $b -le 18 ]
#    do
#        start_gather_productDelta "shop${b}"
#        b=$(($b + 1))
#        sleep 1
#    done
#
#    for data in bookstall_a1 bookstall_a2
#    do
#        start_gather_productDelta $data
#        sleep 1
#    done 
#    ;;
#  product@swk)
#    b=19
#    while [ $b -le 24 ]
#    do
#        start_gather_productDelta "shop${b}"
#        b=$(($b + 1))
#        sleep 1
#    done
#
#    for data in bookstall_b1 bookstallsold_a1 bookstall_b2
#    do
#        start_gather_productDelta $data
#        sleep 1
#    done 
#    ;;
#  product@dy)
#    b=25
#    while [ $b -le 29 ]
#    do
#        start_gather_productDelta "shop${b}"
#        b=$(($b + 1))
#        sleep 1
#    done
#
#    for data in bookstallsold_b1 bookstallsold_a2 bookstallsold_b2
#    do
#        start_gather_productDelta $data
#        sleep 1
#    done 
#    ;;

  product@tslj)
    start_gather_productDelta_less_process "shop1"
    sleep 1
    start_gather_productDelta_less_process "shop6"
    sleep 1
    start_gather_productDelta_less_process "shopsold_b"
    sleep 1
    ;;
  product@ybq)
    start_gather_productDelta_less_process "shop2"
    sleep 1
    start_gather_productDelta_less_process "shop7"
    sleep 1
    start_gather_productDelta_less_process "bookstall_a"
    sleep 1
    ;;
  product@zgkm)
    start_gather_productDelta_less_process "shop3"
    sleep 1
    start_gather_productDelta_less_process "shop8"
    sleep 1
    start_gather_productDelta_less_process "bookstall_b"
    sleep 1
    ;;
  product@swk)
    start_gather_productDelta_less_process "shop4"
    sleep 1
    start_gather_productDelta_less_process "shop9"
    sleep 1
    start_gather_productDelta_less_process "bookstallsold_a"
    sleep 1
    ;;
  product@dy)
    start_gather_productDelta_less_process "shop5"
    sleep 1
    start_gather_productDelta_less_process "shopsold_a"
    sleep 1
    start_gather_productDelta_less_process "bookstallsold_b"
    sleep 1
    ;;

  product_sold@tslj)
    start_gather_productDelta_less_process "shopsold_b"
    sleep 1
    ;;
  product_sold@ybq)
    start_gather_productDelta_less_process "shopsold_a"
    sleep 1
    ;;
  product_sold@zgkm)
    start_gather_productDelta_less_process "bookstallsold_a"
    sleep 1
    ;;
  product_sold@swk)
    ;;
  product_sold@dy)
    start_gather_productDelta_less_process "bookstallsold_b"
    sleep 1
    ;;

  *) 
    printf 'Usage: %s INDEX\n' "$0"  
    exit 1
    ;;
 esac
