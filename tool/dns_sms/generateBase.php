<?php
        require_once 'ip2host.php';
        set_time_limit(0);

        $list = array();
        $info = array('host' => '', 'oldip' => '', 'newip' => '', 'msg' => '', 'isable' => 0);

        foreach($ipHostsList as $host => $ip) {
                echo $host. "\n";
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

        echo '<pre>';
        print_r($ipHostsList);
?>