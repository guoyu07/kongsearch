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

indextype=$1
level=$2

case "${indextype}@${level}" in
  product@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3402183" > /data/kongsearch_logs/repair4.log &
    ;;

  product@2)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId<1902890" > /data/kongsearch_logs/repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=1902890 AND userId<2610642" > /data/kongsearch_logs/repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2610642 AND userId<3185964" > /data/kongsearch_logs/repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3185964 AND userId<3695130" > /data/kongsearch_logs/repair4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3695130" > /data/kongsearch_logs/repair5.log &
    ;;

  product@3)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId<1423376" > /data/kongsearch_logs/repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=1423376 AND userId<1902890" > /data/kongsearch_logs/repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=1902890 AND userId<2241631" > /data/kongsearch_logs/repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2241631 AND userId<2610642" > /data/kongsearch_logs/repair4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2610642 AND userId<2958011" > /data/kongsearch_logs/repair5.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2958011 AND userId<3185964" > /data/kongsearch_logs/repair6.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3185964 AND userId<3451446" > /data/kongsearch_logs/repair7.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3451446 AND userId<3695130" > /data/kongsearch_logs/repair8.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3695130 AND userId<3981474" > /data/kongsearch_logs/repair9.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3981474" > /data/kongsearch_logs/repair10.log &
    ;;

  product_sold@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSold.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/sold1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSold.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/sold2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSold.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/sold3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSold.php -t "all" -w "userId>=3402183" > /data/kongsearch_logs/sold4.log &
    ;;

  product@11)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId<1800000" -m "3000" -p "1" > /data/kongsearch_logs/repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=1800000 AND userId<2378893" -m "3000" -p "1"  > /data/kongsearch_logs/repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=2378893 AND userId<3402183" -m "3000" -p "1"  > /data/kongsearch_logs/repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProduct.php -t "all" -w "userId>=3402183" -m "3000" -p "1"  > /data/kongsearch_logs/repair4.log &
    ;;

  notcertify@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertify.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/notCertify1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertify.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/notCertify2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertify.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/notCertify3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertify.php -t "all" -w "userId>=3402183" > /data/kongsearch_logs/notCertify4.log &
    ;;

  *) 
    usage $0
    ;;
esac
