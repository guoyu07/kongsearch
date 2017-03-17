#!/bin/bash

source /etc/profile

#是否为root
is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

#帮助
usage() {
  printf 'Usage1: %s install TYPE\n' "$1"
  printf 'The value of TYPE:\n'
  printf '\t\t php265\n'
  printf '\t\t web01\n'
  printf 'Usage2: %s {start|stop}\n' "$1"
  exit 1  
}

if [ $# -lt 1 ];then
  usage $0
fi

INSTALL_DIR=/data/elk
REDIS_HOST=192.168.1.225
REDIS_PORT=6379
ACTION=$1
TYPE=$2

#通用nginx配置
nginx_common_config() {
  PROJECT=$1
  echo "
    -
      paths:
        - \"/data/logs/nginx/access/curr/$PROJECT.kongfz.com.log\"
      fields:
        log_type: nginx
        log_source: access
        log_project: $PROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
    -
      paths:
        - \"/data/logs/nginx/nginx_error_$PROJECT.log\"
      fields:
        log_type: nginx
        log_source: error
        log_project: $PROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
" >> filebeat.yml
}

#通用php配置
php_common_config() {
  PROJECT=$1
  VERSION=$2
  echo "
    -
      paths:
        - \"/data/logs/php/php_error_$VERSION.log\"
      fields:
        log_type: php
        log_source: error-$VERSION
        log_project: $PROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
    -
      paths:
        - \"/data/logs/php/php_error_${VERSION}_cli.log\"
      fields:
        log_type: php
        log_source: error-$VERSION-cli
        log_project: $PROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
    -
      paths:
        - \"/data/logs/php/php_fpm_err_$VERSION.log\"
      fields:
        log_type: php
        log_source: fpm-err-$VERSION
        log_project: $PROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
" >> filebeat.yml
}

#通用配置
common_config() {
  PATH=$1
  LOGTYPE=$2
  LOGSOURCE=$3
  LOGPROJECT=$4
  echo "
    -
      paths:
        - \"$PATH\"
      fields:
        log_type: $LOGTYPE
        log_source: $LOGSOURCE
        log_project: $LOGPROJECT
      input_type: log
      scan_frequency: 3s
      harvester_buffer_size: 16384
      max_bytes: 10485760
      tail_files: true
" >> filebeat.yml
}

#安装
if [ "$ACTION" = 'install' ]; then
  if [ $# -lt 2 ];then
    usage $0
  fi
  cd $INSTALL_DIR
  if [ ! -d filebeat-1.3.1-x86_64 ];then
    #下载
    echo "Start to download filebeat-1.3.1-x86_64.tar.gz..."
    wget -O filebeat-1.3.1-x86_64.tar.gz --timeout=300 --tries=2 https://download.elastic.co/beats/filebeat/filebeat-1.3.1-x86_64.tar.gz
    if [ ! -f filebeat-1.3.1-x86_64.tar.gz ];then
      echo "Download error, please retry."
      exit 1
    fi
    tar -zxvf filebeat-1.3.1-x86_64.tar.gz
    rm -rf filebeat-1.3.1-x86_64.tar.gz
  fi
  cd filebeat-1.3.1-x86_64
  mkdir log
  if [ ! -f filebeat -o ! -f filebeat.template.json -o ! -f filebeat.yml ];then
    echo "File error."
    exit 1
  fi

  #修改配置
  echo "Start to modify the configuration file..."
  echo "
############################# Filebeat ######################################
filebeat:
  prospectors:
" > filebeat.yml


  #按项目日志类型配置
  case "${TYPE}" in
  php265)
    echo "Config php265..."
    nginx_common_config newsearch
    nginx_common_config newsearch_local
    nginx_common_config verify
    php_common_config verify 5.5
    ;;

  web14)
    echo "Config web14..."
    nginx_common_config bookv3
    nginx_common_config bq
    nginx_common_config xinshu
    ;;

  web01)
    echo "Config web01..."
    nginx_common_config shop
    ;;

  web13)
    echo "Config web13..."
    nginx_common_config s_login
    nginx_common_config userapi
    nginx_common_config login
    nginx_common_config user
    nginx_common_config xinyu
    nginx_common_config xinyu.m
    nginx_common_config xinyuapi
    nginx_common_config login.gujiushu
    ;;

  2p145)
    echo "Config 2p145..."
    nginx_common_config m
    nginx_common_config mshop
    nginx_common_config mbook
    nginx_common_config mbq
    nginx_common_config msearch_local
    common_config /data/logs/nginx/access/curr/m.kongfz.cn.log nginx access mpm
    common_config /data/logs/nginx/m.kongfz.cn_error.log nginx error mpm
    nginx_common_config mzixun
    nginx_common_config s_res2
    nginx_common_config s_m
    ;;

  web09)
    echo "Config web09..."
    nginx_common_config tanv3
    nginx_common_config www
    ;;

  3p38)
    echo "Config 3p38..."
    nginx_common_config pmgs
    nginx_common_config pmgs_kfzimg
    ;;

  2p95)
    echo "Config 2p95..."
    common_config /data1/logs/nginx/access/curr/app_access.log nginx access app
    common_config /data1/logs/nginx/app_error.log nginx error app
    common_config /data1/logs/nginx/access/curr/ssl_app.kongfz.com_access.log nginx access s_app
    common_config /data1/logs/nginx/ssl_app_error.log nginx error s_app
    ;;

  2p82)
    echo "Config 2p82..."
    common_config /data/logs/nginx/access/curr/pmv2_public_kongfz.com.log nginx access pmv2
    common_config /data/logs/nginx/pmv2_public_error.log nginx error pmv2
    ;;

  esac


  echo "
############################# Output ##########################################
output:
  redis:
    host: \"$REDIS_HOST\"
    port: $REDIS_PORT
    datatype: \"channel\"
    index: \"elk\"

############################# Logging #########################################
logging:
  files:
    path: $INSTALL_DIR/filebeat-1.3.1-x86_64/log/mybeat
    name: mybeat
    rotateeverybytes: 10485760 # = 10MB
    keepfiles: 7
" >> filebeat.yml




#启动
elif [ "$ACTION" = 'start' ]; then
  echo "Start..."
  nohup $INSTALL_DIR/filebeat-1.3.1-x86_64/filebeat start >/dev/null 2>&1 &




#终止
elif [ "$ACTION" = 'stop' ]; then
  echo "Stop..."
  kill -9 `ps -e | grep "filebeat" | awk '{print $1}'`




else
  usage $0
fi

echo "Done."
