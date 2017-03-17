securityCode='Gjp0UrTLfTaITwt2KG6R'
HOSTNAME='sms.kongfz.com.cn'

RECEIPIANT=$1
SUBJECT=$2
echo "$RECEIPIANT $SUBJECT"

para='from=915&mobile='${RECEIPIANT}'&msg='${SUBJECT}'&msgtype=101'
para_sign=`echo -n "${para}${securityCode}" | md5sum |  awk '{print $1}'`

TEXTENCODED=`echo "${SUBJECT}" | sed 's/ /%20/g'`
http_para='from=915&mobile='${RECEIPIANT}'&msg='${TEXTENCODED}'&msgtype=101'

curl 'http://'${HOSTNAME}'/sendMsg.do?'${http_para}'&sign='${para_sign}