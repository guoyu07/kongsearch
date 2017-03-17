<?php
        require_once 'ip2host.php';
        require_once 'basicComp.php';
        set_time_limit(0);

        $diffList = array();
        $errorInfo = array('host' => '', 'oldip' => '', 'newip' => '', 'change' => '');
        foreach($ipHostsList as $host => $ip) {
                echo $host. "\n";
                $result = dns_get_record($host);
                if(!$result) { //当前 不通
                        if($basicCompList[$host]['msg'] == 'unconnected') {
                                continue;
                        } elseif ($basicCompList[$host]['msg'] == 'available' || $basicCompList[$host]['msg'] == 'mismatching') {
                                $errorInfo = array('host' => $host, 'oldip' => $basicCompList[$host]['newip'], 'newip' => '', 'change' => "{$basicCompList[$host]['msg']} => unconnected");
                                $diffList[] = $errorInfo;
                                continue;
                        }
                }
                $curip = $result[0]['ip'];
                if($curip == $basicCompList[$host]['newip']) { //当前 通并和基本对照ip一致
                        continue;
                }
                if($curip != $basicCompList[$host]['newip'] && $curip == $ip) {
                        $errorInfo = array('host' => $host, 'oldip' => $basicCompList[$host]['newip'], 'newip' => $curip, 'change' => "{$basicCompList[$host]['msg']} => available");
                } else { //当前 通并和基本对照ip不一致
                        $errorInfo = array('host' => $host, 'oldip' => $basicCompList[$host]['newip'], 'newip' => $curip, 'change' => "{$basicCompList[$host]['msg']} => mismatching");
                }
                $diffList[] = $errorInfo;
        }

        echo "Time : ". date("Y-m-d H:i:s", time()) . " : \n";

        if(empty($diffList)) {
                echo "Nothing changed !\n";
                exit;
        }
        echo "<pre>";
        print_r($diffList);

        function getSign($data)
    {
        ksort($data);
        reset($data);
        
        $i = 0;
        $str = '';
        
        foreach($data as $key => $val) {
            if($val === '') {
            }
            else {
                if($i == 0) {
                    $str .= "$key=$val";
                }
                else {
                    $str .= "&$key=$val";
                }
                
                $i++;
            }
        }
        
        return $str;
    }

    function unserializeStr($str)
    {
        if(! isset($str) || $str == '' || strlen($str) < 4) {
            return '';
        }
        
        $str = substr($str, 1, strlen($str) - 2);
        $str = str_replace('"', '', $str);
        $data = array();
        if(preg_match("/,/i", $str)) {
            $tmp_data = explode(",", $str);
            for($i = 0; is_array($tmp_data) && count($tmp_data) > $i; $i++) {
                $dataKeyVal = explode(":", $tmp_data[$i]);
                if(is_array($dataKeyVal) && count($dataKeyVal) == 2) {
                    $key = $dataKeyVal[0];
                    $data[$key] = $dataKeyVal[1];
                }
            
            }
        }
        else {
            if(preg_match("/:/i", $str)) {
                $dataKeyVal = explode(":", $str);
                if(is_array($dataKeyVal) && count($dataKeyVal) == 2) {
                    $key = $dataKeyVal[0];
                    $data[$key] = $dataKeyVal[1];
                }
            }
        }
        return $data;
    }

    function postToHost($url, $data, $timeOut)
    {
        if(! is_array($data)) {
            return "";
        }
        
        if(! ($url = parse_url($url))) {
            return "Couldn't parse url!";
        }
        
        if(! isset($url['port'])) {
            $url['port'] = "";
        }
        
        if(! isset($url['query'])) {
            $url['query'] = "";
        }
        
        $encoded = "";
        
        while(list($k, $v) = each($data)) {
            $encoded .= ($encoded ? "&" : "");
            $encoded .= rawurlencode($k) . "=" . rawurlencode($v);
        }
        
        $fp = @fsockopen($url['host'], $url['port'] ? $url['port'] : 80);
        if(! $fp) {
            return "Failed to open socket to $url[host]";
        }
        fputs($fp, sprintf("POST %s%s%s HTTP/1.0\n", $url['path'], $url['query'] ? "?" : "", $url['query']));
        fputs($fp, "User-Agent: kfzagent\n");
        fputs($fp, "Host: $url[host]\n");
        fputs($fp, "Content-type: application/x-www-form-urlencoded\n");
        fputs($fp, "Content-length: " . strlen($encoded) . "\n");
        fputs($fp, "Connection: close\n\n");
        fputs($fp, "$encoded\n");
        
        $line = fgets($fp, 1024);
        if(! preg_match('/^HTTP\/1\.. 200/i', $line)) {
            return;
        }
        
        $results = "";
        $inheader = 1;
        while(! feof($fp)) {
            $line = fgets($fp, 1024);
            if($inheader && ($line == "\n" || $line == "\r\n")) {
                $inheader = 0;
            }
            elseif(! $inheader) {
                $results .= $line;
            }
        }
        fclose($fp);
        return $results;
    }

    $serverUrl = 'http://sms.kongfz.com.cn/sendMsg.do';
    $signKey = "Gjp0UrTLfTaITwt2KG6R";
    $data['from'] = '919';
        $data['msg'] = $msg;
        $data['msgtype'] = '101';
        $data['mobile'] = '13260102779';
        $data['sign'] = md5(getSign($data) . $signKey);

    $msg = '';
        foreach($diffList as $key => $value) {
                $msg .= '【';
                foreach($value as $k => $v) {
                        if(!$v) {
                                continue;
                        }
                        $msg .= $k. ":" . $v. "|";
                }
                $msg = trim($msg, '|');
                $msg .= '】';
        //      $data['msg'] = $msg;
        //      $data['msgtype'] = '101';
                //$data['mobile'] = '13683619370';
                //$data['sign'] = md5(getSign($data) . $signKey);
                //$retArray = unserializeStr(postToHost($serverUrl, $data, $timeOut = 30));
                //var_dump($retArray);
                //$data['mobile'] = '13260102779';
        //      $data['sign'] = md5(getSign($data) . $signKey);
        }
$retArray = unserializeStr(postToHost($serverUrl, $data, $timeOut = 30));
var_dump($retArray);

/*
        $list = array();
        $info = array('host' => '', 'oldip' => '', 'newip' => '', 'msg' => '', 'isable' => 0);
        foreach($ipHostsList as $host => $ip) {
                $result = dns_get_record($host);
                if(!$result) {
                        $info['host'] = $host;
                        $info['oldip']   = '';
                        $info['newip']   = '';
                        $info['msg'] = 'unconnected';
                        $info['isable'] = 0;
                        $list[$host] = $info;
                        continue;
                }
                if($result[0]['ip'] !== $ip) {
                        $info['host'] = $host;
                        $info['oldip'] = $ip;
                        $info['newip'] = $result[0]['ip'];
                        $info['msg'] = 'mismatching';
                        $info['isable'] = 0;
                        $list[$host] = $info;
                        continue;
                }
                $info['host'] = $host;
                $info['oldip'] = $ip;
                $info['newip'] = $ip;
                $info['msg'] = 'available';
                $info['isable'] = 1;
                $list[$host] = $info;
        }
        file_put_contents('basicComp.php', "<?php\n\$basicCompList = ". var_export($list, true). ";\n");
*/

?>