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
  productES@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/es_repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/es_repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/es_repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=3402183 AND userId<5000000" > /data/kongsearch_logs/es_repair4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=5000000" > /data/kongsearch_logs/es_repair5.log &
    ;;

  product_soldES@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/es_sold1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/es_sold2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/es_sold3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=3402183 AND userId<5000000" > /data/kongsearch_logs/es_sold4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=5000000" > /data/kongsearch_logs/es_sold5.log &
    ;;

  productESAll@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId<1800000" -g "1"> /data/kongsearch_logs/es_repair1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=1800000 AND userId<2378893" -g "1" > /data/kongsearch_logs/es_repair2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=2378893 AND userId<3402183" -g "1" > /data/kongsearch_logs/es_repair3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=3402183 AND userId<5000000" -g "1" > /data/kongsearch_logs/es_repair4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=5000000" -g "1" > /data/kongsearch_logs/es_repair5.log &
    ;;

  notcertify@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId<1800000" > /data/kongsearch_logs/es_notCertify1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=1800000 AND userId<2378893" > /data/kongsearch_logs/es_notCertify2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=2378893 AND userId<3402183" > /data/kongsearch_logs/es_notCertify3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=3402183 AND userId<5000000" > /data/kongsearch_logs/es_notCertify4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=5000000" > /data/kongsearch_logs/es_notCertify5.log &
    ;;

  productES@2)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId<1800000" -z "1" > /data/kongsearch_logs/es_repair_spider1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=1800000 AND userId<2378893" -z "1" > /data/kongsearch_logs/es_repair_spider2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=2378893 AND userId<3402183" -z "1" > /data/kongsearch_logs/es_repair_spider3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=3402183 AND userId<5000000" -z "1" > /data/kongsearch_logs/es_repair_spider4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=5000000" -z "1" > /data/kongsearch_logs/es_repair_spider5.log &
    ;;

  product_soldES@2)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId<1800000" -z "1" > /data/kongsearch_logs/es_sold_spider1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=1800000 AND userId<2378893" -z "1" > /data/kongsearch_logs/es_sold_spider2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=2378893 AND userId<3402183" -z "1" > /data/kongsearch_logs/es_sold_spider3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=3402183 AND userId<5000000" -z "1" > /data/kongsearch_logs/es_sold_spider4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductSoldES.php -t "all" -w "userId>=5000000" -z "1" > /data/kongsearch_logs/es_sold_spider5.log &
    ;;

  productESAll@2)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId<1800000" -g "1" -z "1"> /data/kongsearch_logs/es_repair_spider1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=1800000 AND userId<2378893" -g "1"  -z "1" > /data/kongsearch_logs/es_repair_spider2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=2378893 AND userId<3402183" -g "1"  -z "1" > /data/kongsearch_logs/es_repair_spider3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=3402183 AND userId<5000000" -g "1" -z "1" > /data/kongsearch_logs/es_repair_spider4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairProductES.php -t "all" -w "userId>=5000000" -g "1" -z "1" > /data/kongsearch_logs/es_repair_spider5.log &
    ;;

  notcertify@2)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId<1800000" -z "1" > /data/kongsearch_logs/es_notCertify_spider1.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=1800000 AND userId<2378893" -z "1" > /data/kongsearch_logs/es_notCertify_spider2.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=2378893 AND userId<3402183" -z "1" > /data/kongsearch_logs/es_notCertify_spider3.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=3402183 AND userId<5000000" -z "1" > /data/kongsearch_logs/es_notCertify_spider4.log &
    sleep 1
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairNotCertifyES.php -t "all" -w "userId>=5000000" -z "1" > /data/kongsearch_logs/es_notCertify_spider5.log &
    ;;

  endauctionES@1)
    nohup /opt/app/php/bin/php /data/project/kongsearch/tool/repairEndauctionES.php -t "all" -m "50000" > /data/kongsearch_logs/endES.log &
    sleep 1
    ;;

  *) 
    usage $0
    ;;
esac
