<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%
/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

//查询参数
String auctionArea = (String) request.getParameter("auctionArea");
if(auctionArea == null || auctionArea.equals("")){
	auctionArea = "";
}

String category = (String) request.getParameter("catType");//这个名字不同
if(category == null || category.equals("")){
	category = "0";
}

String itemName = (String) request.getParameter("itemName");
if(itemName == null){
	itemName = "";
}


String sellerNickname = (String) request.getParameter("sellerNickname");
if(sellerNickname == null){
	sellerNickname = "";
}

String author = (String) request.getParameter("author");
if(author == null){
	author = "";
}

String press = (String) request.getParameter("press");
if(press == null){
	press = "";
}

//出版日期
String pubDateS = (String) request.getParameter("pubDateS");
if(pubDateS == null || pubDateS.equals("")){
	pubDateS = "";
}

String pubDateE = (String) request.getParameter("pubDateE");
if(pubDateE == null || pubDateE.equals("")){
	pubDateE = "";
}
//开始拍卖时间
String beginTimeS = (String) request.getParameter("beginTimeS");
if(beginTimeS == null || beginTimeS.equals("")){
	beginTimeS = "";
}

String beginTimeE = (String) request.getParameter("beginTimeE");
if(beginTimeE == null || beginTimeE.equals("")){
	beginTimeE = "";
}
//结束拍卖时间
String endTimeS = (String) request.getParameter("endTimeS");
if(endTimeS == null || endTimeS.equals("")){
	endTimeS = "";
}

String endTimeE = (String) request.getParameter("endTimeE");
if(endTimeE == null || endTimeE.equals("")){
	endTimeE = "";
}

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="http://xiaoxi.kongfz.com/css/im/main.css" />
<script src="http://xiaoxi.kongfz.com/js/jquery/jquery.min.js"></script>
<script src="http://xiaoxi.kongfz.com/js/webim_core.js"></script>
<link href="css/shop_main.css" rel="stylesheet" type="text/css">
<link href="css/top.css" rel="stylesheet" type="text/css">
<title>孔夫子旧书搜索——全球最大旧书搜索引擎</title>
<script type="text/javascript" language="javascript" src="js/lib_common.js"></script>
</head>
<body>
<form id="frmSearchItems" name="frmSearchItems" method="get" action="auction_adv.jsp" style="margin:0px">
<input type="hidden" name="query" value="<%=itemName%>" />
<input type="hidden" name="auctionArea" value="<%=auctionArea%>" />
<input type="hidden" name="category" value="<%=category%>" />
<input type="hidden" name="sellerNickname" value="<%=sellerNickname%>" />
<input type="hidden" name="itemName" value="<%=itemName%>" />
<input type="hidden" name="author" value="<%=author%>" />
<input type="hidden" name="press" value="<%=press%>" />
<input type="hidden" name="pubDateS" value="<%=pubDateS%>" />
<input type="hidden" name="pubDateE" value="<%=pubDateE%>" />
<input type="hidden" name="beginTimeS" value="<%=beginTimeS%>" />
<input type="hidden" name="beginTimeE" value="<%=beginTimeE%>" />
<input type="hidden" name="endTimeS" value="<%=endTimeS%>" />
<input type="hidden" name="endTimeE" value="<%=endTimeE%>" />
</form>
<script type="text/javascript">
$search("frmSearchItems").submit();
</script>
</body>
</html>