#!/bin/bash
#crontab: 1 0 * * 1 root sh /data/project/kongsearch/bin/rotateindexupdatelog.sh /data/kongsearch_logs/indexupdateES_item productES_indexupdate.log

logs_path=$1
log_name=$2
year=$(date -d "yesterday" +"%Y")
month=$(date -d "yesterday" +"%m")
ymd=$(date -d "yesterday" +"%Y%m%d")
mkdir -p ${logs_path}/${year}/${month}

file_list=`find ${logs_path} -name ${log_name}`
for full_file_name in $file_list;
do
	file_name=`basename $full_file_name`;
	mv ${logs_path}/$file_name ${logs_path}/${year}/${month}/$file_name-${ymd};
done;
gzip ${logs_path}/${year}/${month}/*-${ymd}
