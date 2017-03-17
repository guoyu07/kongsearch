#!/bin/bash
#author: liuxingzhi@2013.11

GATHER_HOME=/data/project/kongsearch
PHP=/opt/app/php/bin/php
KONGSEARCH_LOG_HOME=/data/kongsearch_logs

is_root() {  
  if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1  
  fi
}

is_root

if [ $SPHINX_NODE ]; then
    node=$SPHINX_NODE
    echo "Notice: Current Sphinx Node is $node"
else
    echo "Error: this machine isn't Sphinx Node."
    exit 1
fi

if [ $# -ne 1 ]; then
     printf 'Usage: %s INDEX\n' "$0"  
     exit 1
fi

index=$1

if [ $SPHINX_ENV -a $SPHINX_ENV = 'local' ]; then
  CONF="$GATHER_HOME/conf/${index}_local.ini"
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  CONF="$GATHER_HOME/conf/${index}_neibu.ini"
else 
  CONF="$GATHER_HOME/conf/${index}.ini"
fi

start_gather_product() {
    itemA1="item_[1-10] item_10001 item_[141-145] item_[10041-10045]"
    itemA2="item_[11-20] item_10003 item_[146-150] item_[10046-10050]"
    itemA3="item_[21-25] item_[102-105] item_10007 item_[151-155] item_[10051-10060]"
    itemA4="item_[121-125] item_[10019-10023] item_10012 item_[156-160] item_[10061-10065]"
    itemA5="item_[10031-10040] item_[161-165]"
    itemA6="item_[26-35] item_[166-170]"
    itemA7="item_[36-45] item_[171-175]"
    itemA8="item_[46-50] item_[106-110] item_[176-180]"
    itemA9="item_[126-130] item_[10015-10016] item_[181-185]"
    itemA10="item_[10024-10030] item_10002 item_10005 item_10011 item_[186-190] item_[10066-10069]"
    itemB1="item_[51-60] item_[191-200]"
    itemB2="item_[61-70] item_[201-210]"
    itemB3="item_[71-75] item_[111-115] item_[211-220]"
    itemB4="item_[131-135] item_101 item_10006 item_10008 item_10014 item_[221-230] item_[10111-10120]"
    itemB5="item_[76-85] item_[231-240] item_[10101-10110]"
    itemB6="item_[86-95] item_[241-250] item_[10091-10100]"
    itemB7="item_[96-100] item_[251-260] item_[10081-10090]"
    itemB8="item_[136-140] item_[10009-10010] item_10004 item_10013 item_10017 item_10018 item_[10070-10080]"
    saledItemA1="saledItem_[1-5] saledItem_[141-145] saledItem_[10041-10045]"
    saledItemA2="saledItem_[6-10] saledItem_[146-150] saledItem_[10046-10050]"
    saledItemA3="saledItem_[11-15] saledItem_[151-155] saledItem_[10051-10060]"
    saledItemA4="saledItem_[16-20] saledItem_[156-160] saledItem_[10061-10065]"
    saledItemA5="saledItem_[21-25] saledItem_[102-105] saledItem_[121-125] saledItem_[161-165]"
    saledItemA6="saledItem_[10019-10023] saledItem_[50001-50025] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[166-170]"
    saledItemA7="saledItem_[10031-10040] saledItem_[171-175]"
    saledItemA8="saledItem_[26-30] saledItem_[176-180]"
    saledItemA9="saledItem_[31-35] saledItem_[181-185]"
    saledItemA10="saledItem_[36-45]"
    saledItemA11="saledItem_[46-50] saledItem_[106-110] saledItem_[186-190]"
    saledItemA12="saledItem_[126-130] saledItem_[10015-10016] saledItem_[10066-10069]"
    saledItemA13="saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[50026-50050]"
    saledItemB1="saledItem_[51-55] saledItem_[191-200]"
    saledItemB2="saledItem_[56-60] saledItem_[201-210]"
    saledItemB3="saledItem_[61-70] saledItem_[211-220]"
    saledItemB4="saledItem_[71-75] saledItem_[111-115] saledItem_[221-230] saledItem_[10111-10120]"
    saledItemB5="saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[50051-50075] saledItem_[231-240] saledItem_[10101-10110]"
    saledItemB6="saledItem_[76-80] saledItem_[241-250] saledItem_[10091-10100]"
    saledItemB7="saledItem_[81-85] saledItem_[251-260] saledItem_[10081-10090]"
    saledItemB8="saledItem_[86-95] saledItem_[10070-10080]"
    saledItemB9="saledItem_[96-100] saledItem_[116-120]"
    saledItemB10="saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[50076-50100]"
    bookstallsoldA1="saledItem_[1-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[10031-10040] saledItem_[50001-50025] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[141-162] saledItem_[10041-10051]"
    bookstallsoldA2="saledItem_[26-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[50026-50050] saledItem_[163-190] saledItem_[10052-10069]"
    bookstallsoldB1="saledItem_[51-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[50051-50075] saledItem_[191-226] saledItem_[10070-10096]"
    bookstallsoldB2="saledItem_[76-100] saledItem_[116-120] saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[50076-50100] saledItem_[227-260] saledItem_[10097-10120]"

    case "$1" in
    shop1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[1-2] item_141 item_10041" -l $KONGSEARCH_LOG_HOME/shop1.log > /dev/null 2>&1 &
    ;;
    shop2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[3-4] item_142 item_10042" -l $KONGSEARCH_LOG_HOME/shop2.log > /dev/null 2>&1 &
    ;;
    shop3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_5 item_143 item_192 item_10043" -l $KONGSEARCH_LOG_HOME/shop3.log > /dev/null 2>&1 &
    ;;
    shop4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_6 item_144 item_200 item_10044" -l $KONGSEARCH_LOG_HOME/shop4.log > /dev/null 2>&1 &
    ;;
    shop5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_7 item_145 item_10045" -l $KONGSEARCH_LOG_HOME/shop5.log > /dev/null 2>&1 &
    ;;
    shop6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_8 item_146 item_201 item_10046" -l $KONGSEARCH_LOG_HOME/shop6.log > /dev/null 2>&1 &
    ;;
    shop7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[9-10] item_147 item_10047" -l $KONGSEARCH_LOG_HOME/shop7.log  > /dev/null 2>&1 &
    ;;
    shop8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[11-12] item_148 item_10048" -l $KONGSEARCH_LOG_HOME/shop8.log  > /dev/null 2>&1 &
    ;;
    shop9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[13-14] item_149 item_202 item_10049" -l $KONGSEARCH_LOG_HOME/shop9.log  > /dev/null 2>&1 &
    ;;
    shop10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[15-16] item_150 item_208 item_10050" -l $KONGSEARCH_LOG_HOME/shop10.log  > /dev/null 2>&1 &
    ;;
    shop11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_17 item_151 item_216 item_10051" -l $KONGSEARCH_LOG_HOME/shop11.log > /dev/null 2>&1  &
    ;;
    shop12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_18 item_152 item_10052" -l $KONGSEARCH_LOG_HOME/shop12.log > /dev/null 2>&1  &
    ;;
    shop13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[19-20] item_153 item_222 item_10053" -l $KONGSEARCH_LOG_HOME/shop13.log > /dev/null 2>&1  &
    ;;
    shop14)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_21 item_154 item_223 item_10054" -l $KONGSEARCH_LOG_HOME/shop14.log > /dev/null 2>&1  &
    ;;
    shop15)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_22 item_155 item_248 item_10055" -l $KONGSEARCH_LOG_HOME/shop15.log > /dev/null 2>&1  &
    ;;
    shop16)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[23-24] item_156 item_10056" -l $KONGSEARCH_LOG_HOME/shop16.log > /dev/null 2>&1  &
    ;;
    shop17)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[25-26] item_157 item_10057" -l $KONGSEARCH_LOG_HOME/shop17.log  > /dev/null 2>&1 &
    ;;
    shop18)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[27-28] item_158 item_10058" -l $KONGSEARCH_LOG_HOME/shop18.log  > /dev/null 2>&1 &
    ;;
    shop19)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[29-30] item_159 item_10059" -l $KONGSEARCH_LOG_HOME/shop19.log  > /dev/null 2>&1 &
    ;;
    shop20)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[31-32] item_160 item_249 item_10060" -l $KONGSEARCH_LOG_HOME/shop20.log  > /dev/null 2>&1 &
    ;;
    shop21)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[33-34] item_161 item_10061" -l $KONGSEARCH_LOG_HOME/shop21.log > /dev/null 2>&1  &
    ;;
    shop22)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_35 item_162 item_10062" -l $KONGSEARCH_LOG_HOME/shop22.log > /dev/null 2>&1  &
    ;;
    shop23)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_36 item_163 item_250 item_10063" -l $KONGSEARCH_LOG_HOME/shop23.log > /dev/null 2>&1  &
    ;;
    shop24)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_41 item_164 item_10064" -l $KONGSEARCH_LOG_HOME/shop24.log  > /dev/null 2>&1 &
    ;;
    shop25)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_42 item_165 item_251 item_10065" -l $KONGSEARCH_LOG_HOME/shop25.log  > /dev/null 2>&1 &
    ;;
    shop26)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_43 item_166 item_252 item_10066" -l $KONGSEARCH_LOG_HOME/shop26.log  > /dev/null 2>&1 &
    ;;
    shop27)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_44 item_167 item_10067" -l $KONGSEARCH_LOG_HOME/shop27.log  > /dev/null 2>&1 &
    ;;
    shop28)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[45-46] item_168 item_10068" -l $KONGSEARCH_LOG_HOME/shop28.log  > /dev/null 2>&1 &
    ;;
    shop29)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[49-50] item_169 item_10069" -l $KONGSEARCH_LOG_HOME/shop29.log  > /dev/null 2>&1 &
    ;;
    shop30)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[51-52] item_170 item_10070" -l $KONGSEARCH_LOG_HOME/shop30.log  > /dev/null 2>&1 &
    ;;
    shop31)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[57-58] item_171 item_10071" -l $KONGSEARCH_LOG_HOME/shop31.log  > /dev/null 2>&1 &
    ;;
    shop32)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[59-60] item_172 item_253 item_10072" -l $KONGSEARCH_LOG_HOME/shop32.log  > /dev/null 2>&1 &
    ;;
    shop33)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[61-62] item_173 item_10073" -l $KONGSEARCH_LOG_HOME/shop33.log  > /dev/null 2>&1 &
    ;;
    shop34)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[63-64] item_174 item_10074" -l $KONGSEARCH_LOG_HOME/shop34.log  > /dev/null 2>&1 &
    ;;
    shop35)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[65-66] item_175 item_10075" -l $KONGSEARCH_LOG_HOME/shop35.log  > /dev/null 2>&1 &
    ;;
    shop36)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[67-68] item_176 item_10076" -l $KONGSEARCH_LOG_HOME/shop36.log  > /dev/null 2>&1 &
    ;;
    shop37)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[73-74] item_177 item_10077" -l $KONGSEARCH_LOG_HOME/shop37.log  > /dev/null 2>&1 &
    ;;
    shop38)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_75 item_178 item_254 item_10078" -l $KONGSEARCH_LOG_HOME/shop38.log  > /dev/null 2>&1 &
    ;;
    shop39)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_76 item_179 item_10079" -l $KONGSEARCH_LOG_HOME/shop39.log  > /dev/null 2>&1 &
    ;;
    shop40)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[81-82] item_180 item_10080" -l $KONGSEARCH_LOG_HOME/shop40.log  > /dev/null 2>&1 &
    ;;
    shop41)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[83-84] item_181 item_10081" -l $KONGSEARCH_LOG_HOME/shop41.log  > /dev/null 2>&1 &
    ;;
    shop42)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[85-86] item_182 item_10082" -l $KONGSEARCH_LOG_HOME/shop42.log  > /dev/null 2>&1 &
    ;;
    shop43)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[87-88] item_183 item_10083" -l $KONGSEARCH_LOG_HOME/shop43.log  > /dev/null 2>&1 &
    ;;
    shop44)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[89-90] item_184 item_10084" -l $KONGSEARCH_LOG_HOME/shop44.log  > /dev/null 2>&1 &
    ;;
    shop45)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[91-92] item_185 item_10085" -l $KONGSEARCH_LOG_HOME/shop45.log  > /dev/null 2>&1 &
    ;;
    shop46)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[93-94] item_186 item_10086" -l $KONGSEARCH_LOG_HOME/shop46.log  > /dev/null 2>&1 &
    ;;
    shop47)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[97-98] item_187 item_10087" -l $KONGSEARCH_LOG_HOME/shop47.log  > /dev/null 2>&1 &
    ;;
    shop48)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[99-100] item_188 item_10088" -l $KONGSEARCH_LOG_HOME/shop48.log  > /dev/null 2>&1 &
    ;;
    shop49)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[105-106] item_189 item_10089" -l $KONGSEARCH_LOG_HOME/shop49.log  > /dev/null 2>&1 &
    ;;
    shop50)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_107 item_190 item_10090" -l $KONGSEARCH_LOG_HOME/shop50.log  > /dev/null 2>&1 &
    ;;
    shop51)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_108 item_191 item_10091" -l $KONGSEARCH_LOG_HOME/shop51.log  > /dev/null 2>&1 &
    ;;
    shop52)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[109-110]" -l $KONGSEARCH_LOG_HOME/shop52.log  > /dev/null 2>&1 &
    ;;
    shop53)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[113-114] item_193 item_10092" -l $KONGSEARCH_LOG_HOME/shop53.log  > /dev/null 2>&1 &
    ;;
    shop54)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[115-116] item_194 item_10093" -l $KONGSEARCH_LOG_HOME/shop54.log  > /dev/null 2>&1 &
    ;;
    shop55)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[117-118] item_195 item_10094" -l $KONGSEARCH_LOG_HOME/shop55.log  > /dev/null 2>&1 &
    ;;
    shop56)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[119-120] item_196 item_10095" -l $KONGSEARCH_LOG_HOME/shop56.log  > /dev/null 2>&1 &
    ;;
    shop57)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_121 item_197 item_10096" -l $KONGSEARCH_LOG_HOME/shop57.log  > /dev/null 2>&1 &
    ;;
    shop58)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_122 item_198 item_255 item_10097" -l $KONGSEARCH_LOG_HOME/shop58.log  > /dev/null 2>&1 &
    ;;
    shop59)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[123-124] item_199 item_10098" -l $KONGSEARCH_LOG_HOME/shop59.log  > /dev/null 2>&1 &
    ;;
    shop60)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[125-126]" -l $KONGSEARCH_LOG_HOME/shop60.log  > /dev/null 2>&1 &
    ;;
    shop61)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[127-128]" -l $KONGSEARCH_LOG_HOME/shop61.log  > /dev/null 2>&1 &
    ;;
    shop62)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[129-130]" -l $KONGSEARCH_LOG_HOME/shop62.log  > /dev/null 2>&1 &
    ;;
    shop63)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[131-132] item_203 item_10099" -l $KONGSEARCH_LOG_HOME/shop63.log  > /dev/null 2>&1 &
    ;;
    shop64)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[133-134] item_204 item_10100" -l $KONGSEARCH_LOG_HOME/shop64.log  > /dev/null 2>&1 &
    ;;
    shop65)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[135-136] item_205 item_10101" -l $KONGSEARCH_LOG_HOME/shop65.log  > /dev/null 2>&1 &
    ;;
    shop66)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[137-138] item_206 item_10102" -l $KONGSEARCH_LOG_HOME/shop66.log  > /dev/null 2>&1 &
    ;;
    shop67)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_139 item_207 item_10103" -l $KONGSEARCH_LOG_HOME/shop67.log  > /dev/null 2>&1 &
    ;;
    shop68)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_140" -l $KONGSEARCH_LOG_HOME/shop68.log  > /dev/null 2>&1 &
    ;;
    shop69)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10001-10002] item_209 item_10104" -l $KONGSEARCH_LOG_HOME/shop69.log  > /dev/null 2>&1 &
    ;;
    shop70)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10003-10004] item_210 item_10105" -l $KONGSEARCH_LOG_HOME/shop70.log  > /dev/null 2>&1 &
    ;;
    shop71)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10005 item_211 item_10106" -l $KONGSEARCH_LOG_HOME/shop71.log  > /dev/null 2>&1 &
    ;;
    shop72)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10006 item_212 item_10107" -l $KONGSEARCH_LOG_HOME/shop72.log  > /dev/null 2>&1 &
    ;;
    shop73)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10007-10008] item_213 item_10108" -l $KONGSEARCH_LOG_HOME/shop73.log  > /dev/null 2>&1 &
    ;;
    shop74)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10009-10010] item_214 item_10109" -l $KONGSEARCH_LOG_HOME/shop74.log  > /dev/null 2>&1 &
    ;;
    shop75)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10011-10012] item_215 item_10110" -l $KONGSEARCH_LOG_HOME/shop75.log  > /dev/null 2>&1 &
    ;;
    shop76)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10013-10014]" -l $KONGSEARCH_LOG_HOME/shop76.log  > /dev/null 2>&1 &
    ;;
    shop77)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10015 item_217 item_10111" -l $KONGSEARCH_LOG_HOME/shop77.log  > /dev/null 2>&1 &
    ;;
    shop78)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10016 item_218 item_10112" -l $KONGSEARCH_LOG_HOME/shop78.log  > /dev/null 2>&1 &
    ;;
    shop79)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10017 item_219 item_10113" -l $KONGSEARCH_LOG_HOME/shop79.log  > /dev/null 2>&1 &
    ;;
    shop80)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_10018 item_220 item_10114" -l $KONGSEARCH_LOG_HOME/shop80.log  > /dev/null 2>&1 &
    ;;
    shop81)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10019-10020] item_221 item_10115" -l $KONGSEARCH_LOG_HOME/shop81.log  > /dev/null 2>&1 &
    ;;
    shop82)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10021-10022]" -l $KONGSEARCH_LOG_HOME/shop82.log  > /dev/null 2>&1 &
    ;;
    shop83)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10023-10024]" -l $KONGSEARCH_LOG_HOME/shop83.log  > /dev/null 2>&1 &
    ;;
    shop84)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10025-10026] item_224" -l $KONGSEARCH_LOG_HOME/shop84.log  > /dev/null 2>&1 &
    ;;
    shop85)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10027-10028] item_225" -l $KONGSEARCH_LOG_HOME/shop85.log  > /dev/null 2>&1 &
    ;;
    shop86)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10029-10030] item_226" -l $KONGSEARCH_LOG_HOME/shop86.log  > /dev/null 2>&1 &
    ;;
    shop87)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10031-10032] item_227" -l $KONGSEARCH_LOG_HOME/shop87.log  > /dev/null 2>&1 &
    ;;
    shop88)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10033-10034] item_228 item_256" -l $KONGSEARCH_LOG_HOME/shop88.log  > /dev/null 2>&1 &
    ;;
    shop89)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10035-10036] item_229 item_257" -l $KONGSEARCH_LOG_HOME/shop89.log  > /dev/null 2>&1 &
    ;;
    shop90)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10037-10038] item_230 item_258" -l $KONGSEARCH_LOG_HOME/shop90.log  > /dev/null 2>&1 &
    ;;
    shop91)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[10039-10040] item_231 item_259" -l $KONGSEARCH_LOG_HOME/shop91.log  > /dev/null 2>&1 &
    ;;
    shop92)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[50001-50002] item_232 item_260" -l $KONGSEARCH_LOG_HOME/shop92.log  > /dev/null 2>&1 &
    ;;
    shop93)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_50006 item_50011 item_50016 item_233 item_10116" -l $KONGSEARCH_LOG_HOME/shop93.log  > /dev/null 2>&1 &
    ;;
    shop94)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[53-54] item_234" -l $KONGSEARCH_LOG_HOME/shop94.log  > /dev/null 2>&1 &
    ;;
    shop95)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_55 item_235 item_10117" -l $KONGSEARCH_LOG_HOME/shop95.log  > /dev/null 2>&1 &
    ;;
    shop96)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_56 item_236 item_10118" -l $KONGSEARCH_LOG_HOME/shop96.log  > /dev/null 2>&1 &
    ;;
    shop97)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[77-78] item_237 item_10119" -l $KONGSEARCH_LOG_HOME/shop97.log  > /dev/null 2>&1 &
    ;;
    shop98)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[79-80] item_238 item_10120" -l $KONGSEARCH_LOG_HOME/shop98.log  > /dev/null 2>&1 &
    ;;
    shop99)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[37-38] item_239" -l $KONGSEARCH_LOG_HOME/shop99.log  > /dev/null 2>&1 &
    ;;
    shop100)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[39-40] item_240" -l $KONGSEARCH_LOG_HOME/shop100.log  > /dev/null 2>&1 &
    ;;
    shop101)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[69-70] item_241" -l $KONGSEARCH_LOG_HOME/shop101.log  > /dev/null 2>&1 &
    ;;
    shop102)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[71-72] item_242" -l $KONGSEARCH_LOG_HOME/shop102.log  > /dev/null 2>&1 &
    ;;
    shop103)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[101-102] item_243" -l $KONGSEARCH_LOG_HOME/shop103.log  > /dev/null 2>&1 &
    ;;
    shop104)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[103-104] item_244" -l $KONGSEARCH_LOG_HOME/shop104.log  > /dev/null 2>&1 &
    ;;
    shop105)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[47-48] item_245" -l $KONGSEARCH_LOG_HOME/shop105.log  > /dev/null 2>&1 &
    ;;
    shop106)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[111-112] item_246" -l $KONGSEARCH_LOG_HOME/shop106.log  > /dev/null 2>&1 &
    ;;
    shop107)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_[95-96] item_247" -l $KONGSEARCH_LOG_HOME/shop107.log  > /dev/null 2>&1 &
    ;;
    shopsold_a1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA1" -l $KONGSEARCH_LOG_HOME/shopsold_a1.log  > /dev/null 2>&1 &
    ;;
    shopsold_a2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA2" -l $KONGSEARCH_LOG_HOME/shopsold_a2.log  > /dev/null 2>&1 &
    ;;
    shopsold_a3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA3" -l $KONGSEARCH_LOG_HOME/shopsold_a3.log  > /dev/null 2>&1 &
    ;;
    shopsold_a4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA4" -l $KONGSEARCH_LOG_HOME/shopsold_a4.log  > /dev/null 2>&1 &
    ;;
    shopsold_a5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA5" -l $KONGSEARCH_LOG_HOME/shopsold_a5.log  > /dev/null 2>&1 &
    ;;
    shopsold_a6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA6" -l $KONGSEARCH_LOG_HOME/shopsold_a6.log  > /dev/null 2>&1 &
    ;;
    shopsold_a7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA7" -l $KONGSEARCH_LOG_HOME/shopsold_a7.log  > /dev/null 2>&1 &
    ;;
    shopsold_a8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA8" -l $KONGSEARCH_LOG_HOME/shopsold_a8.log  > /dev/null 2>&1 &
    ;;
    shopsold_a9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA9" -l $KONGSEARCH_LOG_HOME/shopsold_a9.log  > /dev/null 2>&1 &
    ;;
    shopsold_a10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA10" -l $KONGSEARCH_LOG_HOME/shopsold_a10.log  > /dev/null 2>&1 &
    ;;
    shopsold_a11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA11" -l $KONGSEARCH_LOG_HOME/shopsold_a11.log  > /dev/null 2>&1 &
    ;;
    shopsold_a12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA12" -l $KONGSEARCH_LOG_HOME/shopsold_a12.log  > /dev/null 2>&1 &
    ;;
    shopsold_a13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemA13" -l $KONGSEARCH_LOG_HOME/shopsold_a13.log  > /dev/null 2>&1 &
    ;;
    shopsold_b1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB1" -l $KONGSEARCH_LOG_HOME/shopsold_b1.log  > /dev/null 2>&1 &
    ;;
    shopsold_b2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB2" -l $KONGSEARCH_LOG_HOME/shopsold_b2.log  > /dev/null 2>&1 &
    ;;
    shopsold_b3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB3" -l $KONGSEARCH_LOG_HOME/shopsold_b3.log  > /dev/null 2>&1 &
    ;;
    shopsold_b4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB4" -l $KONGSEARCH_LOG_HOME/shopsold_b4.log  > /dev/null 2>&1 &
    ;;
    shopsold_b5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB5" -l $KONGSEARCH_LOG_HOME/shopsold_b5.log  > /dev/null 2>&1 &
    ;;
    shopsold_b6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB6" -l $KONGSEARCH_LOG_HOME/shopsold_b6.log  > /dev/null 2>&1 &
    ;;
    shopsold_b7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB7" -l $KONGSEARCH_LOG_HOME/shopsold_b7.log  > /dev/null 2>&1 &
    ;;
    shopsold_b8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB8" -l $KONGSEARCH_LOG_HOME/shopsold_b8.log  > /dev/null 2>&1 &
    ;;
    shopsold_b9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB9" -l $KONGSEARCH_LOG_HOME/shopsold_b9.log  > /dev/null 2>&1 &
    ;;
    shopsold_b10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopsold  -p "$saledItemB10" -l $KONGSEARCH_LOG_HOME/shopsold_b10.log  > /dev/null 2>&1 &
    ;;
    bookstall_a1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA1" -l $KONGSEARCH_LOG_HOME/bookstall_a1.log  > /dev/null 2>&1 &
    ;;
    bookstall_a2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA2" -l $KONGSEARCH_LOG_HOME/bookstall_a2.log  > /dev/null 2>&1 &
    ;;
    bookstall_a3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA3" -l $KONGSEARCH_LOG_HOME/bookstall_a3.log  > /dev/null 2>&1 &
    ;;
    bookstall_a4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA4" -l $KONGSEARCH_LOG_HOME/bookstall_a4.log  > /dev/null 2>&1 &
    ;;
    bookstall_a5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA5" -l $KONGSEARCH_LOG_HOME/bookstall_a5.log  > /dev/null 2>&1 &
    ;;
    bookstall_a6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA6" -l $KONGSEARCH_LOG_HOME/bookstall_a6.log  > /dev/null 2>&1 &
    ;;
    bookstall_a7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA7" -l $KONGSEARCH_LOG_HOME/bookstall_a7.log  > /dev/null 2>&1 &
    ;;
    bookstall_a8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA8" -l $KONGSEARCH_LOG_HOME/bookstall_a8.log  > /dev/null 2>&1 &
    ;;
    bookstall_a9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA9" -l $KONGSEARCH_LOG_HOME/bookstall_a9.log  > /dev/null 2>&1 &
    ;;
    bookstall_a10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemA10" -l $KONGSEARCH_LOG_HOME/bookstall_a10.log  > /dev/null 2>&1 &
    ;;
    bookstall_b1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB1" -l $KONGSEARCH_LOG_HOME/bookstall_b1.log  > /dev/null 2>&1 &
    ;;
    bookstall_b2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB2" -l $KONGSEARCH_LOG_HOME/bookstall_b2.log  > /dev/null 2>&1 &
    ;;
    bookstall_b3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB3" -l $KONGSEARCH_LOG_HOME/bookstall_b3.log  > /dev/null 2>&1 &
    ;;
    bookstall_b4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB4" -l $KONGSEARCH_LOG_HOME/bookstall_b4.log  > /dev/null 2>&1 &
    ;;
    bookstall_b5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB5" -l $KONGSEARCH_LOG_HOME/bookstall_b5.log  > /dev/null 2>&1 &
    ;;
    bookstall_b6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB6" -l $KONGSEARCH_LOG_HOME/bookstall_b6.log  > /dev/null 2>&1 &
    ;;
    bookstall_b7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB7" -l $KONGSEARCH_LOG_HOME/bookstall_b7.log  > /dev/null 2>&1 &
    ;;
    bookstall_b8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstall  -p "$itemB8" -l $KONGSEARCH_LOG_HOME/bookstall_b8.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstallsold  -p "$bookstallsoldA1" -l $KONGSEARCH_LOG_HOME/bookstallsold_a1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstallsold  -p "$bookstallsoldA2" -l $KONGSEARCH_LOG_HOME/bookstallsold_a2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstallsold  -p "$bookstallsoldB1" -l $KONGSEARCH_LOG_HOME/bookstallsold_b1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t bookstallsold  -p "$bookstallsoldB2" -l $KONGSEARCH_LOG_HOME/bookstallsold_b2.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_orders() {
  case "$1" in
    orders1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[0-10]" -l $KONGSEARCH_LOG_HOME/orders1.log  > /dev/null 2>&1 &
    ;;
    orders2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[11-20]" -l $KONGSEARCH_LOG_HOME/orders2.log  > /dev/null 2>&1 &
    ;;
    orders3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[21-30]" -l $KONGSEARCH_LOG_HOME/orders3.log  > /dev/null 2>&1 &
    ;;
    orders4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[31-40]" -l $KONGSEARCH_LOG_HOME/orders4.log  > /dev/null 2>&1 &
    ;;
    orders5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[41-50]" -l $KONGSEARCH_LOG_HOME/orders5.log  > /dev/null 2>&1 &
    ;;
    orders6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[51-60]" -l $KONGSEARCH_LOG_HOME/orders6.log  > /dev/null 2>&1 &
    ;;
    orders7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[61-70]" -l $KONGSEARCH_LOG_HOME/orders7.log  > /dev/null 2>&1 &
    ;;
    orders8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[71-80]" -l $KONGSEARCH_LOG_HOME/orders8.log  > /dev/null 2>&1 &
    ;;
    orders9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[81-90]" -l $KONGSEARCH_LOG_HOME/orders9.log  > /dev/null 2>&1 &
    ;;
    orders10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[91-100]" -l $KONGSEARCH_LOG_HOME/orders10.log  > /dev/null 2>&1 &
    ;;
    orders11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[101-110]" -l $KONGSEARCH_LOG_HOME/orders11.log  > /dev/null 2>&1 &
    ;;
    orders12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[111-120]" -l $KONGSEARCH_LOG_HOME/orders12.log  > /dev/null 2>&1 &
    ;;
    orders13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[121-130]" -l $KONGSEARCH_LOG_HOME/orders13.log  > /dev/null 2>&1 &
    ;;
    orders14)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[131-140]" -l $KONGSEARCH_LOG_HOME/orders14.log  > /dev/null 2>&1 &
    ;;
    orders15)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[141-150]" -l $KONGSEARCH_LOG_HOME/orders15.log  > /dev/null 2>&1 &
    ;;
    orders16)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[151-160]" -l $KONGSEARCH_LOG_HOME/orders16.log  > /dev/null 2>&1 &
    ;;
    orders17)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[161-170]" -l $KONGSEARCH_LOG_HOME/orders17.log  > /dev/null 2>&1 &
    ;;
    orders18)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[171-180]" -l $KONGSEARCH_LOG_HOME/orders18.log  > /dev/null 2>&1 &
    ;;
    orders19)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[181-190]" -l $KONGSEARCH_LOG_HOME/orders19.log  > /dev/null 2>&1 &
    ;;
    orders20)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t orders  -p "sellerOrderInfo_[191-200]" -l $KONGSEARCH_LOG_HOME/orders20.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_endauction() {
  case "$1" in
    enditem1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[1-5]" -l $KONGSEARCH_LOG_HOME/enditem1.log  > /dev/null 2>&1 &
    ;;
    enditem2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[6-10]" -l $KONGSEARCH_LOG_HOME/enditem2.log  > /dev/null 2>&1 &
    ;;
    enditem3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[11-15]" -l $KONGSEARCH_LOG_HOME/enditem3.log  > /dev/null 2>&1 &
    ;;
    enditem4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[16-20]" -l $KONGSEARCH_LOG_HOME/enditem4.log  > /dev/null 2>&1 &
    ;;
    enditem5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[21-25]" -l $KONGSEARCH_LOG_HOME/enditem5.log  > /dev/null 2>&1 &
    ;;
    enditem6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[26-30]" -l $KONGSEARCH_LOG_HOME/enditem6.log  > /dev/null 2>&1 &
    ;;
    enditem7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[31-35]" -l $KONGSEARCH_LOG_HOME/enditem7.log  > /dev/null 2>&1 &
    ;;
    enditem8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[36-40]" -l $KONGSEARCH_LOG_HOME/enditem8.log  > /dev/null 2>&1 &
    ;;
    enditem9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[41-45]" -l $KONGSEARCH_LOG_HOME/enditem9.log  > /dev/null 2>&1 &
    ;;
    enditem10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[46-50]" -l $KONGSEARCH_LOG_HOME/enditem10.log  > /dev/null 2>&1 &
    ;;
    enditem11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[51-55]" -l $KONGSEARCH_LOG_HOME/enditem11.log  > /dev/null 2>&1 &
    ;;
    enditem12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[56-60]" -l $KONGSEARCH_LOG_HOME/enditem12.log  > /dev/null 2>&1 &
    ;;
    enditem13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[61-65]" -l $KONGSEARCH_LOG_HOME/enditem13.log  > /dev/null 2>&1 &
    ;;
    enditem14)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[66-70]" -l $KONGSEARCH_LOG_HOME/enditem14.log  > /dev/null 2>&1 &
    ;;
    enditem15)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[71-75]" -l $KONGSEARCH_LOG_HOME/enditem15.log  > /dev/null 2>&1 &
    ;;
    enditem16)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[76-80]" -l $KONGSEARCH_LOG_HOME/enditem16.log  > /dev/null 2>&1 &
    ;;
    enditem17)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[81-85]" -l $KONGSEARCH_LOG_HOME/enditem17.log  > /dev/null 2>&1 &
    ;;
    enditem18)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[86-90]" -l $KONGSEARCH_LOG_HOME/enditem18.log  > /dev/null 2>&1 &
    ;;
    enditem19)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[91-95]" -l $KONGSEARCH_LOG_HOME/enditem19.log  > /dev/null 2>&1 &
    ;;
    enditem20)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[96-100]" -l $KONGSEARCH_LOG_HOME/enditem20.log  > /dev/null 2>&1 &
    ;;
    enditem21)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[101-105]" -l $KONGSEARCH_LOG_HOME/enditem21.log  > /dev/null 2>&1 &
    ;;
    enditem22)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[106-110]" -l $KONGSEARCH_LOG_HOME/enditem22.log  > /dev/null 2>&1 &
    ;;
    enditem23)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[111-115]" -l $KONGSEARCH_LOG_HOME/enditem23.log  > /dev/null 2>&1 &
    ;;
    enditem24)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[116-120]" -l $KONGSEARCH_LOG_HOME/enditem24.log  > /dev/null 2>&1 &
    ;;
    enditem25)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[121-125]" -l $KONGSEARCH_LOG_HOME/enditem25.log  > /dev/null 2>&1 &
    ;;
    enditem26)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[126-130]" -l $KONGSEARCH_LOG_HOME/enditem26.log  > /dev/null 2>&1 &
    ;;
    enditem27)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[131-135]" -l $KONGSEARCH_LOG_HOME/enditem27.log  > /dev/null 2>&1 &
    ;;
    enditem28)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[136-140]" -l $KONGSEARCH_LOG_HOME/enditem28.log  > /dev/null 2>&1 &
    ;;
    enditem29)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[141-145]" -l $KONGSEARCH_LOG_HOME/enditem29.log  > /dev/null 2>&1 &
    ;;
    enditem30)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[146-150]" -l $KONGSEARCH_LOG_HOME/enditem30.log  > /dev/null 2>&1 &
    ;;
    enditem31)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[151-155]" -l $KONGSEARCH_LOG_HOME/enditem31.log  > /dev/null 2>&1 &
    ;;
    enditem32)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[156-160]" -l $KONGSEARCH_LOG_HOME/enditem32.log  > /dev/null 2>&1 &
    ;;
    enditem33)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[161-165]" -l $KONGSEARCH_LOG_HOME/enditem33.log  > /dev/null 2>&1 &
    ;;
    enditem34)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[166-170]" -l $KONGSEARCH_LOG_HOME/enditem34.log  > /dev/null 2>&1 &
    ;;
    enditem35)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[171-175]" -l $KONGSEARCH_LOG_HOME/enditem35.log  > /dev/null 2>&1 &
    ;;
    enditem36)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[176-180]" -l $KONGSEARCH_LOG_HOME/enditem36.log  > /dev/null 2>&1 &
    ;;
    enditem37)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[181-185]" -l $KONGSEARCH_LOG_HOME/enditem37.log  > /dev/null 2>&1 &
    ;;
    enditem38)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[186-190]" -l $KONGSEARCH_LOG_HOME/enditem38.log  > /dev/null 2>&1 &
    ;;
    enditem39)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[191-195]" -l $KONGSEARCH_LOG_HOME/enditem39.log  > /dev/null 2>&1 &
    ;;
    enditem40)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction  -p "endItem_[196-200]" -l $KONGSEARCH_LOG_HOME/enditem40.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_endauction100() {
  case "$1" in
    enditem1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[1-2]" -l $KONGSEARCH_LOG_HOME/enditem1.log > /dev/null 2>&1 &
    ;;
    enditem2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[3-4]" -l $KONGSEARCH_LOG_HOME/enditem2.log > /dev/null 2>&1 &
    ;;
    enditem3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[5-6]" -l $KONGSEARCH_LOG_HOME/enditem3.log > /dev/null 2>&1 &
    ;;
    enditem4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[7-8]" -l $KONGSEARCH_LOG_HOME/enditem4.log > /dev/null 2>&1 &
    ;;
    enditem5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[9-10]" -l $KONGSEARCH_LOG_HOME/enditem5.log > /dev/null 2>&1 &
    ;;
    enditem6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[11-12]" -l $KONGSEARCH_LOG_HOME/enditem6.log > /dev/null 2>&1 &
    ;;
    enditem7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[13-14]" -l $KONGSEARCH_LOG_HOME/enditem7.log > /dev/null 2>&1 &
    ;;
    enditem8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[15-16]" -l $KONGSEARCH_LOG_HOME/enditem8.log > /dev/null 2>&1 &
    ;;
    enditem9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[17-18]" -l $KONGSEARCH_LOG_HOME/enditem9.log > /dev/null 2>&1 &
    ;;
    enditem10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[19-20]" -l $KONGSEARCH_LOG_HOME/enditem10.log > /dev/null 2>&1 &
    ;;
    enditem11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[21-22]" -l $KONGSEARCH_LOG_HOME/enditem11.log > /dev/null 2>&1 &
    ;;
    enditem12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[23-24]" -l $KONGSEARCH_LOG_HOME/enditem12.log > /dev/null 2>&1 &
    ;;
    enditem13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[25-26]" -l $KONGSEARCH_LOG_HOME/enditem13.log > /dev/null 2>&1 &
    ;;
    enditem14)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[27-28]" -l $KONGSEARCH_LOG_HOME/enditem14.log > /dev/null 2>&1 &
    ;;
    enditem15)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[29-30]" -l $KONGSEARCH_LOG_HOME/enditem15.log > /dev/null 2>&1 &
    ;;
    enditem16)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[31-32]" -l $KONGSEARCH_LOG_HOME/enditem16.log > /dev/null 2>&1 &
    ;;
    enditem17)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[33-34]" -l $KONGSEARCH_LOG_HOME/enditem17.log > /dev/null 2>&1 &
    ;;
    enditem18)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[35-36]" -l $KONGSEARCH_LOG_HOME/enditem18.log > /dev/null 2>&1 &
    ;;
    enditem19)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[37-38]" -l $KONGSEARCH_LOG_HOME/enditem19.log > /dev/null 2>&1 &
    ;;
    enditem20)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[39-40]" -l $KONGSEARCH_LOG_HOME/enditem20.log > /dev/null 2>&1 &
    ;;
    enditem21)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[41-42]" -l $KONGSEARCH_LOG_HOME/enditem21.log > /dev/null 2>&1 &
    ;;
    enditem22)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[43-44]" -l $KONGSEARCH_LOG_HOME/enditem22.log > /dev/null 2>&1 &
    ;;
    enditem23)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[45-46]" -l $KONGSEARCH_LOG_HOME/enditem23.log > /dev/null 2>&1 &
    ;;
    enditem24)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[47-48]" -l $KONGSEARCH_LOG_HOME/enditem24.log > /dev/null 2>&1 &
    ;;
    enditem25)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[49-50]" -l $KONGSEARCH_LOG_HOME/enditem25.log > /dev/null 2>&1 &
    ;;
    enditem26)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[51-52]" -l $KONGSEARCH_LOG_HOME/enditem26.log > /dev/null 2>&1 &
    ;;
    enditem27)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[53-54]" -l $KONGSEARCH_LOG_HOME/enditem27.log > /dev/null 2>&1 &
    ;;
    enditem28)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[55-56]" -l $KONGSEARCH_LOG_HOME/enditem28.log > /dev/null 2>&1 &
    ;;
    enditem29)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[57-58]" -l $KONGSEARCH_LOG_HOME/enditem29.log > /dev/null 2>&1 &
    ;;
    enditem30)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[59-60]" -l $KONGSEARCH_LOG_HOME/enditem30.log > /dev/null 2>&1 &
    ;;
    enditem31)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[61-62]" -l $KONGSEARCH_LOG_HOME/enditem31.log > /dev/null 2>&1 &
    ;;
    enditem32)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[63-64]" -l $KONGSEARCH_LOG_HOME/enditem32.log > /dev/null 2>&1 &
    ;;
    enditem33)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[65-66]" -l $KONGSEARCH_LOG_HOME/enditem33.log > /dev/null 2>&1 &
    ;;
    enditem34)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[67-68]" -l $KONGSEARCH_LOG_HOME/enditem34.log > /dev/null 2>&1 &
    ;;
    enditem35)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[69-70]" -l $KONGSEARCH_LOG_HOME/enditem35.log > /dev/null 2>&1 &
    ;;
    enditem36)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[71-72]" -l $KONGSEARCH_LOG_HOME/enditem36.log > /dev/null 2>&1 &
    ;;
    enditem37)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[73-74]" -l $KONGSEARCH_LOG_HOME/enditem37.log > /dev/null 2>&1 &
    ;;
    enditem38)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[75-76]" -l $KONGSEARCH_LOG_HOME/enditem38.log > /dev/null 2>&1 &
    ;;
    enditem39)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[77-78]" -l $KONGSEARCH_LOG_HOME/enditem39.log > /dev/null 2>&1 &
    ;;
    enditem40)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[79-80]" -l $KONGSEARCH_LOG_HOME/enditem40.log > /dev/null 2>&1 &
    ;;
    enditem41)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[81-82]" -l $KONGSEARCH_LOG_HOME/enditem41.log > /dev/null 2>&1 &
    ;;
    enditem42)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[83-84]" -l $KONGSEARCH_LOG_HOME/enditem42.log > /dev/null 2>&1 &
    ;;
    enditem43)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[85-86]" -l $KONGSEARCH_LOG_HOME/enditem43.log > /dev/null 2>&1 &
    ;;
    enditem44)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[87-88]" -l $KONGSEARCH_LOG_HOME/enditem44.log > /dev/null 2>&1 &
    ;;
    enditem45)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[89-90]" -l $KONGSEARCH_LOG_HOME/enditem45.log > /dev/null 2>&1 &
    ;;
    enditem46)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[91-92]" -l $KONGSEARCH_LOG_HOME/enditem46.log > /dev/null 2>&1 &
    ;;
    enditem47)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[93-94]" -l $KONGSEARCH_LOG_HOME/enditem47.log > /dev/null 2>&1 &
    ;;
    enditem48)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[95-96]" -l $KONGSEARCH_LOG_HOME/enditem48.log > /dev/null 2>&1 &
    ;;
    enditem49)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[97-98]" -l $KONGSEARCH_LOG_HOME/enditem49.log > /dev/null 2>&1 &
    ;;
    enditem50)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[99-100]" -l $KONGSEARCH_LOG_HOME/enditem50.log > /dev/null 2>&1 &
    ;;
    enditem51)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[101-102]" -l $KONGSEARCH_LOG_HOME/enditem51.log > /dev/null 2>&1 &
    ;;
    enditem52)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[103-104]" -l $KONGSEARCH_LOG_HOME/enditem52.log > /dev/null 2>&1 &
    ;;
    enditem53)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[105-106]" -l $KONGSEARCH_LOG_HOME/enditem53.log > /dev/null 2>&1 &
    ;;
    enditem54)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[107-108]" -l $KONGSEARCH_LOG_HOME/enditem54.log > /dev/null 2>&1 &
    ;;
    enditem55)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[109-110]" -l $KONGSEARCH_LOG_HOME/enditem55.log > /dev/null 2>&1 &
    ;;
    enditem56)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[111-112]" -l $KONGSEARCH_LOG_HOME/enditem56.log > /dev/null 2>&1 &
    ;;
    enditem57)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[113-114]" -l $KONGSEARCH_LOG_HOME/enditem57.log > /dev/null 2>&1 &
    ;;
    enditem58)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[115-116]" -l $KONGSEARCH_LOG_HOME/enditem58.log > /dev/null 2>&1 &
    ;;
    enditem59)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[117-118]" -l $KONGSEARCH_LOG_HOME/enditem59.log > /dev/null 2>&1 &
    ;;
    enditem60)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[119-120]" -l $KONGSEARCH_LOG_HOME/enditem60.log > /dev/null 2>&1 &
    ;;
    enditem61)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[121-122]" -l $KONGSEARCH_LOG_HOME/enditem61.log > /dev/null 2>&1 &
    ;;
    enditem62)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[123-124]" -l $KONGSEARCH_LOG_HOME/enditem62.log > /dev/null 2>&1 &
    ;;
    enditem63)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[125-126]" -l $KONGSEARCH_LOG_HOME/enditem63.log > /dev/null 2>&1 &
    ;;
    enditem64)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[127-128]" -l $KONGSEARCH_LOG_HOME/enditem64.log > /dev/null 2>&1 &
    ;;
    enditem65)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[129-130]" -l $KONGSEARCH_LOG_HOME/enditem65.log > /dev/null 2>&1 &
    ;;
    enditem66)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[131-132]" -l $KONGSEARCH_LOG_HOME/enditem66.log > /dev/null 2>&1 &
    ;;
    enditem67)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[133-134]" -l $KONGSEARCH_LOG_HOME/enditem67.log > /dev/null 2>&1 &
    ;;
    enditem68)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[135-136]" -l $KONGSEARCH_LOG_HOME/enditem68.log > /dev/null 2>&1 &
    ;;
    enditem69)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[137-138]" -l $KONGSEARCH_LOG_HOME/enditem69.log > /dev/null 2>&1 &
    ;;
    enditem70)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[139-140]" -l $KONGSEARCH_LOG_HOME/enditem70.log > /dev/null 2>&1 &
    ;;
    enditem71)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[141-142]" -l $KONGSEARCH_LOG_HOME/enditem71.log > /dev/null 2>&1 &
    ;;
    enditem72)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[143-144]" -l $KONGSEARCH_LOG_HOME/enditem72.log > /dev/null 2>&1 &
    ;;
    enditem73)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[145-146]" -l $KONGSEARCH_LOG_HOME/enditem73.log > /dev/null 2>&1 &
    ;;
    enditem74)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[147-148]" -l $KONGSEARCH_LOG_HOME/enditem74.log > /dev/null 2>&1 &
    ;;
    enditem75)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[149-150]" -l $KONGSEARCH_LOG_HOME/enditem75.log > /dev/null 2>&1 &
    ;;
    enditem76)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[151-152]" -l $KONGSEARCH_LOG_HOME/enditem76.log > /dev/null 2>&1 &
    ;;
    enditem77)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[153-154]" -l $KONGSEARCH_LOG_HOME/enditem77.log > /dev/null 2>&1 &
    ;;
    enditem78)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[155-156]" -l $KONGSEARCH_LOG_HOME/enditem78.log > /dev/null 2>&1 &
    ;;
    enditem79)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[157-158]" -l $KONGSEARCH_LOG_HOME/enditem79.log > /dev/null 2>&1 &
    ;;
    enditem80)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[159-160]" -l $KONGSEARCH_LOG_HOME/enditem80.log > /dev/null 2>&1 &
    ;;
    enditem81)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[161-162]" -l $KONGSEARCH_LOG_HOME/enditem81.log > /dev/null 2>&1 &
    ;;
    enditem82)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[163-164]" -l $KONGSEARCH_LOG_HOME/enditem82.log > /dev/null 2>&1 &
    ;;
    enditem83)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[165-166]" -l $KONGSEARCH_LOG_HOME/enditem83.log > /dev/null 2>&1 &
    ;;
    enditem84)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[167-168]" -l $KONGSEARCH_LOG_HOME/enditem84.log > /dev/null 2>&1 &
    ;;
    enditem85)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[169-170]" -l $KONGSEARCH_LOG_HOME/enditem85.log > /dev/null 2>&1 &
    ;;
    enditem86)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[171-172]" -l $KONGSEARCH_LOG_HOME/enditem86.log > /dev/null 2>&1 &
    ;;
    enditem87)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[173-174]" -l $KONGSEARCH_LOG_HOME/enditem87.log > /dev/null 2>&1 &
    ;;
    enditem88)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[175-176]" -l $KONGSEARCH_LOG_HOME/enditem88.log > /dev/null 2>&1 &
    ;;
    enditem89)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[177-178]" -l $KONGSEARCH_LOG_HOME/enditem89.log > /dev/null 2>&1 &
    ;;
    enditem90)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[179-180]" -l $KONGSEARCH_LOG_HOME/enditem90.log > /dev/null 2>&1 &
    ;;
    enditem91)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[181-182]" -l $KONGSEARCH_LOG_HOME/enditem91.log > /dev/null 2>&1 &
    ;;
    enditem92)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[183-184]" -l $KONGSEARCH_LOG_HOME/enditem92.log > /dev/null 2>&1 &
    ;;
    enditem93)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[185-186]" -l $KONGSEARCH_LOG_HOME/enditem93.log > /dev/null 2>&1 &
    ;;
    enditem94)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[187-188]" -l $KONGSEARCH_LOG_HOME/enditem94.log > /dev/null 2>&1 &
    ;;
    enditem95)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[189-190]" -l $KONGSEARCH_LOG_HOME/enditem95.log > /dev/null 2>&1 &
    ;;
    enditem96)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[191-192]" -l $KONGSEARCH_LOG_HOME/enditem96.log > /dev/null 2>&1 &
    ;;
    enditem97)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[193-194]" -l $KONGSEARCH_LOG_HOME/enditem97.log > /dev/null 2>&1 &
    ;;
    enditem98)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[195-196]" -l $KONGSEARCH_LOG_HOME/enditem98.log > /dev/null 2>&1 &
    ;;
    enditem99)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[197-198]" -l $KONGSEARCH_LOG_HOME/enditem99.log > /dev/null 2>&1 &
    ;;
    enditem100)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t endauction -p "endItem_[199-200]" -l $KONGSEARCH_LOG_HOME/enditem100.log > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_unproduct() {
  case "$1" in
    unshop1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[1-2] item_[3-4]" -l $KONGSEARCH_LOG_HOME/unshop1.log > /dev/null 2>&1 &
    ;;
    unshop2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[1-2] saledItem_[3-4]" -l $KONGSEARCH_LOG_HOME/unshop2.log > /dev/null 2>&1 &
    ;;
    unshop3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_5 item_6" -l $KONGSEARCH_LOG_HOME/unshop3.log > /dev/null 2>&1 &
    ;;
    unshop4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_5 saledItem_6" -l $KONGSEARCH_LOG_HOME/unshop4.log > /dev/null 2>&1 &
    ;;
    unshop5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_7 item_8" -l $KONGSEARCH_LOG_HOME/unshop5.log > /dev/null 2>&1 &
    ;;
    unshop6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_7 saledItem_8" -l $KONGSEARCH_LOG_HOME/unshop6.log > /dev/null 2>&1 &
    ;;
    unshop7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[9-10] item_[11-12]" -l $KONGSEARCH_LOG_HOME/unshop7.log  > /dev/null 2>&1 &
    ;;
    unshop8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[9-10] saledItem_[11-12]" -l $KONGSEARCH_LOG_HOME/unshop8.log  > /dev/null 2>&1 &
    ;;
    unshop9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[13-14] item_[15-16]" -l $KONGSEARCH_LOG_HOME/unshop9.log  > /dev/null 2>&1 &
    ;;
    unshop10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[13-14] saledItem_[15-16]" -l $KONGSEARCH_LOG_HOME/unshop10.log  > /dev/null 2>&1 &
    ;;
    unshop11)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_17 item_18" -l $KONGSEARCH_LOG_HOME/unshop11.log > /dev/null 2>&1  &
    ;;
    unshop12)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_17 saledItem_18" -l $KONGSEARCH_LOG_HOME/unshop12.log > /dev/null 2>&1  &
    ;;
    unshop13)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[19-20] item_21" -l $KONGSEARCH_LOG_HOME/unshop13.log > /dev/null 2>&1  &
    ;;
    unshop14)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[19-20] saledItem_21" -l $KONGSEARCH_LOG_HOME/unshop14.log > /dev/null 2>&1  &
    ;;
    unshop15)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_22 item_[23-24]" -l $KONGSEARCH_LOG_HOME/unshop15.log > /dev/null 2>&1  &
    ;;
    unshop16)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_22 saledItem_[23-24]" -l $KONGSEARCH_LOG_HOME/unshop16.log > /dev/null 2>&1  &
    ;;
    unshop17)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[25-26] item_[27-28]" -l $KONGSEARCH_LOG_HOME/unshop17.log  > /dev/null 2>&1 &
    ;;
    unshop18)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[25-26] saledItem_[27-28]" -l $KONGSEARCH_LOG_HOME/unshop18.log  > /dev/null 2>&1 &
    ;;
    unshop19)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[29-30] item_[31-32]" -l $KONGSEARCH_LOG_HOME/unshop19.log  > /dev/null 2>&1 &
    ;;
    unshop20)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[29-30] saledItem_[31-32]" -l $KONGSEARCH_LOG_HOME/unshop20.log  > /dev/null 2>&1 &
    ;;
    unshop21)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[33-34] item_35" -l $KONGSEARCH_LOG_HOME/unshop21.log > /dev/null 2>&1  &
    ;;
    unshop22)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[33-34] saledItem_35" -l $KONGSEARCH_LOG_HOME/unshop22.log > /dev/null 2>&1  &
    ;;
    unshop23)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_36 item_41" -l $KONGSEARCH_LOG_HOME/unshop23.log > /dev/null 2>&1  &
    ;;
    unshop24)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_36 saledItem_41" -l $KONGSEARCH_LOG_HOME/unshop24.log  > /dev/null 2>&1 &
    ;;
    unshop25)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_42 item_43" -l $KONGSEARCH_LOG_HOME/unshop25.log  > /dev/null 2>&1 &
    ;;
    unshop26)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_42 saledItem_43" -l $KONGSEARCH_LOG_HOME/unshop26.log  > /dev/null 2>&1 &
    ;;
    unshop27)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_44 item_[45-46]" -l $KONGSEARCH_LOG_HOME/unshop27.log  > /dev/null 2>&1 &
    ;;
    unshop28)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_44 saledItem_[45-46]" -l $KONGSEARCH_LOG_HOME/unshop28.log  > /dev/null 2>&1 &
    ;;
    unshop29)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[49-50] item_[51-52]" -l $KONGSEARCH_LOG_HOME/unshop29.log  > /dev/null 2>&1 &
    ;;
    unshop30)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[49-50] saledItem_[51-52]" -l $KONGSEARCH_LOG_HOME/unshop30.log  > /dev/null 2>&1 &
    ;;
    unshop31)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[57-58] item_[59-60]" -l $KONGSEARCH_LOG_HOME/unshop31.log  > /dev/null 2>&1 &
    ;;
    unshop32)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[57-58] saledItem_[59-60]" -l $KONGSEARCH_LOG_HOME/unshop32.log  > /dev/null 2>&1 &
    ;;
    unshop33)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[61-62] item_[63-64]" -l $KONGSEARCH_LOG_HOME/unshop33.log  > /dev/null 2>&1 &
    ;;
    unshop34)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[61-62] saledItem_[63-64]" -l $KONGSEARCH_LOG_HOME/unshop34.log  > /dev/null 2>&1 &
    ;;
    unshop35)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[65-66] item_[67-68]" -l $KONGSEARCH_LOG_HOME/unshop35.log  > /dev/null 2>&1 &
    ;;
    unshop36)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[65-66] saledItem_[67-68]" -l $KONGSEARCH_LOG_HOME/unshop36.log  > /dev/null 2>&1 &
    ;;
    unshop37)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[73-74] item_75" -l $KONGSEARCH_LOG_HOME/unshop37.log  > /dev/null 2>&1 &
    ;;
    unshop38)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[73-74] saledItem_75" -l $KONGSEARCH_LOG_HOME/unshop38.log  > /dev/null 2>&1 &
    ;;
    unshop39)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_76 item_[81-82]" -l $KONGSEARCH_LOG_HOME/unshop39.log  > /dev/null 2>&1 &
    ;;
    unshop40)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_76 saledItem_[81-82]" -l $KONGSEARCH_LOG_HOME/unshop40.log  > /dev/null 2>&1 &
    ;;
    unshop41)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[83-84] item_[85-86]" -l $KONGSEARCH_LOG_HOME/unshop41.log  > /dev/null 2>&1 &
    ;;
    unshop42)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[83-84] saledItem_[85-86]" -l $KONGSEARCH_LOG_HOME/unshop42.log  > /dev/null 2>&1 &
    ;;
    unshop43)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[87-88] item_[89-90]" -l $KONGSEARCH_LOG_HOME/unshop43.log  > /dev/null 2>&1 &
    ;;
    unshop44)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[87-88] saledItem_[89-90]" -l $KONGSEARCH_LOG_HOME/unshop44.log  > /dev/null 2>&1 &
    ;;
    unshop45)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[91-92] item_[93-94]" -l $KONGSEARCH_LOG_HOME/unshop45.log  > /dev/null 2>&1 &
    ;;
    unshop46)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[91-92] saledItem_[93-94]" -l $KONGSEARCH_LOG_HOME/unshop46.log  > /dev/null 2>&1 &
    ;;
    unshop47)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[97-98] item_[99-100]" -l $KONGSEARCH_LOG_HOME/unshop47.log  > /dev/null 2>&1 &
    ;;
    unshop48)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[97-98] saledItem_[99-100]" -l $KONGSEARCH_LOG_HOME/unshop48.log  > /dev/null 2>&1 &
    ;;
    unshop49)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[105-106] item_107" -l $KONGSEARCH_LOG_HOME/unshop49.log  > /dev/null 2>&1 &
    ;;
    unshop50)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[105-106] saledItem_107" -l $KONGSEARCH_LOG_HOME/unshop50.log  > /dev/null 2>&1 &
    ;;
    unshop51)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_108 item_[109-110]" -l $KONGSEARCH_LOG_HOME/unshop51.log  > /dev/null 2>&1 &
    ;;
    unshop52)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_108 saledItem_[109-110]" -l $KONGSEARCH_LOG_HOME/unshop52.log  > /dev/null 2>&1 &
    ;;
    unshop53)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[113-114] item_[115-116]" -l $KONGSEARCH_LOG_HOME/unshop53.log  > /dev/null 2>&1 &
    ;;
    unshop54)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[113-114] saledItem_[115-116]" -l $KONGSEARCH_LOG_HOME/unshop54.log  > /dev/null 2>&1 &
    ;;
    unshop55)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[117-118] item_[119-120]" -l $KONGSEARCH_LOG_HOME/unshop55.log  > /dev/null 2>&1 &
    ;;
    unshop56)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[117-118] saledItem_[119-120]" -l $KONGSEARCH_LOG_HOME/unshop56.log  > /dev/null 2>&1 &
    ;;
    unshop57)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_121 item_122" -l $KONGSEARCH_LOG_HOME/unshop57.log  > /dev/null 2>&1 &
    ;;
    unshop58)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_121 saledItem_122" -l $KONGSEARCH_LOG_HOME/unshop58.log  > /dev/null 2>&1 &
    ;;
    unshop59)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[123-124] item_[125-126]" -l $KONGSEARCH_LOG_HOME/unshop59.log  > /dev/null 2>&1 &
    ;;
    unshop60)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[123-124] saledItem_[125-126]" -l $KONGSEARCH_LOG_HOME/unshop60.log  > /dev/null 2>&1 &
    ;;
    unshop61)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[127-128] item_[129-130]" -l $KONGSEARCH_LOG_HOME/unshop61.log  > /dev/null 2>&1 &
    ;;
    unshop62)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[127-128] saledItem_[129-130]" -l $KONGSEARCH_LOG_HOME/unshop62.log  > /dev/null 2>&1 &
    ;;
    unshop63)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[131-132] item_[133-134]" -l $KONGSEARCH_LOG_HOME/unshop63.log  > /dev/null 2>&1 &
    ;;
    unshop64)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[131-132] saledItem_[133-134]" -l $KONGSEARCH_LOG_HOME/unshop64.log  > /dev/null 2>&1 &
    ;;
    unshop65)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[135-136] item_[137-138]" -l $KONGSEARCH_LOG_HOME/unshop65.log  > /dev/null 2>&1 &
    ;;
    unshop66)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[135-136] saledItem_[137-138]" -l $KONGSEARCH_LOG_HOME/unshop66.log  > /dev/null 2>&1 &
    ;;
    unshop67)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_139 item_140" -l $KONGSEARCH_LOG_HOME/unshop67.log  > /dev/null 2>&1 &
    ;;
    unshop68)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_139 saledItem_140" -l $KONGSEARCH_LOG_HOME/unshop68.log  > /dev/null 2>&1 &
    ;;
    unshop69)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10001-10002] item_[10003-10004]" -l $KONGSEARCH_LOG_HOME/unshop69.log  > /dev/null 2>&1 &
    ;;
    unshop70)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10001-10002] saledItem_[10003-10004]" -l $KONGSEARCH_LOG_HOME/unshop70.log  > /dev/null 2>&1 &
    ;;
    unshop71)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_10005 item_10006" -l $KONGSEARCH_LOG_HOME/unshop71.log  > /dev/null 2>&1 &
    ;;
    unshop72)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_10005 saledItem_10006" -l $KONGSEARCH_LOG_HOME/unshop72.log  > /dev/null 2>&1 &
    ;;
    unshop73)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10007-10008] item_[10009-10010]" -l $KONGSEARCH_LOG_HOME/unshop73.log  > /dev/null 2>&1 &
    ;;
    unshop74)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10007-10008] saledItem_[10009-10010]" -l $KONGSEARCH_LOG_HOME/unshop74.log  > /dev/null 2>&1 &
    ;;
    unshop75)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10011-10012] item_[10013-10014]" -l $KONGSEARCH_LOG_HOME/unshop75.log  > /dev/null 2>&1 &
    ;;
    unshop76)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10011-10012] saledItem_[10013-10014]" -l $KONGSEARCH_LOG_HOME/unshop76.log  > /dev/null 2>&1 &
    ;;
    unshop77)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_10015 item_10016" -l $KONGSEARCH_LOG_HOME/unshop77.log  > /dev/null 2>&1 &
    ;;
    unshop78)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_10015 saledItem_10016" -l $KONGSEARCH_LOG_HOME/unshop78.log  > /dev/null 2>&1 &
    ;;
    unshop79)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_10017 item_10018" -l $KONGSEARCH_LOG_HOME/unshop79.log  > /dev/null 2>&1 &
    ;;
    unshop80)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_10017 saledItem_10018" -l $KONGSEARCH_LOG_HOME/unshop80.log  > /dev/null 2>&1 &
    ;;
    unshop81)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10019-10020] item_[10021-10022]" -l $KONGSEARCH_LOG_HOME/unshop81.log  > /dev/null 2>&1 &
    ;;
    unshop82)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10019-10020] saledItem_[10021-10022]" -l $KONGSEARCH_LOG_HOME/unshop82.log  > /dev/null 2>&1 &
    ;;
    unshop83)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10023-10024] item_[10025-10026]" -l $KONGSEARCH_LOG_HOME/unshop83.log  > /dev/null 2>&1 &
    ;;
    unshop84)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10023-10024] saledItem_[10025-10026]" -l $KONGSEARCH_LOG_HOME/unshop84.log  > /dev/null 2>&1 &
    ;;
    unshop85)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10027-10028] item_[10029-10030]" -l $KONGSEARCH_LOG_HOME/unshop85.log  > /dev/null 2>&1 &
    ;;
    unshop86)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10027-10028] saledItem_[10029-10030]" -l $KONGSEARCH_LOG_HOME/unshop86.log  > /dev/null 2>&1 &
    ;;
    unshop87)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10031-10032] item_[10033-10034]" -l $KONGSEARCH_LOG_HOME/unshop87.log  > /dev/null 2>&1 &
    ;;
    unshop88)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10031-10032] saledItem_[10033-10034]" -l $KONGSEARCH_LOG_HOME/unshop88.log  > /dev/null 2>&1 &
    ;;
    unshop89)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10035-10036] item_[10037-10038]" -l $KONGSEARCH_LOG_HOME/unshop89.log  > /dev/null 2>&1 &
    ;;
    unshop90)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10035-10036] saledItem_[10037-10038]" -l $KONGSEARCH_LOG_HOME/unshop90.log  > /dev/null 2>&1 &
    ;;
    unshop91)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[10039-10040]" -l $KONGSEARCH_LOG_HOME/unshop91.log  > /dev/null 2>&1 &
    ;;
    unshop92)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[10039-10040]" -l $KONGSEARCH_LOG_HOME/unshop91.log  > /dev/null 2>&1 &
    ;;
    unshop93)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[53-54] item_55" -l $KONGSEARCH_LOG_HOME/unshop93.log  > /dev/null 2>&1 &
    ;;
    unshop94)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[53-54] saledItem_55" -l $KONGSEARCH_LOG_HOME/unshop94.log  > /dev/null 2>&1 &
    ;;
    unshop95)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_56 item_[77-78]" -l $KONGSEARCH_LOG_HOME/unshop95.log  > /dev/null 2>&1 &
    ;;
    unshop96)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_56 saledItem_[77-78]" -l $KONGSEARCH_LOG_HOME/unshop96.log  > /dev/null 2>&1 &
    ;;
    unshop97)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[79-80] item_[37-38]" -l $KONGSEARCH_LOG_HOME/unshop97.log  > /dev/null 2>&1 &
    ;;
    unshop98)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[79-80] saledItem_[37-38]" -l $KONGSEARCH_LOG_HOME/unshop98.log  > /dev/null 2>&1 &
    ;;
    unshop99)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[39-40] item_[69-70]" -l $KONGSEARCH_LOG_HOME/unshop99.log  > /dev/null 2>&1 &
    ;;
    unshop100)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[39-40] saledItem_[69-70]" -l $KONGSEARCH_LOG_HOME/unshop100.log  > /dev/null 2>&1 &
    ;;
    unshop101)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[71-72] item_[101-102]" -l $KONGSEARCH_LOG_HOME/unshop101.log  > /dev/null 2>&1 &
    ;;
    unshop102)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[71-72] saledItem_[101-102]" -l $KONGSEARCH_LOG_HOME/unshop102.log  > /dev/null 2>&1 &
    ;;
    unshop103)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[103-104] item_[47-48]" -l $KONGSEARCH_LOG_HOME/unshop103.log  > /dev/null 2>&1 &
    ;;
    unshop104)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[103-104] saledItem_[47-48]" -l $KONGSEARCH_LOG_HOME/unshop104.log  > /dev/null 2>&1 &
    ;;
    unshop105)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeleteitem  -p "item_[111-112] item_[95-96]" -l $KONGSEARCH_LOG_HOME/unshop105.log  > /dev/null 2>&1 &
    ;;
    unshop106)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t saleoutandisdeletesaleditem  -p "saledItem_[111-112] saledItem_[95-96]" -l $KONGSEARCH_LOG_HOME/unshop106.log  > /dev/null 2>&1 &
    ;;
    unshop_a1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50001" -l $KONGSEARCH_LOG_HOME/unshop_a1.log  > /dev/null 2>&1 &
	;;
    unshop_a2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50002" -l $KONGSEARCH_LOG_HOME/unshop_a2.log  > /dev/null 2>&1 &
	;;
    unshop_a3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50003" -l $KONGSEARCH_LOG_HOME/unshop_a3.log  > /dev/null 2>&1 &
	;;
    unshop_a4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50004" -l $KONGSEARCH_LOG_HOME/unshop_a4.log  > /dev/null 2>&1 &
    ;;
    unshop_a5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50005" -l $KONGSEARCH_LOG_HOME/unshop_a5.log  > /dev/null 2>&1 &
    ;;
    unshop_a6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50006" -l $KONGSEARCH_LOG_HOME/unshop_a6.log  > /dev/null 2>&1 &
	;;
    unshop_a7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50007" -l $KONGSEARCH_LOG_HOME/unshop_a7.log  > /dev/null 2>&1 &
	;;
    unshop_a8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50008" -l $KONGSEARCH_LOG_HOME/unshop_a8.log  > /dev/null 2>&1 &
	;;
    unshop_a9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50009" -l $KONGSEARCH_LOG_HOME/unshop_a9.log  > /dev/null 2>&1 &
    ;;
    unshop_a10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_[50010-50025]" -l $KONGSEARCH_LOG_HOME/unshop_a10.log  > /dev/null 2>&1 &
    ;;
    unshop_b1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50026" -l $KONGSEARCH_LOG_HOME/unshop_b1.log  > /dev/null 2>&1 &
	;;
    unshop_b2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50027" -l $KONGSEARCH_LOG_HOME/unshop_b2.log  > /dev/null 2>&1 &
	;;
    unshop_b3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50028" -l $KONGSEARCH_LOG_HOME/unshop_b3.log  > /dev/null 2>&1 &
	;;
    unshop_b4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50029" -l $KONGSEARCH_LOG_HOME/unshop_b4.log  > /dev/null 2>&1 &
    ;;
    unshop_b5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50030" -l $KONGSEARCH_LOG_HOME/unshop_b5.log  > /dev/null 2>&1 &
    ;;
    unshop_b6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50031" -l $KONGSEARCH_LOG_HOME/unshop_b6.log  > /dev/null 2>&1 &
	;;
    unshop_b7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50032" -l $KONGSEARCH_LOG_HOME/unshop_b7.log  > /dev/null 2>&1 &
	;;
    unshop_b8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50033" -l $KONGSEARCH_LOG_HOME/unshop_b8.log  > /dev/null 2>&1 &
	;;
    unshop_b9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50034" -l $KONGSEARCH_LOG_HOME/unshop_b9.log  > /dev/null 2>&1 &
    ;;
    unshop_b10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_[50035-50050]" -l $KONGSEARCH_LOG_HOME/unshop_b10.log  > /dev/null 2>&1 &
    ;;
    unshop_c1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50051" -l $KONGSEARCH_LOG_HOME/unshop_c1.log  > /dev/null 2>&1 &
	;;
    unshop_c2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50052" -l $KONGSEARCH_LOG_HOME/unshop_c2.log  > /dev/null 2>&1 &
	;;
    unshop_c3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50053" -l $KONGSEARCH_LOG_HOME/unshop_c3.log  > /dev/null 2>&1 &
	;;
    unshop_c4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50054" -l $KONGSEARCH_LOG_HOME/unshop_c4.log  > /dev/null 2>&1 &
    ;;
    unshop_c5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50055" -l $KONGSEARCH_LOG_HOME/unshop_c5.log  > /dev/null 2>&1 &
    ;;
    unshop_c6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50056" -l $KONGSEARCH_LOG_HOME/unshop_c6.log  > /dev/null 2>&1 &
	;;
    unshop_c7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50057" -l $KONGSEARCH_LOG_HOME/unshop_c7.log  > /dev/null 2>&1 &
	;;
    unshop_c8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50058" -l $KONGSEARCH_LOG_HOME/unshop_c8.log  > /dev/null 2>&1 &
	;;
    unshop_c9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50059" -l $KONGSEARCH_LOG_HOME/unshop_c9.log  > /dev/null 2>&1 &
    ;;
    unshop_c10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_[50060-50075]" -l $KONGSEARCH_LOG_HOME/unshop_c10.log  > /dev/null 2>&1 &
    ;;
    unshop_d1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50076" -l $KONGSEARCH_LOG_HOME/unshop_d1.log  > /dev/null 2>&1 &
	;;
    unshop_d2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50077" -l $KONGSEARCH_LOG_HOME/unshop_d2.log  > /dev/null 2>&1 &
	;;
    unshop_d3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50078" -l $KONGSEARCH_LOG_HOME/unshop_d3.log  > /dev/null 2>&1 &
	;;
    unshop_d4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50079" -l $KONGSEARCH_LOG_HOME/unshop_d4.log  > /dev/null 2>&1 &
    ;;
    unshop_d5)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50080" -l $KONGSEARCH_LOG_HOME/unshop_d5.log  > /dev/null 2>&1 &
    ;;
    unshop_d6)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50081" -l $KONGSEARCH_LOG_HOME/unshop_d6.log  > /dev/null 2>&1 &
	;;
    unshop_d7)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50082" -l $KONGSEARCH_LOG_HOME/unshop_d7.log  > /dev/null 2>&1 &
	;;
    unshop_d8)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50083" -l $KONGSEARCH_LOG_HOME/unshop_d8.log  > /dev/null 2>&1 &
	;;
    unshop_d9)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_50084" -l $KONGSEARCH_LOG_HOME/unshop_d9.log  > /dev/null 2>&1 &
    ;;
    unshop_d10)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopcloseitem  -p "item_[50085-50100]" -l $KONGSEARCH_LOG_HOME/unshop_d10.log  > /dev/null 2>&1 &
    ;;
    unshop_e1)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopclosesaleditem  -p "saledItem_[50001-50025]" -l $KONGSEARCH_LOG_HOME/unshop_e1.log  > /dev/null 2>&1 &
	;;
    unshop_e2)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopclosesaleditem  -p "saledItem_[50026-50050]" -l $KONGSEARCH_LOG_HOME/unshop_e2.log  > /dev/null 2>&1 &
	;;
    unshop_e3)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopclosesaleditem  -p "saledItem_[50051-50075]" -l $KONGSEARCH_LOG_HOME/unshop_e3.log  > /dev/null 2>&1 &
	;;
    unshop_e4)
      nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shopclosesaleditem  -p "saledItem_[50076-50100]" -l $KONGSEARCH_LOG_HOME/unshop_e4.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

case "${index}@${node}" in
  product@tslj)
    b=88
    while [ $b -le 107 ] 
    do
        start_gather_product "shop${b}"
        b=$(($b + 1)) 
        sleep 1
    done
	
    c=1
    while [ $c -le 13 ] 
    do
        start_gather_product "shopsold_a${c}"
        c=$(($c + 1)) 
        sleep 1
    done
    ;;
  product@ybq)
    b=66
    while [ $b -le 87 ] 
    do
        start_gather_product "shop${b}"
        b=$(($b + 1)) 
        sleep 1
    done
	
    c=1
    while [ $c -le 10 ] 
    do
        start_gather_product "bookstall_a${c}"
        c=$(($c + 1)) 
        sleep 1
    done

    start_gather_product "shop47"
    sleep 1
    start_gather_product "shop48"
    sleep 1
    start_gather_product "shop51"
    sleep 1
    start_gather_product "shop52"
    sleep 1
    ;;
  product@zgkm)
    a=1
    while [ $a -le 20 ] 
    do
        start_gather_product "shop${a}"
        a=$(($a + 1)) 
        sleep 1
    done

    b=61
    while [ $b -le 65 ] 
    do
        start_gather_product "shop${b}"
        b=$(($b + 1)) 
        sleep 1
    done
	
    start_gather_product "bookstallsold_b1"
    sleep 1
    start_gather_product "bookstallsold_b2"
    sleep 1
    start_gather_product "bookstallsold_a1"
    sleep 1
    start_gather_product "bookstallsold_a2"
    sleep 1

    start_gather_product "shop57"
    sleep 1
    ;;
  product@swk)
    a=46
    while [ $a -le 60 ] 
    do
        if [ $a = '47' -o $a = '48' -o $a = '51' -o $a = '52' -o $a = '57' ]; then
            a=$(($a + 1))
            continue
        fi
        start_gather_product "shop${a}"
        a=$(($a + 1)) 
        sleep 1
    done

    b=1
    while [ $b -le 10 ] 
    do
        start_gather_product "shopsold_b${b}"
        b=$(($b + 1)) 
        sleep 1
    done

    c=1
    while [ $c -le 8 ] 
    do
        start_gather_product "bookstall_b${c}"
        c=$(($c + 1)) 
        sleep 1
    done
    ;;
  product@dy)
    a=21
    while [ $a -le 45 ] 
    do
        start_gather_product "shop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  orders@swk)
    b=1
    while [ $b -le 10 ] 
    do
        start_gather_orders "orders${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  orders@tslj)
    b=11
    while [ $b -le 20 ] 
    do
        start_gather_orders "orders${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  booklib@hr)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
    ;;
  booklib@ybq)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
    ;;
  product@zxd)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t shop  -p "item_1" -l $KONGSEARCH_LOG_HOME/shop1.log > /dev/null 2>&1 &
    ;;
  orders@hr)
    b=1
    while [ $b -le 20 ] 
    do
        start_gather_orders "orders${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  booklib@local)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
    ;;
  product@local)
    b=1
    while [ $b -le 92 ] 
    do
        start_gather_product "shop${b}"
        b=$(($b + 1)) 
        sleep 1
    done

    c=1
    while [ $c -le 10 ] 
    do
        start_gather_product "shopsold_a${c}"
        c=$(($c + 1)) 
        sleep 1
    done

    start_gather_product "bookstallsold_a1"
    sleep 1
    start_gather_product "bookstallsold_a2"
    sleep 1

    c=1
    while [ $c -le 10 ] 
    do
        start_gather_product "bookstall_a${c}"
        c=$(($c + 1)) 
        sleep 1
    done

    d=1
    while [ $d -le 8 ] 
    do
	start_gather_product "bookstall_b${d}"
        d=$(($d + 1)) 
        sleep 1
    done

    c=1
    while [ $c -le 8 ] 
    do
        start_gather_product "shopsold_b${c}"
        c=$(($c + 1)) 
        sleep 1
    done

    start_gather_product "bookstallsold_b1"
    sleep 1
    start_gather_product "bookstallsold_b2"
    sleep 1
    ;;
  orders@local)
    b=1
    while [ $b -le 20 ] 
    do
        start_gather_orders "orders${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  unproduct@tslj)
    a=1
    while [ $a -le 20 ] 
    do
        start_gather_unproduct "unshop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
	
    b=1
    while [ $b -le 10 ] 
    do
        start_gather_unproduct "unshop_a${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  unproduct@ybq)
    a=21
    while [ $a -le 50 ] 
    do
        start_gather_unproduct "unshop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
	
    b=1
    while [ $b -le 10 ] 
    do
        start_gather_unproduct "unshop_b${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  unproduct@zgkm)
    a=51
    while [ $a -le 70 ] 
    do
        start_gather_unproduct "unshop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
	
    b=1
    while [ $b -le 10 ] 
    do
        start_gather_unproduct "unshop_c${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  unproduct@swk)
    a=71
    while [ $a -le 90 ] 
    do
        start_gather_unproduct "unshop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  unproduct@dy)
    a=91
    while [ $a -le 106 ] 
    do
        start_gather_unproduct "unshop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
	
    b=1
    while [ $b -le 10 ] 
    do
        start_gather_unproduct "unshop_d${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  auctioncom@ts)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
  auctioncom@zxd)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
  auctioncom@local1)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
  suggest@ts)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  suggest@qf)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  suggest@zxd)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  suggest@local1)
    nohup $PHP $GATHER_HOME/gather.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  endauction@local1)
    b=1
    while [ $b -le 1 ] 
    do
        start_gather_endauction "enditem${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  endauction@zxd)
    b=1
    while [ $b -le 1 ] 
    do
        start_gather_endauction "enditem${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  endauction@ts)
    b=1
    while [ $b -le 24 ] 
    do
        start_gather_endauction "enditem${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
  endauction@qf)
    b=25
    while [ $b -le 40 ] 
    do
        start_gather_endauction "enditem${b}"
        b=$(($b + 1)) 
        sleep 1
    done
    ;;
#  endauction@tslj)
#    b=1
#    while [ $b -le 20 ] 
#    do
#        start_gather_endauction100 "enditem${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#    ;;
#  endauction@ybq)
#    b=21
#    while [ $b -le 40 ] 
#    do
#        start_gather_endauction100 "enditem${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#    ;;
#  endauction@zgkm)
#    b=41
#    while [ $b -le 60 ] 
#    do
#        start_gather_endauction100 "enditem${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#    ;;
#  endauction@ts)
#    b=61
#    while [ $b -le 80 ] 
#    do
#        start_gather_endauction100 "enditem${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#    ;;
#  endauction@qf)
#    b=81
#    while [ $b -le 100 ] 
#    do
#        start_gather_endauction100 "enditem${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#    ;;
  product@ts)
    a=46
    while [ $a -le 60 ] 
    do
        if [ $a = '47' -o $a = '48' -o $a = '51' -o $a = '52' -o $a = '57' ]; then
            a=$(($a + 1))
            continue
        fi
        start_gather_product "shop${a}"
        a=$(($a + 1)) 
        sleep 1
    done

    b=1
    while [ $b -le 10 ] 
    do
        start_gather_product "shopsold_b${b}"
        b=$(($b + 1)) 
        sleep 1
    done

    c=1
    while [ $c -le 8 ] 
    do
        start_gather_product "bookstall_b${c}"
        c=$(($c + 1)) 
        sleep 1
    done
    ;;
  *) 
    printf 'Usage: %s INDEX\n' "$0"  
    exit 1
    ;;
 esac
