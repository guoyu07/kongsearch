<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ include file="/common_auction.jsp" %>
<%
/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

//视图风格，取自Cookie
String viewStyle = getCookieValue(request, "viewStyle", "graphic");
String viewListRows = "100";
String tplName = "";
if("graphic".equals(viewStyle)){
    tplName = "tpl_auction_adv_graphic.jsp" ;
    viewListRows = "50";
}else{
    tplName = "tpl_auction_adv.jsp";
    viewListRows = "100";
}


//查询参数
String query = StringUtils.strVal(request.getParameter("query"));
String flag = StringUtils.strVal(request.getParameter("flag"));
if("index".equals(flag)){
    query = java.net.URLDecoder.decode(query,"UTF-8");
}else{
    query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
}
query = filterKeywords(query);

// 拍卖区
String auctionArea = StringUtils.strVal(request.getParameter("auctionArea"));

// 类别
String category = StringUtils.strVal(request.getParameter("category"));
if("".equals(category)){ category = "0"; }

// 拍品编号
String itemId = StringUtils.strVal(request.getParameter("itemId"));//新增
itemId = new String(itemId.getBytes("ISO_8859_1"),"UTF-8");

// 拍卖主题
String itemName = StringUtils.strVal(request.getParameter("itemName"));
itemName = new String(itemName.getBytes("ISO_8859_1"),"UTF-8");
itemName = filterKeywords(itemName);

// 拍主昵称
String nickname = StringUtils.strVal(request.getParameter("sellerNickname"));
nickname = new String(nickname.getBytes("ISO_8859_1"),"UTF-8");
nickname = filterKeywords(nickname);

//作者
String author = StringUtils.strVal(request.getParameter("author"));
author = new String(author.getBytes("ISO_8859_1"),"UTF-8");
author = filterKeywords(author);

// 出版社
String press = StringUtils.strVal(request.getParameter("press"));
press = new String(press.getBytes("ISO_8859_1"),"UTF-8");
press = filterKeywords(press);

//出版日期
String pubDateS = StringUtils.strVal(request.getParameter("pubDateS"));
pubDateS = new String(pubDateS.getBytes("ISO_8859_1"),"UTF-8");

String pubDateE = StringUtils.strVal(request.getParameter("pubDateE"));
pubDateE = new String(pubDateE.getBytes("ISO_8859_1"),"UTF-8");

//开始拍卖时间
String beginTimeS = StringUtils.strVal(request.getParameter("beginTimeS"));
beginTimeS = new String(beginTimeS.getBytes("ISO_8859_1"),"UTF-8");

String beginTimeE = StringUtils.strVal(request.getParameter("beginTimeE"));
beginTimeE = new String(beginTimeE.getBytes("ISO_8859_1"),"UTF-8");

//结束拍卖时间
String endTimeS = StringUtils.strVal(request.getParameter("endTimeS"));
endTimeS = new String(endTimeS.getBytes("ISO_8859_1"),"UTF-8");

String endTimeE = StringUtils.strVal(request.getParameter("endTimeE"));
endTimeE = new String(endTimeE.getBytes("ISO_8859_1"),"UTF-8");

//排序参数
String sorttype = StringUtils.strVal(request.getParameter("sorttype"));
if("".equals(sorttype)){ sorttype = "0"; }

//分页参数
String pageNo = StringUtils.strVal(request.getParameter("page"));
if("".equals(pageNo)){ pageNo = "1"; }


/****************************************************************************
 * 调用远程服务接口
 ****************************************************************************/
ServiceInterface server = null;
Map resultSet = null;
String result = "";
String serverStatus = "";
List<Map> documents = null;
String currentPage = "0";
String bidTotal = "0";
String pageTotal = "0";
String searchTime = "0";

try{
    //取得远程服务器接口实例
    server = (ServiceInterface)Naming.lookup("rmi://192.168.1.105:9101/AuctionSearchService");
}catch(Exception ex){
    server = null;
    //ex.printStackTrace();
}
/*******************************************************************************
 * 请求远程服务：建立索引、查询索引、删除索引
 *******************************************************************************/
if(server != null){
    HashMap parameters = new HashMap();
    //查询参数
    //parameters.put("searchField", String.valueOf(search_type));
    parameters.put("keywords", query);
    parameters.put("auctionArea", auctionArea);
    parameters.put("category", category);
    parameters.put("itemId", itemId);//新增
    parameters.put("itemName", itemName);
    parameters.put("nickname", nickname);
    parameters.put("author", author);
    parameters.put("press", press);
    parameters.put("pubDateS", pubDateS);
    parameters.put("pubDateE", pubDateE);
    parameters.put("beginTimeS", beginTimeS);
    parameters.put("beginTimeE", beginTimeE);
    parameters.put("endTimeS", endTimeS);
    parameters.put("endTimeE", endTimeE);
    //排序参数
    parameters.put("sortType", sorttype);
    //查询类配置参数
    parameters.put("currentPage", pageNo);
    parameters.put("paginationSize", viewListRows);
    //parameters.put("sortDefault", );
    //parameters.put("maxClauseCount", );
    //parameters.put("isOutputHtml", true);

    //调用远程查询接口
    try{
        resultSet = server.work("Search", parameters);
    }catch(Exception ex){
        ex.printStackTrace();
        serverStatus="服务器异常：调用远程服务器查询失败。";
    }

    if(null != resultSet){
        //处理查询结果
        result = StringUtils.strVal(resultSet.get("status"));
        documents = (List) resultSet.get("documents");
    }else{
        serverStatus = "服务器异常：未知错误。";
    }

    if("0".equals(result)){
        //将查询到的拍品列表输出
        currentPage = StringUtils.strVal(resultSet.get("currentPage"));
        bidTotal    = StringUtils.strVal(resultSet.get("hitsCount"));
        pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
        searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
        serverStatus = "ok";
    }else if("1".equals(result)){
        serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
    }else if("2".equals(result)){
        serverStatus = "服务器异常：查询受阻，正在将磁盘索引载入内存。";
    }else if("3".equals(result)){
        serverStatus = "服务器异常：查询过程中出现错误。";
    }else{
        serverStatus = "服务器异常：未知错误。";
    }
    //
}else{
    serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
}
//System.out.println(serverStatus);

/*******************************************************************************
 * 组织页面显示内容
 *******************************************************************************/
String htmlCategoryOptions = buildCategoryOptions(category);
String htmlAuctionAreaOptions = buildAuctionAreaOptions(auctionArea);

//查询结果提示信息
StringBuffer buffer = new StringBuffer();
if("ok".equals(serverStatus)){
    buffer.append("<span style=\"padding-left:20px;\">");
    if(!query.equals("")){
        buffer.append("您查询的是“<font color=red>"+encodeForHTML(query)+"</font>”，");
    }
    buffer.append("查找到相关拍品："+bidTotal+"项，");
    buffer.append("共"+pageTotal+"页，");
    buffer.append("用时"+searchTime+"秒");
    buffer.append("</span>");
}
else
{
    buffer.append("<span style=\"padding-left:20px;color:red\">系统维护中，暂时不能搜索，敬请谅解！</span>");
}
String queryRepport = buffer.toString();
buffer = null;


String tradeMessage = "<a href=\"http://www.kongfz.com/trade/add_trade.php?tc=matching&tn="
+java.net.URLEncoder.encode(new String("求购配售"),"GBK")
+"&ti="+java.net.URLEncoder.encode(query,"GBK")
+"&subtc="+java.net.URLEncoder.encode(new String("求购"),"GBK")+"\" target=\"_blank\"><img style=\"margin:0px;\" border=\"0\" src=\"images/bt_publish.gif\" title=\"发布求购信息\" /></a>";

String notFoundMessage = "<div class=\"hintBox\">"
        +"<div><img src=\"images/none_message.gif\" /></div>"
        +"<div><ul>"
        +"<li>很抱歉，没有找到符合检索条件的相关图书。</li>"
        +"<li>确信所有的字串正确无误。</li>"
        +"<li>尽可能让字串简洁和使用常规字串。</li>"
        +"<li>试用不同的关键字。 </li>"
        //+"<li>您还可以"+tradeMessage+" </li>"
        +"</ul></div>"
        +"</div>";

String graphicImg = viewStyle.equals("graphic")?"icon_pic.gif":"icon_pic_gray.gif";
String textImg = !viewStyle.equals("graphic")?"icon_list.gif":"icon_list_gray.gif";

buffer = new StringBuffer();
buffer.append("<span style=\"vertical-align:bottom\">");

if("graphic".equals(viewStyle)){
    buffer.append("<img src=\"/images/"+graphicImg+"\" alt=\"图文\" align=\"baseline\">&nbsp;<strong>图文</strong>");
}else{
    buffer.append("<a href=\"javascript:showView('graphic');\" class=\"red\"><img src=\"/images/"+graphicImg+"\" alt=\"图文\" align=\"baseline\">&nbsp;图文</a>");
}
buffer.append("&nbsp;&nbsp;&nbsp;&nbsp;");
if(!"graphic".equals(viewStyle)){
    buffer.append("<img src=\"/images/"+textImg+"\" alt=\"列表\" align=\"baseline\">&nbsp;<strong>列表</strong>");
}else{
    buffer.append("<a href=\"javascript:showView('text');\" class=\"red\" style=\"font-weight:normal;\"><img src=\"/images/"+textImg+"\" alt=\"列表\" align=\"baseline\">&nbsp;列表</a>");
}
buffer.append("</span>");
String htmlViewStylePanel = buffer.toString();

String htmlPageNavigation = displayNavigation(StringUtils.intVal(pageTotal), StringUtils.intVal(currentPage), request.getQueryString(), "auction_adv.jsp");


/********************************************************************************
 * 使用模板显示处理结果
 ********************************************************************************/
//设置模板变量
request.setAttribute("query", query);
request.setAttribute("category", category);
request.setAttribute("itemId", itemId);
request.setAttribute("itemName", itemName);
request.setAttribute("nickname", nickname);
request.setAttribute("author", author);
request.setAttribute("press", press);
request.setAttribute("pubDateS", pubDateS);
request.setAttribute("pubDateE", pubDateE);
request.setAttribute("beginTimeS", beginTimeS);
request.setAttribute("beginTimeE", beginTimeE);
request.setAttribute("endTimeS", endTimeS);
request.setAttribute("endTimeE", endTimeE);

request.setAttribute("sorttype", sorttype);
request.setAttribute("pageNo", pageNo);
request.setAttribute("viewStyle", viewStyle);

request.setAttribute("result", result);
request.setAttribute("serverStatus", serverStatus);
request.setAttribute("documents", documents);
request.setAttribute("currentPage", currentPage);
request.setAttribute("bidTotal", bidTotal);
request.setAttribute("pageTotal", pageTotal);
request.setAttribute("searchTime", searchTime);

request.setAttribute("queryRepport", queryRepport);
request.setAttribute("notFoundMessage", notFoundMessage);
request.setAttribute("htmlCategoryOptions", htmlCategoryOptions);
request.setAttribute("htmlAuctionAreaOptions", htmlAuctionAreaOptions);
request.setAttribute("htmlPageNavigation",htmlPageNavigation );
request.setAttribute("htmlViewStylePanel", htmlViewStylePanel);


//转交到指定JSP模板文件输出处理结果
try {
    RequestDispatcher viewDispatcher = request.getRequestDispatcher("/templates/"+tplName);
    viewDispatcher.forward(request, response);
} catch (ServletException e) {
    e.printStackTrace();
} catch (Exception e) {
    e.printStackTrace();
}


%>
