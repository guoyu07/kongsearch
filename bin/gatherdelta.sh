#!/bin/bash
#author: zhangxinde

GATHER_HOME=/data/project/kongsearch
PHP=/opt/app/php/bin/php

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
  CONF="$GATHER_HOME/conf/${index}_delta_local.ini"
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  CONF="$GATHER_HOME/conf/${index}_delta_neibu.ini"
else 
  CONF="$GATHER_HOME/conf/${index}_delta.ini"
fi

start_gather_product() {
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
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[1-8]" -l $GATHER_HOME/logs/delta1.log > /dev/null 2>&1 &
    ;;
    shop2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[9-16]" -l $GATHER_HOME/logs/delta2.log  > /dev/null 2>&1 &
    ;;
    shop3)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[17-24]" -l $GATHER_HOME/logs/delta3.log > /dev/null 2>&1  &
    ;;
    shop4)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[25-32]" -l $GATHER_HOME/logs/delta4.log  > /dev/null 2>&1 &
    ;;
    shop5)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[33-36]" -l $GATHER_HOME/logs/delta5.log > /dev/null 2>&1  &
    ;;
    shop6)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[41-46]" -l $GATHER_HOME/logs/delta6.log  > /dev/null 2>&1 &
    ;;
    shop7)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[49-52]" -l $GATHER_HOME/logs/delta7.log  > /dev/null 2>&1 &
    ;;
    shop8)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[57-64]" -l $GATHER_HOME/logs/delta8.log  > /dev/null 2>&1 &
    ;;
    shop9)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[65-68]" -l $GATHER_HOME/logs/delta9.log  > /dev/null 2>&1 &
    ;;
    shop10)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[73-76]" -l $GATHER_HOME/logs/delta10.log  > /dev/null 2>&1 &
    ;;
    shop11)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[81-88]" -l $GATHER_HOME/logs/delta11.log  > /dev/null 2>&1 &
    ;;
    shop12)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[89-94]" -l $GATHER_HOME/logs/delta12.log  > /dev/null 2>&1 &
    ;;
    shop13)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[97-100]" -l $GATHER_HOME/logs/delta13.log  > /dev/null 2>&1 &
    ;;
    shop14)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[105-110]" -l $GATHER_HOME/logs/delta14.log  > /dev/null 2>&1 &
    ;;
    shop15)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[113-120]" -l $GATHER_HOME/logs/delta15.log  > /dev/null 2>&1 &
    ;;
    shop16)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[121-128]" -l $GATHER_HOME/logs/delta16.log  > /dev/null 2>&1 &
    ;;
    shop17)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[129-136]" -l $GATHER_HOME/logs/delta17.log  > /dev/null 2>&1 &
    ;;
    shop18)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[137-140]" -l $GATHER_HOME/logs/delta18.log  > /dev/null 2>&1 &
    ;;
    shop19)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[10001-10008]" -l $GATHER_HOME/logs/delta19.log  > /dev/null 2>&1 &
    ;;
    shop20)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[10009-10016]" -l $GATHER_HOME/logs/delta20.log  > /dev/null 2>&1 &
    ;;
    shop21)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[10017-10024]" -l $GATHER_HOME/logs/delta21.log  > /dev/null 2>&1 &
    ;;
    shop22)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[10025-10032]" -l $GATHER_HOME/logs/delta22.log  > /dev/null 2>&1 &
    ;;
    shop23)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[10033-10040]" -l $GATHER_HOME/logs/delta23.log  > /dev/null 2>&1 &
    ;;
    shop24)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[53-56]" -l $GATHER_HOME/logs/delta24.log  > /dev/null 2>&1 &
    ;;
    shop25)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[77-80]" -l $GATHER_HOME/logs/delta25.log  > /dev/null 2>&1 &
    ;;
    shop26)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[37-40]" -l $GATHER_HOME/logs/delta26.log  > /dev/null 2>&1 &
    ;;
    shop27)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[69-72]" -l $GATHER_HOME/logs/delta27.log  > /dev/null 2>&1 &
    ;;
    shop28)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[101-104]" -l $GATHER_HOME/logs/delta28.log  > /dev/null 2>&1 &
    ;;
    shop29)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shop  -p "item_[47-48] item_[111-112] item_[95-96]" -l $GATHER_HOME/logs/delta29.log  > /dev/null 2>&1 &
    ;;
    shopsold_a1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopsold  -p "$saledItemA1" -l $GATHER_HOME/logs/delta_shopsold_a1.log  > /dev/null 2>&1 &
    ;;
    shopsold_a2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopsold  -p "$saledItemA2" -l $GATHER_HOME/logs/delta_shopsold_a2.log  > /dev/null 2>&1 &
    ;;
    shopsold_b1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopsold  -p "$saledItemB1" -l $GATHER_HOME/logs/delta_shopsold_b1.log  > /dev/null 2>&1 &
    ;;
    shopsold_b2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopsold  -p "$saledItemB2" -l $GATHER_HOME/logs/delta_shopsold_b2.log  > /dev/null 2>&1 &
    ;;
    bookstall_a1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "$itemA1" -l $GATHER_HOME/logs/delta_bookstall_a1.log  > /dev/null 2>&1 &
    ;;
    bookstall_a2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "$itemA2" -l $GATHER_HOME/logs/delta_bookstall_a2.log  > /dev/null 2>&1 &
    ;;
    bookstall_b1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "$itemB1" -l $GATHER_HOME/logs/delta_bookstall_b1.log  > /dev/null 2>&1 &
    ;;
    bookstall_b2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "$itemB2" -l $GATHER_HOME/logs/delta_bookstall_b2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstallsold  -p "$saledItemA1" -l $GATHER_HOME/logs/delta_bookstallsold_a1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstallsold  -p "$saledItemA2" -l $GATHER_HOME/logs/delta_bookstallsold_a2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstallsold  -p "$saledItemB1" -l $GATHER_HOME/logs/delta_bookstallsold_b1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstallsold  -p "$saledItemB2" -l $GATHER_HOME/logs/delta_bookstallsold_b2.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}


start_gather_unproduct() {
    itemA1="item_[1-25] item_[102-105] item_[121-125] item_[10019-10023] item_[10031-10040] item_10001 item_10003 item_10007 item_10012 item_[50001-50025]"
    itemA2="item_[26-50] item_[106-110] item_[126-130] item_[10015-10016] item_[10024-10030] item_10002 item_10005 item_10011 item_[50026-50050]"
    itemB1="item_[51-75] item_[111-115] item_[131-135] item_101 item_10006 item_10008 item_10014 item_[50051-50075]"
    itemB2="item_[76-100] item_[116-120] item_[136-140] item_[10009-10010] item_10004 item_10013 item_10017 item_10018 item_[50076-50100]"
    saledItemA1="saledItem_[1-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[10031-10040] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[50001-50025]"
    saledItemA2="saledItem_[26-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[50026-50050]"
    saledItemB1="saledItem_[51-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[50051-50075]"
    saledItemB2="saledItem_[76-100] saledItem_[116-120] saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[50076-50100]"
    closeItemA1="item_[50001-50025]"
    closeItemA2="item_[50026-50050]"
    closeItemB1="item_[50051-50075]"
    closeItemB2="item_[50076-50100]"
    closeSaledItemA1="saledItem_[50001-50025]"
    closeSaledItemA2="saledItem_[50026-50050]"
    closeSaledItemB1="saledItem_[50051-50075]"
    closeSaledItemB2="saledItem_[50076-50100]"

    case "$1" in
    unshop1)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeleteitem  -p "$itemA1" -l $GATHER_HOME/logs/delta_unshop1.log > /dev/null 2>&1 &
    ;;
    unshop2)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeleteitem  -p "$itemA2" -l $GATHER_HOME/logs/delta_unshop2.log > /dev/null 2>&1 &
    ;;
    unshop3)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeleteitem  -p "$itemB1" -l $GATHER_HOME/logs/delta_unshop3.log > /dev/null 2>&1 &
    ;;
    unshop4)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeleteitem  -p "$itemB2" -l $GATHER_HOME/logs/delta_unshop4.log > /dev/null 2>&1 &
    ;;
    unshop5)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeletesaleditem  -p "$saledItemA1" -l $GATHER_HOME/logs/delta_unshop5.log > /dev/null 2>&1 &
    ;;
    unshop6)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeletesaleditem  -p "$saledItemA2" -l $GATHER_HOME/logs/delta_unshop6.log > /dev/null 2>&1 &
    ;;
    unshop7)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeletesaleditem  -p "$saledItemB1" -l $GATHER_HOME/logs/delta_unshop7.log > /dev/null 2>&1 &
    ;;
    unshop8)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t saleoutandisdeletesaleditem  -p "$saledItemB2" -l $GATHER_HOME/logs/delta_unshop8.log > /dev/null 2>&1 &
    ;;
    unshop9)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopcloseitem  -p "$closeItemA1" -l $GATHER_HOME/logs/delta_unshop9.log > /dev/null 2>&1 &
    ;;
    unshop10)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopcloseitem  -p "$closeItemA2" -l $GATHER_HOME/logs/delta_unshop10.log > /dev/null 2>&1 &
    ;;
    unshop11)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopcloseitem  -p "$closeItemB1" -l $GATHER_HOME/logs/delta_unshop11.log > /dev/null 2>&1 &
    ;;
    unshop12)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopcloseitem  -p "$closeItemB2" -l $GATHER_HOME/logs/delta_unshop12.log > /dev/null 2>&1 &
    ;;
    unshop13)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopclosesaleditem  -p "$closeSaledItemA1" -l $GATHER_HOME/logs/delta_unshop13.log > /dev/null 2>&1 &
    ;;
    unshop14)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopclosesaleditem  -p "$closeSaledItemA2" -l $GATHER_HOME/logs/delta_unshop14.log > /dev/null 2>&1 &
    ;;
    unshop15)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopclosesaleditem  -p "$closeSaledItemB1" -l $GATHER_HOME/logs/delta_unshop15.log > /dev/null 2>&1 &
    ;;
    unshop16)
      nohup $PHP $GATHER_HOME/delta.php -c $CONF -t shopclosesaleditem  -p "$closeSaledItemB2" -l $GATHER_HOME/logs/delta_unshop16.log > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}



case "${index}@${node}" in
  product@local1)
    b=1
    while [ $b -le 29 ] 
    do
        start_gather_product "shop${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  product@local2)
    for data in shopsold_a1 shopsold_b1 shopsold_a2 shopsold_b2 bookstall_a1 bookstall_a2 bookstall_b1 bookstall_b2 bookstallsold_a1 bookstallsold_a2 bookstallsold_b1 bookstallsold_b2
    do
        start_gather_product $data
        sleep 1
    done
    ;;
  product@hr)
    nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "item_[1-25]" -l $GATHER_HOME/logs/delta1.log > /dev/null 2>&1 &
    sleep 1
    nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "item_[26-50]" -l $GATHER_HOME/logs/delta2.log > /dev/null 2>&1 &
    sleep 1
    nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "item_[51-75]" -l $GATHER_HOME/logs/delta3.log > /dev/null 2>&1 &
    sleep 1
    nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstall  -p "item_[76-100]" -l $GATHER_HOME/logs/delta4.log > /dev/null 2>&1 &
    sleep 1
    nohup $PHP $GATHER_HOME/delta.php -c $CONF -t bookstallsold  -p "saledItem_1" -l $GATHER_HOME/logs/delta_bookstallsold_1.log  > /dev/null 2>&1 &
    ;;

  product@tslj|product@ybq|product@zgkm|product@swk|product@dy)
    b=1
    while [ $b -le 29 ]
    do
        start_gather_product "shop${b}"
        b=$(($b + 1))
        sleep 1
    done

    for data in shopsold_a1 shopsold_b1 bookstall_a1 bookstall_b1 bookstallsold_a1 bookstallsold_b1 shopsold_a2 shopsold_b2 bookstall_a2 bookstall_b2 bookstallsold_a2 bookstallsold_b2
    do
        start_gather_product $data
        sleep 1
    done 
    ;;

  unproduct@tslj|unproduct@ybq|unproduct@zgkm|unproduct@swk|unproduct@dy)
    b=1
    while [ $b -le 16 ]
    do
        start_gather_unproduct "unshop${b}"
        b=$(($b + 1))
        sleep 1
    done
    ;;
  
  seoproduct@nmw)
    b=1
    while [ $b -le 29 ]
    do
        start_gather_product "shop${b}"
        b=$(($b + 1))
        sleep 1
    done

    for data in shopsold_a1 shopsold_b1 bookstall_a1 bookstall_b1 bookstallsold_a1 bookstallsold_b1 shopsold_a2 shopsold_b2 bookstall_a2 bookstall_b2 bookstallsold_a2 bookstallsold_b2
    do
        start_gather_product $data
        sleep 1
    done 
    ;;
  *) 
    printf 'Usage: %s INDEX\n' "$0"  
    exit 1
    ;;
 esac
