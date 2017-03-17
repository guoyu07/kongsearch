<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.util.datetime.TimeUtils" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%!

    /**
     * 过滤查询的关键词
     * @param keywords
     * @return
     */
    private String filterKeywords(String keywords)
    {
        int maxlength = 50;
        keywords = keywords.trim();
        if(keywords.equals("支持书名、作者、出版社、店名、省市等多个关键字的复合查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市进行组合查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市进行查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市查询")){
            keywords="";
        }
        if(keywords.equals("可输入拍卖主题、拍主昵称、作者查询")){
            keywords="";
        }
        if(keywords.equals("可输入帖子主题、内容查询")){
            keywords="";
        }
        if(keywords.equals("请输入书名或作者进行查询！")){
            keywords="";
        }
        
        if( keywords.length() > maxlength){
            keywords = keywords.substring(0, maxlength);
        }
        //屏蔽的字符：\ ! ( ) : ^ [ ] { } ~ * ? /
        keywords = keywords.replaceAll("[\\\\\\!\\(\\)\\:\\^\\[\\]\\{\\}\\~\\*\\?/\'\";]", "");
        //替换为空格的字符：全角空格　、制表符\t
        keywords = keywords.replaceAll("[　\t]", " ");
        //多个空格替换为一个空格
        keywords = keywords.replaceAll("( )+", " ");
        keywords = keywords.replaceAll("－－|--", "——");//两个全角减号替换为一个破折号
        
        //全角的＋、－、ＡＮＤ、ＯＲ替换为半角的
        keywords = keywords.replaceAll("＋", "+");
        keywords = keywords.replaceAll("－", "-");		
        keywords = keywords.replaceAll("ＡＮＤ", "AND");
        keywords = keywords.replaceAll("ＯＲ", "OR");		

        //先去掉+或-前后的空格
        keywords = keywords.replaceAll("( ?\\+ ?)+", "+");
        keywords = keywords.replaceAll("( ?\\- ?)+", "-");
        keywords = keywords.replaceAll("( ?AND ?)+", "AND");
        keywords = keywords.replaceAll("( ?OR ?)+", "OR");
        //再去掉连续的逻辑运算符
        keywords = keywords.replaceAll("(\\+)+", "+");
        keywords = keywords.replaceAll("(\\-)+", "-");
        keywords = keywords.replaceAll("(AND)+", "AND");
        keywords = keywords.replaceAll("(OR)+", "OR");		
        //去掉重叠的逻辑运算符
        keywords = keywords.replaceAll("(\\-\\+)+", "-");
        keywords = keywords.replaceAll("(\\+\\-)+", "+");
        keywords = keywords.replaceAll("(ORAND)+", "OR");
        keywords = keywords.replaceAll("(ANDOR)+", "AND");
        //去掉行头和行尾的逻辑运算符
        keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        //规范化逻辑表达式
        keywords = keywords.replaceAll("\\+", " +");
        keywords = keywords.replaceAll("\\-", " -");
        keywords = keywords.replaceAll("AND", " AND ");
        keywords = keywords.replaceAll("OR", " OR ");
        keywords = keywords.trim();
        return keywords;
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage, String queryString, String pageUrl)
    {
        StringBuffer buffer = new StringBuffer();
        if(queryString != null){
            queryString = queryString.replaceAll("&*page=\\d*", "");
        }else{
            queryString = "";
        }
        queryString = pageUrl + "?"+ queryString + "&page=";

        if(pageCount > 0) {
            //htmlContent += "<span><a href=\"javascript:go(1)\">首页</a></span>";
            
            //如果当前页为第一页，则不显示“上一页链接”
            if(currentPage > 1){
                buffer.append("<span><a href=\""+queryString+(currentPage-1)+"\">上一页</a></span>");
            }else{
                buffer.append("<span><a>上一页</a></span>");
            }
            
            //每次从当前页向后显示十页，如果不够十页，则全部显示。
            int pageStep = 9;//显示的页码数量
            int start = ( currentPage - 1 ) / pageStep * pageStep + 1;
            start = start < 1 ? 1 : start;
            int end = start + pageStep;
            end = end > pageCount ? pageCount : end;
            
            if(start > 1){
                buffer.append("<span><a href=\""+queryString+"1"+"\">1</a></span>");
            }
            
            if(start > 2){
                buffer.append("<span>...</span>");
            }
            
            for(int i = start; i <= end ; i++){
                if(currentPage == i){
                    buffer.append("<span><a class=\"current\">"+i+"</a></span>");
                }else{
                    buffer.append("<span><a href=\""+queryString+i+"\">"+i+"</a></span>");
                }
            }
            
            if(end  < pageCount){
                buffer.append("<span>...</span>");
            }
            //htmlContent += "<span><a href=\"javascript:go("+pageCount+")\">"+pageCount+"</a></span>";
            
            //如果当前页为最后一页，则不显示“下一页”链接
            if(currentPage < pageCount){
                buffer.append("<span><a href=\""+queryString+(currentPage+1)+"\">下一页</a></span>");
            }else{
                buffer.append("<span><a>下一页</a></span>");
            }
            //htmlContent += "<a href=\"javascript:go("+pageCount+")\">末页</a>";
            //跳转到指定页
            /*if(pageCount > 1){
            buffer.append("<span>　　到第<input id=\"pageNo\" type=\"text\" maxLength=3 style=\"margin-top:5px;width:25px;\" onkeydown=\"if(event.keyCode==13)go(this.value)\" />页</span>");
            buffer.append("<span><input style=\"margin-top:5px;\" type=\"button\" onclick=\"jumppage()\" value=\"确定\"/></span>");
            }*/
            
        }
        return buffer.toString();
    }

    /**
     * 显示论坛帖子查询结果
     */
    private void displayForumTable(ArrayList articleList, String keyword, JspWriter out) throws Exception
    {
    	String forumSite = "";
        String primaryKey, tid, pid, fid, authorid, author, subject, content, postSubject, link;
        long postdate = 0;
        for(int i=0; i < articleList.size(); i++)
        {
            Map map = (Map) articleList.get(i);
            primaryKey  = StringUtils.strVal(map.get("primaryKey"));
            tid         = StringUtils.strVal(map.get("tid"));
            pid         = StringUtils.strVal(map.get("pid"));
            fid         = StringUtils.strVal(map.get("fid"));
            authorid    = StringUtils.strVal(map.get("authorid"));
            author      = StringUtils.strVal(map.get("author"));
            subject     = StringUtils.strVal(map.get("subject_hl"));
            content     = StringUtils.strVal(map.get("content_hl"));
            postSubject = StringUtils.strVal(map.get("postSubject_hl"));
            postdate    = StringUtils.longVal(map.get("postdate"));
            if(primaryKey.contains("_-1")){
            	forumSite = "http://www.gujiushu.com/article_";
            }else{
        		forumSite = "http://www.gujiushu.com/";
            }
            link        = forumSite + tid + ".html";

            out.write("<div class=\"subject\"><a href=\"" + link + "\" target=\"_blank\">"+subject+"</a></div>");
            out.write("<div>"+postSubject+"</div>");
            out.write("<div class=\"content\">" + (!"0".equals(pid)?"[回复] " : "") + content + "</div>");
            out.write("<div class=\"contentLink\">");
            out.write(forumSite + tid + ".html ");
            out.write(TimeUtils.getDateTime(postdate, "yyyy-MM-dd"));
            out.write(" " + getForumName(fid));
            out.write(" - <a href=\""+link+"\" target=\"_blank\">详细内容</a></div>");
        
        }
    }

    private String getForumName(String fid)
    {
        Map<String, String> map = new HashMap<String, String>();
        map.put("26", "网站公告");
        map.put("9", "淘书指南");
        map.put("10", "收藏学堂");
        map.put("6", "文史大话");
        map.put("7", "夫子书话");
        map.put("13", "精品自荐");
        map.put("11", "分类信息");
        map.put("14", "灌水区");
        map.put("18", "意见建议");
        map.put("9999", "书界新闻");
        map.put("9998", "市场动态");

        String fname = map.get(fid);
        if (null == fname) {
            fname = "";
        }
        return fname;
    }
%>
<%
    /****************************************************************************
     * 接收页面请求参数
     ****************************************************************************/
    //设置页面中使用UTF-8编码
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    //查询参数
    String query = (String) request.getParameter("query");
    try{
        String flag = (String) request.getParameter("flag");
        if(flag != null && flag.equals("index")){
            query = java.net.URLDecoder.decode(query,"UTF-8");
        }else{
            query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
        }
        query = filterKeywords(query);
    }catch(Exception ex){
        query = "";
    }


    String category = (String) request.getParameter("category");
    if(category == null || category.equals("")){
        category = "";
    }

    String pageNo = (String) request.getParameter("page");
    if(pageNo == null || pageNo.equals("")){
        pageNo = "0";
    }


    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface server = null;
    Map resultSet = null;
    String serverStatus = "";
    String status = "";
    ArrayList documents = new ArrayList();
    String currentPage = "0";
    String hitsTotal = "0";
    String pageTotal = "0";
    String searchTime = "0";

    try{
        //取得远程服务器接口实例
        server = (ServiceInterface)Naming.lookup("rmi://192.168.1.3:9200/ForumContentService");
    }catch(Exception ex){
        server = null;
        //ex.printStackTrace();
    }
    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、删除索引
     *******************************************************************************/
    if(server != null){
        HashMap parameters = new HashMap();
        parameters.put("keywords", query);
        parameters.put("category", category);

        //查询类配置参数
        parameters.put("currentPage", pageNo);
        parameters.put("paginationSize", "20");
        //parameters.put("sortDefault", );

        //调用远程查询接口
        try{
            resultSet = server.work("SearchForum", parameters);
        }catch(Exception ex){
            ex.printStackTrace();
            serverStatus="服务器异常：调用远程服务器查询失败。";
        }

        if(resultSet != null){
            //处理查询结果
            status = StringUtils.strVal(resultSet.get("status"));
            documents = (ArrayList) resultSet.get("documents");
        }else{
            serverStatus = "服务器异常：未知错误。";
        }

        if(status.equals("0")){
            //将查询到的拍品列表输出
            currentPage = StringUtils.strVal(resultSet.get("currentPage"));
            if (documents.size() > 0) {
		hitsTotal   = StringUtils.strVal(resultSet.get("hitsCount"));
            pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
		}
            searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
            serverStatus = "ok";
        }else if(status.equals("1")){
            serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
        }else if(status.equals("2")){
            serverStatus = "服务器异常：查询受阻，正在将磁盘索引载入内存。";
        }else if(status.equals("3")){
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
    //查询结果提示信息
    StringBuffer buffer = new StringBuffer();
    if (serverStatus.equals("ok")) {
        buffer.append("<span style=\"padding-left:20px;\">");
        if(!query.equals("")){
            buffer.append("您查询的是“<font color=red>"+query+"</font>”，");
        }
        buffer.append("查找到相关结果"+hitsTotal+"项，");
        buffer.append("共"+pageTotal+"页，");
        buffer.append("用时"+searchTime+"秒");
        buffer.append("</span>");
    }
    else {
        buffer.append("<span style=\"padding-left:20px;color:red\">系统维护中，暂时不能搜索，敬请谅解！</span>");
    }
    String queryRepport = buffer.toString();
    buffer = null;

%>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="http://xiaoxi.kongfz.com/css/im/main.css" />
<script src="http://xiaoxi.kongfz.com/js/jquery/jquery.min.js"></script>
<script src="http://xiaoxi.kongfz.com/js/webim_core.js"></script>
<link href="css/shop_main.css" rel="stylesheet" type="text/css">
<link href="css/top.css" rel="stylesheet" type="text/css">
<title>孔夫子旧书搜索——全球最大旧书搜索引擎</title>
<style type="text/css">
    body{ text-align:center; margin:0; padding:0;}
    *{ font-size:12px;}
    #search{ background:url(images/bg_search_result.gif); height:48px;_height:42px; width:948px; margin:0 auto; padding-top:2px;_padding-top:8px; border-bottom:1px solid #a4c1d3;border-left:1px solid #a4c1d3;border-right:1px solid #a4c1d3;}
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
    .page span a:hover{ background-color:#bfdff8;font-size:14px; color:#000b7d;}

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
    #list .blue{ font-size:14px;}
    #list .gray{ color:#6d6d6d;}
    #list .prace{ font-size:14px; font-weight:bold; color:#fe4902;}
    a.blue:link{ color:#010dbc;text-decoration:none;}
    a.blue:hover{ color:#da0000;text-decoration:underline;}
    a.blue:visited{color:#010dbc;text-decoration:none;}
    .orange{ color:#fe6102;}
    #list th{ background:url(images/bg_h2.gif); height:30px; line-height:30px;padding-left:5px;}
    
    #list .subject {}
    #list .subject a {font-size:16px;color:#1111CC;}
    #list .subject font {font-size:16px;}

    #list .content {font-size:13px;line-height:18px}
    #list .content font {font-size:13px;line-height:18px}
    
    #list .contentLink {padding-bottom:10px;font-size:14px;color:#0D776F}
    #list .contentLink a {color:#666666}

    .red2 {color:red;}
    .hintBox{float:left; padding:10px; margin-left:60px;}
    .hintBox div{float:left;}
    .hintBox ul{margin-left:30px;}
    .hintBox li{list-style-type:disc;}
</style>
<script type="text/javascript" language="javascript" src="js/lib_common.js"></script>
<script type="text/javascript" language="javascript" src="http://res.kongfz.com/js/core/base.js"></script>
<script type="text/javascript">
    var forms = {"shop":"frmSearchShop", "auction":"frmSearchAuction", "forum":"frmSearchForum"};
    var names = ["shopPanelConent", "auctionPanelConent", "forumPanelConent"];
    var currentName = "forum";

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
        $search("page").value = 0;
	$search("cacheHiddenTime").value = new Date().getTime();
        $search(forms[currentName]).submit();
    }

    function changeAuctionTarget(value)
    {
        $search("frmSearchAuction").action = auctionLinks[value];
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
        $search("frmSearchForum").submit();
    }

    function jumppage()
    {
        var page = $search("pageNo").value;
        go(page);
    }

    function changeQueryValue(value)
    {
        resetSearchHint("query", value);
        $search('content').value = value;
    }

    function initFormFields()
    {
        $search("panelSwitch").value="forum";
        changeQueryValue("<%=query%>");
        initSearchHintMessage("query");
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
      <td><select id="panelSwitch" name="panelSwitch" onchange="switchPanel(this.value)" style="display:none;">
          <option value="shop">书店区</option>
          <option value="auction">拍卖区</option>
          <!-- <option value="forum" selected="selected">社区</option> -->
        </select>
      </td>
      <td><span id="shopPanelConent" style="display:none">
        <form id="frmSearchShop" name="frmSearchShop" method="get" action="book.jsp" style="margin:0px;">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:280px;" />
          <select name="sale" id="sale">
            <option value="0">未售</option>
            <option value="1">已售</option>
          </select>
          <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="book_adv.html">高级搜索</a> <a href="/">搜索首页</a></label>
        </form>
        </span> <span id="auctionPanelConent" style="display:none">
        <form id="frmSearchAuction" name="frmSearchAuction" method="get" action="auction.jsp" style="margin:0px;">
          <input type="text" id="query" name="query" onchange="changeQueryValue(this.value)" style="width:245px;" />
          <select name="searchProperty" onchange="changeAuctionTarget(this.value)">
            <option value="current">三天内拍卖</option>
            <option value="history" selected="selected">历史拍卖</option>
          </select>
          <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="auction_adv.html">高级搜索</a> <a href="/">搜索首页</a></label>
           <input type="hidden" id="content" name="content" value="<%=query%>" />
        <input type="hidden" name="act" value="search"  />
        </form>
        </span> <span id="forumPanelConent" style="display:block">
        <form id="frmSearchForum" name="frmSearchForum" method="get" action="forum.jsp" style="margin:0px;">
<input type="text" id="query" name="query" value="<%=query%>" onchange="changeQueryValue(this.value)"  style="width:255px;" />
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
          <script type="text/javascript">
          $search("category").value="<%=category%>";
          </script>
         <label><img onclick="searchSubmit()" style="cursor:pointer;" src="images/bt_search_result.gif" alt="搜索" align="absmiddle" /> <a href="/">搜索首页</a></label>
          <input type="hidden" id="page" name="page" value="" />
		<input type="hidden" id="cacheHiddenTime" name="_"/>
        </form>
        </span> </td>
    </tr>
  </table>
</div>
<script>initFormFields();</script>
<!--search end-->
<!--查询结果提示信息-->
<%
if(serverStatus.equals("ok")){
%>

<div id="position"><%=queryRepport%></div>
<!--bigdiv begin-->
<div id="bigDiv">
  <!--左侧开始-->
  <div class="left">
  <!--显示结果页-->
    <div id="list" style="border:0px; padding:4px;">
    <%
        //显示结果页
        if(documents != null && documents.size() > 0){
            try{
                displayForumTable(documents, query, out);
            }catch(Exception e){
                e.printStackTrace();
            }
        }else{
            //查询不到结果时显示提示信息
            out.write("<div class=\"hintBox\">"
                +"<div><img src=\"images/none_message.gif\" /></div>"
                +"<div><ul>"
                +"<li>很抱歉，没有找到符合检索条件的相关网页。</li>"
                +"<li>确信所有的字串正确无误。</li>"
                +"<li>尽可能让字串简洁和使用常规字串。</li>"
                +"<li>试用不同的关键字。 </li>"
                +"</ul></div>"
                +"</div>");
        }
    %>
    </div>
      <!--分页开始-->
      <div class="page">
        <div style=" padding-left:30px;">
        <%=displayNavigation(StringUtils.intVal(pageTotal), StringUtils.intVal(currentPage),request.getQueryString(), "forum.jsp")%>
        </div>
        <div class="clear"></div>
      </div>
      <!--分页结束-->
  </div>
  <!--左侧结束-->
  <!--右侧开始-->
  <div class="right"></div>
  <!--右侧结束-->
</div>
<div class="clear"></div>
<%
}else{
	StringBuffer sb = new StringBuffer();
	sb.append("<div style=\"width:950px; margin:6px auto 6px auto;\" >");
	sb.append(" <iframe id=\"iframeDom\" name=\"iframeDom\" ");
	sb.append(" width=\"950px\" height=\"500px\"");
	sb.append(" frameborder=\"0\" ");
	sb.append(" src=\"http://www.baidu.com/s?si=shequ.kongfz.com&cl=3&ct=2097152&word="+query+"&tn=baidulocal\" ");
	sb.append(" ></iframe></div> ");
	out.write(sb.toString());
}
%>
<!-- End  -->
<!--footer开始-->
<div id="contact"> <a href="http://www.kongfz.com/help/aboutus.php" target="_blank">关于孔夫子</a> - <a href="http://help.kongfz.com/" target="_blank">网站帮助</a> -<a href="http://www.kongfz.com/help/guanggao.php" target="_blank"> 广告业务</a> - <a href="http://www.kongfz.com/help/zhaopin.php" target="_blank"> 诚聘英才</a> - <a href="http://www.kongfz.com/help/lianxi.html" target="_blank"> 联系我们</a> - <a href="http://www.kongfz.com/help/copyright.php" target="_blank"> 版权隐私</a> - <a href="http://www.kongfz.com/community/links.php" target="_blank">友情链接</a> - <a href="http://shop.kongfz.com/advice.php?act=add" target="_blank"> 意见建议</a> </div>
<div id="footer"> 版权所有©2002-2013 孔夫子图书网（<a href="http://www.kongfz.com/">www.kongfz.com</a>）<br />
  Copyright © All rights reserved 京ICP 041501&nbsp;&nbsp;客服电话：010-64755951 </div>
<!--footer结束-->

</body>
</html>
