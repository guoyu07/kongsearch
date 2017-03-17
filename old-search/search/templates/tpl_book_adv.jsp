<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.*" %>
<%@ include file="/common_book.jsp" %>
<%
/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

//取出模板变量
String sale = (String) request.getAttribute("sale");
String query = (String) request.getAttribute("query");
String state = (String) request.getAttribute("state");
String county = (String) request.getAttribute("county");
String category = (String) request.getAttribute("category");
String itemName = (String) request.getAttribute("itemName");
String author = (String) request.getAttribute("author");
String press = (String) request.getAttribute("press");
String pubDateStart = (String) request.getAttribute("pubDateStart");
String pubDateEnd = (String) request.getAttribute("pubDateEnd");
String isbn = (String) request.getAttribute("isbn");

//注：售价和书店名称为新增加的查询项
String priceStart = (String) request.getAttribute("priceStart");
String priceEnd = (String) request.getAttribute("priceEnd");
String priceLevel = (String) request.getAttribute("priceLevel");
String shopName = (String) request.getAttribute("shopName");

String more = (String) request.getAttribute("more");
String fuzzy = (String) request.getAttribute("fuzzy");
String sorttype = (String) request.getAttribute("sorttype");
String pageNo = (String) request.getAttribute("pageNo");
String viewStyle = (String) request.getAttribute("viewStyle");

String result = (String) request.getAttribute("result");
String serverStatus = (String) request.getAttribute("serverStatus");
List documents = (List) request.getAttribute("documents");
String currentPage = (String) request.getAttribute("currentPage");
String bookTotal = (String) request.getAttribute("bookTotal");
String pageTotal = (String) request.getAttribute("pageTotal");
String searchTime = (String) request.getAttribute("searchTime");

String searchMode = (String) request.getAttribute("searchMode");
String fuzzyQueryWord = (String) request.getAttribute("fuzzyQueryWord");
String queryRepport = (String) request.getAttribute("queryRepport");
String youWantFind = (String) request.getAttribute("youWantFind");
String notFoundMessage = (String) request.getAttribute("notFoundMessage");
String htmlPageNavigation = (String) request.getAttribute("htmlPageNavigation");
String htmlCategoryOptions = (String) request.getAttribute("htmlCategoryOptions");
String htmlIsNewBook = (String) request.getAttribute("htmlIsNewBook");
String htmlViewStylePanel = (String) request.getAttribute("htmlViewStylePanel");
String onlyStallHtml = (String) request.getAttribute("onlyStallHtml");
String queryMoreHtml = (String) request.getAttribute("queryMoreHtml");
String queryLessHtml = (String) request.getAttribute("queryLessHtml");
String notFoundHintHtml = (String) request.getAttribute("notFoundHintHtml");
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
<link href="css/search_result.css" rel="stylesheet" type="text/css" />
<title>孔夫子旧书搜索——全球最大旧书搜索引擎</title>
<style type="text/css">
body{ text-align:center; margin:0; padding:0;}
form{margin:0px;}
*{ font-size:12px;}
#search{ background:url(images/bg_search_result.gif); height:48px; width:948px; margin:0 auto; padding-top:2px; border-bottom:1px solid #a4c1d3;border-left:1px solid #a4c1d3;border-right:1px solid #a4c1d3;}
#search input,#search select{ font-size:14px;line-height:20px;}
#search input{ height:18px; padding-left:5px;}
#search select{ height:22px; line-height:22px;}

#top0612{ margin:0 auto; width:950px; }
#footer001{ margin:0 auto; margin-top:7px;width:950px;text-align:center;}
#bigDiv{ width:950px; margin:0 auto;}

.clear{ clear:both; line-height:0; font-size:0;}
.title01{ background:url(images/bg_h2.gif); height:30px; line-height:30px; font-size:12px; padding-left:12px; width:936px; margin:0 auto; text-align:left;}
.red{ color:red;}
.search{ margin:6px 12px 6px 12px;}
.search td{ font-size:12px; color:#606060; line-height:220%;}
.search td input{ font-size:12px; line-height:14px; height:14px;}
#position{  background-color:#FEFACD; border:1px solid #D9CF76; width:950px; margin:6px auto 6px auto; height:30px auto; line-height:30px; text-align:left;}

.notFoundHint{background-color:#F6F9FE; border:1px solid #A4C1D3; width:950px; margin:6px auto 6px auto; height:92px auto; line-height:normal; text-align:center; font-size:14px;}
.notFoundHint td a:link,.notFoundHint td a:visited{ font-size:14px;color:blue;text-decoration:underline;}
.notFoundHint td a:hover{ font-size:14px;color:red;text-decoration:underline;}
.notFoundHint td{ font-size:14px;}
.notFoundHint label{color:#FF0000;font-size:14px;}

a:link{color:#000f74;text-decoration:none; font-size:12px; }
a:visited{color:#000f74;text-decoration:none;font-size:12px;}
a:hover{color:red;text-decoration:underline;font-size:12px;}

.List {text-align:center;}
.List td{ font-size:12px; line-height:26px;}

#sx{ border:1px solid #c2d8e5; width:948px; margin:0 auto 8px auto;}
.sort{ text-align:left; padding:5px;color:#606060; padding-left:12px; border-bottom:1px dashed #c9c9c9; line-height:24px;}

.page{ padding:20px 0 20px 20px;text-align:left; font-size:18px; background-color:#fff;border-top:1px dashed #c9c9c9}
.page font{font-size:18px;}
.page span{ float:left;}
.page span a{display:block; border:1px solid #8eaac0; background-color:#f7fbfe; padding:2px 8px 2px 8px; margin-left:1px; font-size:14px; margin-right:2px; text-decoration:none; color:#000b7d; }
.page span .current{ background-color:#397eb5;border:1px solid #397eb5; color:#fff; font-weight:bold; }
.page span a:visited{ background-color:#f7fbfe; font-size:14px;}
.page span a:hover{ background-color:#bfdff8;font-size:14px; color:#000b7d;}

.queryMore{ padding:20px 0 20px 20px;text-align:left; font-size:18px; background-color:#fff;}
.queryMore a:link{font-size:18px;color:blue;text-decoration:none;}
.queryMore a:visited{ font-size:18px;color:blue;}
.queryMore a:hover{ font-size:18px;color:red;text-decoration:underline;}

#resultList{ border:1px solid #9fb9c6; width:948px; margin:0 auto;}

a.bookName:link{ color:#010dbc;text-decoration:none; }
a.bookName:hover{ color:#da0000;text-decoration:underline; }
a.bookName:visited{color:#010dbc;text-decoration:none; }

.sale_on_order{cursor:pointer;}

.hintBox{margin:20px 0px 50px 100px;height:160px;width:650px;}
.hintBox div{float:left;font-size:14px;}
.hintBox ul{margin-left:30px;font-size:14px;}
.hintBox li{list-style-type:disc;font-size:14px;}

.searchHint{position:absolute;top:275px;left:600px;
width:365px;background-color:#FFFFFF;border:1px solid #9FB9C6;}
.searchHint .hintTitle{width:100%;border-bottom:1px solid #9FB9C6;background-color:#D5E4F1;}
.hintTitle span{float:left;width:300px;font-weight:bold;}
.searchHint p{padding:10px; line-height:20px;}

.viewSwitch{
}

.toolbar li{float:left; margin-left:5px;}
.sortPanel {margin-left:10px; vertical-align:middle; }
.sortPanel a{float:left;height:21px;border:0px solid #009900;margin:2px 2px 0px 0px;}

.priceAsc{width:44px;background-image:url(images/sort/icon_price_up.gif);}
.priceDesc{width:44px;background-image:url(images/sort/icon_price_down.gif);}
.priceGray{width:44px;background-image:url(images/sort/icon_price_up_gray.gif);}
.priceGray:hover{background-image:url(images/sort/icon_price_up.gif);}

.pubDateAsc{width:71px;background-image:url(images/sort/icon_pubdate_up.gif)}
.pubDateDesc{width:71px;background-image:url(images/sort/icon_pubdate_down.gif)}
.pubDateGray{width:71px;background-image:url(images/sort/icon_pubdate_down_gray.gif)}
.pubDateGray:hover{background-image:url(images/sort/icon_pubdate_down.gif)}

.addTimeAsc{width:71px;background-image:url(images/sort/icon_upload_up.gif)}
.addTimeDesc{width:71px;background-image:url(images/sort/icon_upload_down.gif)}
.addTimeGray{width:71px;background-image:url(images/sort/icon_upload_down_gray.gif)}
.addTimeGray:hover{background-image:url(images/sort/icon_upload_down.gif)}

</style>
<script type="text/javascript" language="javascript" src="js/lib_common.js"></script>
<script type="text/javascript" language="javascript" src="js/cls_cookie.js"></script>
<script type="text/javascript" language="javascript" src="js/cls_state_county_linkage.js"></script>
<script type="text/javascript" language="javascript" src="js/shopping_cart.js"></script>
<script type="text/javascript" language="javascript" src="http://res.kongfz.com/js/core/base.js"></script>
<script type="text/javascript">
var linkage = new StateCountyLinkage();

var forms = {"shop":"frmSearchShop", "auction":"frmSearchAuction", "forum":"frmSearchForum"};
var names = ["shopPanelConent", "auctionPanelConent", "forumPanelConent"];
//var auctionLinks = {"history":"auction.jsp", "current":"http://pm.kongfz.com/search_result.php"};
var currentName = "shop";

function switchPanel(name)
{
    currentName = name;
    for(var i=0; i < names.length; i++){
        $search(names[i]).style.display="none";
    }
    $search(name+"PanelConent").style.display="block";
}

function queryMore()
{
    $search("more").value = 1;
    $search("page").value = parseInt($search("page").value) + 1;
    $search("frmSearchBook").submit();
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
    // modified for bug5551 by zhouyun
    //$search("page").value = 0;
    //$search("frmSearchBook").submit();
    if (checkDate()) {
        $search("page").value = 0;
        $search("frmSearchBook").submit();
    }
}

// added for bug5551 by zhouyun
//判断日期格式
function checkDate(){
    var pubDateStart = trim($search('pubDateStart').value);
    var pubDateEnd   = trim($search('pubDateEnd').value);
    var fomat = true;
    if(pubDateEnd != '')
    {
        if(! pubDateEnd.match(/[0-9]{6}/))
        {
            $search('pubDateEnd').value = '';
            $search('pubDateEnd').focus();
            fomat = false;
        }
    }
    if(pubDateStart != '')
    {
        if(! pubDateStart.match(/[0-9]{6}/))
        {
            $search('pubDateStart').value = '';
            $search('pubDateStart').focus();
            fomat = false;
        }
    }
    if(fomat == false)
    {
        alert('出版日期格式应为6位数字，如201110！');
        return false;
    }
    if(pubDateStart != '' && pubDateEnd != ''){
        if(pubDateEnd - pubDateStart > 10000){
            alert('出版日期范围不能大于100年！');
            $search('pubDateStart').focus();
            return false;
        }
    }
    else if(pubDateStart == '' && pubDateEnd != '')
    {
        alert('请输入出版开始日期！');
        $search('pubDateStart').focus();
        return false;
    }
    else if(pubDateStart != '' && pubDateEnd == '')
    {
        alert('请输入出版结束日期！');
        $search('pubDateEnd').focus();
        return false;
    }
    return true;
}
// added END

function showNewBook(isNewBook)
{
    $search("isNewBook").value = isNewBook;
    $search("frmSearchBook").submit();
}

function showView(style)
{
    var cookie = new JsCookie();
    cookie.expires = "month";
    cookie.set("viewStyle", style);//将style写入Cookies
    $search("frmSearchBook").submit();
}

function setSort(type)
{
    $search("sorttype").value = type;
    $search("frmSearchBook").submit();
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
    var pageTotal = parseInt('<%=pageTotal%>');
    if(page > pageTotal){
        alert("您输入的页码过大，请输入正确的页码。");
        return;
    }
    $search("page").value = page;
    $search("frmSearchBook").submit();
}

function jumppage()
{
    var page = $search("pageNo").value;
    go(page);
}

function showSearchHintPanel()
{
    var display = $search('searchHint').style.display;
    if(display == 'none'){
        $search('searchHint').style.display = 'block';
        $search('searchHint').focus();
    }else{
        $search('searchHint').style.display = 'none';
    }
}

function changeQueryValue(value)
{
    resetSearchHint("query", value);
    $search('content').value=value;
}

function initFormFields()
{
    $search("panelSwitch").value="shop";
    changeQueryValue("<%=encodeForJavaScript(query)%>");
    initSearchHintMessage("query");
}
function changeCategory(value){
	$search("categoryHid").value = value;
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
          <option value="shop" selected="selected">书店区</option>
          <option value="auction">拍卖区</option>
          <!--<option value="forum">社区</option>-->
        </select>
      </td>
      <td><span id="shopPanelConent" style="display:block;">
        <form id="frmSearchShop" name="frmSearchShop" method="get" action="book_adv.jsp">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:280px;" value="<%=encodeForHTML(query)%>" />
          <select name="sale" id="sale">
            <option value="0" <%=("0".equals(sale)?"selected=\"selected\"":"")%>>未售</option>
            <option value="1" <%=("1".equals(sale)?"selected=\"selected\"":"")%>>已售</option>
            <option value="2" <%=("2".equals(sale)?"selected=\"selected\"":"")%>>全部</option>
          </select>
          <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" />
          <a href="/">搜索首页</a> 
          <a href="book_adv.html" target="_blank">高级搜索</a> 
          <a href="index_p.html" target="_blank" class="red">精确搜索</a> 
          <a href="http://help.kongfz.com/?act=detail&contentId=316" target="_blank">如何搜索？</a>
          </label>
        </form>
        </span> <span id="auctionPanelConent" style="display:none">
        <form id="frmSearchAuction" name="frmSearchAuction" method="get" action="auction.jsp">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:245px;" />
          <select id="searchProperty" name="searchProperty" onchange="changeAuctionTarget(this.value)">
            <option value="current">三天内拍卖</option>
            <option value="history" selected="selected">历史拍卖</option>
          </select>
          <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="auction_adv.html">高级搜索</a> <a href="/">搜索首页</a></label>
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
         <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="/">搜索首页</a></label>
        </form>
        </span></td>
    </tr>
  </table>
</div>
<!--search end-->

<!--查询结果提示信息-->
<%=notFoundHintHtml%>

<%
//显示查询结果页，筛选查询栏等
if(serverStatus.equals("ok")){
%>
<div id="position"><%=queryRepport%><div style="clear:both;"></div></div>
<div id="sx">
<div class="search">
<form id="frmSearchBook" name="frmSearchBook" method="get" action="book_adv.jsp" onkeypress="if(event.keyCode==13)this.submit();">
      <input type="hidden" name="sale" id="sale" value="<%=encodeForHTML(sale)%>" />
      <input type="hidden" name="category" id="categoryHid" value="<%=encodeForHTML(category)%>" />
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
	  <tr>
	    <td><strong>在结果中筛选：</strong></td>
	  </tr>
	</table>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td align="right">关键词：</td>
          <td><input type="text" name="query" id="query" value="<%=encodeForHTML(query)%>" /></td>
          <td align="right">分类：</td>
          <td>
          	<select style="width:140px;" id="categorySel" onchange="changeCategory(this.value);">
          		<%=htmlCategoryOptions%>
          	</select>
          </td>
          <td align="right">商品名称：</td>
          <td width="16%"><input type="text" name="itemName" value="<%=encodeForHTML(itemName)%>" style="width:136px;"/></td>
          <td width="2%" rowspan="3" align="center"><img src="images/dot.gif" width="4" height="59" /></td>
          <td width="8%" rowspan="3" align="left"><img onclick="filterSearchSubmit()" style="cursor:pointer" src="images/bt_search02.gif" alt="筛选" /> </td>
          <td width="13%" rowspan="3"><a href="javascript:void(0)" onclick="showSearchHintPanel()">>>搜索小技巧</a></td>
        </tr>
        <tr>
            <td width="7%" align="right">作者：</td>
            <td width="15%" align="left"><input type="text" name="author" value="<%=encodeForHTML(author)%>" style="width:136px;" /></td>
            <td width="7%"  align="right">出版社：</td>
            <td width="15%"><input type="text" name="press" value="<%=encodeForHTML(press)%>" style="width:136px;" /></td>
            <td align="right" title="按价位查询">售价：</td>
            <td title="按价位查询" align="left">
				<select style="width:140px;" id="priceLevel" name="priceLevel">
				<option value="" selected="selected">请选择价位...</option>
				<option value="1">1元以下</option>
				<option value="2">1～4元</option>
				<option value="3">5～9元</option>
				<option value="4">10～19元</option>
				<option value="5">20～49元</option>
				<option value="6">50～99元</option>
				<option value="7">100～199元</option>
				<option value="8">200～499元</option>
				<option value="9">500～999元</option>
				<option value="10">1000～1999元</option>
				<option value="11">2000～4999元</option>
				<option value="12">5000～9999元</option>
				<option value="13">1万～9万元</option>
				<option value="14">10万～99万元</option>
				<option value="15">100万元以上</option>
				</select>
				<script>$search("priceLevel").value="<%=encodeForJavaScript(priceLevel)%>";</script>
            </td>
        </tr>
        <tr>
           <td title="出版日期在六年前的为旧书，六年内的为新书。" align="right">新旧书：</td>
          <td title="出版日期在六年前的为旧书，六年内的为新书。"><select id="isNewBook" name="isNewBook"><%=htmlIsNewBook%></select></td>
          <td width="7%" align="right">书店名称：</td>
          <td width="15%"><input type="text" name="shopName" value="<%=encodeForHTML(shopName)%>" style="width:136px;" /></td>
          <td align="right">省市：</td>
          <td colspan="3" align="left"><label><select id="state" name="state" onchange="linkage.fillCounty(this.value, $search('county'))"></select></label>
				<label><select id="county" name="county" ><option value="">全部</option></select><label>
				<script type="text/javascript">
				linkage.fillState($search('state'));
				linkage.fillCounty("<%=encodeForJavaScript(state)%>", $search('county'))
				$search("state").value = "<%=encodeForJavaScript(state)%>";
				$search("county").value = "<%=encodeForJavaScript(county)%>";
				</script>
            </td>
        </tr>
        <tr>
          <td width="8%" align="right" title="请输入年月，格式如：201110">出版日期：</td>
          <td colspan="3" title="请输入年月，格式如：201110"><input type="text" id="pubDateStart" name="pubDateStart" size="6" maxlength="6" value="<%=encodeForHTML(pubDateStart)%>" />&nbsp;至&nbsp;<input type="text" id="pubDateEnd" name="pubDateEnd" size="6" maxlength="6" value="<%=encodeForHTML(pubDateEnd)%>" /> 格式：201110&nbsp;</label></td>
          <td align="right">ISBN：</td>
          <td align="left"><input type="text" id="isbn" name="isbn" value="<%=encodeForHTML(isbn)%>" style="width:136px;" /></td>
         </tr>
      </table>
      <input type="hidden" name="page" id="page" value="<%=encodeForHTML(currentPage)%>" />
      <input type="hidden" name="sorttype" id="sorttype" value="<%=encodeForHTML(sorttype)%>" />
      <input type="hidden" name="more" id="more" value="<%=encodeForHTML(more)%>" />
      <input type="hidden" name="fuzzy" id="fuzzy" value="<%=encodeForHTML(fuzzy)%>" />
      <input type="hidden" name="priceStart" id="priceStart" value="<%=encodeForHTML(priceStart)%>" />
      <input type="hidden" name="priceEnd" id="priceEnd" value="<%=encodeForHTML(priceEnd)%>" />
    </form>
      </div>
  <!--search end-->
  <script>initFormFields();</script>
</div>
<%
if(documents != null && documents.size() > 0){
%>
<!--bigdiv begin-->
<DIV id="resultList">
  <div class="title01">
  
 
<ul class="toolbar">
<li><%=htmlViewStylePanel%>
<%
    if("precise".equals(searchMode)){
%>
<label style="color:black; font-weight:bold; margin-left:30px">排序：
<select id="sorttypeSelect" onchange="setSort(this.value)" style="margin-top:2px;width:145px;">
<option value="0" selected="selected">默认排序</option>
<option value="1">价格 从低到高↑</option>
<option value="2">价格 从高到低↓</option>
<option value="3">出版日期 从远到近↑</option>
<option value="4">出版日期 从近到远↓</option>
<option value="5">上书时间 从远到近↑</option>
<option value="6">上书时间 从近到远↓</option>
</select></label>
</li>
<li class="sortPanel"><a id="priceSort"></a><a id="pubDateSort"></a><a id="addTimeSort"></a>
<script type="text/javascript">
$search("sorttypeSelect").value="<%=encodeForJavaScript(sorttype)%>";
initSortPanel(<%=encodeForJavaScript(sorttype)%>);
</script>
<%
    }
%>
</li>
</ul>
    
  </div>
  <!--list begin-->
  <%
//显示结果页
try{
    displayHitsTable(documents, out);
}catch(Exception e){
    e.printStackTrace();
}
%>
  <!--分页开始-->
  <%=queryLessHtml%>
  <div class="page"><!--查询的图书总数：，共 <font class="red2"></font> 页--><br />
    <div><%=htmlPageNavigation%><div class="clear"></div>
    </div>
  </div>
  <%=queryMoreHtml%>
  <!--分页结束-->
</DIV>
<!--list end-->
<%
}else{
    //查询不到结果时显示提示信息
    out.write(notFoundMessage);
}  
%>
<%
}else{
    StringBuffer sb = new StringBuffer();
    sb.append("<div style=\"width:950px; margin:6px auto 6px auto;\" >");
    sb.append(" <iframe id=\"iframeDom\" name=\"iframeDom\" ");
    sb.append(" width=\"950px\" height=\"500px\"");
    sb.append(" frameborder=\"0\" ");
    sb.append(" src=\"http://www.baidu.com/s?si=book.kongfz.com&cl=3&ct=2097152&word="+query+"+"+itemName+"+"+author+"&tn=baidulocal\" ");
    sb.append(" ></iframe></div> ");
    out.write(sb.toString());
}
%>
<!-- End  -->
<!--footer开始-->
<div id="contact"> <a href="http://www.kongfz.com/help/aboutus.php" target="_blank">关于孔夫子</a> - <a href="http://help.kongfz.com/" target="_blank">网站帮助</a> -<a href="http://www.kongfz.com/help/guanggao.php" target="_blank"> 广告业务</a> -<a href="http://www.kongfz.com/help/zhaopin.php" target="_blank"> 诚聘英才</a> -<a href="http://www.kongfz.com/help/lianxi.html" target="_blank"> 联系我们</a> -<a href="http://www.kongfz.com/help/copyright.php" target="_blank"> 版权隐私</a> - <a href="http://www.kongfz.com/community/links.php" target="_blank">友情链接</a> -<a href="http://shop.kongfz.com/advice.php?act=add" target="_blank"> 意见建议</a> </div>
<div id="footer"> 版权所有©2002-2013 孔夫子图书网（<a href="http://www.kongfz.com/">www.kongfz.com</a>）<br />
  Copyright © All rights reserved 京ICP 041501&nbsp;&nbsp;客服电话：010-64755951 </div>
<!--footer结束-->

<div id="searchHint" class="searchHint" style="display:none;">
<div class="hintTitle"><span>&nbsp;&nbsp;搜索小技巧</span><a href="javascript:void(0)" onclick="showSearchHintPanel()" title="关闭“搜索小技巧”窗口">[ 关闭 ]</a></div>
<p>
1、全文搜索：可以在“书名、作者、出版社”等项查询您输入的关键词。<br />
2、筛选：搜索后您还可以在页面右侧在结果中进一步筛选。例如：按书名、出版社、 出版时间、书店所在地等等来筛选。<br />
3、排序：在检索的结果中您可以按照价格、出版时间、上书时间等来排序。<br />
4、搜索结果的显示：您可以选择“图文形式”和“列表形式”，默认为“图文形式”。<br />
5、搜索结果中按新书与旧书筛选：您可以选择显示“全部图书”或者“只显示新书”、“只显示旧书”。出版时间在六年前的为旧书，六年内的为新书。<br />
6、搜索区域：您可以在书店和在线拍卖中搜索您要的图书，而且您也可以查看已售的图书。
</p>
</div>
<script type="text/javascript" language="javascript" src="js/query_suggest_agent.js"></script>
<script>
var agent = new QuerySuggestAgent("query");
agent.setFontSize(14);
agent.setPosOffset(1);
agent.start();
</script>
</body>
</html>