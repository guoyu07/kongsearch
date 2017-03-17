#!/bin/sh
# -----------------------------------------------------------------------------
# Start Script for the BookServiceManager
#
# -----------------------------------------------------------------------------

# set character set
export LANG=zh_CN.UTF-8

# set message system home
FORUM_HOME="/data/forum"

# set java environment
JAVA_HOME="/opt/java/jdk1.5"

CLASSPATH="$CLASSPATH:$FORUM_HOME/common/classes"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/lucene-3.0.1.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/kongdev-1.0.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/mysql-connector-java-5.1.6-bin.jar"

COMMAND=$(echo $1 | tr [A-Z] [a-z])


    JAVA_OPTS="-Dpn=ShieldPost -Xmx8g -Xms2g -Xmn128m -Dfile.encoding=UTF-8"
    
#    FORUM_CONFIG="$FORUM_HOME/conf/forum_index_global.conf"
#    LOG_FILE="$FORUM_HOME/logs/indexing_log/forum/indexing_tmsg_$CURRENT_DATE.log"
    _RUNJAVA="com.kongfz.search.service.forum.works.util.ShieldPost"
    $JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $_RUNJAVA > shield.log
