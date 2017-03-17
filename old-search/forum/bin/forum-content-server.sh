#!/bin/sh
# -----------------------------------------------------------------------------
# Start Script for the BookServiceManager
#
# -----------------------------------------------------------------------------

# set character set
export LANG=zh_CN.UTF-8

# set kongfz search engine home
FORUM_HOME="/data/forum"

# set java environment
JAVA_HOME="/opt/java/jdk1.6"

CLASSPATH="$CLASSPATH:$FORUM_HOME/common/classes"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/lucene-3.0.1.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/kongdev-1.0.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/mysql-connector-java-5.1.6-bin.jar"

CONFIG_FILE="$FORUM_HOME/conf/forum_index_global.conf"

COMMAND=$(echo $1 | tr [A-Z] [a-z])

if [ "$COMMAND" = "start" ] ; then

    JAVA_OPTS="-server -Dpn=forumService -Xmx8g -Xms128m -Xmn32m -Dfile.encoding=UTF-8"

    _RUNJAVA="com.kongfz.dev.rmi.Bootstrap2 $CONFIG_FILE start"
    $JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $_RUNJAVA >> $FORUM_HOME/logs/forum-content-server.out &

elif [ "$COMMAND" = "stop" ] ; then

    _RUNJAVA="com.kongfz.dev.rmi.Bootstrap $CONFIG_FILE stop"
    $JAVA_HOME/bin/java -classpath $CLASSPATH $_RUNJAVA

elif [ "$COMMAND" = "restart" ] ; then

    $FORUM_HOME/bin/forum-content-server.sh stop
    sleep 5
    $FORUM_HOME/bin/forum-content-server.sh start

elif [ "$COMMAND" = "stats" ] ; then

    _RUNJAVA="com.kongfz.dev.rmi.Dovelet $CONFIG_FILE stats"
    $JAVA_HOME/bin/java -classpath $CLASSPATH $_RUNJAVA

elif [ "$COMMAND" = "indexing" ] ; then

    _RUNJAVA="com.kongfz.dev.rmi.Dovelet $CONFIG_FILE Indexing"
    $JAVA_HOME/bin/java -classpath $CLASSPATH $_RUNJAVA

elif [ "$COMMAND" = "indexed" ] ; then

    _RUNJAVA="com.kongfz.dev.rmi.Dovelet $CONFIG_FILE Indexed"
    $JAVA_HOME/bin/java -classpath $CLASSPATH $_RUNJAVA

else

    echo "Usage: forum-content-server.sh ( commands ... )"
    echo "commands:"
    echo "  start                     Start ForumContentServer in a separate process"
    echo "  stop                      Stop ForumContentServer"
    echo "  restart                   Restart ForumContentServer"
    echo "  stats                     Stats server info"
    echo "  Indexing                  Indexing"
    echo "  Indexed                   Indexed"
    exit 1

fi





