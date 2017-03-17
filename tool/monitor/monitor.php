<?php

/**
 * 监控类
 * 
 * @author      xinde <zxdxinde@gmail.com>
 * @date        2015年10月23日17:50:03
 */
class MonitorModel 
{

    static private function getSign($data)
    {
        ksort($data);
        reset($data);

        $i = 0;
        $str = '';

        foreach ($data as $key => $val) {
            if ($val === '') {
                
            } else {
                if ($i == 0) {
                    $str .= "$key=$val";
                } else {
                    $str .= "&$key=$val";
                }

                $i++;
            }
        }

        return $str;
    }

    static private function unserializeStr($str)
    {
        if (!isset($str) || $str == '' || strlen($str) < 4) {
            return '';
        }

        $str = substr($str, 1, strlen($str) - 2);
        $str = str_replace('"', '', $str);
        $data = array();
        if (preg_match("/,/i", $str)) {
            $tmp_data = explode(",", $str);
            for ($i = 0; is_array($tmp_data) && count($tmp_data) > $i; $i++) {
                $dataKeyVal = explode(":", $tmp_data[$i]);
                if (is_array($dataKeyVal) && count($dataKeyVal) == 2) {
                    $key = $dataKeyVal[0];
                    $data[$key] = $dataKeyVal[1];
                }
            }
        } else {
            if (preg_match("/:/i", $str)) {
                $dataKeyVal = explode(":", $str);
                if (is_array($dataKeyVal) && count($dataKeyVal) == 2) {
                    $key = $dataKeyVal[0];
                    $data[$key] = $dataKeyVal[1];
                }
            }
        }
        return $data;
    }

    static private function postToHost($url, $data, $timeOut)
    {
        if (!is_array($data)) {
            return "";
        }

        if (!($url = parse_url($url))) {
            return "Couldn't parse url!";
        }

        if (!isset($url['port'])) {
            $url['port'] = "";
        }

        if (!isset($url['query'])) {
            $url['query'] = "";
        }

        $encoded = "";

        while (list($k, $v) = each($data)) {
            $encoded .= ($encoded ? "&" : "");
            $encoded .= rawurlencode($k) . "=" . rawurlencode($v);
        }

        $fp = @fsockopen($url['host'], $url['port'] ? $url['port'] : 80);
        if (!$fp) {
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
        if (!preg_match('/^HTTP\/1\.. 200/i', $line)) {
            return;
        }

        $results = "";
        $inheader = 1;
        while (!feof($fp)) {
            $line = fgets($fp, 1024);
            if ($inheader && ($line == "\n" || $line == "\r\n")) {
                $inheader = 0;
            } elseif (!$inheader) {
                $results .= $line;
            }
        }
        fclose($fp);
        return $results;
    }

    static public function sendMsg($text)
    {
        $serverUrl = 'http://sms.kongfz.com.cn/sendMsg.do';
        $signKey = "Gjp0UrTLfTaITwt2KG6R";
        $data['from'] = '919';
        $data['mobile'] = '13260102779';
        $data['msg'] = $text;
        $data['msgtype'] = '101';
        $data['sign'] = md5(self::getSign($data) . $signKey);
        $retArray = self::unserializeStr(self::postToHost($serverUrl, $data, $timeOut = 30));
        return $retArray;
    }

}

?>