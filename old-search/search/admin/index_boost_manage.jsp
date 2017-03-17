<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%!

    /**
     * 取得提交的图书权重记录的列表
     */
    private static List<Map<String, Object>> getBookBoostList(String[] bookInfoList)
    {
        List<Map<String, Object>> recordList = new LinkedList<Map<String, Object>>();
        if (null == bookInfoList) {
            return recordList;
        }
        
        for (String bookInfo : bookInfoList) {
            String[] items = StringUtils.urldecode(bookInfo).split("\n");
            if (null != items && items.length >= 2) {
                Map<String, Object> record = new HashMap<String, Object>();
                record.put("bizType",      items[0].trim());
                record.put("shopId",       items[1].trim());
                recordList.add(record);
            }
        }
        return recordList;
    }

    /**
     * 是否已经更新索引的权重值
     */
    private String getUpdatedIndexStatus(String isUpdatedIndex)
    {
        if ("1".equals(isUpdatedIndex)) {
            return "已更新";
        }
        else {
            return "未更新";
        }
    }

    /**
     * 取得业务类型的文字描述
     */
    private String getBizTypeDesc(String bizType)
    {
        if("shop".equals(bizType)){
            return "书店";
        }
        if("bookstall".equals(bizType)){
            return "书摊";
        }
        return "";
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
    String permission = "indexBoostManage";
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
    String task = StringUtils.strVal(request.getParameter("task"));

    int currentPage = StringUtils.intVal(request.getParameter("page"));

    String searchType = StringUtils.strVal(request.getParameter("searchType"));

    String keywords = StringUtils.strVal(request.getParameter("keywords"));

    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface manager = null;
    Map<String, Object> resultSet = null;
    List<Map<String, Object>> boostRecordList = null;
    String serverStatus = "";
    int recordCount = 0;
    int pageCount = 0;
    List<Map<String, Object>> recordInfoList = null;
    try{
        //取得远程服务器接口实例
        manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.105:9820/AdminBookSearchService");
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：增加、修改、删除图书索引权重记录
     *******************************************************************************/
    if(null != manager){
        // 添加、修改、删除
        
        if (StringUtils.inArray(act, "add", "modify", "delete")) {
            String[] bookInfoArray = request.getParameterValues("recordInfo[]");
            recordInfoList = getBookBoostList(bookInfoArray);
            
            Map<String, Object> parameters = new HashMap<String, Object>();
            if ("add".equalsIgnoreCase(act)) {
                parameters.put("adminRealName", adminRealName);
                parameters.put("task", task);
                String bizType = StringUtils.strVal(request.getParameter("r_bizType")); 
                String shopIdList = StringUtils.strVal(request.getParameter("r_shopIdList"));
                int boostVal = StringUtils.intVal(request.getParameter("r_boostVal"));
                String memo = StringUtils.strVal(request.getParameter("r_memo"));
                parameters.put("bizType", bizType);
                parameters.put("shopIdList", shopIdList);
                parameters.put("boostVal", boostVal);
                parameters.put("memo", memo);
                
            }
            if ("modify".equalsIgnoreCase(act)) {
                parameters.put("adminRealName", adminRealName);
                parameters.put("task", task);
                int boostVal = StringUtils.intVal(request.getParameter("boostVal"));
                String memoVal = StringUtils.strVal(request.getParameter("memoVal"));
                parameters.put("boostVal", boostVal);
                parameters.put("memoVal", memoVal);
                parameters.put("recordInfoList", recordInfoList);
            }
            
            if ("delete".equalsIgnoreCase(act)) {
                parameters.put("task", task);
                parameters.put("recordInfoList", recordInfoList);
            }
            
            //调用远程查询接口
            try{
                resultSet = manager.work("ManageBookBoost", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器查询失败。";
            }

            String status = "";
            if(null != resultSet){
                //处理查询结果
                status = StringUtils.strVal(resultSet.get("status"));
            }else{
                serverStatus = "服务器信息：未知错误。";
            }

            if("0".equals(status)){
                act = "search";
            }
            else if ("1".equals(status)){
                String error = StringUtils.strVal(resultSet.get("error"));
                serverStatus = "提示信息：<br />" + error;
            }
            else if("9".equals(status)){
                serverStatus = "服务器信息：Task参数错误。";
            }
            else{
                serverStatus = "服务器信息：未知错误。";
            }

        }

        // 查询服务
        if("search".equalsIgnoreCase(act)){

            Map<String, Object> parameters = new HashMap<String, Object>();
            parameters.put("task", "searchBoostRecord");
            parameters.put("keywords", keywords);
            parameters.put("searchType", searchType);
            parameters.put("currentPage", currentPage);
            parameters.put("paginationSize", "100");

            //调用远程查询接口
            try{
                resultSet = manager.work("ManageBookBoost", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器查询失败。";
            }

            String status = "";
            if(null != resultSet){
                //处理查询结果
                status = StringUtils.strVal(resultSet.get("status"));
                boostRecordList = (List<Map<String, Object>>) resultSet.get("boostRecordList");
                recordCount = StringUtils.intVal(resultSet.get("recordCount"));
                pageCount = StringUtils.intVal(resultSet.get("pageCount"));
                currentPage = StringUtils.intVal(resultSet.get("currentPage"));
            }else{
                serverStatus = "服务器信息：未知错误。";
            }

            if("0".equals(status)){
                //将查询到的图书列表输出
                serverStatus = "ok";
            }
            else if("9".equals(status)){
                serverStatus = "服务器信息：Task参数错误。";
            }
            else{
                serverStatus = "服务器信息：未知错误。";
            }
        }

    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }

%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>管理图书索引权重</title>
<style>
    body{ 
    margin:0; 
    padding:0; 
    text-align:center
    }
    .clear {clear: both;}
    
    a{ text-decoration:none;}
    a:hover{ 
    text-decoration:underline; 
    color:red;
    }

    .funcMenuPanel{ 
    width:99%; 
    height:28px; 
    border:1px solid #CCCCCC; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#F5F5F5; 
    }
    .funcMenuPanel a {
    color:#000000;
    }

    .searchSub{ 
    background:url(./images/bg_searchsub.gif); 
    border:1px solid #d17528; 
    width:80px;
    padding-top:2px; 
    font-weight:bold; 
    color:#fff;
    }

    #Page td{ font-size:12px; line-height:200%;}
    .bookList td{ font-size:12px; line-height:220%!important; line-height:150%;}
    .bookList td a{ color:#0000ba; text-decoration:none;}
    .bookList td a:hover{ color:red; text-decoration:underline;}

    .search{
    width:99%; 
    height:62px; 
    border-bottom:1px solid #CCCCCC; 
    border-left:1px solid #CCCCCC; 
    border-right:1px solid #CCCCCC; 
    margin:0 auto 2px auto; 
    background:url(./images/bg_search_2.gif); 
    font-size:12px;
    }

    form{
    margin:0px;
    }
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

    .isNewBook{
    font-size:14px;
    color:#FF0000;
    font-weight:bold;
    }
    .isNewBookNomal{
    font-size:14px;
    }
    
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
    
    .addRecordPanel {
    margin:2px 2px 5px 2px;
    width:300px; 
    border:1px solid #579CE2;
    padding-bottom:10px;
    background-color:#EFE7D6;
    font-size:14px;
    display:none;
    }
    .addRecordPanelTitle {
    float:left;
    width:100%;
    text-align:left;
    background-color:#588CC8;
    border-bottom:1px solid #579CE2;
    padding:4px;
    color:#FFFFFF;
    font-weight:bold;
    }
    .addRecordPanelItem {
    width:auto;
    color:#524D52;
    }	
    
    .useDesc {
    margin:10px;
    padding:5px;
    text-align:left;
    font-size:12px;
    background-color:#F5F5F5;
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
        $search("page").value="";
    }

    var m_isCheckAll = false;
   
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('recordInfo[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }
    
    /**
     * 管理图书索引权重
     */
    function deleteBoostRecord(recordInfo)
    {
        var title = "是否删除所选项目？";
        if (recordInfo != null && !confirm(title)) {
            return void(0);
        }
 
        var elements = document.getElementsByName('recordInfo[]');
        
        if(recordInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == recordInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再进行操作！");return;
        }
        if((recordInfo == null) && (!confirm(title))){return;}
        
        $search('act').value = "delete";
        $search('task').value = "deleteBoostRecord";
        $search('frmSearch').submit();
    }
    
    // 修改权重记录的备注
    function modifyRecordMemo(recordInfo)
    {
        var elements = document.getElementsByName('recordInfo[]');
        if(recordInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == recordInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再进行操作！");return;
        }

        var title = "请输入备注内容：";
        var theResponse = window.prompt(title, "");
        if (null == theResponse){
            return;
        }
        theResponse = theResponse.replace(/ /g,"");
        if ("" == theResponse){
            alert("输入为空，请重新输入！");return;
        }
        $search('memoVal').value = theResponse;
        $search('act').value = 'modify';
        $search('task').value = "modifyRecordMemo";
        $search('frmSearch').submit();
    }
    
    // 修改图书权重
    function modifyBoostRecord(recordInfo)
    {
        var elements = document.getElementsByName('recordInfo[]');
        if(recordInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == recordInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再进行操作！");return;
        }

        var title = "请输入一个图书索引的权重值，范围从 0 到 9：";
        var theResponse = window.prompt(title, "");
        if (null == theResponse){
            return;
        }
        theResponse = theResponse.replace(/ /g,"");
        if ("" == theResponse){
            alert("输入为空，请重新输入！");return;
        }
        if (isInvalidNumber(theResponse)) {
            alert("请输入一个有效的数字！");return;
        }
        var boostVal = parseInt(theResponse,10);
        if (!(0 <= boostVal && boostVal < 10)) {
            alert("请输入一个在 0 到 9 之间的数字！");return;
        }

        $search('boostVal').value = theResponse;
        $search('act').value = 'modify';
        $search('task').value = "modifyBoostRecord";
        $search('frmSearch').submit();
    }

    function isInvalidNumber(string)
    { 
        var Letters = "1234567890";
        var c;
        for (var i=0; i < string.length; i++ ) {
            c = string.charAt(i);
            if (Letters.indexOf(c) == -1) {
                return true;
            }
        }
        return false;
    }

    function selectVerifyModule(module) {
        var map = {
            "0":""
        };
        $search('docBaseType').value = map[module];
        $search("keywordGroupId").value = "";
        $search('sorttype').value=0;
        $search('isNewBook').value='-1';
        $search('category').value=0;
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search("bizType").value="";
        $search("hasPic").value="-1";
        $search('frmSearch').submit();
    }
    
    function setModulePanelHighlight(module) {
        var map = {
            "":0
        };
        var items = $search("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("searchType").value="";
        $search("keywords").value="";
        $search("bizType").value="";
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
            if(obj.className != "bookList"){
                return;
            }
            obj.onmouseover = function(){
                obj.style.backgroundColor="#FFC44C";
            };
            obj.onmouseout = function(){
                obj.style.backgroundColor="#FFFFFF";
            };
        }
    }

    /**
     * 设置表单提交事件，用于
     */
    var m_formType = "search";
    function switchFormSubmit()
    {
         if ("addRecord" == m_formType) {
            submitNewRecord();
            return false;
         } else {
            return true;
         }
    }

    /**
     * 显示或隐藏添加记录的表单
     */
    function showAddRecordPanel(visible)
    {
        m_formType = (visible ? "addRecord" : "search");
        $search("r_bizType").value="shop";
        $search("r_shopIdList").value="";
        $search("r_boostVal").value="";
        $search("addRecordPanel").style.display=(visible?"block":"none");
    }

    /**
     * 提交表单：添加图书索引权重记录
     */
    function submitNewRecord()
    {
        var bizType = $search("bizType").value.replace(/ /g,"");
        var shopIdListStr = $search("r_shopIdList").value.replace(/ /g,"");
        var boostVal = $search("r_boostVal").value.replace(/ /g,"");
        // 检查权重值
        if ("" == boostVal) {
            alert("权重值不能为空！");
            $search("r_boostVal").focus();
            return;
        }
        if (isInvalidNumber(boostVal)) {
            alert("请输入一个有效的权重值（从０到９）！");
            $search("r_boostVal").focus();
            return;
        }
        if (!(0 <= boostVal && boostVal < 10)) {
            alert("请输入一个在 0 到 9 之间的权重值！");
            $search("r_boostVal").focus();
            return;
        }
        // 检查书店编号列表
        if ("" == shopIdListStr) {
            alert("书店编号不能为空！");
            $search("r_shopIdList").focus();
            return;
        }
        // 分析书店编号列表是否存在无效的数据
        var shopIdList = analyzeShopIdList(shopIdListStr);
        if (!shopIdList) {
            return;
        }
        
        $search('act').value = "add";
        $search('task').value = "addBoostRecord";
        $search("frmSearch").submit();
    }
    
    /**
     * 分析书店编号列表是否存在无效的数据
     */
    function analyzeShopIdList(shopIdListStr)
    {
        shopIdListStr = shopIdListStr.replace(/\r/g,"");
        var lines = shopIdListStr.split("\n");
        var shopIdList = new Array();
        var shopId;
        for (var i=0; i < lines.length; i++) {
            shopId = lines[i];
             if (shopId) {
                if (isInvalidNumber(shopId)) {
                    alert("第" + (i+1) + "行“" + shopId + "”不是一个有效的书店编号！");
                    return;
                } else {
                    shopIdList.push(shopId);
                }
             }
        }
        return shopIdList.join(",");
    }
</script>
</HEAD>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="index_boost_manage.jsp" class="menuItemSel">管理图书索引权重</a>
</div>

<!-- 查询区域 -->
<form name="frmSearch" id="frmSearch" method="post" action="" onSubmit="return switchFormSubmit();" >
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="15%" align="left">&nbsp;</td>
    <td height="26" align="left" valign="bottom">
    <select name="searchType" id="searchType">
    <option value="">全部</option>
    <option value="1">书店名称</option>
    <option value="2">书店编号</option>
    <option value="3">操作人</option>
    </select>
    <script>$search("searchType").value="<%=searchType%>";</script>
    <input type="text" id="keywords" name="keywords" size="40" maxlength="350" value="<%=keywords%>" />
    <select name="bizType" id="bizType">
      <option value="">全部</option>
      <option value="shop">书店</option>
      <option value="bookstall">书摊</option>
    </select>
    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="clearQueryCondition();" />
    <input type="submit" value="搜 索" class="searchSub" onClick="initSearchForm()"/>
    <input type="hidden" id="page" name="page" value="<%=currentPage%>" />
    <input type="hidden" id="act" name="act" value="" />
    <input type="hidden" id="task" name="task" value="" />
    <input type="hidden" id="boostVal" name="boostVal" value="" />  
    <input type="hidden" id="memoVal" name="memoVal" value="" />  
    </td>
    </tr>
  <tr>
    <td align="left">&nbsp;</td>
    <td height="26" align="left" valign="middle" style="padding-left:42px;color:gray;">    </td>
    </tr>
</table>
</div>

<div class="funcMenuPanel">
　　<a href="javascript:void(0);" onClick="showAddRecordPanel(true);">添加图书索引权重记录</a>
</div>

<!-- 添加新记录区域 -->
<div class="addRecordPanel" id="addRecordPanel">
<div class="addRecordPanelTitle">添加图书索引权重记录</div>
<p />
<table width="100%" border="0" cellspacing="0">
  <tr>
    <td width="36%"><div align="right"><span class="addRecordPanelItem">业务类型：</span></div></td>
    <td width="64%"><div align="left">
      <select id="r_bizType" name="r_bizType">
        <option value="shop">书店</option>
        <option value="bookstall">书摊</option>
      </select>
    </div></td>
  </tr>
  <tr>
    <td><div align="right"><span class="addRecordPanelItem">权 重 值：</span></div></td>
    <td><div align="left"><input type="text" id="r_boostVal" name="r_boostVal" value="" /></div></td>
  </tr>
  <tr>
    <td><div align="right"><span class="addRecordPanelItem">备 　 注：</span></div></td>
    <td><div align="left"><textarea rows="3" id="r_memo" name="r_memo" style="width:150px;"></textarea></div></td>
  </tr>
  <tr>
    <td><div align="right"><span class="addRecordPanelItem">书店编号：</span></div></td>
    <td><div align="left"><textarea rows="5" id="r_shopIdList" name="r_shopIdList" style="width:150px;"></textarea></div>
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td><div align="left"><span class="addRecordPanelItem">可每行输入一个书店编号</span></div></td>
  </tr>
</table>
<hr style="margin-left:4px;"/>
<div>
<input type="button" value=" 提交 " onClick="submitNewRecord()" />　　
<input type="button" value=" 取消 " onClick="showAddRecordPanel(false)" />
</div>
</div>

<div style="width:99%;">
<div class="useDesc">
说明：
本功能用于降低书店或书摊的图书排序权重，使其在每次搜索结果中排名靠后。
权重值的范围为 0 到 9，其值越小，则其对应的图书在搜索结果中排名越靠后。<br />
　　　例如，若要小幅降低某个书店图书的权重，设其值为 9；
若要大幅降低某个书店图书的权重，设其值为 0。
</div>
</div>
<%
//查询结果为空的情况
if("ok".equals(serverStatus) && (null == boostRecordList || 0 == boostRecordList.size())){
%>
    <div class="result_message">
    <img class="float_left" src="./images/none.gif" />
    <div class="float_left">
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>很抱歉！没有找到符合的结果。</div>
    </div>
    </div>
<%
}
else if("ok".equals(serverStatus) && null != boostRecordList && boostRecordList.size() > 0){
%>

<!--页码导航开始-->
<hr style="width:99%" />
<div align="left" style="padding-bottom:4px;">
　<input type="button" value="　删除　" onClick="deleteBoostRecord();"/>
　　<input type="button" value="修改权重" onClick="modifyBoostRecord()"/>
　　<input type="button" value="修改备注" onClick="modifyRecordMemo()"/>
</div>

<table align="center" border=0  width="98%" id="Page">
<tr><td height="28" align="left">
<% 
   String strNavigationHtml = displayNavigation(pageCount, currentPage);
   out.write(strNavigationHtml);
%>
<span><%=("记录总数：" + recordCount)%></span>
</td></tr>
</table>
<!--页码导航结束-->

<div>
  <script>var data =[];</script>
  <table width="98%" border="1" cellspacing="0" style="font-size:14px">
    <tr bordercolor="#D7DFF3" bgcolor="#D7DFF3" style="color:#524D52;">
      <td width="26"><img src="./images/smile.gif" id="smile" title="Ahoy!" onClick="checkAll(!m_isCheckAll)" style="cursor:pointer" /></td>
      <td width="61">业务类型</td>
      <td width="61">书店编号</td>
      <td width="150">书店名称</td>
      <td width="32">权重</td>
      <td width="227">备注</td>
      <td width="105">修改时间</td>
      <td width="62">更新索引</td>
      <td width="70">操作人</td>
      <td width="118">操作</td>
    </tr>
    <%
    for (int i=0; i < boostRecordList.size(); i++) {
        Map<String, Object> record = boostRecordList.get(i);
            StringBuffer fields = new StringBuffer();
            fields.append(record.get("bizType")+" \n");
            fields.append(record.get("shopId")+" \n");
            String recordInfo = StringUtils.urlencode(fields.toString());

    %>
    <script>data[<%=i%>]="<%=recordInfo%>";</script>
    <tr>
      <td><input type="checkbox" name="recordInfo[]" value="<%=recordInfo%>" ></td>
      <td><%=getBizTypeDesc(StringUtils.strVal(record.get("bizType")))%>&nbsp;</td>
      <td><%=record.get("shopId")%>&nbsp;</td>
      <td><%=record.get("shopName")%>&nbsp;</td>
      <td><%=record.get("boost")%>&nbsp;</td>
      <td style="word-break: break-all; text-align:left"><%=record.get("memo")%>&nbsp;</td>
      <td><%=record.get("modifyTime")%>&nbsp;</td>
      <td><%=getUpdatedIndexStatus(StringUtils.strVal(record.get("isUpdatedIndex")))%>&nbsp;</td>
      <td><%=record.get("adminRealName")%>&nbsp;</td>
      <td>[<a href="javascript:deleteBoostRecord(data[<%=i%>]);">删除</a>] 
          [<a href="javascript:modifyBoostRecord(data[<%=i%>]);">修改权重</a>]&nbsp;</td>
    </tr>
    <%
    }
    %>
  </table>
</div>

<table align="center" border=0  width="98%" id="Page">
<tr><td height="28" align="left">
<% 
   out.write(strNavigationHtml);
%>
</td></tr>
</table>

<!--页码导航开始-->
<div align="left" style="padding-bottom:4px;">
　<input type="button" value="　删除　" onClick="deleteBoostRecord();"/>
　　<input type="button" value="修改权重" onClick="modifyBoostRecord()"/>
　　<input type="button" value="修改备注" onClick="modifyRecordMemo()"/>
</div>

<!--页码导航结束-->
<%
}
//系统异常的情况
else
{
%>

<table align="center" border=0  width="98%" id="Page">
<tr>
<td width="25%"></td>
<td height="28" align="left">
<span style="background-color:#FF9933; padding:2px;">
    <% 
   out.write(serverStatus);
%>
</span>
</td>
</tr>
</table>

<%
}
//-----
%>
</FORM>

<div class="copyright"><label>版权所有 © 2002-2011 孔夫子旧书网</label></div>
</body>
</html>
