#!/bin/bash
#author: zhangxinde

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
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES_local.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES_local.ini"
  fi
elif [ $SPHINX_ENV -a $SPHINX_ENV = 'neibu' ]; then
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES_neibu.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES_neibu.ini"
  fi
else 
  if [ "$index" = 'product_sold' ]; then
    CONF="$GATHER_HOME/conf/productES.ini"
  else
    CONF="$GATHER_HOME/conf/${index}ES.ini"
  fi
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
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[1-2] item_141 item_10041" -l $KONGSEARCH_LOG_HOME/ES_shop1.log > /dev/null 2>&1 &
    ;;
    shop2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[3-4] item_142 item_10042" -l $KONGSEARCH_LOG_HOME/ES_shop2.log > /dev/null 2>&1 &
    ;;
    shop3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_5 item_143 item_192 item_10043" -l $KONGSEARCH_LOG_HOME/ES_shop3.log > /dev/null 2>&1 &
    ;;
    shop4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_6 item_144 item_200 item_10044" -l $KONGSEARCH_LOG_HOME/ES_shop4.log > /dev/null 2>&1 &
    ;;
    shop5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_7 item_145 item_10045" -l $KONGSEARCH_LOG_HOME/ES_shop5.log > /dev/null 2>&1 &
    ;;
    shop6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_8 item_146 item_201 item_10046" -l $KONGSEARCH_LOG_HOME/ES_shop6.log > /dev/null 2>&1 &
    ;;
    shop7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[9-10] item_147 item_10047" -l $KONGSEARCH_LOG_HOME/ES_shop7.log  > /dev/null 2>&1 &
    ;;
    shop8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[11-12] item_148 item_10048" -l $KONGSEARCH_LOG_HOME/ES_shop8.log  > /dev/null 2>&1 &
    ;;
    shop9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[13-14] item_149 item_202 item_10049" -l $KONGSEARCH_LOG_HOME/ES_shop9.log  > /dev/null 2>&1 &
    ;;
    shop10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[15-16] item_150 item_208 item_10050" -l $KONGSEARCH_LOG_HOME/ES_shop10.log  > /dev/null 2>&1 &
    ;;
    shop11)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_17 item_151 item_216 item_10051" -l $KONGSEARCH_LOG_HOME/ES_shop11.log > /dev/null 2>&1  &
    ;;
    shop12)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_18 item_152 item_10052" -l $KONGSEARCH_LOG_HOME/ES_shop12.log > /dev/null 2>&1  &
    ;;
    shop13)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[19-20] item_153 item_222 item_10053" -l $KONGSEARCH_LOG_HOME/ES_shop13.log > /dev/null 2>&1  &
    ;;
    shop14)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_21 item_154 item_223 item_10054" -l $KONGSEARCH_LOG_HOME/ES_shop14.log > /dev/null 2>&1  &
    ;;
    shop15)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_22 item_155 item_248 item_10055" -l $KONGSEARCH_LOG_HOME/ES_shop15.log > /dev/null 2>&1  &
    ;;
    shop16)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[23-24] item_156 item_10056" -l $KONGSEARCH_LOG_HOME/ES_shop16.log > /dev/null 2>&1  &
    ;;
    shop17)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[25-26] item_157 item_10057" -l $KONGSEARCH_LOG_HOME/ES_shop17.log  > /dev/null 2>&1 &
    ;;
    shop18)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[27-28] item_158 item_10058" -l $KONGSEARCH_LOG_HOME/ES_shop18.log  > /dev/null 2>&1 &
    ;;
    shop19)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[29-30] item_159 item_10059" -l $KONGSEARCH_LOG_HOME/ES_shop19.log  > /dev/null 2>&1 &
    ;;
    shop20)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[31-32] item_160 item_249 item_10060" -l $KONGSEARCH_LOG_HOME/ES_shop20.log  > /dev/null 2>&1 &
    ;;
    shop21)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[33-34] item_161 item_10061" -l $KONGSEARCH_LOG_HOME/ES_shop21.log > /dev/null 2>&1  &
    ;;
    shop22)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_35 item_162 item_10062" -l $KONGSEARCH_LOG_HOME/ES_shop22.log > /dev/null 2>&1  &
    ;;
    shop23)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_36 item_163 item_250 item_10063" -l $KONGSEARCH_LOG_HOME/ES_shop23.log > /dev/null 2>&1  &
    ;;
    shop24)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_41 item_164 item_10064" -l $KONGSEARCH_LOG_HOME/ES_shop24.log  > /dev/null 2>&1 &
    ;;
    shop25)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_42 item_165 item_251 item_10065" -l $KONGSEARCH_LOG_HOME/ES_shop25.log  > /dev/null 2>&1 &
    ;;
    shop26)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_43 item_166 item_252 item_10066" -l $KONGSEARCH_LOG_HOME/ES_shop26.log  > /dev/null 2>&1 &
    ;;
    shop27)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_44 item_167 item_10067" -l $KONGSEARCH_LOG_HOME/ES_shop27.log  > /dev/null 2>&1 &
    ;;
    shop28)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[45-46] item_168 item_10068" -l $KONGSEARCH_LOG_HOME/ES_shop28.log  > /dev/null 2>&1 &
    ;;
    shop29)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[49-50] item_169 item_10069" -l $KONGSEARCH_LOG_HOME/ES_shop29.log  > /dev/null 2>&1 &
    ;;
    shop30)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[51-52] item_170 item_10070" -l $KONGSEARCH_LOG_HOME/ES_shop30.log  > /dev/null 2>&1 &
    ;;
    shop31)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[57-58] item_171 item_10071" -l $KONGSEARCH_LOG_HOME/ES_shop31.log  > /dev/null 2>&1 &
    ;;
    shop32)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[59-60] item_172 item_253 item_10072" -l $KONGSEARCH_LOG_HOME/ES_shop32.log  > /dev/null 2>&1 &
    ;;
    shop33)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[61-62] item_173 item_10073" -l $KONGSEARCH_LOG_HOME/ES_shop33.log  > /dev/null 2>&1 &
    ;;
    shop34)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[63-64] item_174 item_10074" -l $KONGSEARCH_LOG_HOME/ES_shop34.log  > /dev/null 2>&1 &
    ;;
    shop35)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[65-66] item_175 item_10075" -l $KONGSEARCH_LOG_HOME/ES_shop35.log  > /dev/null 2>&1 &
    ;;
    shop36)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[67-68] item_176 item_10076" -l $KONGSEARCH_LOG_HOME/ES_shop36.log  > /dev/null 2>&1 &
    ;;
    shop37)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[73-74] item_177 item_10077" -l $KONGSEARCH_LOG_HOME/ES_shop37.log  > /dev/null 2>&1 &
    ;;
    shop38)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_75 item_178 item_254 item_10078" -l $KONGSEARCH_LOG_HOME/ES_shop38.log  > /dev/null 2>&1 &
    ;;
    shop39)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_76 item_179 item_10079" -l $KONGSEARCH_LOG_HOME/ES_shop39.log  > /dev/null 2>&1 &
    ;;
    shop40)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[81-82] item_180 item_10080" -l $KONGSEARCH_LOG_HOME/ES_shop40.log  > /dev/null 2>&1 &
    ;;
    shop41)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[83-84] item_181 item_10081" -l $KONGSEARCH_LOG_HOME/ES_shop41.log  > /dev/null 2>&1 &
    ;;
    shop42)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[85-86] item_182 item_10082" -l $KONGSEARCH_LOG_HOME/ES_shop42.log  > /dev/null 2>&1 &
    ;;
    shop43)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[87-88] item_183 item_10083" -l $KONGSEARCH_LOG_HOME/ES_shop43.log  > /dev/null 2>&1 &
    ;;
    shop44)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[89-90] item_184 item_10084" -l $KONGSEARCH_LOG_HOME/ES_shop44.log  > /dev/null 2>&1 &
    ;;
    shop45)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[91-92] item_185 item_10085" -l $KONGSEARCH_LOG_HOME/ES_shop45.log  > /dev/null 2>&1 &
    ;;
    shop46)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[93-94] item_186 item_10086" -l $KONGSEARCH_LOG_HOME/ES_shop46.log  > /dev/null 2>&1 &
    ;;
    shop47)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[97-98] item_187 item_10087" -l $KONGSEARCH_LOG_HOME/ES_shop47.log  > /dev/null 2>&1 &
    ;;
    shop48)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[99-100] item_188 item_10088" -l $KONGSEARCH_LOG_HOME/ES_shop48.log  > /dev/null 2>&1 &
    ;;
    shop49)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[105-106] item_189 item_10089" -l $KONGSEARCH_LOG_HOME/ES_shop49.log  > /dev/null 2>&1 &
    ;;
    shop50)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_107 item_190 item_10090" -l $KONGSEARCH_LOG_HOME/ES_shop50.log  > /dev/null 2>&1 &
    ;;
    shop51)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_108 item_191 item_10091" -l $KONGSEARCH_LOG_HOME/ES_shop51.log  > /dev/null 2>&1 &
    ;;
    shop52)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[109-110]" -l $KONGSEARCH_LOG_HOME/ES_shop52.log  > /dev/null 2>&1 &
    ;;
    shop53)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[113-114] item_193 item_10092" -l $KONGSEARCH_LOG_HOME/ES_shop53.log  > /dev/null 2>&1 &
    ;;
    shop54)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[115-116] item_194 item_10093" -l $KONGSEARCH_LOG_HOME/ES_shop54.log  > /dev/null 2>&1 &
    ;;
    shop55)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[117-118] item_195 item_10094" -l $KONGSEARCH_LOG_HOME/ES_shop55.log  > /dev/null 2>&1 &
    ;;
    shop56)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[119-120] item_196 item_10095" -l $KONGSEARCH_LOG_HOME/ES_shop56.log  > /dev/null 2>&1 &
    ;;
    shop57)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_121 item_197 item_10096" -l $KONGSEARCH_LOG_HOME/ES_shop57.log  > /dev/null 2>&1 &
    ;;
    shop58)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_122 item_198 item_255 item_10097" -l $KONGSEARCH_LOG_HOME/ES_shop58.log  > /dev/null 2>&1 &
    ;;
    shop59)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[123-124] item_199 item_10098" -l $KONGSEARCH_LOG_HOME/ES_shop59.log  > /dev/null 2>&1 &
    ;;
    shop60)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[125-126]" -l $KONGSEARCH_LOG_HOME/ES_shop60.log  > /dev/null 2>&1 &
    ;;
    shop61)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[127-128]" -l $KONGSEARCH_LOG_HOME/ES_shop61.log  > /dev/null 2>&1 &
    ;;
    shop62)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[129-130]" -l $KONGSEARCH_LOG_HOME/ES_shop62.log  > /dev/null 2>&1 &
    ;;
    shop63)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[131-132] item_203 item_10099" -l $KONGSEARCH_LOG_HOME/ES_shop63.log  > /dev/null 2>&1 &
    ;;
    shop64)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[133-134] item_204 item_10100" -l $KONGSEARCH_LOG_HOME/ES_shop64.log  > /dev/null 2>&1 &
    ;;
    shop65)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[135-136] item_205 item_10101" -l $KONGSEARCH_LOG_HOME/ES_shop65.log  > /dev/null 2>&1 &
    ;;
    shop66)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[137-138] item_206 item_10102" -l $KONGSEARCH_LOG_HOME/ES_shop66.log  > /dev/null 2>&1 &
    ;;
    shop67)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_139 item_207 item_10103" -l $KONGSEARCH_LOG_HOME/ES_shop67.log  > /dev/null 2>&1 &
    ;;
    shop68)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_140" -l $KONGSEARCH_LOG_HOME/ES_shop68.log  > /dev/null 2>&1 &
    ;;
    shop69)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10001-10002] item_209 item_10104" -l $KONGSEARCH_LOG_HOME/ES_shop69.log  > /dev/null 2>&1 &
    ;;
    shop70)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10003-10004] item_210 item_10105" -l $KONGSEARCH_LOG_HOME/ES_shop70.log  > /dev/null 2>&1 &
    ;;
    shop71)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10005 item_211 item_10106" -l $KONGSEARCH_LOG_HOME/ES_shop71.log  > /dev/null 2>&1 &
    ;;
    shop72)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10006 item_212 item_10107" -l $KONGSEARCH_LOG_HOME/ES_shop72.log  > /dev/null 2>&1 &
    ;;
    shop73)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10007-10008] item_213 item_10108" -l $KONGSEARCH_LOG_HOME/ES_shop73.log  > /dev/null 2>&1 &
    ;;
    shop74)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10009-10010] item_214 item_10109" -l $KONGSEARCH_LOG_HOME/ES_shop74.log  > /dev/null 2>&1 &
    ;;
    shop75)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10011-10012] item_215 item_10110" -l $KONGSEARCH_LOG_HOME/ES_shop75.log  > /dev/null 2>&1 &
    ;;
    shop76)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10013-10014]" -l $KONGSEARCH_LOG_HOME/ES_shop76.log  > /dev/null 2>&1 &
    ;;
    shop77)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10015 item_217 item_10111" -l $KONGSEARCH_LOG_HOME/ES_shop77.log  > /dev/null 2>&1 &
    ;;
    shop78)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10016 item_218 item_10112" -l $KONGSEARCH_LOG_HOME/ES_shop78.log  > /dev/null 2>&1 &
    ;;
    shop79)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10017 item_219 item_10113" -l $KONGSEARCH_LOG_HOME/ES_shop79.log  > /dev/null 2>&1 &
    ;;
    shop80)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_10018 item_220 item_10114" -l $KONGSEARCH_LOG_HOME/ES_shop80.log  > /dev/null 2>&1 &
    ;;
    shop81)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10019-10020] item_221 item_10115" -l $KONGSEARCH_LOG_HOME/ES_shop81.log  > /dev/null 2>&1 &
    ;;
    shop82)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10021-10022]" -l $KONGSEARCH_LOG_HOME/ES_shop82.log  > /dev/null 2>&1 &
    ;;
    shop83)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10023-10024]" -l $KONGSEARCH_LOG_HOME/ES_shop83.log  > /dev/null 2>&1 &
    ;;
    shop84)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10025-10026] item_224" -l $KONGSEARCH_LOG_HOME/ES_shop84.log  > /dev/null 2>&1 &
    ;;
    shop85)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10027-10028] item_225" -l $KONGSEARCH_LOG_HOME/ES_shop85.log  > /dev/null 2>&1 &
    ;;
    shop86)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10029-10030] item_226" -l $KONGSEARCH_LOG_HOME/ES_shop86.log  > /dev/null 2>&1 &
    ;;
    shop87)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10031-10032] item_227" -l $KONGSEARCH_LOG_HOME/ES_shop87.log  > /dev/null 2>&1 &
    ;;
    shop88)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10033-10034] item_228 item_256" -l $KONGSEARCH_LOG_HOME/ES_shop88.log  > /dev/null 2>&1 &
    ;;
    shop89)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10035-10036] item_229 item_257" -l $KONGSEARCH_LOG_HOME/ES_shop89.log  > /dev/null 2>&1 &
    ;;
    shop90)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10037-10038] item_230 item_258" -l $KONGSEARCH_LOG_HOME/ES_shop90.log  > /dev/null 2>&1 &
    ;;
    shop91)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10039-10040] item_231 item_259" -l $KONGSEARCH_LOG_HOME/ES_shop91.log  > /dev/null 2>&1 &
    ;;
    shop92)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[50001-50002] item_232 item_260" -l $KONGSEARCH_LOG_HOME/ES_shop92.log  > /dev/null 2>&1 &
    ;;
    shop93)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_50006 item_50011 item_50016 item_233 item_10116" -l $KONGSEARCH_LOG_HOME/ES_shop93.log  > /dev/null 2>&1 &
    ;;
    shop94)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[53-54] item_234" -l $KONGSEARCH_LOG_HOME/ES_shop94.log  > /dev/null 2>&1 &
    ;;
    shop95)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_55 item_235 item_10117" -l $KONGSEARCH_LOG_HOME/ES_shop95.log  > /dev/null 2>&1 &
    ;;
    shop96)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_56 item_236 item_10118" -l $KONGSEARCH_LOG_HOME/ES_shop96.log  > /dev/null 2>&1 &
    ;;
    shop97)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[77-78] item_237 item_10119" -l $KONGSEARCH_LOG_HOME/ES_shop97.log  > /dev/null 2>&1 &
    ;;
    shop98)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[79-80] item_238 item_10120" -l $KONGSEARCH_LOG_HOME/ES_shop98.log  > /dev/null 2>&1 &
    ;;
    shop99)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[37-38] item_239" -l $KONGSEARCH_LOG_HOME/ES_shop99.log  > /dev/null 2>&1 &
    ;;
    shop100)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[39-40] item_240" -l $KONGSEARCH_LOG_HOME/ES_shop100.log  > /dev/null 2>&1 &
    ;;
    shop101)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[69-70] item_241" -l $KONGSEARCH_LOG_HOME/ES_shop101.log  > /dev/null 2>&1 &
    ;;
    shop102)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[71-72] item_242" -l $KONGSEARCH_LOG_HOME/ES_shop102.log  > /dev/null 2>&1 &
    ;;
    shop103)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[101-102] item_243" -l $KONGSEARCH_LOG_HOME/ES_shop103.log  > /dev/null 2>&1 &
    ;;
    shop104)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[103-104] item_244" -l $KONGSEARCH_LOG_HOME/ES_shop104.log  > /dev/null 2>&1 &
    ;;
    shop105)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[47-48] item_245" -l $KONGSEARCH_LOG_HOME/ES_shop105.log  > /dev/null 2>&1 &
    ;;
    shop106)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[111-112] item_246" -l $KONGSEARCH_LOG_HOME/ES_shop106.log  > /dev/null 2>&1 &
    ;;
    shop107)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[95-96] item_247" -l $KONGSEARCH_LOG_HOME/ES_shop107.log  > /dev/null 2>&1 &
    ;;
    shopsold_a1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA1" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a1.log  > /dev/null 2>&1 &
    ;;
    shopsold_a2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA2" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a2.log  > /dev/null 2>&1 &
    ;;
    shopsold_a3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA3" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a3.log  > /dev/null 2>&1 &
    ;;
    shopsold_a4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA4" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a4.log  > /dev/null 2>&1 &
    ;;
    shopsold_a5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA5" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a5.log  > /dev/null 2>&1 &
    ;;
    shopsold_a6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA6" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a6.log  > /dev/null 2>&1 &
    ;;
    shopsold_a7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA7" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a7.log  > /dev/null 2>&1 &
    ;;
    shopsold_a8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA8" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a8.log  > /dev/null 2>&1 &
    ;;
    shopsold_a9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA9" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a9.log  > /dev/null 2>&1 &
    ;;
    shopsold_a10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA10" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a10.log  > /dev/null 2>&1 &
    ;;
    shopsold_a11)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA11" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a11.log  > /dev/null 2>&1 &
    ;;
    shopsold_a12)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA12" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a12.log  > /dev/null 2>&1 &
    ;;
    shopsold_a13)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA13" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a13.log  > /dev/null 2>&1 &
    ;;
    shopsold_b1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB1" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b1.log  > /dev/null 2>&1 &
    ;;
    shopsold_b2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB2" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b2.log  > /dev/null 2>&1 &
    ;;
    shopsold_b3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB3" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b3.log  > /dev/null 2>&1 &
    ;;
    shopsold_b4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB4" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b4.log  > /dev/null 2>&1 &
    ;;
    shopsold_b5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB5" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b5.log  > /dev/null 2>&1 &
    ;;
    shopsold_b6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB6" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b6.log  > /dev/null 2>&1 &
    ;;
    shopsold_b7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB7" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b7.log  > /dev/null 2>&1 &
    ;;
    shopsold_b8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB8" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b8.log  > /dev/null 2>&1 &
    ;;
    shopsold_b9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB9" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b9.log  > /dev/null 2>&1 &
    ;;
    shopsold_b10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB10" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b10.log  > /dev/null 2>&1 &
    ;;
    bookstall_a1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA1" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a1.log  > /dev/null 2>&1 &
    ;;
    bookstall_a2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA2" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a2.log  > /dev/null 2>&1 &
    ;;
    bookstall_a3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA3" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a3.log  > /dev/null 2>&1 &
    ;;
    bookstall_a4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA4" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a4.log  > /dev/null 2>&1 &
    ;;
    bookstall_a5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA5" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a5.log  > /dev/null 2>&1 &
    ;;
    bookstall_a6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA6" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a6.log  > /dev/null 2>&1 &
    ;;
    bookstall_a7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA7" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a7.log  > /dev/null 2>&1 &
    ;;
    bookstall_a8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA8" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a8.log  > /dev/null 2>&1 &
    ;;
    bookstall_a9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA9" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a9.log  > /dev/null 2>&1 &
    ;;
    bookstall_a10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA10" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a10.log  > /dev/null 2>&1 &
    ;;
    bookstall_b1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB1" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b1.log  > /dev/null 2>&1 &
    ;;
    bookstall_b2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB2" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b2.log  > /dev/null 2>&1 &
    ;;
    bookstall_b3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB3" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b3.log  > /dev/null 2>&1 &
    ;;
    bookstall_b4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB4" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b4.log  > /dev/null 2>&1 &
    ;;
    bookstall_b5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB5" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b5.log  > /dev/null 2>&1 &
    ;;
    bookstall_b6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB6" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b6.log  > /dev/null 2>&1 &
    ;;
    bookstall_b7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB7" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b7.log  > /dev/null 2>&1 &
    ;;
    bookstall_b8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB8" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b8.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldA1" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold_a1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_a2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldA2" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold_a2.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldB1" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold_b1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold_b2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldB2" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold_b2.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_product_es_10() {
    itemA1="item_[1-10] item_10001 item_[11-20] item_10003 item_[21-25] item_[102-105] item_10007 item_[141-150] item_[10041-10050]"
    itemA2="item_[121-125] item_[10019-10023] item_10012 item_[10031-10040] item_[26-35] item_[151-170] item_[10051-10060]"
    itemA3="item_[36-45] item_[46-50] item_[106-110] item_[126-130] item_[10015-10016] item_[10024-10030] item_10002 item_10005 item_10011 item_[171-190] item_[10061-10069]"
    itemB1="item_[51-60] item_[61-70] item_[71-75] item_[111-115] item_[191-210] item_[10070-10085]"
    itemB2="item_[131-135] item_101 item_10006 item_10008 item_10014 item_[76-85] item_[86-95] item_[211-230] item_[10086-10100]"
    itemB3="item_[96-100] item_[116-120] item_[136-140] item_[10009-10010] item_10004 item_10013 item_10017 item_10018 item_[231-260] item_[10111-10120]"
    saledItemA1="saledItem_[1-5] saledItem_[6-10] saledItem_[11-15] saledItem_[141-150] saledItem_[10041-10050]"
    saledItemA2="saledItem_[16-20] saledItem_[21-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[50001-50025] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[151-160] saledItem_[10051-10060]"
    saledItemA3="saledItem_[10031-10040] saledItem_[26-30] saledItem_[31-35] saledItem_[161-175] saledItem_[10061-10065]"
    saledItemA4="saledItem_[36-45] saledItem_[46-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[50026-50050] saledItem_[176-190] saledItem_[10066-10069]"
    saledItemB1="saledItem_[51-55] saledItem_[56-60] saledItem_[61-70] saledItem_[191-200] saledItem_[10070-10080]"
    saledItemB2="saledItem_[71-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[50051-50075] saledItem_[76-80] saledItem_[201-220] saledItem_[10081-10090]"
    saledItemB3="saledItem_[81-85] saledItem_[76-80] saledItem_[96-100] saledItem_[116-120] saledItem_[221-240] saledItem_[10091-10100]"
    saledItemB4="saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[50076-50100] saledItem_[241-260] saledItem_[10101-10120]"
    bookstallsoldA="saledItem_[1-25] saledItem_[102-105] saledItem_[121-125] saledItem_[10019-10023] saledItem_[10031-10040] saledItem_[50001-50025] saledItem_10001 saledItem_10003 saledItem_10007 saledItem_10012 saledItem_[26-50] saledItem_[106-110] saledItem_[126-130] saledItem_[10015-10016] saledItem_[10024-10030] saledItem_10002 saledItem_10005 saledItem_10011 saledItem_[50026-50050] saledItem_[141-190] saledItem_[10041-10069]"
    bookstallsoldB="saledItem_[51-75] saledItem_[111-115] saledItem_[131-135] saledItem_101 saledItem_10006 saledItem_10008 saledItem_10014 saledItem_[50051-50075] saledItem_[76-100] saledItem_[116-120] saledItem_[136-140] saledItem_[10009-10010] saledItem_10004 saledItem_10013 saledItem_10017 saledItem_10018 saledItem_[50076-50100] saledItem_[191-260] saledItem_[10070-10120]"

    case "$1" in
    shop10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10033-10037] item_[141-144]" -l $KONGSEARCH_LOG_HOME/ES_shop_10.log > /dev/null 2>&1 &
    ;;
    shop11)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10038-10040] item_[50001-50002] item_[145-148]" -l $KONGSEARCH_LOG_HOME/ES_shop_11.log > /dev/null 2>&1 &
    ;;
    shop12)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_50006 item_[53-56] item_[149-152]" -l $KONGSEARCH_LOG_HOME/ES_shop_12.log > /dev/null 2>&1 &
    ;;
    shop13)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_50011 item_[77-80] item_[153-156]" -l $KONGSEARCH_LOG_HOME/ES_shop_13.log > /dev/null 2>&1 &
    ;;
    shop14)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_50016 item_[37-40] item_[157-160]" -l $KONGSEARCH_LOG_HOME/ES_shop_14.log > /dev/null 2>&1 &
    ;;
    shop15)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[69-72] item_[161-164]" -l $KONGSEARCH_LOG_HOME/ES_shop_15.log > /dev/null 2>&1 &
    ;;
    shop16)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[101-104] item_95 item_[165-168] item_[10119-10120]" -l $KONGSEARCH_LOG_HOME/ES_shop_16.log > /dev/null 2>&1 &
    ;;
    shop17)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[47-48] item_[111-112] item_96 item_[169-172] item_[10116-10118]" -l $KONGSEARCH_LOG_HOME/ES_shop_17.log > /dev/null 2>&1 &
    ;;
    shop20)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[137-140] item_10001 item_[173-176] item_[10113-10115]" -l $KONGSEARCH_LOG_HOME/ES_shop20.log  > /dev/null 2>&1 &
    ;;
    shop21)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10002-10006] item_[177-180] item_[10110-10112]" -l $KONGSEARCH_LOG_HOME/ES_shop21.log  > /dev/null 2>&1 &
    ;;
    shop22)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10007-10011] item_[181-184] item_[10107-10109]" -l $KONGSEARCH_LOG_HOME/ES_shop22.log  > /dev/null 2>&1 &
    ;;
    shop23)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10012-10016] item_[185-188] item_[10104-10106]" -l $KONGSEARCH_LOG_HOME/ES_shop23.log  > /dev/null 2>&1 &
    ;;
    shop24)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10017-10021] item_[189-192] item_[10101-10103]" -l $KONGSEARCH_LOG_HOME/ES_shop24.log  > /dev/null 2>&1 &
    ;;
    shop25)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10022-10026] item_[193-196] item_[10098-10100]" -l $KONGSEARCH_LOG_HOME/ES_shop25.log  > /dev/null 2>&1 &
    ;;
    shop26)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[10027-10032] item_[197-200] item_[10095-10097]" -l $KONGSEARCH_LOG_HOME/ES_shop26.log  > /dev/null 2>&1 &
    ;;
    shop30)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[1-5] item_[201-204] item_[10092-10094]" -l $KONGSEARCH_LOG_HOME/ES_shop30.log > /dev/null 2>&1 &
    ;;
    shop31)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[6-10] item_[205-208] item_[10089-10091]" -l $KONGSEARCH_LOG_HOME/ES_shop31.log > /dev/null 2>&1 &
    ;;
    shop32)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[11-15] item_[209-212] item_[10086-10088]" -l $KONGSEARCH_LOG_HOME/ES_shop32.log > /dev/null 2>&1 &
    ;;
    shop33)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[16-20] item_[213-216] item_[10083-10085]" -l $KONGSEARCH_LOG_HOME/ES_shop33.log > /dev/null 2>&1 &
    ;;
    shop34)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[21-25] item_[217-220] item_[10080-10082]" -l $KONGSEARCH_LOG_HOME/ES_shop34.log > /dev/null 2>&1 &
    ;;
    shop35)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[26-30] item_[221-224] item_[10077-10079]" -l $KONGSEARCH_LOG_HOME/ES_shop35.log > /dev/null 2>&1 &
    ;;
    shop36)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[31-32] item_[127-129] item_[225-228] item_[10074-10076]" -l $KONGSEARCH_LOG_HOME/ES_shop36.log > /dev/null 2>&1 &
    ;;
    shop37)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[130-134] item_[229-232] item_[10071-10073]" -l $KONGSEARCH_LOG_HOME/ES_shop37.log > /dev/null 2>&1 &
    ;;
    shop38)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[135-136] item_[233-236] item_[10068-10070]" -l $KONGSEARCH_LOG_HOME/ES_shop38.log > /dev/null 2>&1 &
    ;;
    shop40)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[93-94] item_[97-99] item_[237-240] item_[10065-10067]" -l $KONGSEARCH_LOG_HOME/ES_shop40.log > /dev/null 2>&1 &
    ;;
    shop41)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_100 item_[105-108] item_[241-244] item_[10062-10064]" -l $KONGSEARCH_LOG_HOME/ES_shop41.log > /dev/null 2>&1 &
    ;;
    shop42)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[109-110] item_[113-115] item_[245-248] item_[10059-10061]" -l $KONGSEARCH_LOG_HOME/ES_shop42.log > /dev/null 2>&1 &
    ;;
    shop43)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[116-120] item_[249-252] item_[10056-10058]" -l $KONGSEARCH_LOG_HOME/ES_shop43.log > /dev/null 2>&1 &
    ;;
    shop44)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[121-124] item_[253-256] item_[10053-10055]" -l $KONGSEARCH_LOG_HOME/ES_shop44.log > /dev/null 2>&1 &
    ;;
    shop45)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[125-126] item_[257-260] item_[10050-10052]" -l $KONGSEARCH_LOG_HOME/ES_shop45.log > /dev/null 2>&1 &
    ;;
    shop50)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[33-36] item_41 item_[10047-10049]" -l $KONGSEARCH_LOG_HOME/ES_shop50.log > /dev/null 2>&1 &
    ;;
    shop51)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[42-46] item_[10044-10046]" -l $KONGSEARCH_LOG_HOME/ES_shop51.log > /dev/null 2>&1 &
    ;;
    shop52)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[49-52] item_57 item_[10041-10043]" -l $KONGSEARCH_LOG_HOME/ES_shop52.log > /dev/null 2>&1 &
    ;;
    shop53)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[58-62]" -l $KONGSEARCH_LOG_HOME/ES_shop53.log > /dev/null 2>&1 &
    ;;
    shop54)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[63-67]" -l $KONGSEARCH_LOG_HOME/ES_shop54.log > /dev/null 2>&1 &
    ;;
    shop55)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_68 item_[73-76]" -l $KONGSEARCH_LOG_HOME/ES_shop55.log > /dev/null 2>&1 &
    ;;
    shop56)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[81-86]" -l $KONGSEARCH_LOG_HOME/ES_shop56.log > /dev/null 2>&1 &
    ;;
    shop57)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_[87-92]" -l $KONGSEARCH_LOG_HOME/ES_shop57.log > /dev/null 2>&1 &
    ;;
    shopsold_a1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA1" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a1.log  > /dev/null 2>&1 &
    ;;
    shopsold_a2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA2" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a2.log  > /dev/null 2>&1 &
    ;;
    shopsold_a3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA3" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a3.log  > /dev/null 2>&1 &
    ;;
    shopsold_a4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemA4" -l $KONGSEARCH_LOG_HOME/ES_shopsold_a4.log  > /dev/null 2>&1 &
    ;;
    shopsold_b1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB1" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b1.log  > /dev/null 2>&1 &
    ;;
    shopsold_b2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB2" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b2.log  > /dev/null 2>&1 &
    ;;
    shopsold_b3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB3" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b3.log  > /dev/null 2>&1 &
    ;;
    shopsold_b4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "$saledItemB4" -l $KONGSEARCH_LOG_HOME/ES_shopsold_b4.log  > /dev/null 2>&1 &
    ;;
    bookstall_a1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA1" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a1.log  > /dev/null 2>&1 &
    ;;
    bookstall_a2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA2" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a2.log  > /dev/null 2>&1 &
    ;;
    bookstall_a3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemA3" -l $KONGSEARCH_LOG_HOME/ES_bookstall_a3.log  > /dev/null 2>&1 &
    ;;
    bookstall_b1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB1" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b1.log  > /dev/null 2>&1 &
    ;;
    bookstall_b2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB2" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b2.log  > /dev/null 2>&1 &
    ;;
    bookstall_b3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstall  -p "$itemB3" -l $KONGSEARCH_LOG_HOME/ES_bookstall_b3.log  > /dev/null 2>&1 &
    ;;
    bookstallsold1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldA" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold1.log  > /dev/null 2>&1 &
    ;;
    bookstallsold2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t bookstallsold  -p "$bookstallsoldB" -l $KONGSEARCH_LOG_HOME/ES_bookstallsold2.log  > /dev/null 2>&1 &
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
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[1-5]" -l $KONGSEARCH_LOG_HOME/ES_enditem1.log  > /dev/null 2>&1 &
    ;;
    enditem2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[6-10]" -l $KONGSEARCH_LOG_HOME/ES_enditem2.log  > /dev/null 2>&1 &
    ;;
    enditem3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[11-15]" -l $KONGSEARCH_LOG_HOME/ES_enditem3.log  > /dev/null 2>&1 &
    ;;
    enditem4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[16-20]" -l $KONGSEARCH_LOG_HOME/ES_enditem4.log  > /dev/null 2>&1 &
    ;;
    enditem5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[21-25]" -l $KONGSEARCH_LOG_HOME/ES_enditem5.log  > /dev/null 2>&1 &
    ;;
    enditem6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[26-30]" -l $KONGSEARCH_LOG_HOME/ES_enditem6.log  > /dev/null 2>&1 &
    ;;
    enditem7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[31-35]" -l $KONGSEARCH_LOG_HOME/ES_enditem7.log  > /dev/null 2>&1 &
    ;;
    enditem8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[36-40]" -l $KONGSEARCH_LOG_HOME/ES_enditem8.log  > /dev/null 2>&1 &
    ;;
    enditem9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[41-45]" -l $KONGSEARCH_LOG_HOME/ES_enditem9.log  > /dev/null 2>&1 &
    ;;
    enditem10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[46-50]" -l $KONGSEARCH_LOG_HOME/ES_enditem10.log  > /dev/null 2>&1 &
    ;;
    enditem11)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[51-55]" -l $KONGSEARCH_LOG_HOME/ES_enditem11.log  > /dev/null 2>&1 &
    ;;
    enditem12)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[56-60]" -l $KONGSEARCH_LOG_HOME/ES_enditem12.log  > /dev/null 2>&1 &
    ;;
    enditem13)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[61-65]" -l $KONGSEARCH_LOG_HOME/ES_enditem13.log  > /dev/null 2>&1 &
    ;;
    enditem14)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[66-70]" -l $KONGSEARCH_LOG_HOME/ES_enditem14.log  > /dev/null 2>&1 &
    ;;
    enditem15)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[71-75]" -l $KONGSEARCH_LOG_HOME/ES_enditem15.log  > /dev/null 2>&1 &
    ;;
    enditem16)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[76-80]" -l $KONGSEARCH_LOG_HOME/ES_enditem16.log  > /dev/null 2>&1 &
    ;;
    enditem17)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[81-85]" -l $KONGSEARCH_LOG_HOME/ES_enditem17.log  > /dev/null 2>&1 &
    ;;
    enditem18)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[86-90]" -l $KONGSEARCH_LOG_HOME/ES_enditem18.log  > /dev/null 2>&1 &
    ;;
    enditem19)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[91-95]" -l $KONGSEARCH_LOG_HOME/ES_enditem19.log  > /dev/null 2>&1 &
    ;;
    enditem20)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[96-100]" -l $KONGSEARCH_LOG_HOME/ES_enditem20.log  > /dev/null 2>&1 &
    ;;
    enditem21)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[101-105]" -l $KONGSEARCH_LOG_HOME/ES_enditem21.log  > /dev/null 2>&1 &
    ;;
    enditem22)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[106-110]" -l $KONGSEARCH_LOG_HOME/ES_enditem22.log  > /dev/null 2>&1 &
    ;;
    enditem23)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[111-115]" -l $KONGSEARCH_LOG_HOME/ES_enditem23.log  > /dev/null 2>&1 &
    ;;
    enditem24)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[116-120]" -l $KONGSEARCH_LOG_HOME/ES_enditem24.log  > /dev/null 2>&1 &
    ;;
    enditem25)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[121-125]" -l $KONGSEARCH_LOG_HOME/ES_enditem25.log  > /dev/null 2>&1 &
    ;;
    enditem26)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[126-130]" -l $KONGSEARCH_LOG_HOME/ES_enditem26.log  > /dev/null 2>&1 &
    ;;
    enditem27)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[131-135]" -l $KONGSEARCH_LOG_HOME/ES_enditem27.log  > /dev/null 2>&1 &
    ;;
    enditem28)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[136-140]" -l $KONGSEARCH_LOG_HOME/ES_enditem28.log  > /dev/null 2>&1 &
    ;;
    enditem29)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[141-145]" -l $KONGSEARCH_LOG_HOME/ES_enditem29.log  > /dev/null 2>&1 &
    ;;
    enditem30)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[146-150]" -l $KONGSEARCH_LOG_HOME/ES_enditem30.log  > /dev/null 2>&1 &
    ;;
    enditem31)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[151-155]" -l $KONGSEARCH_LOG_HOME/ES_enditem31.log  > /dev/null 2>&1 &
    ;;
    enditem32)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[156-160]" -l $KONGSEARCH_LOG_HOME/ES_enditem32.log  > /dev/null 2>&1 &
    ;;
    enditem33)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[161-165]" -l $KONGSEARCH_LOG_HOME/ES_enditem33.log  > /dev/null 2>&1 &
    ;;
    enditem34)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[166-170]" -l $KONGSEARCH_LOG_HOME/ES_enditem34.log  > /dev/null 2>&1 &
    ;;
    enditem35)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[171-175]" -l $KONGSEARCH_LOG_HOME/ES_enditem35.log  > /dev/null 2>&1 &
    ;;
    enditem36)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[176-180]" -l $KONGSEARCH_LOG_HOME/ES_enditem36.log  > /dev/null 2>&1 &
    ;;
    enditem37)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[181-185]" -l $KONGSEARCH_LOG_HOME/ES_enditem37.log  > /dev/null 2>&1 &
    ;;
    enditem38)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[186-190]" -l $KONGSEARCH_LOG_HOME/ES_enditem38.log  > /dev/null 2>&1 &
    ;;
    enditem39)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[191-195]" -l $KONGSEARCH_LOG_HOME/ES_enditem39.log  > /dev/null 2>&1 &
    ;;
    enditem40)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t endauction  -p "endItem_[196-200]" -l $KONGSEARCH_LOG_HOME/ES_enditem40.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}

start_gather_message() {
  case "$1" in
    message1)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_1" -l $KONGSEARCH_LOG_HOME/ES_message1.log  > /dev/null 2>&1 &
    ;;
    message2)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_2" -l $KONGSEARCH_LOG_HOME/ES_message2.log  > /dev/null 2>&1 &
    ;;
    message3)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_3" -l $KONGSEARCH_LOG_HOME/ES_message3.log  > /dev/null 2>&1 &
    ;;
    message4)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_4" -l $KONGSEARCH_LOG_HOME/ES_message4.log  > /dev/null 2>&1 &
    ;;
    message5)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_5" -l $KONGSEARCH_LOG_HOME/ES_message5.log  > /dev/null 2>&1 &
    ;;
    message6)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_6" -l $KONGSEARCH_LOG_HOME/ES_message6.log  > /dev/null 2>&1 &
    ;;
    message7)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_7" -l $KONGSEARCH_LOG_HOME/ES_message7.log  > /dev/null 2>&1 &
    ;;
    message8)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_8" -l $KONGSEARCH_LOG_HOME/ES_message8.log  > /dev/null 2>&1 &
    ;;
    message9)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_9" -l $KONGSEARCH_LOG_HOME/ES_message9.log  > /dev/null 2>&1 &
    ;;
    message10)
      nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t message  -p "messageHistory_10" -l $KONGSEARCH_LOG_HOME/ES_message10.log  > /dev/null 2>&1 &
    ;;
    *)  
      printf 'Usage: %s INDEX\n' "$0"  
      exit 1  
    ;;
    esac
}




case "${index}@${node}" in
  product@tslj)
#    b=10
#    while [ $b -le 17 ] 
#    do
#        start_gather_product_es_10 "shop${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#	
#    c=1
#    while [ $c -le 4 ] 
#    do
#        start_gather_product_es_10 "shopsold_a${c}"
#        c=$(($c + 1)) 
#        sleep 1
#    done
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
#    b=20
#    while [ $b -le 26 ] 
#    do
#        start_gather_product_es_10 "shop${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#	
#    c=1
#    while [ $c -le 3 ] 
#    do
#        start_gather_product_es_10 "bookstall_a${c}"
#        c=$(($c + 1)) 
#        sleep 1
#    done
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
#    b=30
#    while [ $b -le 38 ] 
#    do
#        start_gather_product_es_10 "shop${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#	
#    c=1
#    while [ $c -le 2 ] 
#    do
#        start_gather_product_es_10 "bookstallsold${c}"
#        c=$(($c + 1)) 
#        sleep 1
#    done
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
#    b=40
#    while [ $b -le 45 ] 
#    do
#        start_gather_product_es_10 "shop${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#	
#    c=1
#    while [ $c -le 4 ] 
#    do
#        start_gather_product_es_10 "shopsold_b${c}"
#        c=$(($c + 1)) 
#        sleep 1
#    done
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
#    b=50
#    while [ $b -le 57 ] 
#    do
#        start_gather_product_es_10 "shop${b}"
#        b=$(($b + 1)) 
#        sleep 1
#    done
#	
#    c=1
#    while [ $c -le 3 ] 
#    do
#        start_gather_product_es_10 "bookstall_b${c}"
#        c=$(($c + 1)) 
#        sleep 1
#    done
    a=21
    while [ $a -le 45 ] 
    do
        start_gather_product "shop${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  booklib@hr)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
    ;;
  booklib@ybq)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
    ;;
  product@zxd)
#    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shop  -p "item_1" -l $KONGSEARCH_LOG_HOME/ES_shop1.log > /dev/null 2>&1 &
#    sleep 1
#    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shopsold  -p "saledItem_1" -l $KONGSEARCH_LOG_HOME/ES_shopsold1.log > /dev/null 2>&1 &
    b=1
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
    while [ $c -le 10 ] 
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
  booklib@local)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t booklib  -p "books" -l $KONGSEARCH_LOG_HOME/booklib.log  > /dev/null 2>&1 &
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





  product_sold@tslj)
    start_gather_product_es_10 "shopsold_a1"
    sleep 1
    start_gather_product_es_10 "shopsold_a2"
    sleep 1
    ;;
  product_sold@ybq)
    start_gather_product_es_10 "shopsold_a3"
    sleep 1
    start_gather_product_es_10 "shopsold_a4"
    sleep 1
    ;;
  product_sold@zgkm)
    start_gather_product_es_10 "shopsold_b1"
    sleep 1
    start_gather_product_es_10 "shopsold_b2"
    sleep 1
    ;;
  product_sold@swk)
    c=1
    while [ $c -le 2 ] 
    do
        start_gather_product_es_10 "bookstallsold${c}"
        c=$(($c + 1)) 
        sleep 1
    done
    ;;
  product_sold@dy)
    start_gather_product_es_10 "shopsold_b3"
    sleep 1
    start_gather_product_es_10 "shopsold_b4"
    sleep 1
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



  suggest@ts)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  suggest@zxd)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;
  suggest@local1)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t suggest  -p "suggest" -l $KONGSEARCH_LOG_HOME/suggest.log  > /dev/null 2>&1 &
    ;;



  message@tslj)
    a=1
    while [ $a -le 3 ] 
    do
        start_gather_message "message${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  message@ybq)
    a=4
    while [ $a -le 6 ] 
    do
        start_gather_message "message${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  message@zgkm)
    a=7
    while [ $a -le 8 ] 
    do
        start_gather_message "message${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;
  message@dy)
    a=9
    while [ $a -le 10 ] 
    do
        start_gather_message "message${a}"
        a=$(($a + 1)) 
        sleep 1
    done
    ;;



  member@ts)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t member  -p "member" -l $KONGSEARCH_LOG_HOME/member.log  > /dev/null 2>&1 &
    ;;
  member@zxd)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t member  -p "member" -l $KONGSEARCH_LOG_HOME/member.log  > /dev/null 2>&1 &
    ;;
  member@local1)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t member  -p "member" -l $KONGSEARCH_LOG_HOME/member.log  > /dev/null 2>&1 &
    ;;
    auctioncom@hr)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
    auctioncom@ybq)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
    auctioncom@zxd)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t auctioncom  -p "itemInfo" -l $KONGSEARCH_LOG_HOME/auctioncom.log  > /dev/null 2>&1 &
    ;;
    studysearch@hr)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "oAuthStudy" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
    studysearch@ybq)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "oAuthStudy" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
    studysearch@zxd)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "oAuthStudy" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
    studybooksearch@hr)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "studyBookSearch" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
    studybooksearch@ybq)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "studyBookSearch" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
    studybooksearch@zxd)
    nohup $PHP $GATHER_HOME/gatherES.php -c $CONF -t shufang  -p "studyBookSearch" -l $KONGSEARCH_LOG_HOME/shufang.log  > /dev/null 2>&1 &
    ;;
  *)
    printf 'Usage: %s INDEX\n' "$0"  
    exit 1
    ;;
 esac
