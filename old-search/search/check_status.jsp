<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="com.kongfz.dev.rmi.RMIUtils" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.config.ConfigReader" %>
<%

request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");


//取得请求参数
//业务类型
String bizType = StringUtils.strVal(request.getParameter("bizType"));
String saleStatus = StringUtils.strVal(request.getParameter("saleStatus"));
String node = StringUtils.strVal(request.getParameter("node"));

String configFile = "/data/kongse5/conf/";
if("shop".equalsIgnoreCase(bizType)){
	configFile += "shop_";
} else if("stall".equalsIgnoreCase(bizType)) {
	configFile += "stall_";
} else if("fresh".equalsIgnoreCase(bizType)){
	configFile += "fresh_index_global.conf";
} else {
	out.println("bizType error!");
	return;
}
if("0".equals(saleStatus)){
	configFile += "sale_index_sharding_";
} else if("1".equals(saleStatus)) {
	configFile += "sold_index_sharding_";
}

if(!configFile.endsWith("conf")){
	configFile += node + ".conf";
}
ConfigReader reader = new ConfigReader();
reader.open(configFile);
String host = StringUtils.strVal(reader.get("ManagerHost"));
String port = StringUtils.strVal(reader.get("ManagerPort"));
String service = StringUtils.strVal(reader.get("SearchService"));
//检查文件和内容合法性
if("".equals(host) || "".equals(port) || "".equals(service)){
	out.println("config file error!");
	return;
}
String rmiUrl = "rmi://" + host + ":" +port + "/" + service;
ServiceInterface manager = null;
try{
    //取得远程服务器接口实例
    manager = RMIUtils.getRemoteServer(configFile, 3);;
}catch(Exception ex){
	out.println("service error!");
	return;
}

if(manager == null){
	out.println("service error!");
} else {
	out.println("service is OK!");
}

%>