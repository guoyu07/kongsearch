<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="/common_auction.jsp" %>
<%
/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

//取出模板变量
String query = StringUtils.strVal(request.getAttribute("query"));
String category = StringUtils.strVal(request.getAttribute("category"));
String itemName = StringUtils.strVal(request.getAttribute("itemName"));
String nickname = StringUtils.strVal(request.getAttribute("nickname"));
String author = StringUtils.strVal(request.getAttribute("author"));
String press = StringUtils.strVal(request.getAttribute("press"));
String pubDateS = StringUtils.strVal(request.getAttribute("pubDateS"));
String pubDateE = StringUtils.strVal(request.getAttribute("pubDateE"));

String sorttype = StringUtils.strVal(request.getAttribute("sorttype"));
String pageNo = StringUtils.strVal(request.getAttribute("pageNo"));
String viewStyle = StringUtils.strVal(request.getAttribute("viewStyle"));

String result = StringUtils.strVal(request.getAttribute("result"));
String serverStatus = StringUtils.strVal(request.getAttribute("serverStatus"));
List documents = (List) request.getAttribute("documents");
String currentPage = StringUtils.strVal(request.getAttribute("currentPage"));
String bidTotal = StringUtils.strVal(request.getAttribute("bidTotal"));
String pageTotal = StringUtils.strVal(request.getAttribute("pageTotal"));
String searchTime = StringUtils.strVal(request.getAttribute("searchTime"));
String searchProperty = StringUtils.strVal(request.getAttribute("searchProperty"));

String queryRepport = StringUtils.strVal(request.getAttribute("queryRepport"));
String notFoundMessage = StringUtils.strVal(request.getAttribute("notFoundMessage"));
String htmlCategoryOptions = StringUtils.strVal(request.getAttribute("htmlCategoryOptions"));
String htmlAuctionAreaOptions = StringUtils.strVal(request.getAttribute("htmlAuctionAreaOptions"));
String htmlPageNavigation = StringUtils.strVal(request.getAttribute("htmlPageNavigation"));
String htmlViewStylePanel = StringUtils.strVal(request.getAttribute("htmlViewStylePanel"));

%>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="http://xiaoxi.kongfz.com/css/im/main.css" />
<script src="http://xiaoxi.kongfz.com/js/jquery/jquery.min.js"></script>
<script src="http://xiaoxi.kongfz.com/js/webim_core.js"></script>
<link href="css/shop_main.css" rel="stylesheet" type="text/css" />
<link href="css/top.css" rel="stylesheet" type="text/css" />
<title>孔夫子旧书搜索——全球最大旧书搜索引擎</title>
<style type="text/css">
body{ text-align:center; margin:0; padding:0;}
form{margin:0px;}
*{ font-size:12px;}
#search{ background:url(images/bg_search_result.gif); height:48px; width:948px; margin:0 auto; padding-top:2px; border-bottom:1px solid #a4c1d3;border-left:1px solid #a4c1d3;border-right:1px solid #a4c1d3;}
#search input,#search select{ font-size:14px;line-height:20px;}
#search input{ height:18px; padding-left:5px;}
#search select{ height:22px; line-height:22px;}

#top0612{ margin:0 auto; width:950px;text-align:center;}
#footer001{ margin:0 auto; margin-top:7px;width:950px;text-align:center;}
#bigDiv{ width:950px; margin:0 auto;}
.clear{ clear:both; line-height:0; font-size:0;}
#position{  background-color:#fef5d8; width:950px; margin:6px auto 6px auto; height:30px; line-height:30px; text-align:left;}

a:link{color:#000f74;text-decoration:none; font-size:12px; }
a:visited{color:#000f74;text-decoration:none;font-size:12px;}
a:hover{color:red;text-decoration:underline;font-size:12px;}

.page{ padding:20px 0 20px 20px;text-align:left; font-size:18px; background-color:#fff;}
.page font{font-size:18px;}
.page span{ float:left;}
.page span a{display:block; border:1px solid #8eaac0; background-color:#f7fbfe; padding:2px 8px 2px 8px; margin-left:1px; font-size:14px; margin-right:2px; text-decoration:none; color:#000b7d; }
.page span .current{ background-color:#397eb5;border:1px solid #397eb5; color:#fff; font-weight:bold; }
.page span a:visited{ background-color:#f7fbfe; font-size:14px;}
.page span a:hover{ background-color:#bfdff8; font-size:14px; color:#000b7d; }
#bigDiv{ width:950px; margin:0 auto;}
#bigDiv .left{ float:left; width:722px;}
#bigDiv .right{ float:right; width:220px;}
#bigDiv #rightBox1,#bigDiv #rightBox2,#bigDiv #rightBox3,#bigDiv #rightBox4{ border:1px solid #9fb9ca; line-height:24px; text-align:left; padding-bottom:12px;}
#bigDiv #rightBox2,#bigDiv #rightBox3,#bigDiv #rightBox4{ padding-left:12px; padding-right:12px; margin-top:8px;}
#bigDiv #rightBox1 h2{ background-color:#e9f4fa; height:30px; line-height:30px; padding-left:12px; text-align:left; margin-bottom:5px;}
#bigDiv #rightBox2 h2,#bigDiv #rightBox3 h2,#bigDiv #rightBox4 h2{ border-bottom:1px solid #d3d3d3; background:url(images/icon01_result_pic.gif) no-repeat 0 9px; height:30px; line-height:30px; text-align:left; padding-left:10px; margin-bottom:5px;}
#rightBox1 td{ line-height:240%;}
#rightBox4 ul li{ text-align:center; padding-bottom:12px;}
#list{border:1px solid #9fb9ca;}
#list td{ padding:10px 0 10px 10px; line-height:20px; border-bottom:1px dashed #d3d3d3;}
#list td font{ font-size:14px;}
#list .blue{ font-size:14px;}
#list .gray{ color:#6d6d6d;}
#list .prace{ font-size:14px; font-weight:bold; color:#fe4902;}
a.blue:link{ color:#010dbc;text-decoration:none;}
a.blue:hover{ color:#da0000;text-decoration:underline;}
a.blue:visited{color:#010dbc;text-decoration:none;}
.orange{ color:#fe6102;}
#list th{ background:url(images/bg_h2.gif); height:30px; line-height:30px;padding-left:5px;}
.title01 {background:url(images/bg_h2.gif); height:30px; line-height:30px; font-size:12px; padding-left:12px; width:936px; margin:0 auto; text-align:left;}
.hintBox{float:left; padding:10px; margin-left:60px;}
.hintBox div{float:left;}
.hintBox ul{margin-left:30px;}
.hintBox li{list-style-type:disc;}
</style>
<script type="text/javascript" language="javascript" src="js/lib_common.js"></script>
<script type="text/javascript" language="javascript" src="js/cls_cookie.js"></script>
<script type="text/javascript" language="javascript" src="http://res.kongfz.com/js/core/base.js"></script>
<script type="text/javascript">
var forms = {"shop":"frmSearchShop", "auction":"frmSearchAuction", "forum":"frmSearchForum"};
var names = ["shopPanelConent", "auctionPanelConent", "forumPanelConent"];
//var auctionLinks = {"history":"auction.jsp", "current":"http://pm.kongfz.com/search_result.php"};
var currentName = "auction";

function switchPanel(name)
{
    currentName = name;
    for(var i=0; i < names.length; i++){
        $search(names[i]).style.display="none";
    }
    $search(name+"PanelConent").style.display="block";
}

function searchSubmit()
{
    clearSearchHint("query");
    $search(forms[currentName]).submit();
}

function changeAuctionTarget(value)
{
    $search("frmSearchAuction").action = auctionLinks[value];
}

function filterSearchSubmit()
{
    $search("page").value = 0;
    $search("frmSearchItems").submit();
}

function showView(style)
{
    var cookie = new JsCookie();
    cookie.expires = "month";
    cookie.set("viewStyle", style);//将style写入Cookies
    $search("frmSearchItems").submit();
}

function setSort(type)
{
    $search("sorttype").value = type;
    $search("frmSearchItems").submit();
}

function go(page)
{
    page = trim(page);
    if(page==""){
        alert("请输入页码。");
        return;
    }
    if(page < 1){
        alert("您输入的页码过小，请输入正确的页码。");
        return;
    }
    if(page > '<%=pageTotal%>'){
        alert("您输入的页码过大，请输入正确的页码。");
        return;
    }
    $search("page").value = page;
    $search("frmSearchItems").submit();
}

function jumppage()
{
    var page = $search("pageNo").value;
    go(page);
}

// 重置日期
function resetDate(flg)
{
  var objS = flg+"S";
  var objE = flg+"E";
  document.getElementById(objS).value = "";
  document.getElementById(objE).value = "";
}

function changeQueryValue(value)
{
    resetSearchHint("query", value);
    $search('content').value=value;
}

function initFormFields()
{
    $search("panelSwitch").value="auction";
    $search("searchProperty").value="history";
    changeQueryValue("<%=encodeForJavaScript(query)%>");
    initSearchHintMessage("query");
}

function changeCategory(value){
	$search("categoryHid").value = value;
}

//跳转到新搜索搜索字段
function shopSearchToNewSearch(){
	var val = $search('content').value;
	if(val == ""){
		alert("请输入搜索关键字！");
		return false;
	} else {
		var str = "z"+toUnicode(val)+searchY;
		self.location.href="http://search.kongfz.com/product/"+str+"/";
		return true;
	}
}

//替换新搜索中的转换类型
function changeQueryValueToNewSearch(val){
	val = toUnicode(val);
    $search('content').value=val;
}

var searchY = "y0";
//拼接新搜索在售状态字段
function changeQueryValueToNewSearchYVal(val){
	searchY = "y"+val;
}

//将字符转换成unicode代码
function toUnicode(str) {
	if (!str) return;
    var unicode = '', i = 0, len = (str = '' + str).length;
	for (; i < len; i ++) {
		unicode += 'k' + str.charCodeAt(i).toString(16).toLowerCase();
	}
	return unicode;
}
</script>


</head>
<body>
<script>
document.write('<s'+'cript src="http://user.kongfz.com/interface/server_interface/comm_header.php?site=search&'+Math.random()+'"></'+'script>');
</script>
<style>
.kfz-header-top-nav-right .kfz-star-div{margin-top:0px;*margin-top:2px; float:left;}
</style>

<div id="header">
<div id="logo"><a href="http://www.kongfz.com/"><img src="images/logo_com.gif" alt="孔夫子旧书网" /></a></div>
<div id="topRight">
<div id="memberLoginArea" style="text-align:right;height:20px;">
</div>
    <div id="topmenu">
      <ul>
        <li><a href="http://www.kongfz.com/">首页</a></li>
        <li><a href="http://shop.kongfz.com/" target="_blank">书店区</a></li>
        <li><a href="http://www.kongfz.cn/" target="_blank">在线拍卖</a></li>
        <li><a href="http://zixun.kongfz.com/" target="_blank">资讯</a></li>
        <li><a href="http://www.gujiushu.com/" target="_blank">社区</a></li>
      </ul>
      <div class="clear"></div>
    </div>
  </div>
  <div class="clear"></div>
</div>
<div id="subMenu2"></div>
<!--top结束-->
<!--search begin-->
<div id="search">
  <table align="center" style="margin:auto">
    <tr>
      <td><img src="images/icon_search_result.gif" alt="搜索" align="absmiddle" /> </td>
      <td><select id="panelSwitch" name="panelSwitch" onchange="switchPanel(this.value)">
          <option value="shop">书店区</option>
          <option value="auction" selected="selected">拍卖区</option>
          <!--<option value="forum">社区</option>-->
        </select>
      </td>
      <td><span id="shopPanelConent" style="display:none">
        <form id="frmSearchShop" name="frmSearchShop" method="get">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:280px;" />
          <select name="sale" id="sale" onchange="changeQueryValueToNewSearchYVal(this.value);">
            <option value="0">未售</option>
            <option value="1">已售</option>
          </select>
          <label>
          	<img onclick="shopSearchToNewSearch()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> 
          	<a href="adv.html" target="_blank">高级搜索</a> 
          	<a href="/" target="_blank">搜索首页</a></label>
        </form>
        </span>
        <span id="auctionPanelConent" style="display:block">
        <form id="frmSearchAuction" name="frmSearchAuction" method="get" action="auction.jsp">
          <input type="text" id="query" name="query" value="<%=encodeForHTML(query)%>" onchange="changeQueryValue(this.value)" style="width:245px;" />
          <select name="searchProperty" onchange="changeAuctionTarget(this.value)">
            <option value="current">三天内拍卖</option>
            <option value="history" selected="selected">历史拍卖</option>
          </select>
          <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" />
          <a href="auction_adv.html" target="_blank">高级搜索</a>
          <a href="/" target="_blank">搜索首页</a></label>
          <input type="hidden" id="content" name="content" value="<%=encodeForHTML(query)%>" />
        <input type="hidden" name="act" value="search"  />
        </form>
          </span> <span id="forumPanelConent" style="display:none">
        <form id="frmSearchForum" name="frmSearchForum" method="get" action="forum.jsp">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:255px;" />
          <select id="category" name="category">
                <option value="">全部</option>
                <option value="26">网站公告</option>
                <option value="9">淘书指南</option>
                <option value="10">收藏学堂</option>
                <option value="6">文史大话</option>
                <option value="7">夫子书话</option>
                <option value="13">精品自荐</option>
                <option value="11">分类信息</option>
                <option value="14">灌水区</option>
                <option value="18">意见建议</option>
                <option value="9999">书界新闻</option>
                <option value="9998">市场动态</option>
          </select>
         <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="/" target="_blank">搜索首页</a></label>
        </form>
          </span> </td>
    </tr>
  </table>
</div>
<!--search end-->
<!--查询结果提示信息-->

<%
//显示查询结果页，筛选查询栏等
if(serverStatus.equals("ok")){
%>
<div id="position"><%=queryRepport%></div>
<!--bigdiv begin-->
<div id="bigDiv">

  <!--右侧开始-->
  <div class="right">
    <!--筛选开始-->
    <div id="rightBox1">
      <h2>在结果中筛选</h2>
      <form id="frmSearchItems" name="frmSearchItems" method="get" action="auction.jsp" onkeypress="if(event.keyCode==13)this.submit();">
      <input class="notset" type="hidden" name="query" id="query" value="<%=encodeForHTML(query)%>" />
      <input type="hidden" name="searchProperty" id="searchProperty" value="<%=searchProperty %>" />
      <input type="hidden" name="category" id="categoryHid" value="<%=encodeForHTML(category)%>" />
      <table width="94%" border="0" cellspacing="0" cellpadding="0" align="center">
        <tr>
          <td align="right">拍卖区：</td>
          <td><select id="auctionArea" name="auctionArea" style="width:140px"><%=htmlAuctionAreaOptions%></select></td>
        </tr>
        <tr>
          <td align="right">分类：</td>
          <td>
          	<select id="categorySel" style="width:140px;" onchange="changeCategory(this.value);">
          		<%=htmlCategoryOptions%>
          	</select>
          </td>
        </tr>
        <tr>
          <td align="right">拍卖主题：</td>
          <td><input type="text" name="itemName" value="<%=encodeForHTML(itemName)%>" style="width:136px" /></td>
        </tr>
        <tr>
          <td align="right">拍主昵称：</td>
          <td><input type="text" name="sellerNickname" value="<%=encodeForHTML(nickname)%>" style="width:136px" /></td>
        </tr>
        <tr>
          <td align="right">作者：</td>
          <td><input type="text" name="author" value="<%=encodeForHTML(author)%>" style="width:136px" /></td>
        </tr>
        <tr>
          <td align="right">出版社：</td>
          <td><input type="text" name="press" value="<%=encodeForHTML(press)%>" style="width:136px" /></td>
        </tr>
        <tr title="按年月日查询，格式：20090501">
          <td align="right">出版日期：</td>
          <td><input id="pubDateS" name="pubDateS" size="6" maxlength="8" value="<%=encodeForHTML(pubDateS)%>" />&nbsp;至&nbsp;<input id="pubDateE" name="pubDateE" size="6" maxlength="8" value="<%=encodeForHTML(pubDateE)%>" /></td>
        </tr>
        <tr>
          <td>&nbsp;</td>
          <td><img onclick="filterSearchSubmit()" style="cursor:pointer" src="images/bt_search02.gif" alt="筛选" /></td>
        </tr>
      </table>
    <input type="hidden" name="page" id="page" value="<%=encodeForHTML(currentPage)%>" />
    <input type="hidden" name="sorttype" id="sorttype" value="<%=encodeForHTML(sorttype)%>" />
    </form>
    </div>
    <!--筛选结束-->
    <script>initFormFields();</script>
<div style="margin-bottom:8px;"></div>
<!-- 广告位：[Search][Detail][200*200][Image] -->
<script type="text/javascript" >BAIDU_CLB_SLOT_ID = "306840";</script>
<script type="text/javascript" src="http://cbjs.baidu.com/js/o.js"></script>
<!--技巧开始-->
<div id="rightBox3">
<h2>搜索小技巧</h2>
<p>
1、全文搜索：可以在“书名、作者、出版社”等项查询您输入的关键词<br />
2、筛选：搜索后您还可以在页面右侧在结果中进一步筛选。例如：按书名、出版社、 出版时间、书店所在地等等来筛选。<br />
3、排序：在检索的结果中您可以按照价格、出版时间、上书时间等来排序。<br />
4、搜索结果的显示：您可以选择“图文形式”和“列表形式”，默认为“图文形式”。<br />
5、搜索区域：您可以在书店和在线拍卖中搜索您要的图书，而且您也可以查看已售的图书。
</p>
</div>
<!--技巧结束-->
  </div>
  <!--右侧结束-->

<%
if(documents != null && documents.size() > 0){
%>
  <!--左侧开始-->
  <div class="left">
    <div id="list">
    	<table width="100%" border="0" cellpadding="0" cellspacing="0">
        	<tr>
	        	<th colspan="2" width="57%">
	        		<%=htmlViewStylePanel%>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong style="color:black">排序：</strong>
	        		<select name="select2" id="sorttypeSelect" onchange="setSort(this.value)">
	        			<option value="0" selected="selected">默认排序</option>
	        			<option value="1">结束拍卖时间　从远到近↑</option>
	        			<option value="2">结束拍卖时间　从近到远↓</option>
	        			<option value="3">最高价　从低到高↑</option>
	        			<option value="4">最高价　从高到低↓</option>
	        			<option value="5">竞标　从少到多↑</option>
	        			<option value="6">竞标　从多到少↓</option>
	        			<option value="7">阅读　从少到多↑</option>
	        			<option value="8">阅读　从多到少↓</option>
	        			<option value="9">起拍价　从低到高↑</option>
	        			<option value="10">起拍价　从高到低↓</option>
	        			</select>
	        		<script type="text/javascript">$search("sorttypeSelect").value="0";</script>
	        	</th>
	        	<th width="12%" align="center" valign="top" style="font-weight:normal">起拍价/最高价</th>
	        	<th width="16%" align="center" valign="top" style="font-weight:normal">竞标/阅读</th>
	        	<th style="font-weight:normal" valign="top" width="20%" align="center">结束时间</th>
        	</tr>
<%
//显示结果页
try{
    displayBidsGraphic(documents, out);
}catch(Exception e){
    e.printStackTrace();
}


%>
	</table>
    <!--分页开始-->
    <div class="page">
    查询的图书总数：<%=bidTotal%>，共 <font class="red"><%=pageTotal%></font> 页<br />
    <div><%=htmlPageNavigation%></div><div class="clear"></div>
    </div>
    <!--分页结束-->
    </div>
  </div>
  <!--左侧结束-->
<%
}else{
    //查询不到结果时显示提示信息
    out.write(notFoundMessage);
}  
%>
</div>
<div class="clear"></div>
<!-- End  -->
<%
}else{
        StringBuffer sb = new StringBuffer();
        sb.append("<div style=\"width:950px; margin:6px auto 6px auto;\" >");
        sb.append(" <iframe id=\"iframeDom\" name=\"iframeDom\" ");
        sb.append(" width=\"950px\" height=\"500px\"");
        sb.append(" frameborder=\"0\" ");
        sb.append(" src=\"http://www.baidu.com/s?si=www.kongfz.cn&cl=3&ct=2097152&word="+query+"&tn=baidulocal\" ");
        sb.append(" ></iframe></div> ");
        out.write(sb.toString());
}
%>

<!--footer开始-->
<div id="contact">
<a href="http://www.kongfz.com/help/aboutus.php" target="_blank">关于孔夫子</a> - <a href="http://help.kongfz.com/" target="_blank">网站帮助</a> -<a href="http://www.kongfz.com/help/guanggao.php" target="_blank"> 广告业务</a> -<a href="http://www.kongfz.com/help/zhaopin.php" target="_blank"> 诚聘英才</a> -<a href="http://www.kongfz.com/help/lianxi.html" target="_blank"> 联系我们</a> -<a href="http://www.kongfz.com/help/copyright.php" target="_blank"> 版权隐私</a> - <a href="http://www.kongfz.com/community/links.php" target="_blank">友情链接</a> -<a href="http://shop.kongfz.com/advice.php?act=add" target="_blank"> 意见建议</a>
</div>
<div id="footer">
版权所有©2002-2013 孔夫子图书网（<a href="http://www.kongfz.com/">www.kongfz.com</a>）<br />
Copyright © All rights reserved 京ICP 041501&nbsp;&nbsp;客服电话：010-64755951
</div>
<!--footer结束-->
</body>
</html>