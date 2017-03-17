<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.search.service.manage.book.VerifyMenuUpdater"%>
<%@ include file="cls_memcached_session.jsp"%>
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
    response.sendRedirect("index.jsp");
    return;
}

//判断管理员权限
//String[] permission = new String[]{"manageIndex", "manAuctioneer"};
String permission = "indexSetting";
if(!MemSession.hasPermission(permission)){
    out.write("您无权限使用此页面。");
    return;
}

/****************************************************************************
* 接收页面求参数
****************************************************************************/
//动作类型
String act = StringUtils.strVal(request.getParameter("act"));

//任务类型
String task = StringUtils.strVal(request.getParameter("task"));

//更新辅助数据：可疑关键字列表、可信任出版列表
if("assistant".equals(act)){
    String path = application.getRealPath("/");

    VerifyMenuUpdater updater = new VerifyMenuUpdater();

    if("updateKeywords".equals(task)){
        updater.updateDistrustKeywordsFile(path+"/admin/distrust_keywords.js");
    }
	
    if("updatePress".equals(task)){
        updater.updateBelivePressFile(path+"/admin/belive_press.js");
    }
	
}



%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>设置<%=act%></title>
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
    border:1px solid #FFC44C; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#FFF7E6; 
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
    #List td{ font-size:12px; line-height:220%!important; line-height:150%;}
    #List td a{ color:#0000ba; text-decoration:none;}
    #List td a:hover{ color:red; text-decoration:underline;}

    .search{
    width:99%; 
    height:62px; 
    border-bottom:1px solid #CCCCCC; 
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
    width:100%; 
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

    function showNewBook(isNewBook){
        $search("isNewBook").value = isNewBook;
        $search("frmSearch").submit();
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
        $search('sorttype').value=0;
        $search('isNewBook').value='-1';
        $search('category').value=0;
        $search("keywordGroupId").value = "";
        $search("hasPic").value="-1";
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
     * 审核图书
     */
    function verifyBook(act, bookInfo)
    {
        var titleMap = {
        "approve":     "是否通过所选项目？",
        "reject":      "是否驳回所选项目？",
        "delete":      "是否删除所选项目？",
        "unconfirmed": "是否待确认所选项目？"
        };
        var title = titleMap[act];

        if(null != bookInfo && !confirm(title)){
            return void(0);
        }

        var elements = document.getElementsByName('bookInfo[]');

        if(bookInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == bookInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再执行审核操作！");return;
        }
        if((bookInfo == null) && (!confirm(title))){return;}
        
        $search('act').value = act;
        $search('frmSearch').submit();
    }

    var iframe = null;// 遮罩窗口对象

    /**
     * 显示可疑关键字列表
     */
    function showDistrustKeywords(isVisible){
        function hideDistrustKeywordsPanel(){showDistrustKeywords(false);}
        var panel = $search('distrustKeywordsPanel');
        if(!isVisible){
            panel.style.display="none";
            iframe.style.display = 'none';
            removeEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            panel.style.zIndex = 65535;

            iframe.style.left = pos[0] + 'px';
            iframe.style.top = (pos[1]+15) + 'px';
            iframe.style.width = panel.offsetWidth  + 'px';
            iframe.style.height = panel.offsetHeight + 'px';
            iframe.style.display = 'block';

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
            iframe.style.display = 'none';
            removeEventListener(document.documentElement, 'click', hideBelivePressPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            panel.style.zIndex = 65535;

            iframe.style.left = pos[0] + 'px';
            iframe.style.top = (pos[1]+15) + 'px';
            iframe.style.width = panel.offsetWidth  + 'px';
            iframe.style.height = panel.offsetHeight + 'px';
            iframe.style.display = 'block';

            addEventListener(document.documentElement, 'click', hideBelivePressPanel);
        }
    }

    /**
     * 创建遮罩窗口
     */
    function createBoardWindow()
    {
        iframe = document.createElement('IFRAME');
        iframe.frameBorder=0;
        iframe.style.cssText="display:none;position:absolute;left:0px;top:0px;";
        document.body.appendChild(iframe);
    }

    /**
    * 装入辅助数据
    */
    function loadAssistantData(){
        createBoardWindow();
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
        $search('keywords').value = keywords;
        $search('frmSearch').submit();
    }

    function queryCategory(catId){
        $search('category').value = catId;
        $search('frmSearch').submit();
    }

    function selectVerifyModule(module) {
        var map = {
            "0":"", 
            "1":"NonSuspicious",
            "2":"DistrustBanned",
            "3":"DistrustKeyword",
            "4":"UnknowPress",
            "5":"Unconfirmed"
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
            "":0, 
            "NonSuspicious":1,
            "DistrustBanned":2,
            "DistrustKeyword":3,
            "UnknowPress":4,
            "Unconfirmed":5
        };
        var items = $search("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    function queryKeywordGroup(groupId) {
        $search("keywordGroupId").value=groupId;
        $search('frmSearch').submit();
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search("bizType").value="";
    }

    /**
     * 隐藏查询框
     */
    function hideQueryBox(index)
    {
		if(0 == index ){
			$search("sub_panel").style.display = "block";
		} else {
			$search("sub_panel").style.display = "none";
			$search("author").value="";
			$search("press").value="";
		}
		
    }

    function executeAssistTask(task)
    {
        if(null == task || "" == task ){
            alert("请选择要执行的操作，然后再试！");
            return;
        }
        $search('act').value = 'assist';
        $search('frmSearch').submit();
    }
    
    function showHasPic(hasPic)
    {
        $search("hasPic").value = hasPic;
        $search("frmSearch").submit();
    }
	
	
	function callTask(task)
	{
        var titleMap = {
        "updateKeywords":    "是否更新可疑关键字？",
        "updatePress":      "是否更新可信任出版社？"
        };
        var title = titleMap[task];

        if(null != task && !confirm(title)){
            return void(0);
        }
		$search("task").value=task;
 		$search("frmSetting").submit();
	}
</script>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>
</HEAD>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="setting.jsp" class="menuItemSel">设置</a>
</div>

<div>
<form name="frmSetting" id="frmSetting" method="post" action="">
<input type="hidden" name="act" id="act" value="assistant" />
<input type="hidden" name="task" id="task" value="" />
  <table width="919" height="137" border="1" style="text-align:left">
    <tr>
      <td width="581">更新可疑关键字</td>
      <td width="171"><input name="button" type="button" onClick="callTask('updateKeywords')" value="更新" /></td>
      <td width="72">&nbsp;</td>
    </tr>
    <tr>
      <td>更新可信任出版社</td>
      <td><input name="button2" type="button" onClick="callTask('updatePress')" value="更新" /></td>
      <td>&nbsp;</td>
    </tr>
    <tr>
      <td>&nbsp;</td>
      <td>&nbsp;</td>
      <td>&nbsp;</td>
    </tr>
  </table>

</form>

</div>
<div class="copyright"><label>版权所有(C)2002-2010 孔夫子旧书网</label></div>
</body>
</html>
