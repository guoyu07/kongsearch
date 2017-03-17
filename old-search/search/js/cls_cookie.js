// JavaScript Document
/*
js设定cookie的时间是以毫秒为单位
*/
function JsCookie(){
	var COOKIE_LIFE ={year:31536000,month:2592000,week:604800,
	                  day:86400,hour:3600,browser:0}
	
	this.expires = 'browser';
	this.path = null;
	this.domain = null;
	this.secure = null;
	
	this.get=function(fieldName){
		var regexp = window.eval("/"+fieldName+"=([\\w%,]+)(|;)/");
		var result = document.cookie.match(regexp);
		return (result?unescape(result[1]):"");
	}	
	this.set=function(fieldName,fieldValue){
		var cookie_list;
		cookie_list = fieldName+"="+escape(fieldValue);
		cookie_list += expires_param(this.expires);
		cookie_list += path_param(this.path);
		cookie_list += domain_param(this.domain);
		cookie_list += secure_param(this.secure);
		//alert(cookie_list);
		document.cookie = cookie_list;
	}
	function expires_param(expires){
		var tm=0;
		if(typeof(expires)=='string'){
			if(!COOKIE_LIFE[expires]) return "";
			tm = COOKIE_LIFE[expires]*1000;
		}else if(typeof(expires)=='number'){
			tm = expires*1000;
		}else{return "";}
		expires = ";expires="+new Date(new Date().getTime()+ tm).toUTCString();
		return expires;
	}
	function path_param(path){//验证路径？
		if(!path) return "";
		return (";path="+path);
	}
	function domain_param(domain){//验证形式？  .xxx.com
		if(!domain) return "";
		return (";domain="+domain);
	}
	function secure_param(secure){
		if(secure!='secure') return "";	
		return ";secure";
	}
	//未写的接口，以后扩充
	//this.maxage = null;	
	//function maxage_param(){}
	
}
