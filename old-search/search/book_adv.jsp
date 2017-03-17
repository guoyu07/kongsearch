<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.Map"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ include file="common_book.jsp" %>
<%

/** 将旧是书店搜索定位到新书店搜索地址 （完全避免用户使用旧书店搜索进行相关内容检索，防止内容不正确）*/
response.sendRedirect("http://search.kongfz.com");

/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

//视图风格，取自Cookie
String viewStyle = getCookieValue(request, "viewStyle", "graphic");//graphic,text
String viewListRows = "100";
String tplName = "";
if("graphic".equals(viewStyle)){
    tplName = "tpl_book_adv_graphic.jsp" ;
    viewListRows = "50";
}else{
    tplName = "tpl_book_adv.jsp";
    viewListRows = "100";
}

//索引模块：未售或已售
String sale = StringUtils.strVal(request.getParameter("sale"));
if("".equals(sale)){ sale = "0"; }

//查询参数
String query = StringUtils.strVal(request.getParameter("query"));
String flag = StringUtils.strVal(request.getParameter("flag"));
if("index".equals(flag)){
    query = java.net.URLDecoder.decode(query,"UTF-8");
}else{
    query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
}
query = filterKeywords(query);

//书名
String itemName = StringUtils.strVal(request.getParameter("itemName"));
itemName = new String(itemName.getBytes("ISO_8859_1"),"UTF-8");
itemName = filterKeywords(itemName);

//作者
String author = StringUtils.strVal(request.getParameter("author"));
author = new String(author.getBytes("ISO_8859_1"),"UTF-8");
author = filterKeywords(author);

//出版社
String press = StringUtils.strVal(request.getParameter("press"));
press = new String(press.getBytes("ISO_8859_1"),"UTF-8");
press = filterKeywords(press);

//省市
String state = StringUtils.strVal(request.getParameter("state"));
state = new String(state.getBytes("ISO_8859_1"),"UTF-8");
state = filterKeywords(state);

String county = StringUtils.strVal(request.getParameter("county"));
county = new String(county.getBytes("ISO_8859_1"),"UTF-8");
county = filterKeywords(county);

//只显示书摊图书
String bizType = "";
String onlyStall = StringUtils.strVal(request.getParameter("onlyStall"));
if(!"".equals(onlyStall)){
    bizType = "bookstall";
}

//图书类别
String category = StringUtils.strVal(request.getParameter("category"));
if("".equals(category)){ category = "0"; }

//出版日期
String pubDateStart = StringUtils.strVal(request.getParameter("pubDateStart"));
pubDateStart = new String(pubDateStart.getBytes("ISO_8859_1"),"UTF-8");

String pubDateEnd = StringUtils.strVal(request.getParameter("pubDateEnd"));
pubDateEnd = new String(pubDateEnd.getBytes("ISO_8859_1"),"UTF-8");

//ISBN书号
String isbn = StringUtils.strVal(request.getParameter("isbn"));
isbn = new String(isbn.getBytes("ISO_8859_1"),"UTF-8");

//注：售价和书店名称为新增加的查询项
//售价
String priceStart = StringUtils.strVal(request.getParameter("priceStart"));
priceStart = new String(priceStart.getBytes("ISO_8859_1"),"UTF-8");

String priceEnd = StringUtils.strVal(request.getParameter("priceEnd"));
priceEnd = new String(priceEnd.getBytes("ISO_8859_1"),"UTF-8");

if(!"".equals(priceStart) || !"".equals(priceEnd)){
    System.out.println("price: " + priceStart + "\t" + priceEnd);
}

// 价位
String priceLevel = StringUtils.strVal(request.getParameter("priceLevel"));


//书店名称
String shopName = StringUtils.strVal(request.getParameter("shopName"));
shopName = new String(shopName.getBytes("ISO_8859_1"),"UTF-8");

//新旧书
String isNewBook = StringUtils.strVal(request.getParameter("isNewBook"));
if(isNewBook.equals("")){ isNewBook = "-1"; }

//排序参数
String sorttype = StringUtils.strVal(request.getParameter("sorttype"));
if("".equals(sorttype)){ sorttype = "0"; }

//分页参数
String pageNo = StringUtils.strVal(request.getParameter("page"));
if("".equals(pageNo)){ pageNo = "1"; }

// 查看被省略的结果
String more = StringUtils.strVal(request.getParameter("more"));

// 使用模糊搜索功能
String fuzzy = StringUtils.strVal(request.getParameter("fuzzy"));

// 查看爬虫情况
String agent = StringUtils.strVal(request.getHeader("User-Agent"));
if(!"Mozilla".equalsIgnoreCase(StringUtils.subStr(agent, 7))){
    System.out.println(agent+"\t"+pageNo+"\t"+query);
}

/****************************************************************************
 * 调用远程服务接口
 ****************************************************************************/
ServiceInterface manager = null;
Map resultSet = null;
String result = "";
String serverStatus = "";
List<Map> documents = null;
String currentPage = "0";
String bookTotal = "0";
String pageTotal = "0";
String searchTime = "0";
String searchMode = "";
List<String> querySuggestList = null;
String fuzzyQueryWord = "";
try{
    //取得远程服务器接口实例
    manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.3:9009/BookSearchService");
}catch(Exception ex){
    manager = null;
    //ex.printStackTrace();
}


/*******************************************************************************
 * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
 *******************************************************************************/
if(null != manager){
    HashMap parameters = new HashMap();
    //普通查询加强版
    //parameters.put("advanced", "extendAdv");
    //查询参数
    parameters.put("bizType", bizType);
    parameters.put("saleStatus", sale);//增加的参数
    //parameters.put("searchField", String.valueOf(search_type));
    parameters.put("keywords", query);
    parameters.put("category", category);
    parameters.put("itemName", itemName);
    parameters.put("author", author);
    parameters.put("press", press);
    parameters.put("pubDateStart", pubDateStart);
    parameters.put("pubDateEnd", pubDateEnd);
    parameters.put("isNewBook", isNewBook);
    //省市 
    parameters.put("state", state);
    parameters.put("county", county);
    //ISBN
    parameters.put("isbn", isbn);
    //售价和书店名称，新增查询项
    parameters.put("priceStart", priceStart);
    parameters.put("priceEnd", priceEnd);
    parameters.put("priceLevel", priceLevel);
    parameters.put("shopName", shopName);
    // 查看更多结果
    parameters.put("more", more);
    parameters.put("fuzzy", fuzzy);
    //排序参数
    parameters.put("sortType", sorttype);
    //配置参数
    parameters.put("currentPage", pageNo);
    parameters.put("paginationSize", viewListRows);//由pageSize改为paginationSize，保留pageSize为开本使用
    //parameters.put("sortDefault", );
    //parameters.put("maxClauseCount", );
    //parameters.put("isOutputHtml", true);

    //调用远程查询接口
    try{
        resultSet = manager.work("search", parameters);
    }catch(Exception ex){
        //ex.printStackTrace();
        serverStatus="服务器异常：调用远程服务器查询失败。";
    }

    if(null != resultSet){
        //处理查询结果
        result = StringUtils.strVal(resultSet.get("result"));
        documents = (List) resultSet.get("documents");
    }else{
        serverStatus = "服务器异常：未知错误。";
    }

    if("0".equals(result)){
        searchMode = StringUtils.strVal(resultSet.get("searchMode"));
        querySuggestList = (List<String>) resultSet.get("querySuggestList");
        fuzzyQueryWord = StringUtils.strVal(resultSet.get("fuzzyQueryWord"));
        //System.out.println("searchMode:"+searchMode+","+querySuggestList);
        //将查询到的图书列表输出
        currentPage = StringUtils.strVal(resultSet.get("currentPage"));
        bookTotal   = StringUtils.strVal(resultSet.get("hitsCount"));
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
String htmlIsNewBook = buildIsNewBookBar(encodeForHTML(isNewBook));

//查询结果提示信息
String youWantFind = "";
if(null != querySuggestList && querySuggestList.size() > 0){
    List<String> linkList = new ArrayList<String>();
    for(String word : querySuggestList){
        String link = "<a href=\"book.jsp?query="+java.net.URLEncoder.encode(word,"UTF-8")+"\">"+encodeForHTML(word)+"</a>";
        linkList.add(link);
    }
    youWantFind = StringUtils.join(" | ", linkList);
}

String queryRepport = "";
String notFoundHintHtml = "";
if("ok".equals(serverStatus)){
     if("fuzzy".equals(searchMode) && StringUtils.intVal(bookTotal) > 0){
        // 精确搜索不到结果时的提示信息
        notFoundHintHtml = getNotFoundHintHtml(fuzzy, encodeForHTML(fuzzyQueryWord), youWantFind);
    
        StringBuffer buffer = new StringBuffer();
        buffer.append("<span style=\"padding-left:20px;font-size:14px;\">");
        buffer.append("以下是系统给您推荐的与“<label style=\"color:#FF0000;font-size:14px;\">"+encodeForHTML(fuzzyQueryWord)+"</label>”相似的图书"+encodeForHTML(bookTotal)+"项，");
        //buffer.append("共"+pageTotal+"页，");
        buffer.append("用时"+encodeForHTML(searchTime)+"秒");
        buffer.append("</span>");
        queryRepport = buffer.toString();
    }
    else
    {
        StringBuffer buffer = new StringBuffer();
        buffer.append("<span style=\"padding-left:20px;font-size:14px;\">");
        if(!query.equals("")){
            buffer.append("您查询的是“<label style=\"color:#FF0000;font-size:14px;\">"+encodeForHTML(query)+"</label>”，");
        }
        buffer.append("查找到相关图书"+encodeForHTML(bookTotal)+"项，");
        //buffer.append("共"+pageTotal+"页，");
        buffer.append("用时"+encodeForHTML(searchTime)+"秒");
        buffer.append("</span>");
        queryRepport = buffer.toString();
    }
}
else
{
    queryRepport = "<span style=\"padding-left:20px;color:red\">系统维护中，暂时不能搜索，敬请谅解！</span>";
}

String tradeMessage = "<a href=\"http://www.kongfz.com/trade/add_trade.php?tc=matching&tn="
+java.net.URLEncoder.encode(new String("求购配售"),"GBK")
+"&ti="+java.net.URLEncoder.encode(query,"GBK")
+"&subtc="+java.net.URLEncoder.encode(new String("求购"),"GBK")+"\" target=\"_blank\"><img style=\"margin:0px;\" border=\"0\" src=\"images/bt_publish.gif\" title=\"发布求购信息\" /></a>";

// 搜索无结果时的提示信息
String notFoundMessage = getNotFoundMessageHtml(encodeForHTML(query));

// 图文 或 列表 切换按钮
String graphicImg = "graphic".equals(viewStyle)?"icon_pic.gif":"icon_pic_gray.gif";
String textImg = !"graphic".equals(viewStyle)?"icon_list.gif":"icon_list_gray.gif";
StringBuffer buffer = new StringBuffer();
buffer.append("<span style=\"vertical-align:bottom\">");
if("graphic".equals(viewStyle)){
    buffer.append("<img src=\"/images/"+graphicImg+"\" alt=\"图文\" align=\"baseline\">&nbsp;<strong>图文</strong>");
}else{
    buffer.append("<a href=\"javascript:showView('graphic');\" class=\"red\"><img src=\"/images/"+graphicImg+"\" alt=\"图文\" align=\"baseline\">&nbsp;图文</a>");
}
buffer.append("&nbsp;&nbsp;");
if(!viewStyle.equals("graphic")){
    buffer.append("<img src=\"/images/"+textImg+"\" alt=\"列表\" align=\"baseline\">&nbsp;<strong>列表</strong>");
}else{
    buffer.append("<a href=\"javascript:showView('text');\" class=\"red\" style=\"font-weight:normal;\"><img src=\"/images/"+textImg+"\" alt=\"列表\" align=\"baseline\">&nbsp;列表</a>");
}
buffer.append("</span>");
String htmlViewStylePanel = buffer.toString();

// 默认情况下，限制显示前100页
int navPageTotal = StringUtils.intVal(pageTotal);
if(0 == StringUtils.intVal(more) && navPageTotal > 100){
    navPageTotal = 100;
}
String htmlPageNavigation = displayNavigation(navPageTotal, StringUtils.intVal(currentPage), request.getQueryString(), "book_adv.jsp");

String onlyStallHtml = "".equals(onlyStall) ? "" : "checked=\"checked\"";

String queryMoreHtml = "";
if(0 == StringUtils.intVal(more) && StringUtils.intVal(pageTotal) > 100 && StringUtils.intVal(currentPage) >= 100){
    queryMoreHtml = "<div class=\"queryMore\">提示：限于网页篇幅，部分结果未予显示。<a href=\"javascript:queryMore();\">您可以点击此处查看省略的结果。</a></div>";
}

String queryLessHtml = "";
if("precise".equals(searchMode) && currentPage.equals(pageTotal)){
    String fuzzyQueryStr="query="+query+"&sale=0&fuzzy=1";
    queryLessHtml = "<div class=\"queryMore\">"
                  + "提示：如果您想查找更多相关图书，请查看<a href=\"?"+fuzzyQueryStr+"\">模糊搜索结果。</a><br />"
                  + "您可以试着搜索：" + youWantFind + "<br />"
                  + "也可以尝试减少搜索的字词来获得更多的结果。"
                  + "</div>";
}

/********************************************************************************
 * 使用模板显示处理结果
 ********************************************************************************/
//设置模板变量
request.setAttribute("sale", sale);
request.setAttribute("query", query);
request.setAttribute("state", state);
request.setAttribute("county", county);
request.setAttribute("category", category);
request.setAttribute("itemName", itemName);
request.setAttribute("author", author);
request.setAttribute("press", press);
request.setAttribute("pubDateStart", pubDateStart);
request.setAttribute("pubDateEnd", pubDateEnd);
request.setAttribute("isbn", isbn);

request.setAttribute("priceStart", priceStart);
request.setAttribute("priceEnd", priceEnd);
request.setAttribute("priceLevel", priceLevel);
request.setAttribute("shopName", shopName);

request.setAttribute("more", more);
request.setAttribute("fuzzy", fuzzy);
request.setAttribute("sorttype", sorttype);
request.setAttribute("pageNo", pageNo);
request.setAttribute("viewStyle", viewStyle);

request.setAttribute("result", result);
request.setAttribute("serverStatus", serverStatus);
request.setAttribute("documents", documents);
request.setAttribute("currentPage", currentPage);
request.setAttribute("bookTotal", bookTotal);
request.setAttribute("pageTotal", pageTotal);
request.setAttribute("searchTime", searchTime);

request.setAttribute("searchMode", searchMode);
request.setAttribute("fuzzyQueryWord", fuzzyQueryWord);
request.setAttribute("queryRepport", queryRepport);
request.setAttribute("youWantFind", youWantFind);
request.setAttribute("notFoundMessage", notFoundMessage);
request.setAttribute("htmlPageNavigation", htmlPageNavigation);
request.setAttribute("htmlCategoryOptions", htmlCategoryOptions);
request.setAttribute("htmlIsNewBook", htmlIsNewBook);
request.setAttribute("htmlViewStylePanel", htmlViewStylePanel);
request.setAttribute("onlyStallHtml", onlyStallHtml);
request.setAttribute("queryMoreHtml", queryMoreHtml);
request.setAttribute("queryLessHtml", queryLessHtml);
request.setAttribute("notFoundHintHtml", notFoundHintHtml);

//System.out.println("book_adv,"+viewStyle+","+sorttype+","+pageNo+","+isNewBook+","+state+","+county);

//转交到指定JSP模板文件输出处理结果
try {
    RequestDispatcher viewDispatcher = request.getRequestDispatcher("/templates/"+tplName);
    viewDispatcher.forward(request, response);
} catch (ServletException e) {
    //e.printStackTrace();
} catch (Exception e) {
    //e.printStackTrace();
}

%>
