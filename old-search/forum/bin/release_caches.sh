#
# release caches
#

sync
echo 1 > /proc/sys/vm/drop_caches
cat /proc/sys/vm/drop_caches
echo 0 > /proc/sys/vm/drop_caches
cat /proc/sys/vm/drop_caches
