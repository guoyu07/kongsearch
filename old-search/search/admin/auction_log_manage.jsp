<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%!
    /**
     * 取得审核操作的文字描述
     */
    private String getVerifyAct(String verifyAct)
    {
        String result = "";
        if("Approve".equalsIgnoreCase(verifyAct)){
            result = "通过";
        }
        if("Reject".equalsIgnoreCase(verifyAct)){
            result = "驳回";
        }
        if("Delete".equalsIgnoreCase(verifyAct)){
            result = "删除";
        }
        return result;
    }

    /**
     * 取得审核方式的文字描述
     */
    private String getVerifyMode(String verifyMode)
    {
        String result = "";
        if("Manual".equalsIgnoreCase(verifyMode)){
            result = "人工";
        }
        if("Automatic".equalsIgnoreCase(verifyMode)){
            result = "自动";
        }
        return result;
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage)
    {
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
     * 显示审核日志查询结果
     */
    private void displayVerifyLogQueryResult(ArrayList logList, JspWriter out) throws Exception
    {
        StringBuffer buffer = new StringBuffer();
        buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"itemList\">");
        buffer.append("<tr height=\"30\" align=\"center\">");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\"><img src=\"./images/smile.gif\" id=\"smile\" title=\"Ahoy!\" style=\"cursor:pointer\" /></td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"15%\">卖家昵称</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"\">拍品名称</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">审核操作</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">审核方式</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"12%\">操作时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">审核人</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">操作</td>");
        buffer.append("</tr></table>");
        out.print(buffer.toString());
        
        for(int i = 0, length = logList.size(); i < length; i++){
            buffer.setLength(0);
            Map map = (Map) logList.get(i);
            String adminRealName  = StringUtils.strVal(map.get("adminRealName"));
            String userId         = StringUtils.strVal(map.get("userId"));
            String itemId         = StringUtils.strVal(map.get("itemId"));
            String itemName       = StringUtils.strVal(map.get("itemName"));
            String nickname       = StringUtils.strVal(map.get("nickname"));
            String verifyTime     = StringUtils.strVal(map.get("verifyTime"));
            String verifyMode     = StringUtils.strVal(map.get("verifyMode"));
            String verifyAct      = StringUtils.strVal(map.get("verifyAct"));

            
            String itemUrl = "http://www.kongfz.cn/detail.php?tb=his&itemId=" + itemId;
            String userUrl = "http://user.kongfz.com/member/view_member_info.php?memberId=" + userId;

            buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"itemList\">");
            buffer.append("<tr bgcolor=\"" + ((i % 2 == 0) ? "#EFEFEF" : "#ffffff") + "\">");
            buffer.append("<td width=\"3%\">&nbsp;</td>");
            buffer.append("<td width=\"15%\"><a href=\"javascript:quickQueryShop('"+nickname+"');\">" + nickname +"</a><a href=\""+userUrl+"\" target=\"_blank\"><img src=\"images/bookstore.gif\" border=0 /></a></td>");
            buffer.append("<td width=\"\"><a href=\""+itemUrl+"\" target=\"_blank\" title=\"\">" + itemName + "</a>&nbsp;</td>");
            buffer.append("<td width=\"6%\">" + getVerifyAct(verifyAct) +"&nbsp;</td>");
            buffer.append("<td width=\"6%\">" + getVerifyMode(verifyMode) +"&nbsp;</td>");
            buffer.append("<td width=\"12%\">" + verifyTime +"&nbsp;</td>");
            buffer.append("<td width=\"6%\"><a href=\"javascript:quickQuery('"+adminRealName+"');\">" + adminRealName +"</a>&nbsp;</td>");
            buffer.append("<td width=\"6%\"> --- </td>");
            buffer.append("</tr></table>\n");
            out.write(buffer.toString());
        }
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
    // 从Session中取得管理员的姓名，并记录之。
    String adminRealName = MemSession.get("adminRealName");

    // user login
    String logon_result = "";
    String username = MemSession.get("adminName");//用于网站管理员登录

    if(!MemSession.isLogin("admin")){
        //response.sendRedirect("index.jsp");
        //return;
    }

    //判断管理员权限
    //String[] permission = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "auctionLogManage";
    if(!MemSession.hasPermission(permission)){
        //out.write("您无权限使用此页面。");
        //return;
    }

    /****************************************************************************
    * 接收页面求参数
    ****************************************************************************/

    //动作类型
    String act = StringUtils.strVal(request.getParameter("act"));
    if("".equals(act)){ act="search"; }

    //任务类型

    String keywords = StringUtils.strVal(request.getParameter("query"));
    int searchType = StringUtils.intVal(request.getParameter("searchType"));
    String userId  = StringUtils.strVal(request.getParameter("userId")).trim();
    String itemId  = StringUtils.strVal(request.getParameter("itemId")).trim();

    int current_page = StringUtils.intVal(request.getParameter("page"));

    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface manager = null;
    Map resultSet = null;
    String serverStatus = "";
    ArrayList documents = new ArrayList();
    String currentPage = "0";
    int bookTotal = 0;
    String pageTotal = "0";
    String searchTime = "0";
    List<Map<String, Object>> bookInfoList = null;

    try{
        //取得远程服务器接口实例, 根据未售或已售调用不同的远程对象
        manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.105:9111/AuctionLogService");
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(null != manager){
        // 查询索引服务
        if("Search".equalsIgnoreCase(act)){
            HashMap parameters = new HashMap();
            
            switch(searchType){
                case 0: parameters.put("itemName", keywords);            break;
                case 1: parameters.put("nickname", keywords);      break;
                case 2: parameters.put("adminRealName", keywords);       break;
            }

            parameters.put("itemId", itemId);
            parameters.put("userId", userId);
            //查询类配置参数
            parameters.put("currentPage", String.valueOf(current_page));
            parameters.put("paginationSize", "200");
            //parameters.put("sortDefault", );

            //调用远程查询接口
            try{
                resultSet = manager.work("Search", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器查询失败。";
            }

            String status = "";
            if(null != resultSet){
                //处理查询结果
                status = StringUtils.strVal(resultSet.get("status"));
                documents = (ArrayList) resultSet.get("documents");
            }else{
                serverStatus = "服务器信息：未知错误。";
            }

            if("0".equals(status)){
                //将查询到的图书列表输出
                currentPage = StringUtils.strVal(resultSet.get("currentPage"));
                bookTotal   = StringUtils.intVal(resultSet.get("hitsCount"));
                pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
                searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
                serverStatus = "ok";
            }else if("1".equals(status)){
                serverStatus = "服务器信息：索引为空，或未建立，或正在建立索引。";
            }else if("2".equals(status)){
                serverStatus = "服务器信息：查询受阻，正在将磁盘索引载入内存。";
            }else if("3".equals(status)){
                serverStatus = "服务器信息：查询过程中出现错误。";
            }else{
                serverStatus = "服务器信息：未知错误。";
            }
        }
    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }
    //System.out.println(serverStatus);

%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>拍品审核日志查询</title>
<style>
    body{ 
    margin:0; 
    padding:0; 
    text-align:center
    }

    a{ text-decoration:none;}
    a:hover{ 
    text-decoration:underline; 
    color:red;
    }

    .sort{ 
    width:99%; 
    height:28px; 
    margin:0px 0px 5px 0px; 
    padding-top:4px;
    border:1px solid #CCCCCC; 
    background-color:#F1F1F1; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    }
    .sort label{
    font-size:12px; 
    color:gray;
    }

    .searchSub{ 
    background:url(./images/bg_searchsub.gif); 
    border:1px solid #d17528; 
    width:80px;
    padding-top:2px; 
    font-weight:bold; 
    color:#fff;
    }

    .Page td{ font-size:12px; line-height:200%;}
    .itemList td{ font-size:12px; line-height:220%!important; line-height:150%;}
    .itemList td a{ color:#0000ba; text-decoration:none;}
    .itemList td a:hover{ color:red; text-decoration:underline;}

    .search{
    width:99%; 
    height:91px; 
    border-left:1px solid #CCCCCC; 
    border-right:1px solid #CCCCCC; 
    border-bottom:1px solid #CCCCCC; 
    margin:0 auto 2px auto; 
    background:url(./images/bg_search_3.gif); 
    font-size:12px;
    }

    form{
    margin:0px;
    }
    .copyright{
    width:auto;
    padding-top:20px;
    padding-bottom:20px;
    border:1px solid #EFF2FA;
    background-color:#F1F1F1;
    font-size:12px;
    text-align:center;
    }
    .result_message{
    font-size:12px;
    border:0px solid #003300;
    height:200px;
    width:99%;
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

    /* 业务模块面板 */
    .modulePanel{
    margin:2px 0px 0px 0px; 
    padding-top:2px;
    width:99%; height:34px; 
    border-bottom:1px solid #adc1dc; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#FEF0D0; 
    }
    .modulePanelItem{
    float:left;
    border:1px dashed #F6881B;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#000000;
    text-decoration:none;
    }
    .modulePanelItem:hover {
    color:white;
    text-decoration:none;
    background-color:#F6881B;
    }
    .modulePanelItemSel{
    float:left;
    border:1px dashed #F6881B;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#FFFFFF;
    font-weight:bold;
    text-decoration:none;
    background-color:#F6881B;
    }
    .modulePanelItemSel:hover {
    color:#FFFFFF;
    text-decoration:none;
    background-color:#F6881B;
    }
</style>
</head>
<script type="text/javascript">
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

    function setSort(type){
        $search("sorttype").value = type;
        go(1);
    }

    function go(page){
        $search("page").value = page;
        $search("frmSearch").submit();
    }

    function gotopage(){
        var pages = document.getElementsByName("gopage");
        var page = pages[0].value!=""? pages[0].value : pages[1].value;
        page = page.replace(/ /g,"");
        go(page);
    }

    function initSearchForm(){

    }

    var m_isCheckAll = false;
   
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('bookInfo[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }
   
    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("itemId").value="";
        $search("userId").value="";
    }


    /**
     * 筛选查询
     */
    function filterQuery(value)
    {
        $search("frmSearch").submit();
    }

    /**
     * 查询审核人
     */
    function quickQuery(query)
    {
        $search("searchType").value="2";
        $search("keywords").value=query;
        $search("frmSearch").submit();
    }

    /**
     * 查询书店名称
     */
    function quickQueryShop(query)
    {
        $search("searchType").value="1";
        $search("keywords").value=query;
        $search("frmSearch").submit();
    }

    /**
     * 使选区高亮
     */
    function enableSelectionHighlight()
    {
        var tables = document.getElementsByTagName("table");
        for(var index in tables){
            setHighlight(tables[index]);
        }

        function setHighlight(obj)
        {
            if(obj.className != "itemList"){
                return;
            }
            obj.onmouseover = function(){
                obj.style.backgroundColor="#A7A6AA";
            };
            obj.onmouseout = function(){
                obj.style.backgroundColor="#FFFFFF";
            };
        }
    }
</script>
</head>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="auction_log_manage.jsp" class="menuItemSel">拍品审核日志查询</a>
</div>

<form name="frmSearch" id="frmSearch" method="post" action="" >
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0" style="margin-top:4px">
  <tr>
    <td width="15%" align="left">&nbsp;</td>
    <td width="10%" align="left" valign="bottom">
    <select name="searchType" id="searchType">
    <option value="0">拍品名称</option>
    <option value="1">卖家昵称</option>
    <option value="2">审核人姓名</option>
    </select>
    <script>$search("searchType").value="<%=searchType%>";</script>    </td>
    <td height="26" colspan="2" align="left" valign="bottom">
    <input type="text" id="keywords" name="query" size="40" maxlength="350" value="<%=keywords%>" title="<%=keywords%>" />
    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="clearQueryCondition();" />
    <input type="submit" value="查 询" class="searchSub" onClick="initSearchForm()"/>
    <input type="hidden" name="page" id="page" value="" />
    <input type="hidden" id="act" name="act" value="<%=act%>" />    </td>
  </tr>
  <tr>
    <td align="left">&nbsp;</td>
    <td height="26" colspan="3" align="left" valign="middle" style="padding-left:38px;color:gray;">
    <div id="sub_panel" style="float:left;margin-right:10px;">
    卖家编号：<input name="userId" type="text" id="userId" value="<%=userId%>" size="12" /> 
    拍品编号：<input name="itemId" type="text" id="itemId" value="<%=itemId%>" size="12" />
    </div>    </td>
    </tr>
  <tr>
    <td align="left">&nbsp;</td>
    <td height="26" colspan="3" align="left" valign="middle" style="padding-left:38px;color:gray;">
     <div id="sub_panel" style="float:left;margin-right:10px;">

    </div>
    </td>
  </tr>
</table>
</div>

<div class="sort">&nbsp;</div>

<%
//查询结果为空的情况
if("ok".equals(serverStatus) && 0 == bookTotal){
%>
    <div class="result_message">
    <img class="float_left" src="./images/none.gif" />
    <div class="float_left">
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>很抱歉！没有找到符合 <label><%=keywords%></label> 的结果。</div>
    </div>
    </div>
<%
}
else if("ok".equals(serverStatus) && bookTotal > 0){

%>

<!--页码导航开始-->
<table align="center" border=0  width="98%" class="Page">
<tr><td height="28" align="left">
<% 
    StringBuffer strPageNavigation = new StringBuffer();
    strPageNavigation.append("<font color='#666666'><b>查询结果总数：</b></font>" + bookTotal + "&nbsp;");
    strPageNavigation.append("共<font color='#0000ff'>" + pageTotal + "</font>页&nbsp;&nbsp;");
    strPageNavigation.append("现为<font color=red>" + currentPage + "</font>页&nbsp;");
    strPageNavigation.append(displayNavigation(StringUtils.intVal(pageTotal), StringUtils.intVal(currentPage)));
    strPageNavigation.append("<label>第<input type=\"text\" size=\"3\" maxlength=\"4\" value=\"\" name=\"gopage\"  onkeydown=\"if(event.keyCode==13){gotopage();}\" />页&nbsp;<input type=\"button\" onclick=\"gotopage()\" value=\"转到\" class=\"goto_button\" /></label>");
    out.print(strPageNavigation.toString());
    out.print("&nbsp;&nbsp;搜索用时 " + searchTime + " 秒&nbsp;&nbsp;");
%>
</td></tr>
</table>
<!--页码导航结束-->

<div>
<%
    try{
        displayVerifyLogQueryResult(documents, out);
    }catch(Exception ex){
        ex.printStackTrace();
    }
%>
</div>

<!--页码导航开始-->
<table align="center" border=0  width="98%" class="Page">
<tr><td height="28" align="left">
<% 
    out.print(strPageNavigation.toString());
%>
</td></tr>
</table>
<!--页码导航结束-->
<%
}
//系统异常的情况
else
{

%>
    <div class="result_message">
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div><%=serverStatus%></div>
    </div>
<%
}
//-----
%>
</FORM>

<div class="copyright"><label>版权所有 © 2002-2011 孔夫子旧书网</label></div>
<script>enableSelectionHighlight();</script>

</body>
</html>
