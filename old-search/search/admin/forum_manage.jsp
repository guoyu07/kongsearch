<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.util.datetime.TimeUtils" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ include file="cls_memcached_session.jsp"%>
<%!

    /**
     * 过滤查询的关键词
     * @param keywords
     * @return
     */
    private String filterKeywords(String keywords){
        int maxlength = 350;
        keywords = keywords.trim();
        if(keywords.equals("支持书名、作者、出版社、店名、省市等多个关键字的复合查询")){
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
        
        return keywords;
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage){
        String htmlContent = "<label class=\"page_navigation\">";
        if(pageCount > 0) {
            htmlContent += "<a href=\"javascript:go(1)\">首页</a>";
            //如果当前页为第一页，则不显示“上一页链接”
            if(currentPage > 1){
                htmlContent += "<a href=\"javascript:go("+(currentPage-1)+")\">上一页</a>";
            }
            //每次从当前页向后显示十页，如果不够十页，则全部显示。
            int max = (currentPage < 100 ? 11 : 6);//显示的页码数量
            int maxhalf = max / 2;
            int start = (currentPage <= maxhalf) ? 1 : (currentPage - maxhalf);
            int end = ((currentPage + maxhalf) <= pageCount) ? (currentPage + maxhalf) : pageCount;

            for(int i = start; i <= end; i++){
                if(currentPage == i){
                    htmlContent += "<b>" + i + "</b>";
                }else{
                    htmlContent += "<a href=\"javascript:go("+i+")\">" + i + "</a>";
                }
            }		
            //如果当前页为最后一页，则不显示“下一页”链接
            if(currentPage < pageCount){
                htmlContent += "<a href=\"javascript:go("+(currentPage+1)+")\">下一页</a>";
            }		
            htmlContent += "<a href=\"javascript:go("+pageCount+")\">末页</a>";
        }
        htmlContent += "</label>";
        return htmlContent;
    }

    /**
     * 显示论坛帖子查询结果
     */
    private void displayForumTable(ArrayList articleList, String keyword, JspWriter out) throws Exception
    {
        String forumSite = "";
        String primaryKey, tid, pid, fid, authorid, author, subject, content, postSubject, link;
        long postdate = 0;
        out.write("<form id=\"delForm\" name=\"delForm\">");
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
            	forumSite = "http://shequ.kongfz.com/article_";
            }else{
            	forumSite = "http://shequ.gujiushu.com/";
            }
            link        = forumSite + tid + ".html";
			if(primaryKey.contains("_-1")){
				out.write("<div class=\"subject\">&nbsp;&nbsp;<a href=\"" + link + "\" target=\"_blank\">"+subject+"</a></div>");
            }else{
            	out.write("<div class=\"subject\"><input type=\"checkbox\" name=\"tmsgInfoList\" value=\""+primaryKey+"\" onChange=\"changeBtnStats()\"/><a href=\"" + link + "\" target=\"_blank\">"+subject+"</a></div>");
            }
            out.write("<div>"+postSubject+"</div>");
            out.write("<div class=\"content\">" + (!"0".equals(pid)?"[回复] " : "") + content + "</div>");
            out.write("<div class=\"contentLink\">");
            out.write(forumSite + tid + ".html ");
            out.write(TimeUtils.getDateTime(postdate, "yyyy-MM-dd"));
            out.write(" " + getForumName(fid));
            out.write(" - <a href=\""+link+"\" target=\"_blank\">详细内容</a></div>");
        }
        out.write("<input type=\"checkbox\" id=\"selall\" title=\"全选\"  onClick=\"select_all()\"></input><input type=\"button\" id='delBtn' value=\"删除选中\" onclick=\"del()\" disabled></input>");
        out.write("<input type=\"hidden\" name=\"type\" id=\"type\" value=\"\" />");
        out.write("</form>");
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
     * 设置页面中使用UTF-8编码
     ****************************************************************************/
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    /****************************************************************************
     * 验证用户登录状态和管理权限
     ****************************************************************************/
    MemcachedSession MemSession = new MemcachedSession(session, request, response, out, false);

    // user login
    String logon_result = "";
    String username = MemSession.get("adminName");//用于网站管理员登录

    if(!MemSession.isLogin("admin")){
        response.sendRedirect("index.jsp");
        return;
    }

    //判断管理员权限
    //String[] permission = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "forumManage";
    if(!MemSession.hasPermission(permission)){
        out.write("您无权限使用此页面。");
        return;
    }

    /****************************************************************************
    * 接收页面求参数
    ****************************************************************************/

    //动作类型
    String act = StringUtils.strVal(request.getParameter("act"));
    if("".equals(act)) act="search";

    String type = StringUtils.strVal(request.getParameter("type"));
    if("".equals(type)) type="search";

    String[] tmsgInfoList = request.getParameterValues("tmsgInfoList");

    //任务类型
    String task = StringUtils.strVal(request.getParameter("task"));

    //查询参数
    String query = StringUtils.strVal(request.getParameter("query"));
    query = filterKeywords(query);

    String author = StringUtils.strVal(request.getParameter("author"));
    String sendTimeStart = StringUtils.strVal(request.getParameter("sendTimeStart"));
    String sendTimeEnd = StringUtils.strVal(request.getParameter("sendTimeEnd"));
    String category = StringUtils.strVal(request.getParameter("category"));

    String postType = request.getParameter("postType");

    String pageNo = StringUtils.strVal(request.getParameter("page"));
    if("".equals(pageNo)){ pageNo = "0"; }

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
        
        //parameters.put("sortDefault", );

        //调用远程查询接口
        if("delete".equals(type)){
                parameters.put("deleteType", "lucene");
                parameters.put("tmsgInfoList", tmsgInfoList);
            try{
                resultSet = server.work("Delete",parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器异常：调用远程服务器删除失败。";
            }
            
            String result = "";
            if(null != resultSet){
                //处理查询结果
                result = StringUtils.strVal(resultSet.get("status"));
                serverStatus = "ok";
            }else{
                serverStatus = "服务器异常：未知错误。";
            }
            
            if("0".equals(result)){
                type = "search";
            }
            else if("1".equals(result)){
                serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
            }
            else if("2".equals(result)){
                serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
            }
            else if("3".equals(result)){
                serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
            }
            else{
                serverStatus = "服务器异常：未知错误。";
            }
        }
        if("search".equals(type)){
            try{
                parameters = new HashMap();
                parameters.put("keywords", query);
                parameters.put("category", category);
                parameters.put("postType", postType);// 查询主贴和回帖

                parameters.put("author", author);
                parameters.put("sendTimeStart", sendTimeStart);
                parameters.put("sendTimeEnd", sendTimeEnd);
                //查询类配置参数
                parameters.put("currentPage", pageNo);
                parameters.put("paginationSize", "100");
                resultSet = server.work("SearchForum", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器异常：调用远程服务器查询失败。";
            }
       

            if(resultSet != null){
                //处理查询结果
                status = (String) resultSet.get("status");
                documents = (ArrayList) resultSet.get("documents");
            }else{
                serverStatus = "服务器异常：未知错误。";
            }

            if(status.equals("0")){
                //将查询到的拍品列表输出
                currentPage = StringUtils.strVal(resultSet.get("currentPage"));
                hitsTotal   = StringUtils.strVal(resultSet.get("hitsCount"));
                pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
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
        }
        //
    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }
    // System.out.println(serverStatus);

    /*******************************************************************************
     * 组织页面显示内容
     *******************************************************************************/
    //查询结果提示信息
    StringBuffer buffer = new StringBuffer();
    if(serverStatus.equals("ok")){
        buffer.append("<span style=\"padding-left:20px;\">");
        if(!query.equals("")){
            buffer.append("您查询的是“<font color=red>"+query+"</font>”，");
        }
        buffer.append("查找到相关结果：<strong>"+hitsTotal+"</strong> 项，");
        buffer.append("共 <strong>"+pageTotal+"</strong> 页，");
        buffer.append("用时 "+searchTime+" 秒 ");
        buffer.append("</span>");
    }
    else
    {
        buffer.append("<span style=\"padding-left:20px;color:red\">系统维护中，暂时不能搜索，敬请谅解！</span>");
    }
    String queryRepport = buffer.toString();
    buffer = null;

    //总页数和当前页
    int page_count;
    try{
        page_count = Integer.parseInt(pageTotal);
    }catch(Exception ex){
        page_count = 0;
    }

    int current_page = 0;
    try{
        current_page = Integer.parseInt(currentPage);
    }catch(Exception ex){
        current_page = 0;
    }

%>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>管理论坛索引</title>
<style>
    body{ margin:0; padding:0; text-align:center}
    #bigDiv{ width:95%; margin:0 auto;}
    #bigDiv .left{ float:left; width:722px;}
    #bigDiv .right{ float:right; width:220px;}
    #bigDiv #rightBox1,#bigDiv #rightBox2,#bigDiv #rightBox3,#bigDiv #rightBox4{ border:1px solid #9fb9ca; line-height:24px; text-align:left; padding-bottom:12px;}
    #bigDiv #rightBox2,#bigDiv #rightBox3,#bigDiv #rightBox4{ padding-left:12px; padding-right:12px; margin-top:8px;}
    #bigDiv #rightBox1 h2{ background-color:#e9f4fa; height:30px; line-height:30px; padding-left:12px; text-align:left; margin-bottom:5px;}
    #bigDiv #rightBox2 h2,#bigDiv #rightBox3 h2,#bigDiv #rightBox4 h2{ border-bottom:1px solid #d3d3d3; background:url(images/icon01_result_pic.gif) no-repeat 0 9px; height:30px; line-height:30px; text-align:left; padding-left:10px; margin-bottom:5px;}

    form{margin:0px;}
    a{ text-decoration:none;}
    a:hover{ text-decoration:underline; color:red;}
    #Sort{
    width:99%; font-size:14px; line-height:30px; background-color:#e1eaf6; border:1px solid #adc1dc; margin:0 auto;  height:28px; text-align:left; padding-top:2px;
    }
    .searchSub{ background:url(./images/bg_searchsub.gif); border:1px solid #d17528; width:80px; padding-top:2px; font-weight:bold; color:#fff;}
    #Page td{ font-size:13px; line-height:200%;}
    #List td{ font-size:13px; line-height:220%!important; line-height:150%;}
    #List td a{ color:#0000ba; text-decoration:none;}
    #List td a:hover{ color:red; text-decoration:underline;}

    #list .subject {}
    #list .subject a {font-size:16px;color:#1111CC;}
    #list .subject font {font-size:16px;}

    #list .content {font-size:13px;line-height:18px}
    #list .content font {font-size:13px;line-height:18px}
    
    #list .contentLink {padding-bottom:10px;font-size:14px;color:#0D776F}
    #list .contentLink a {color:#666666}

    
    #search{ width:99%; height:62px; border-bottom:1px solid #adc1dc; margin:0 auto 8px auto; background:url(./images/bg_search.gif); font-size:12px;}

    .search_result{
    width:99%;
    text-align:left;
    font-size:13px;
    }
	.clear{ clear:both; line-height:0; font-size:0;}
    .copyright{
    font-size:12px;
    width:99%;
    border:1px solid #EFF2FA;
    padding-top:20px;
    padding-bottom:20px;
    text-align:center;
    background-color:#EFF2FA;
    }
    .result_message{
    font-size:12px;
    border:0px solid #003300;
    height:200px;
    width:970px;
    text-align:center;
    }
    .result_message img{
    margin:20px 20px 20px 200px;
    }
    .result_message label{
    color:#FF6F02;
    }
    .float_left{
    float:left;
    }

    .page_navigation{

    }
    .page_navigation a{
    margin:2px;
    padding:2px;
    text-decoration:none;
    color:#100EB0;
    font-size:14px;
    }
    .page_navigation a:hover{
    text-decoration:underline;
    color:#FF0000;
    font-size:14px;
    }
    .page_navigation label{
    margin:2px;
    padding:2px;
    }
    .page_navigation b{
    color:#FF0000;
    margin:2px;
    padding:2px;
    font-size:14px;
    }

    .page_navigation input{
    border:1px solid #ADC1DC;
    }

    .goto_button{
    height:20px;
    width:36px;
    border:1px solid #ADC1DC;
    color:#006E0B;
    padding:2px;
    background-color:#FFFFFF;
    background-image:url(images/bg_sort.gif);
    cursor:pointer;
    }
    
    .hintBox{float:left; padding:10px; margin-left:60px; font-size:12px;}
    .hintBox div{float:left;}
    .hintBox ul{margin-left:30px;}
    .hintBox li{list-style-type:disc;}

    .belivePress{
    display:none;
    position:absolute;
    padding:2px;
    width:120px; 
    height:auto; 
    background-color:#C7D5E9;
    border:1px solid #ADC1DC;
    }
    .belivePress a{
    float:left;
    padding:2px;
    width:100%;
    color:#000000;
    text-align:left;
    font-size:14px;
    }
    .belivePress a:hover{
    background-color:#FDDA96;
    color:#FF0000;
    }
    .distrustKeywords{
    display:none;
    position:absolute;
    padding:2px;
    width:120px; 
    height:auto; 
    background-color:#C7D5E9;
    border:1px solid #ADC1DC;
    }
    .distrustKeywords a{
    float:left;
    padding:2px;
    width:100%;
    color:#000000;
    text-align:left;
    font-size:14px;
    }
    .distrustKeywords a:hover{
    background-color:#FDDA96;
    color:#FF0000;
    }
    /* 主菜单面板 */
    .mainMenuPanel{
    margin:auto;
    padding:4px 4px 0px 4px;
    height:18px; 
    width:auto; 
    text-align:left;
    font-size:12px; 
    border-bottom:1px solid #E6E6E6; 
    background-color:#ECECEC;
    }
    .menuItemSel{
    color:#FF0000;
    font-weight:bold;
    }
</style>
<SCRIPT LANGUAGE="JavaScript">
    function $search(id){return document.getElementById(id);}
    function findPos(obj) {
        var curleft = curtop = 0;
        if (obj.offsetParent) {
            curleft = obj.offsetLeft;
            curtop = obj.offsetTop;
            while (obj = obj.offsetParent) {
                curleft += obj.offsetLeft;
                curtop += obj.offsetTop;
            }
        }
        return [curleft,curtop];
    }
    
    function del(){
        var c = confirm("是否删除");
        if(c==true){
            document.getElementById("type").value="delete";
            document.getElementById("frmSearch").submit();
        }
    }
    
    function changeBtnStats(){
    	var m = document.getElementsByName('tmsgInfoList');
    	var l = m.length;
        for ( var i=0; i< l; i++){
            if(m[i].checked){
            	document.getElementById('delBtn').disabled='';
            	return;
            }
            document.getElementById('delBtn').disabled='true';
        }
    }

    // -------- 全選或取消 checkbox 方塊   
    function select_all() {   
        var m = document.getElementsByName('tmsgInfoList');
            var l = m.length;
            if(document.getElementById("selall").checked){
                for ( var i=0; i< l; i++){
                    m[i].checked = true;
                }
            }else{
                for ( var i=0; i< l; i++){
                    m[i].checked = false;
                }
            }
            changeBtnStats();
        }   

     /**
     * 添加事件监听
     */
    function addEventListener(obj, eventName, callback)
    {
        if(document.all){
            obj.attachEvent("on" + eventName,callback);
        }else{
            obj.addEventListener(eventName,callback,true); 
        }
    }
    
    /**
     * 取消事件监听
     */
    function removeEventListener(obj, eventName, callback)
    {
        if(document.all){
            obj.detachEvent("on" + eventName, callback);
        }else{
            obj.removeEventListener(eventName, callback, true); 
        }
    }

    function go(page){
    $search("page").value = page;
    $search("frmSearch").submit();
    }

    function setSort(type){
    $search("sorttype").value = type;
    go(1);
    }

    function gotopage(){
    var pages = document.getElementsByName("gopage");
    var page = pages[0].value!=""? pages[0].value : pages[1].value;
    page = page.replace(/ /g,"");
    go(page);
    }

    function initSearchForm(){
    $search('sorttype').value=0;
    }

    var m_isCheckAll = false;
    
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('itemInfo[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }


    function deleteBid(itemInfo){
        var elements = document.getElementsByName('itemInfo[]');

        if(itemInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == itemInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再执行删除操作！");return;
        }
        if((itemInfo == null) && (!confirm("是否删除所选项目？"))){return;}
        
        $search('act').value = 'delete';
        $search('task').value = 'delete';
        $search('frmSearch').submit();
    }

     /**
     * 显示可疑关键字列表
     */
    function showDistrustKeywords(isVisible){
        function hideDistrustKeywordsPanel(){showDistrustKeywords(false);}
        var panel = $search('distrustKeywordsPanel');
        if(!isVisible){
            panel.style.display="none";
            removeEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            addEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
        }
    }
    
    /**
     * 显示可信任出版社列表
     */
    function showBelivePress(isVisible){
        function hideBelivePressPanel(){showBelivePress(false);}
        var panel = $search('belivePressPanel');
        if(!isVisible){
            panel.style.display="none";
            removeEventListener(document.documentElement, 'click', hideBelivePressPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=(pos[0]-20)+'px';
            panel.style.top=(pos[1]+15)+'px';
            addEventListener(document.documentElement, 'click', hideBelivePressPanel);
        }
    }
    
    /**
    * 装入辅助数据
    */
    function loadAssistantData(){
        //装入可疑关键字列表
        if(m_distrustKeywords){
            var keywordsHtml = [];
            for(var i=0; i < m_distrustKeywords.length; i++){
                keywordsHtml.push('<div><a href="javascript:quickQuery(\''+m_distrustKeywords[i].keywords+'\')" title="'+m_distrustKeywords[i].keywords+'">'+m_distrustKeywords[i].name+'</a></div>');
            }
            $search('distrustKeywordsPanel').innerHTML = keywordsHtml.join('');
        }
        //装入可信任出版社列表
        if(m_belivePress){
            var pressHtml = [];
            for(var i=0; i < m_belivePress.length; i++){
                pressHtml.push('<div><a href="javascript:quickQuery(\''+m_belivePress[i].name+'\')" title="'+m_belivePress[i].name+'">'+m_belivePress[i].name+'</a></div>');
            }
            $search('belivePressPanel').innerHTML=pressHtml.join('');
        }
    
    }

    function quickQuery(keywords){
        $search('query').value = keywords;
        $search('frmSearch').submit();
    }

    function clearSearchForm()
    {
         $search('query').value = "";
         $search('category').value = "";
         $search('frmSearch').postType[0].checked=true;
    }

</SCRIPT>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>
</HEAD>

<BODY>
<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="auction_manage.jsp">管理拍品索引</a>
<a href="forum_manage.jsp" class="menuItemSel">管理论坛索引</a>
</div>

</div>
<form name="frmSearch" id="frmSearch" method="post" action="" >
  <div id="search">
    <table width="96%" border="0" cellspacing="0" cellpadding="0">
<tr>
    <td width="200" rowspan="3" align="left"><img src="./../images/logo_com.gif" alt="logo" width="160" height="60" /></td>
    <td width="800" height="26" align="left" valign="bottom">
    <input maxLength=2048 size=35 value="<%=query%>" name="query" id="query"/>
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
    <SCRIPT language=JavaScript>
    $search('category').value="<%=category%>";
    </SCRIPT>
    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="query.value=''" />
    <input type="submit" value="搜 索" class="searchSub" onClick="initSearchForm()" />
    <INPUT type="hidden" name="page" id="page" value="<%=current_page %>" />
    <input type="hidden" id="act" name="act" />
    <input type="hidden" id="task" name="task" value="none" />
    </td>
</tr>

<tr>
    <td align="left" valign="top">
    <label><INPUT type=radio CHECKED value="2" name=postType>全部</label>
    <label><INPUT type=radio value="0" name=postType>主帖</label>
    <label><INPUT type=radio value="1" name=postType>回帖</label>
    <SCRIPT language=JavaScript>
    for (var i=0;i<frmSearch.postType.length;i++){
        if (frmSearch.postType[i].value=="<%=postType%>") {
            frmSearch.postType[i].checked=true;
        }
    }
    </SCRIPT>
     	<label style="color:gray">发帖作者：</label>
    	<input type="text" id="author" name="author" value="<%=author%>" />
    	<label style="color:gray">发帖时间：</label>
		<input type="text" id="sendTimeStart" name="sendTimeStart" value="<%=sendTimeStart%>" />~
		<input type="text" id="sendTimeEnd" name="sendTimeEnd" value="<%=sendTimeEnd%>" />
	</td>
    <td width="244" height="26" align="right" valign="bottom">
    <span><a href="javascript:showDistrustKeywords(true)">选择可疑关键字</a>
    <div id="distrustKeywordsPanel" class="distrustKeywords" style="display:none" ></div>
    </span>&nbsp;
    <span><a href="javascript:showBelivePress(true)">选择可信任出版社</a>
    <div id="belivePressPanel" class="belivePress" style="display:none" ></div>
    </span>
    <script type="text/javascript">loadAssistantData();</script>
    </td>
</tr>
    </table>
  </div>
  <div id="Sort" style="height:auto;"><%=queryRepport%></div>



<%
if(serverStatus.equals("ok")){
%>

<!--bigdiv begin-->
<div id="bigDiv">
  <!--左侧开始-->
  <div class="left">
  <!--显示结果页-->
    <div id="list" style="border:0px; padding:4px; text-align:left">
    <%
        //显示结果页
        if(documents != null && documents.size() > 0){
            try{
                displayForumTable(documents, query, out);
            }catch(Exception e){
                e.printStackTrace();
            }
        }else if("delete".equals(act)){
            out.write("删除");
            act = null;
        }else{
            //查询不到结果时显示提示信息
            out.write("<div class=\"hintBox\">"
                +"<div><img src=\"images/none.gif\" /></div>"
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
        <%=displayNavigation(page_count, current_page)%>
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
}
%>
</form>

<div class="copyright">
  <label>版权所有(C)2002-2011 孔夫子旧书网</label>
</div>
</BODY>
</HTML>
