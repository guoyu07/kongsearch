#!/bin/bash

source /etc/profile

#帮助
usage() {
  printf 'useradd elk && su - elk'
  printf 'Usage: %s {install|start|stop} TYPE\n' "$1"
  printf 'The value of TYPE:\n'
  printf '\t\t es\n'
  printf '\t\t file\n'
  exit 1  
}

if [ $# -lt 1 ];then
  usage $0
fi

INSTALL_DIR=/data/elk
JAVA_HOME=/opt/app/java/jdk1.8.0
LS_HEAP_SIZE=8g
REDIS_HOST=192.168.1.225
REDIS_PORT=6379
ES_HOSTS=192.168.2.42:9191
LOG_OUTPUT_DIR=/data/logs/elk
ACTION=$1
TYPE=$2
MODE=$3

#安装
if [ "$ACTION" = 'install' ]; then
  if [ $# -lt 2 ];then
    usage $0
  fi
  cd $INSTALL_DIR
  if [ ! -d logstash-2.4.0 ];then
    #下载
    echo "Start to download logstash-2.4.0.tar.gz..."
    wget -O logstash-2.4.0.tar.gz --timeout=300 --tries=2 https://download.elastic.co/logstash/logstash/logstash-2.4.0.tar.gz
    if [ ! -f logstash-2.4.0.tar.gz ];then
      echo "Download error, please retry."
      exit 1
    fi
    tar -zxvf logstash-2.4.0.tar.gz
    rm -rf logstash-2.4.0.tar.gz
  fi
  if [ ! -d logstash-2.4.0/config ];then
    mkdir logstash-2.4.0/config
  fi
  if [ ! -d logstash-2.4.0/logs ];then
    mkdir logstash-2.4.0/logs
  fi
  cd logstash-2.4.0/config

  #修改配置
  echo "Start to modify the configuration file..."


  case "${TYPE}" in
  #修改ES存储配置
  es)
    echo "Config the logstash-es-indexer.conf..."
    echo "
############################# Input ######################################
input {
    redis {
        host => \"$REDIS_HOST\"
        port => $REDIS_PORT
        data_type => \"pattern_channel\"
        key => \"elk\"
    }
}
############################# Filter ######################################
filter {
    if [fields][log_project] == \"newsearch\" and [fields][log_source] == \"access\" {
        grok {
            match => [
                \"message\", \"%{IPORHOST:client_ip} (?:%{IPORHOST:http_x_forwarded_for}|-)?( -)? (?:%{IPORHOST:remote_user}|-)? \[%{HTTPDATE:timestamp}\] \\\"%{WORD:http_verb} %{NOTSPACE:request_url} HTTP/%{NUMBER:http_version}\\\" %{NUMBER:http_status_code} %{NUMBER:body_bytes_sent} (?:%{QS:referer}|-)? %{QS:agent}(?:\\s+%{NUMBER:request_time}|0)?(?:\\s+%{NUMBER:response_time}|0)?(?:\\s+%{IPORHOST:server_ip}|-)?(?:\\:%{IPORHOST:server_host}|-)?(?:\\s+%{USER:kfz_cookie}|-)?(?:\\s+%{USER:kfz_sid}|-)?\"
            ]
            #add_field => [ "received_at", "%{timestamp}" ]
        }
    } else if [fields][log_project] == \"newsearch_local\" and [fields][log_source] == \"access\" {
        grok {
            match => [
                \"message\", \"%{IPORHOST:client_ip} (?:%{IPORHOST:http_x_forwarded_for}|-)?( -)? (?:%{IPORHOST:remote_user}|-)? \[%{HTTPDATE:timestamp}\] \\\"%{WORD:http_verb} %{NOTSPACE:request_url} HTTP/%{NUMBER:http_version}\\\" %{NUMBER:http_status_code} %{NUMBER:body_bytes_sent} (?:%{QS:referer}|-)? %{QS:agent}(?:\\s+%{NUMBER:request_time}|0)?(?:\\s+%{NUMBER:response_time}|0)?(?:\\s+%{IPORHOST:server_ip}|-)?(?:\\:%{IPORHOST:server_host}|-)?(?:\\s+%{USER:kfz_cookie}|-)?(?:\\s+%{USER:kfz_sid}|-)?\"
            ]
            #add_field => [ "received_at", "%{timestamp}" ]
        }
    } else if [fields][log_project] == \"bookv3\" and [fields][log_source] == \"access\" {
        grok {
            match => [
                \"message\", \"%{IPORHOST:client_ip} (?:%{IPORHOST:http_x_forwarded_for}|-)?( -)? (?:%{IPORHOST:remote_user}|-)? \[%{HTTPDATE:timestamp}\] \\\"%{WORD:http_verb} %{NOTSPACE:request_url} HTTP/%{NUMBER:http_version}\\\" %{NUMBER:http_status_code} %{NUMBER:body_bytes_sent} (?:%{QS:referer}|-)? %{QS:agent}(?:\\s+%{NUMBER:request_time}|0)?(?:\\s+%{NUMBER:response_time}|0)?(?:\\s+%{IPORHOST:server_ip}|-)?(?:\\:%{IPORHOST:server_host}|-)?(?:\\s+%{USER:kfz_cookie}|-)?(?:\\s+%{USER:kfz_sid}|-)?\"
            ]
            #add_field => [ "received_at", "%{timestamp}" ]
        }
    } else if [fields][log_project] == \"shop\" and [fields][log_source] == \"access\" {
        grok {
            match => [
                \"message\", \"%{IPORHOST:client_ip} (?:%{IPORHOST:http_x_forwarded_for}|-)?( -)? (?:%{IPORHOST:remote_user}|-)? \[%{HTTPDATE:timestamp}\] \\\"%{WORD:http_verb} %{NOTSPACE:request_url} HTTP/%{NUMBER:http_version}\\\" %{NUMBER:http_status_code} %{NUMBER:body_bytes_sent} (?:%{QS:referer}|-)? %{QS:agent}(?:\\s+%{NUMBER:request_time}|0)?(?:\\s+%{NUMBER:response_time}|0)?(?:\\s+%{IPORHOST:server_ip}|-)?(?:\\:%{IPORHOST:server_host}|-)?(?:\\s+%{USER:kfz_cookie}|-)?(?:\\s+%{USER:kfz_sid}|-)?\"
            ]
            #add_field => [ "received_at", "%{timestamp}" ]
        }
    } else {
        drop {}
    }
    urldecode {
        all_fields => true
    }
    date {
        locale => \"en\"
        match => [\"timestamp\" , \"dd/MMM/YYYY:HH:mm:ss Z\"]
    }
}
############################# Output ######################################
output {
    elasticsearch {
        hosts => \"$ES_HOSTS\"
        #index => \"logstash-%{[beat][hostname]}-%{[fields][log_type]}-%{[fields][log_source]}-%{+YYYY-MM-dd}\"
        index => \"logstash-%{[fields][log_project]}-%{[fields][log_type]}-%{[fields][log_source]}-%{+YYYY-MM-dd}\"
    }
    stdout {
        codec => rubydebug {}
    }
}" > logstash-es-indexer.conf
    ;;


  #修改文件存储配置
  file)
    echo "Config the logstash-file-indexer.conf..."
    mkdir -p $LOG_OUTPUT_DIR
    chmod -R 777 $LOG_OUTPUT_DIR
    echo "
############################# Input ######################################
input {
    redis {
        host => \"$REDIS_HOST\"
        port => $REDIS_PORT
        data_type => \"pattern_channel\"
        key => \"elk\"
    }
}
############################# Filter ######################################
filter {
    date {
        locale => \"en\"
        match => [\"timestamp\" , \"dd/MMM/YYYY:HH:mm:ss Z\"]
    }
}
############################# Output ######################################
output {
    file {
        #path => \"$LOG_OUTPUT_DIR/%{[beat][hostname]}-%{[fields][log_type]}-%{[fields][log_source]}-%{+YYYY-MM-dd}.log\"
        path => \"$LOG_OUTPUT_DIR/%{[fields][log_type]}/%{[fields][log_project]}-%{[fields][log_type]}-%{[fields][log_source]}-%{+YYYY-MM-dd}.log\"
        codec => line { format => \"%{message}\"}
    }
    stdout {
        codec => rubydebug {}
    }
}" > logstash-file-indexer.conf
    ;;

  esac



#启动
elif [ "$ACTION" = 'start' ]; then
  export JAVA_HOME=$JAVA_HOME
  export LS_HEAP_SIZE=$LS_HEAP_SIZE
  echo "Start..."
  case "${TYPE}" in
  es)
    if [ "$MODE" = 'debug' ]; then
      nohup $INSTALL_DIR/logstash-2.4.0/bin/logstash -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-es-indexer.conf -w 24 -b 1000 > $INSTALL_DIR/logstash-2.4.0/logs/logstash-es-indexer.log 2>&1 &
    else
      nohup $INSTALL_DIR/logstash-2.4.0/bin/logstash -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-es-indexer.conf -w 24 -b 1000 > /dev/null 2>&1 &
    fi
  ;;
  file)
    if [ "$MODE" = 'debug' ]; then
      nohup $INSTALL_DIR/logstash-2.4.0/bin/logstash -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-file-indexer.conf -w 24 -b 1000 > $INSTALL_DIR/logstash-2.4.0/logs/logstash-file-indexer.log 2>&1 &
    else
      nohup $INSTALL_DIR/logstash-2.4.0/bin/logstash -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-file-indexer.conf -w 24 -b 1000 > /dev/null 2>&1 &
    fi
  ;;
  esac  



#终止
elif [ "$ACTION" = 'stop' ]; then
  echo "Stop..."
  case "${TYPE}" in
  es)
    kill -9 `ps -ef | grep "agent -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-es-indexer.conf" | grep -v "grep" | awk '{print $2}'`
  ;;
  file)
    kill -9 `ps -ef | grep "agent -r -f $INSTALL_DIR/logstash-2.4.0/config/logstash-file-indexer.conf" | grep -v "grep" | awk '{print $2}'`
  ;;
  esac

else
  usage $0
fi

echo "Done."
