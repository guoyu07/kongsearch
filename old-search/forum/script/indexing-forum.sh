#!/bin/sh

# set forum system home
FORUM_HOME="/data/forum"

#
# log filename
#
CURRENT_DATE="`date +%Y-%m-%d`"
LOG_FILE="$FORUM_HOME/script/logs/indexing/indexing_$CURRENT_DATE.log"

# copy index
#cp $FORUM_HOME/data/index $FORUM_HOME/data/build -rf
echo "release caches ...1"
$FORUM_HOME/bin/release_caches.sh >> $LOG_FILE
#sleep 10

# build forum index
echo "build forum index : tmsg"
$FORUM_HOME/bin/build-forum-index.sh tmsg >> $LOG_FILE
sleep 60
echo "build forum index : post"
$FORUM_HOME/bin/build-forum-index.sh post >> $LOG_FILE
sleep 60
#$FORUM_HOME/bin/build-forum-index.sh article >> $LOG_FILE
#sleep 60

# shutdown forum server
echo "stop forum content server..."
$FORUM_HOME/bin/forum-content-server.sh stop >> $LOG_FILE
echo "release caches ...2"
$FORUM_HOME/bin/release_caches.sh >> $LOG_FILE
sleep 30

# use new index
echo "rm -rf index"
rm -rf $FORUM_HOME/data/index/*
echo "mv -f build index"
mv -f $FORUM_HOME/data/build/* $FORUM_HOME/data/index/
echo "rm -rf build"
rm -rf $FORUM_HOME/data/build
echo "release caches ...3"
$FORUM_HOME/bin/release_caches.sh >> $LOG_FILE
sleep 10

# startup forum server
echo "start forum content server..."
$FORUM_HOME/bin/forum-content-server.sh start >> $LOG_FILE
sleep 10


