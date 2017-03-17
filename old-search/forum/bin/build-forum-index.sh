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
JAVA_HOME="/opt/java/jdk1.6"

CLASSPATH="$CLASSPATH:$FORUM_HOME/common/classes"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/lucene-3.0.1.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/kongdev-1.0.jar"
CLASSPATH="$CLASSPATH:$FORUM_HOME/common/lib/mysql-connector-java-5.1.6-bin.jar"

COMMAND=$(echo $1 | tr [A-Z] [a-z])

CURRENT_DATE="`date +%Y-%m-%d`"

if [ "$COMMAND" = "tmsg" ] ; then

    JAVA_OPTS="-Dpn=indexingForum -Xmx8g -Xms2g -Xmn128m -Dfile.encoding=UTF-8"
    
    # create tmsg index file
    echo "Indexing..."
    FORUM_CONFIG="$FORUM_HOME/conf/forum_index_global.conf"
    LOG_FILE="$FORUM_HOME/logs/indexing_log/forum/indexing_tmsg_$CURRENT_DATE.log"
    _RUNJAVA="com.kongfz.search.service.forum.index.ForumIndexer $FORUM_CONFIG tmsg "
    $JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $_RUNJAVA >> $LOG_FILE
    echo "Indexed."
    echo
    $FORUM_HOME/bin/release_caches.sh

elif [ "$COMMAND" = "post" ] ; then

    JAVA_OPTS="-Dpn=indexingForum -Xmx8g -Xms2g -Xmn128m -Dfile.encoding=UTF-8"

    # create post index file
    echo "Indexing..."
    FORUM_CONFIG="$FORUM_HOME/conf/forum_index_global.conf"
    LOG_FILE="$FORUM_HOME/logs/indexing_log/forum/indexing_post_$CURRENT_DATE.log"
    _RUNJAVA="com.kongfz.search.service.forum.index.ForumIndexer $FORUM_CONFIG post "
    $JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $_RUNJAVA >> $LOG_FILE
    echo "Indexed."
    echo
    $FORUM_HOME/bin/release_caches.sh

elif [ "$COMMAND" = "article" ] ; then

    JAVA_OPTS="-Dpn=indexingForum -Xmx8g -Xms2g -Xmn128m -Dfile.encoding=UTF-8"

    # create post index file
    echo "Indexing..."
    FORUM_CONFIG="$FORUM_HOME/conf/forum_index_global.conf"
    LOG_FILE="$FORUM_HOME/logs/indexing_log/forum/indexing_article_$CURRENT_DATE.log"
    _RUNJAVA="com.kongfz.search.service.forum.index.ForumIndexer $FORUM_CONFIG article "
    $JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $_RUNJAVA >> $LOG_FILE
    echo "Indexed."
    echo
    $FORUM_HOME/bin/release_caches.sh

else

    echo "Usage: build-forum-index.sh ( commands ... )"
    echo "commands:"
    echo "  tmsg                     Build tmsg index"
    echo "  post                     Build post index"
    exit 1

fi



