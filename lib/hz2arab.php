<?php

include "NumberConventer.php";
$str = '一千二百三十四';
$str = '一二三四五六七';
$str = '五十';
$str = '一千二';
$str = '一千零一';
$str = '八百二';
$str = '五十二';
$str = '二零零六';
$str = '一千二百三十四';
$str = '一千零二十一 ';
$str = '三十万';
$str = '四万三千七百零三亿';
$str = '十八';
$str = '一十八';
$str = '一亿三十二万五千四百九';
$str = '一仟三佰肆';
$str = '三点四';
$str = '一千零五点六';
$str = '一万亿';
$str = '一千万亿';
$str = '负三百二';
var_dump(NumberConventer::ChnToArab($str));
exit;


class NumberConventer {
	static private $Units = array(
		'亿', '千万', '百万', '十万', '万', '千', '百', '十'
	);
	public function __construct() {
		
	}

	//汉字转阿拉伯数字
	static public function ChnToArab($ChnNum) {
		$ChnNum = self::FormatChnNum($ChnNum);
		if(!preg_match('/亿|千万|百万|十万|万|千|百|十|点/isU', $ChnNum)) {
			return self::GetNoUnitNum($ChnNum);	
		}
		$ChnNum = trim($ChnNum);
		$result = 0;
		$temp = $ChnNum;
		$neg = 0;
		if(strpos($ChnNum, '负') !== false) {
			$neg = 1;
			$temp = str_replace("负", '', $temp);
		}
		$pre = '';
		$abo = '';
		$temp = str_replace("点", '.', $temp);
		$part = explode('.', $temp);
		$pre = $part[0];
		$dotPart = 0;
		if(count($part) > 1) {
			$abo = $part[1];
			$dotPart = self::GetArabDotPart($abo);
		}
		$yCount = 0;  //亿的个数
		$index = 0;
		while($index < strlen($pre)) {
			if(strpos($pre, '亿', $index) !== false) {
				++$yCount;
				$index = strpos($pre, '亿', $index) + 1;
			} else {
				break;
			}
		}
		if($yCount == 2) { //亿亿
			$pre = str_replace('亿', ',', $pre);
			$sp = explode(',', $pre);
			$result = ($neg ? -1 : 1) * ((self::HandlePart($sp[0]) * 10000000000000000) + (self::HandlePart($sp[1]) * 100000000) + self::HandlePart($sp[2])) + $dotPart;
		} else {
			if($yCount == 1) {
				$pre = str_replace('亿', ',', $pre);
				$sp = explode(',', $pre);
				$result = ($neg ? -1 : 1) * ((self::HandlePart($sp[0]) * 100000000) + self::HandlePart($sp[1])) + $dotPart;
			} else {
				if($yCount == 0) {
					$result = ($neg ? -1 : 1) * (self::HandlePart($pre)) + $dotPart;
				}
			}
		}
		return $result;
	}

	//没有任何单位的中文数字转阿拉伯  例： 一二三 => 123
	private function GetNoUnitNum($ChnNum) {
		$returnNum = '';
		$len = mb_strlen($ChnNum, 'UTF-8');
		for($i = 0; $i < $len; $i++) {
			$returnNum .= strval(self::SwitchNum(mb_substr($ChnNum, $i, 1, 'UTF-8')));
		}
		return $returnNum;
	}

	//格式化中文数字 例：二万五 => 二万五千
	private function FormatChnNum($ChnNum) {
		$ChnNum = self::TurnWordCase($ChnNum);
		if(!in_array(mb_substr($ChnNum, -1, 1, 'UTF-8'), self::$Units)) {
			$unit = mb_substr($ChnNum, -2, 1, 'UTF-8');
			if($unit != '十' && in_array($unit, self::$Units)) {
				$index = array_search($unit, self::$Units);
				$ChnNum .= self::$Units[$index + 1];
			}
		}
		return $ChnNum;
	}

	//转化中文单位表示形式 例：仟 => 千
	private function TurnWordCase($ChnNum) {
		return str_replace(array('仟', '佰', '拾', '玖', '捌', '柒', '陆', '伍', '肆', '叁', '贰', '壹'), array('千', '百', '十', '九', '八', '七', '六', '五', '四', '三', '二', '一'), $ChnNum);
	}

	//处理亿以下内容
	private function HandlePart($num) {
		$result = 0;
		$temp = $num;
		$temp = str_replace('万', ',', $temp);
		$part = explode(',', $temp);
		$count = count($part);
		for($i = 0; $i < $count; $i++) {
			$result += self::GetArabThousandPart($part[$count - $i - 1]) * pow(10000, $i);
		}
		return $result;
	}

	//取得阿拉伯数字小数部分
	private function GetArabDotPart($dotPart) {
		$result = 0;
		$spe = "0.";
		$last = 0;
		$len = mb_strlen($dotPart, 'UTF-8');
		for($i = 0; $i < $len; $i++) {
			$last = self::SwitchNum(mb_substr($dotPart, $i, 1, 'UTF-8'));
		}
		$result = floatval($spe. $last);
		return $result;
	}

	//取得阿拉伯数字千位下部分
	private function GetArabThousandPart($number) {
		$chnNumString = $number;
		if($chnNumString == '零') {
			return 0;
		}
		if($chnNumString != '') {
			if(mb_substr($chnNumString, 0, 1, 'UTF-8') == '十') {
				$chnNumString = '一'. $chnNumString;
			}
		}
		$chnNumString = str_replace('零', '', $chnNumString);
		$result = 0;
		$index = strpos($chnNumString, '千');
		if($index !== false) {
			$result += self::SwitchNum(substr($chnNumString, 0, $index)) * 1000;
			$chnNumString = substr($chnNumString, $index + 3);
		}

		$index = strpos($chnNumString, '百');
		if($index !== false) {
			$result += self::SwitchNum(substr($chnNumString, 0, $index)) * 100;
			$chnNumString = substr($chnNumString, $index + 3);
		}

		$index = strpos($chnNumString, '十');
		if($index !== false) {
			$result += self::SwitchNum(substr($chnNumString, 0, $index)) * 10;
			$chnNumString = substr($chnNumString, $index + 3);
		}

		if($chnNumString != '') {
			$result += self::SwitchNum($chnNumString);
		}
		return $result;
	}

	//取得汉字对应的阿拉伯数字
	private function SwitchNum($n) {
		switch($n) {
			case '零':
				return 0;
			case '一':
				return 1;
			case '二':
				return 2;
			case '三':
				return 3;
			case '四':
				return 4;
			case '五':
				return 5;
			case '六':
				return 6;
			case '七':
				return 7;
			case '八':
				return 8;
			case '九':
				return 9;
			default:
				return -1;
		}
		return -1;
	}
}

?>
