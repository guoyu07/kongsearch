#!/bin/bash
#crontab: 1 0 * * * root sh /data/project/kongsearch/rotatequerylog.sh LOGPATH

logs_path=$1
year=$(date -d "yesterday" +"%Y")
month=$(date -d "yesterday" +"%m")
ymd=$(date -d "yesterday" +"%Y%m%d")
mkdir -p ${logs_path}/${year}/${month}

file_list=`find ${logs_path} -name query.log`
for full_file_name in $file_list;
do
	file_name=`basename $full_file_name`;
	mv ${logs_path}/$file_name ${logs_path}/${year}/${month}/$file_name-${ymd};
done;
kill -USR1 `cat ${logs_path}/searchd.pid`
gzip ${logs_path}/${year}/${month}/*-${ymd}
