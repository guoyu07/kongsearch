<?php
    /*****************************************
     * author: xinde
     * 
     * 商品数据更新脚本
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('h');
    
    $log_path = '/data/kongsearch_logs/updateESAttr/';
    $log = $log_path. 'updateRank0_'. date('Y_m_d');
    if(!is_dir($log_path)) {
        mkdir($log_path, 0777, true);
    }
    
    $searchHost = '192.168.2.19';
    $searchPort = '9800';
    $searchHostSpider = '192.168.1.137';
    $searchPortSpider = '9700';
    $searchIndex = 'item,item_sold';
    $searchIndexUnSold = 'item';
    $searchIndexSold = 'item_sold';
    $searchType = 'product';
    $maxLoad    = '25.0';
    
    $userIdsArr = array(
        '2268390',
        '41300',
        '4852319',
        '2105770',
        '4845777',
        '4759515',
        '1050725',
        '1726148',
        '106881',
        '5115132',
        '5005525',
        '5115366',
        '2843',
        '5115045',
        '5115609',
        '5098346',
        '4518749',
        '4450705',
        '4538094',
        '2000049',
        '4087357',
        '5115343',
        '2554581',
        '5098432',
        '3110915',
        '2303921',
        '5115572',
        '4406966',
        '81972',
        '1214007',
        '1445966',
        '4655986',
        '5743821',
        '1927912',
        '74520',
        '2818395',
        '3693501',
        '1228450',
        '3077402',
        '168471',
        '3991943',
        '19943',
        '2406488',
        '5184492',
        '3784263',
        '4986191',
        '1315',
        '2363920',
        '4791268',
        '1108462',
        '1378199',
        '116422',
        '3063759',
        '115547',
        '3611626',
        '4096713',
        '4763310',
        '5152552',
        '1779636',
        '1012088',
        '1388124',
        '3106242',
        '4309203',
        '2277435',
        '5126996',
        '5205932',
        '4335595',
        '2254859',
        '2608699',
        '4802590',
        '4925429',
        '1488706',
        '105076',
        '1674591',
        '4458604',
        '1454190',
        '173115',
        '2311073',
        '5048294',
        '5555042',
        '3458239',
        '5278503',
        '2267824',
        '5503396',
        '2320966',
        '3343584',
        '5077743',
        '3908790',
        '4454162',
        '4453568',
        '2903863',
        '4367251',
        '2332801',
        '5510586',
        '2511476',
        '4808376',
        '4337093',
        '2070122',
        '649',
        '2281878',
        '1709579',
        '2431793',
        '2836190',
        '4620994',
        '190',
        '5275795',
        '5117949',
        '5197052',
        '2078334',
        '1027641',
        '3366705',
        '4575355',
        '2178142',
        '2969029',
        '2022052',
        '4313165',
        '5128827',
        '1112119',
        '1014262',
        '2118811',
        '3795027',
        '199412',
        '5254341',
        '4463095',
        '1065519',
        '1022895',
        '4757455',
        '1613856',
        '3764456',
        '2993308',
        '4845282',
        '4542759',
        '1776524',
        '3427270',
        '3259934',
        '2216403',
        '2286898',
        '3487712',
        '1724638',
        '5413745',
        '2032622',
        '1090881',
        '2427847',
        '2874673',
        '4803023',
        '84061',
        '2982467',
        '2775142',
        '124655',
        '1773806',
        '4418479',
        '187125',
        '3715848',
        '36053',
        '1848013',
        '1764237',
        '296',
        '1928626',
        '1589547',
        '5191601',
        '2687433',
        '3731517',
        '3642926',
        '4725221',
        '5273150',
        '2768301',
        '4682718',
        '4397673',
        '2835957',
        '1730454',
        '5065428',
        '4279274',
        '1812910',
        '155479',
        '1878335',
        '1053661',
        '2366295',
        '4737345',
        '4301634',
        '5418471',
        '1025397',
        '3474983',
        '3538928',
        '4613710',
        '5338734',
        '1678887',
        '4281891',
        '5275859',
        '28241',
        '4848793',
        '2453522',
        '3782662',
        '5493472',
        '1555740',
        '2241102',
        '5161828',
        '3984336',
        '1593227',
        '14518',
        '5557853',
        '2283297',
        '3675865',
        '3617840',
        '2265903',
        '2332244',
        '4854432',
        '5203014',
        '1870557',
        '4075326',
        '3134429',
        '3326398',
        '1741009',
        '4279956',
        '3767365',
        '3806163',
        '2298596',
        '4959003',
        '5436911',
        '2336721',
        '1178985',
        '5163188',
        '30713',
        '1594239',
        '190546',
        '3831244',
        '4993441',
        '1434173',
        '2319435',
        '5047435',
        '5228791',
        '1528624',
        '3709223',
        '2178251',
        '2953493',
        '4937785',
        '4917005',
        '3788206',
        '1944507',
        '4161376',
        '2157409',
        '1229727',
        '3845717',
        '1720297',
        '3866739',
        '1607718',
        '3108173',
        '4608466',
        '1451906',
        '142313',
        '1827595',
        '1885695',
        '1065910',
        '3557797',
        '4437933',
        '3453615',
        '2355220',
        '4060130',
        '1918947',
        '4382670',
        '4260552',
        '4420943',
        '4314759',
        '1426537',
        '1073313',
        '5072221',
        '4753419',
        '4313951',
        '4162201',
        '4377190',
        '4436558',
        '184444',
        '2320990',
        '2490917',
        '1459949',
        '218884',
        '4750787',
        '4305581',
        '13875',
        '1325120',
        '3929944',
        '2156758',
        '4902526',
        '3609938',
        '3323810',
        '5527561',
        '3090496',
        '1101655',
        '2485397',
        '3193962',
        '17378',
        '1233475',
        '1132630',
        '1262882',
        '2250501',
        '4484683',
        '5045829',
        '3701583',
        '89834',
        '154080',
        '2469193',
        '5182807',
        '1891822',
        '3531691',
        '5076255',
        '2789617',
        '2504300',
        '108107',
        '2021695',
        '4477174',
        '22066',
        '3539556',
        '2043918',
        '3891681',
        '1488813',
        '2310343',
        '3960142',
        '5142909',
        '211623',
        '4587092',
        '3948902',
        '2184820',
        '2350357',
        '5265127',
        '3245',
        '152381',
        '4281014',
        '1370396',
        '4065424',
        '4633051',
        '1162585',
        '3988742',
        '4591257',
        '3934653',
        '1797826',
        '4814402',
        '2480715',
        '205875',
        '3525383',
        '2405901',
        '4790911',
        '1678357',
        '1814472',
        '2552246',
        '5136354',
        '1214089',
        '1440490',
        '2968593',
        '3947765',
        '1980100',
        '153642',
        '5297615',
        '1873055',
        '1046507',
        '204619',
        '219247',
        '5709087',
        '4782690',
        '3577303',
        '2149980',
        '2576828',
        '3931177',
        '1441348',
        '2769388',
        '1600184',
        '4299623',
        '5420358',
        '4561298',
        '5653464',
        '5484968',
        '2188610',
        '1441685',
        '3985872',
        '4760194',
        '1177549',
        '1213315',
        '4300227',
        '22693',
        '1911967',
        '3951134',
        '3394503',
        '4324637',
        '1263413',
        '1223954',
        '4042644',
        '4620173',
        '1719724',
        '4584355',
        '4658060',
        '1072455',
        '70757',
        '2704521',
        '2353214',
        '1079606',
        '2786878',
        '1982620',
        '5185316',
        '1143549',
        '44198',
        '3307413',
        '123530',
        '3100507',
        '5604894',
        '4177980',
        '2350005',
        '5252838',
        '1106766',
        '4183380',
        '1122453',
        '20793',
        '4712808',
        '3687865',
        '34621',
        '4874630',
        '2699313',
        '1786095',
        '4427686',
        '4559793',
        '1157153',
        '59609',
        '3648242',
        '4382951',
        '5509618',
        '4335230',
        '1910705',
        '144367',
        '1316696',
        '2157365',
        '1255739',
        '3150770',
        '4807480',
        '4889571',
        '3376368',
        '2655367',
        '1422342',
        '5353902',
        '5145897',
        '1016331',
        '4903974',
        '4873886',
        '1923073',
        '4066070',
        '4424838',
        '5144797',
        '3377312',
        '4183657',
        '4268927',
        '4572755',
        '4840648',
        '3409963',
        '1174441',
        '1542641',
        '5115116',
        '2447022',
        '98587',
        '4284343',
        '2386037',
        '5115650',
        '2103933',
        '3276103',
        '87562',
        '4826181',
        '4569854',
        '4788374',
        '5108300',
        '1057388',
        '3555543',
        '2653139',
        '3843480',
        '4085816',
        '1580168',
        '1959938',
        '2189372',
        '2007150',
        '2050778',
        '1545046',
        '1079094',
        '105038',
        '1449166',
        '1593074',
        '5091089',
        '2183446',
        '2105131',
        '4695145',
        '3692891',
        '4803508',
        '2874949',
        '3148241',
        '1612425',
        '64425',
        '4456042',
        '1016956',
        '2286873',
        '2243881',
        '2697966',
        '1837128',
        '2186714',
        '3788998',
        '3573236',
        '1343439',
        '4439671',
        '1186860',
        '19941',
        '2318776',
        '3934224',
        '1168147',
        '4835250',
        '5197081',
        '27352',
        '2124694',
        '3226277',
        '2391254',
        '2660378',
        '1009076',
        '3057973',
        '2476691',
        '1374188',
        '4797963',
        '1719174',
        '1783503',
        '3979240',
        '216480',
        '1134862',
        '2836803',
        '2286243',
        '3212690',
        '2770037',
        '3747532',
        '2951210',
        '39729',
        '4316026',
        '2970431',
        '3243463',
        '1228353',
        '5484853',
        '5180560',
        '3559039',
        '3603325',
        '2283998',
        '4060088',
        '2552455',
        '3480608',
        '3727995',
        '2665855',
        '4046286',
        '1192411',
        '2209427',
        '3254256',
        '4428865',
        '3897935',
        '4598899',
        '4680424',
        '1035388',
        '5202014',
        '4945160',
        '1322173',
        '4285213',
        '4274642',
        '3605992',
        '4359185',
        '1348451',
        '1180692',
        '1650226',
        '1095553',
        '2089469',
        '5182873',
        '3263501',
        '2013195',
        '3731970',
        '1070647',
        '5215518',
        '4446085',
        '2784748',
        '4306178',
        '2438103',
        '2297099',
        '3108438',
        '1122119',
        '2040270',
        '3329578',
        '4056277',
        '4512381',
        '5124068',
        '4546924',
        '2297820',
        '1007439',
        '156220',
        '4288507',
        '5594189',
        '4899431',
        '1273348',
        '27781',
        '1642938',
        '12418',
        '2095652',
        '10918',
        '1449163',
        '5031963',
        '1449060',
        '1600528',
        '2996271',
        '4738302',
        '1010549',
        '4321758',
        '3367477',
        '4387883',
        '2161351',
        '1023140',
        '3117912',
        '3133866',
        '4588377',
        '7372',
        '1438149',
        '2551931',
        '1765272',
    );
    
    foreach ($userIdsArr as $userId) 
    {
        if (!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while (true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if ($loadStatus) {
                    break;
                }
            }
        }
        ++$repairShopNum;
        $userId = intval($userId);
        if(!$userId) {
            continue;
        }
        $condition = array();
        $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
        $condition['limit'] = array('from' => 0, 'size' => 500000);
        $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid', 'salestatus', 'rank'), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 60));
        if (empty($searchResult['data'])) {
            echo "----- The UserId {$userId} Has Null.\n";
            file_put_contents($log, "----- The UserId {$userId} Has Null.\n", FILE_APPEND);
            continue;
        }
        echo "----- The UserId {$userId} Has {$searchResult['total']}.\n";
        file_put_contents($log, "----- The UserId {$userId} Has {$searchResult['total']}.\n", FILE_APPEND);
        foreach ($searchResult['data'] as $item) {
            $itemid = $item['itemid'];
            $salestatus = $item['salestatus'];
            $oldrank = $item['rank'];
            $rank = 0;
            echo "itemid : {$itemid} , salestatus : {$salestatus} , oldrank : {$oldrank}   =>   rank : {$rank} \n";
            file_put_contents($log, "itemid : {$itemid} , salestatus : {$salestatus} , oldrank : {$oldrank}   =>   rank : {$rank} \n", FILE_APPEND);
            if ($oldrank == $rank) {
                continue;
            }
            ++$repairItemNum;
            if ($salestatus) {
                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexSold, $searchType, $itemid, array('rank' => $rank));
                ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexSold, $searchType, $itemid, array('rank' => $rank));
            } else {
                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexUnSold, $searchType, $itemid, array('rank' => $rank));
                ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexUnSold, $searchType, $itemid, array('rank' => $rank));
            }
        }
    }

    echo "End Time : ". date("Y-m-d H:i:s"). "   . RepairShopNum : {$repairShopNum} , RepairItemNum : {$repairItemNum} . \n";
    file_put_contents($log, "End Time : ". date("Y-m-d H:i:s"). "   . RepairShopNum : {$repairShopNum} , RepairItemNum : {$repairItemNum} . \n", FILE_APPEND);
    exit;
    
    /**
     * 检测系统负载
     * 
     * @param string $ip
     * @param int    $port
     * @param int    $maxLoad
     * @return boolean
     */
    function checkLoad($ip, $port, $maxLoad)
    {
        $loadInfo = ElasticSearchModel::getLoadInfo($ip, $port);
        $loadInfoArr = explode(' ', trim($loadInfo));
        if(is_array($loadInfoArr) && !empty($loadInfoArr)) {
            foreach($loadInfoArr as $info) {
                $load = trim($info);
                if($load > $maxLoad) {
                    return false;
                }
            }
        }
        return true;
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>