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
JAVA_HOME=/opt/app/java/jdk1.8.0
CLUSTER_NAME=elk
NODE_NAME=elk-online1
ES_HOST=192.168.2.42
ES_PORT=9191
ACTION=$1
ES_MIN_MEM=32g
ES_MAX_MEM=32g

#安装
if [ "$ACTION" = 'install' ]; then
  cd $INSTALL_DIR
  if [ ! -d elasticsearch-2.4.0 ];then
    #下载
    echo "Start to download elasticsearch-2.4.0.tar.gz..."
    wget -O elasticsearch-2.4.0.tar.gz --timeout=300 --tries=2 https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.0/elasticsearch-2.4.0.tar.gz
    if [ ! -f elasticsearch-2.4.0.tar.gz ];then
      echo "Download error, please retry."
      exit 1
    fi
    tar -zxvf elasticsearch-2.4.0.tar.gz
    rm -rf elasticsearch-2.4.0.tar.gz
  fi
  if [ ! -d elasticsearch-2.4.0/logs ];then
    mkdir elasticsearch-2.4.0/logs
  fi
  if [ ! -d elasticsearch-2.4.0/data ];then
    mkdir elasticsearch-2.4.0/data
  fi
  cd elasticsearch-2.4.0

  #修改配置
  echo "Start to modify the configuration file..."
  echo "
cluster.name: $CLUSTER_NAME
node.name: $NODE_NAME
path.data: $INSTALL_DIR/elasticsearch-2.4.0/data
path.logs: $INSTALL_DIR/elasticsearch-2.4.0/logs
http.host: $ES_HOST
http.port: $ES_PORT
discovery.zen.fd.ping_timeout: 120s
discovery.zen.fd.ping_retries: 6
discovery.zen.fd.ping_interval: 30s
bootstrap.mlockall: true
index.number_of_shards: 20
" > config/elasticsearch.yml


  echo "#!/bin/sh
if [ \"x\$ES_CLASSPATH\" != \"x\" ]; then
    cat >&2 << EOF
Error: Don\\\'t modify the classpath with ES_CLASSPATH. Best is to add
additional elements via the plugin mechanism, or if code must really be
added to the main classpath, add jars to lib/ (unsupported).
EOF
    exit 1
fi
ES_CLASSPATH=\"\$ES_HOME/lib/elasticsearch-2.4.0.jar:\$ES_HOME/lib/*\"
if [ \"x\$ES_MIN_MEM\" = \"x\" ]; then
    ES_MIN_MEM=$ES_MIN_MEM
fi
if [ \"x\$ES_MAX_MEM\" = \"x\" ]; then
    ES_MAX_MEM=$ES_MAX_MEM
fi
if [ \"x\$ES_HEAP_SIZE\" != \"x\" ]; then
    ES_MIN_MEM=\$ES_HEAP_SIZE
    ES_MAX_MEM=\$ES_HEAP_SIZE
fi
JAVA_OPTS=\"\$JAVA_OPTS -Xms\${ES_MIN_MEM}\"
JAVA_OPTS=\"\$JAVA_OPTS -Xmx\${ES_MAX_MEM}\"
if [ \"x\$ES_HEAP_NEWSIZE\" != \"x\" ]; then
    JAVA_OPTS=\"\$JAVA_OPTS -Xmn\${ES_HEAP_NEWSIZE}\"
fi
if [ \"x\$ES_DIRECT_SIZE\" != \"x\" ]; then
    JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxDirectMemorySize=\${ES_DIRECT_SIZE}\"
fi
JAVA_OPTS=\"\$JAVA_OPTS -Djava.awt.headless=true\"
if [ \"x\$ES_USE_IPV4\" != \"x\" ]; then
  JAVA_OPTS=\"\$JAVA_OPTS -Djava.net.preferIPv4Stack=true\"
fi
if [ \"x\$ES_GC_OPTS\" = \"x\" ]; then
  ES_GC_OPTS=\"\$ES_GC_OPTS -XX:+UseParNewGC\"
  ES_GC_OPTS=\"\$ES_GC_OPTS -XX:+UseConcMarkSweepGC\"
  ES_GC_OPTS=\"\$ES_GC_OPTS -XX:CMSInitiatingOccupancyFraction=75\"
  ES_GC_OPTS=\"\$ES_GC_OPTS -XX:+UseCMSInitiatingOccupancyOnly\"
fi
JAVA_OPTS=\"\$JAVA_OPTS \$ES_GC_OPTS\"
if [ -n \"\$ES_GC_LOG_FILE\" ]; then
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCDetails\"
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCTimeStamps\"
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCDateStamps\"
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintClassHistogram\"
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintTenuringDistribution\"
  JAVA_OPTS=\"\$JAVA_OPTS -XX:+PrintGCApplicationStoppedTime\"
  JAVA_OPTS=\"\$JAVA_OPTS -Xloggc:\$ES_GC_LOG_FILE\"
  mkdir -p \"\`dirname \\\"\$ES_GC_LOG_FILE\\\"\`\"
fi
JAVA_OPTS=\"\$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError\"
# Disables explicit GC
JAVA_OPTS=\"\$JAVA_OPTS -XX:+DisableExplicitGC\"
JAVA_OPTS=\"\$JAVA_OPTS -Dfile.encoding=UTF-8\"
JAVA_OPTS=\"\$JAVA_OPTS -Djna.nosys=true\"
JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseNUMA\"
" > bin/elasticsearch.in.sh

#启动
elif [ "$ACTION" = 'start' ]; then
  export JAVA_HOME=$JAVA_HOME
  echo "Start..."
  $INSTALL_DIR/elasticsearch-2.4.0/bin/elasticsearch -d

#终止
elif [ "$ACTION" = 'stop' ]; then
  echo "Stop..."
  #curl -XPOST "${ES_HOST}:${ES_PORT}/_cluster/nodes/$NODE_NAME/_shutdown/"
  kill -9 `ps -ef | grep "$INSTALL_DIR/elasticsearch-2.4.0/lib/elasticsearch-2.4.0.jar" | grep -v "grep" | awk '{print $2}'`


else
  usage $0
fi

echo "Done."
