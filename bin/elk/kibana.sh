#!/bin/bash

source /etc/profile

#帮助
usage() {
  printf 'useradd elk && su - elk'
  printf 'Usage: %s {install|start|stop} \n' "$1"
  exit 1  
}

if [ $# -lt 1 ];then
  usage $0
fi

INSTALL_DIR=/data/elk
KIBANA_HOST=192.168.2.42
KIBANA_PORT=5601
ES_HOSTS=192.168.2.42:9191
ACTION=$1

#安装
if [ "$ACTION" = 'install' ]; then
  cd $INSTALL_DIR
  if [ ! -d kibana-4.6.1-linux-x86_64 ];then
    #下载
    echo "Start to download kibana-4.6.1-linux-x86_64.tar.gz..."
    wget -O kibana-4.6.1-linux-x86_64.tar.gz --timeout=300 --tries=2 https://download.elastic.co/kibana/kibana/kibana-4.6.1-linux-x86_64.tar.gz
    if [ ! -f kibana-4.6.1-linux-x86_64.tar.gz ];then
      echo "Download error, please retry."
      exit 1
    fi
    tar -zxvf kibana-4.6.1-linux-x86_64.tar.gz
    rm -rf kibana-4.6.1-linux-x86_64.tar.gz
  fi
  if [ ! -d kibana-4.6.1-linux-x86_64/config ];then
    echo "File error."
    exit 1
  fi
  if [ ! -d kibana-4.6.1-linux-x86_64/logs ];then
    mkdir kibana-4.6.1-linux-x86_64/logs
  fi
  cd kibana-4.6.1-linux-x86_64


  #修改配置
  echo "Start to modify the configuration file..."

  echo "
server.port: $KIBANA_PORT
server.host: \"$KIBANA_HOST\"
elasticsearch.url: \"http://$ES_HOSTS\"
" > config/kibana.yml

#启动
elif [ "$ACTION" = 'start' ]; then
  echo "Start..."
  nohup $INSTALL_DIR/kibana-4.6.1-linux-x86_64/bin/kibana > $INSTALL_DIR/kibana-4.6.1-linux-x86_64/logs/kibana.log 2>&1 &

#终止
elif [ "$ACTION" = 'stop' ]; then
  echo "Stop..."
  kill `netstat -nlp | grep :$KIBANA_PORT | awk '{print $7}' | awk -F"/" '{ print $1 }'`

else
  usage $0
fi

echo "Done."
