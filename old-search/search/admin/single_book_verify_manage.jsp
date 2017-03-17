<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.sql.DBOperator" %>
<%@ page import="com.kongfz.dev.util.serialize.PHPSerialize" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.io.OutputStream" %>
<%@ page import="java.io.DataOutputStream" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.DataInputStream" %>
<%@ include file="cls_memcached_session.jsp"%>
<%
	// 书店编号白名单[ 28022=新大学问书坊  tangjunfeng 2013/12/25 ADD 孙老师说添加的]
    String[] singleVerifyShopId = {"19661", "23451", "24333" ,"28022"};
    int length = singleVerifyShopId.length;
    StringBuffer sb = new StringBuffer();
    for (int i=0; i<length; i++) {
            sb.append(singleVerifyShopId[i] + ",");
    }
    String shopIdStr = sb.toString();

    // 数据库信息
    String host = "192.168.1.67:3306";
    String database = "shop";
    String user = "sunyutian";
    String password = "sun100112";
	DBOperator dbo = new DBOperator(host, database, user, password);
%>
<%!
	/**
	 * 判断输入的书店编号是否在书店编号白名单中
	 * @param shopId
	 * @return true, false
	*/
/*	private boolean isSingleVerifyShopId(String shopId) {
		boolean b = false;
		
		for (int i=0; i<singleVerifyShopId.length; i++) {
			if (shopId.equalsIgnoreCase(singleVerifyShopId[i])) {
				b = true;
			}
		}
		return b;
	}*/
	
	public Map<String, Object> getDbConnectParams(DBOperator dbo, String shopId){
		String selDbSql = "SELECT tm.tableId as tableId, tm.masterHost as masterHost,tm.dbName as dbName, si.shopName as shopName " + 
			" FROM tableMap tm, userMap um, shopInfo si " +
			" WHERE tm.tableId = um.tableId and um.userId = si.userId and si.shopId =" + shopId;
		Map<String, Object> dbMap = dbo.getRow(selDbSql);
		return dbMap;
	}
	
	/**
	 * 查询图书信息
	 * @param dbo, shopId, itemId
	 * @return 图书信息 
	 */
	private Map<String, Object> singleBookVerifySearch(DBOperator itemDbo, String tableId, String itemId) {
		Map<String, Object> result = new HashMap<String, Object>();
		if (null != itemId && !"".equals(itemId) && null != tableId && !"".equals(tableId)) {
			String dataSql = "SELECT itemName, author, press, certifyStatus FROM item_" + tableId + " WHERE itemId="	+ itemId;
			result = itemDbo.getRow(dataSql);
		}
		return result;
	}
	
	/**
	 * 更新图书的审核状态 
	 * @param dbo, shopId, itemId
	 * @return  void
	 */
	 private String singleBookVerifyUpdate(DBOperator dbo, String tableId, String itemId) {
		
		String status = "";
		if (null != itemId && !"".equals(itemId) && null != tableId && !"".equals(tableId)) {
			String sql = "UPDATE item_" + tableId + " SET certifyStatus='certified' WHERE itemId="	+ itemId + " LIMIT 1";
			dbo.executeUpdate(sql);
			status = "0";
		}
		return  status;
	}
	
	/**
	 * 将单本图书信息发往图书缓存清理服务器
	 * @param 单本图书信息  
	 * @return void
	 */
	 private void sendToChangeBookCacheServer(Map<String, String> record) {
		
		String serverURL = "http://shop.kongfz.com/interface/server_interface/change_book_cache.php";
		
		String act = "delete";
		
		if (null != record && record.size() != 0) {
			String data = null;
			String sign = null;
			try {
				data = PHPSerialize.serialize(record);
				sign = StringUtils.Md5Encode(data + act + "1kd8uj4Ja0LKjfd8");
				URL dataUrl = new URL(serverURL);
				HttpURLConnection con = (HttpURLConnection) dataUrl.openConnection();
				con.setRequestMethod("POST");
				con.setRequestProperty("Proxy-Connection", "Keep-Alive");
				con.setDoOutput(true);
				con.setDoInput(true);

				OutputStream os = con.getOutputStream();
				DataOutputStream dos = new DataOutputStream(os);
				dos.write(("act=" + act + "&data=" + data + "&sign=" + sign).getBytes());
				dos.flush();
				dos.close();

				InputStream is = con.getInputStream();
				DataInputStream dis = new DataInputStream(is);
				byte d[] = new byte[dis.available()];
				dis.read(d);
				data = new String(d);
				System.out.println(data);
				con.disconnect();
			}
			catch (Exception e) {
				e.printStackTrace();
			}
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
        response.sendRedirect("index.jsp");
        return;
    }

    //判断管理员权限
    //String[] permission = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "singleBookVerifyManage";
    if(!MemSession.hasPermission(permission)){
        out.write("您无权限使用此页面。");
        return;
    }

    /****************************************************************************
    * 接收页面请求参数
    ****************************************************************************/

    //动作类型
    String act = StringUtils.strVal(request.getParameter("act"));
    if("".equals(act)){ act="search"; }
    
    String shopId = StringUtils.strVal(request.getParameter("shopId")).replaceAll(" ", "");
    String itemId = StringUtils.strVal(request.getParameter("itemId")).replaceAll(" ", "");
    String shopName = StringUtils.strVal(request.getParameter("shopName"));
    String itemName = StringUtils.strVal(request.getParameter("itemName"));
    String author = StringUtils.strVal(request.getParameter("author"));
    String press = StringUtils.strVal(request.getParameter("press"));
    String certifyStatus = StringUtils.strVal(request.getParameter("certifyStatus"));

    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface manager = null;
    ServiceInterface manager_log = null;
    Map<String, Object> resultSet = null;
    Map<String, Object> resultSet_log = null;
    List<Map<String, Object>> bookInfoList = new LinkedList<Map<String, Object>>();
    String serverStatus = "";
    String updateStatus = "";
    int bookTotal = 0;
    try{
        //取得远程服务器接口实例
        manager_log = (ServiceInterface) Naming.lookup("rmi://192.168.1.105:9823/VerifyLogService");
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(null != manager_log){

        // 审核服务：通过
        if ("Approve".equalsIgnoreCase(act)) {
            //要审核的图书信息列表
            Map<String, Object> record = new HashMap<String, Object>();
            record.put("shopId", shopId);
            record.put("shopName", shopName);
            record.put("itemId", itemId);
            record.put("itemName", itemName);
            record.put("author", author);
            record.put("press", press);
            record.put("certifyStatus", certifyStatus);
            record.put("bizType", "shop");
            record.put("saleStatus", "0");
            
            bookInfoList.add(record);

            // 组织参数
            Map<String, Object> parameters = new HashMap<String, Object>();
            parameters.put("itemList", bookInfoList);
            parameters.put("adminRealName", adminRealName);
            parameters.put("task", act);
            parameters.put("verifyMode", "Manual");//人工审核

            try {
            	Map<String,Object> dbParams = getDbConnectParams(dbo, shopId);
            	String tableId = StringUtils.strVal(dbParams.get("tableId"));
            	String masterHost = StringUtils.strVal(dbParams.get("masterHost"));
            	String dbName = StringUtils.strVal(dbParams.get("dbName"));
            	DBOperator itemDbo = new DBOperator(masterHost, dbName, user, password);
            	updateStatus = singleBookVerifyUpdate(itemDbo, tableId, itemId);
            }catch (Exception ex) {
            	ex.printStackTrace();
            	serverStatus="服务器信息：更新远程数据库失败。";
            }
            //更新数据库中图书审核状态 
            try{
                resultSet_log = manager_log.work("RecordVerifyLog", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器工作失败。";
            }
            
            //处理请求的结果
            String status_log = "";
            if(null != resultSet_log){
                status_log = StringUtils.strVal(resultSet_log.get("status"));
            }
            
            if("0".equals(updateStatus) && "0".equals(status_log)){
            	
            	// 处理成功后将图书信息发往图书缓存清理服务器 
            	Map<String, String> sendMap = new HashMap<String, String>();
            	sendMap.put(itemId, shopId);
            	sendToChangeBookCacheServer(sendMap);
            	
                act = "search";
            }
            else{
                serverStatus = "服务器信息：未知错误。";
                act = "";
            }
            //其它错误，略
        }
        
    }else{
        serverStatus = "请求远程审核日志服务器出现异常，可能是远程审核日志服务器未启动，请与系统管理员联系。";
    }
    
    // 查询数据库服务
    if("Search".equalsIgnoreCase(act) && !"".equals(shopId)){
    	
        //调用远程查询接口
        try{
        	Map<String,Object> dbParams = getDbConnectParams(dbo, shopId);
        	String tableId = StringUtils.strVal(dbParams.get("tableId"));
        	String masterHost = StringUtils.strVal(dbParams.get("masterHost"));
        	String dbName = StringUtils.strVal(dbParams.get("dbName"));
        	shopName = StringUtils.strVal(dbParams.get("shopName"));
        	DBOperator itemDbo = new DBOperator(masterHost, dbName, user, password);
            resultSet = singleBookVerifySearch(itemDbo, tableId, itemId);
        }catch(Exception ex){
            ex.printStackTrace();
            serverStatus="服务器信息：查询远程数据库失败。";
        }

        if(null != resultSet){
            //将查询到的图书列表输出
           
            itemName = StringUtils.strVal(resultSet.get("itemName"));
            author = StringUtils.strVal(resultSet.get("author"));
            press = StringUtils.strVal(resultSet.get("press"));
            certifyStatus = StringUtils.strVal(resultSet.get("certifyStatus"));
            serverStatus = "ok";
            if (!"".equals(shopName) && !"".equals(itemName)) {
        		bookTotal = 1;
        	}
        }else{
            serverStatus = "服务器信息：未知错误。";
        }
    }
    	
%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>单本图书审核通过系统【新】</title>
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
<script type="text/javascript">
	/**
	 * 判断输入的书店编号是否在书店编号白名单中
	 * @param shopId
	 * @return true, false
	*/
    function isSingleVerifyShopId(shopId) {
    	
	    // 提取服务器端的书店编号白名单
	    var shopIdStr = trim($search('shopIdStr').value);
	    var length = ($search('length').value);
 		// 分离书店编号白名单   	
    	var shopIdArray = shopIdStr.split(",");
    	
    	var b = false;
    	for (i=0; i<length; i++) {
    		if (shopId == shopIdArray[i]) {
    			b = true;
    		}
    	}
    	
    	return b;
    }

    function initSearchForm(){
    	
    	var shopId = trim($search('shopId').value);
    	var itemId = trim($search('itemId').value);
    	
    	if (shopId == "") {
    		$search('shopId').focus();
    		alert("请输入书店编号！");
    		return;
    	} else if (!isSingleVerifyShopId(shopId)) {
    		$search('shopId').value = "";
    		$search('shopId').focus();
    		alert("输入的书店编号不在白名单中，请输入正确的书店编号！");
    		return;
    	}
    	
    	if (itemId == "") {
    		$search('itemId').focus();
    		alert("请输入图书编号！");
    		return;
    	} else {
    		$search('frmSearch').submit();
    	}
    	
    }
    
    /**
     * 审核图书
     */
    function verifyBook(act)
    {
        $search('act').value = act;
        $search('frmSearch').submit();
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("shopId").value = "";
        $search("itemId").value = "";
    }
</script>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>
<script type="text/javascript" language="javascript" src="../js/lib_common.js"></script>
</head>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="doc_base_manage.jsp">违禁图书审查系统</a>
<a href="book_verify_manage.jsp">待审图书管理系统</a>
<a href="single_book_verify_manage.jsp" class="menuItemSel">单本图书审核通过系统</a>
</div>

<form name="frmSearch" id="frmSearch" method="post" action="" >
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="15%" align="left">&nbsp;</td>
    <td height="26" colspan="2" align="left" valign="bottom">

    <font>书店编号： </font><input type="text" id="shopId" name="shopId" value="<%=shopId %>" size="20" maxlength="100" />
    <font>图书编号： </font><input type="text" id="itemId" name="itemId" value="<%=itemId %>" size="20" maxlength="100" />

    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="clearQueryCondition();" />
    <input type="hidden" id=shopIdStr name="shopIdStr" value="<%=shopIdStr%>" />
    <input type="hidden" id=length name="length" value="<%=length%>" />
    <input type="button" value="搜 索" class="searchSub" onClick="initSearchForm()"/>
    <input type="hidden" id="act" name="act" value="<%=act%>" />
  </tr>
</table>
</div>

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
        <div>很抱歉！没有找到图书编号为“<label><%=itemId %></label> ”的结果。</div>
    </div>
    </div>
<%
}
else if("ok".equals(serverStatus) && bookTotal > 0){
	%>	
	
	<table style="font-size:14px; margin-bottom:5px;" width="99%" border="1" cellpadding="1" cellspacing="1">
	    <tr>
	    <td width="20%">书店名称</td>
	    <td width="20%">书名</td>
	    <td width="20%">作者</td>
	    <td width="20%">出版社</td>
	    <td width="20%">审核状态</td>
	    </tr>
	    <tr>
	    <td width="20%"><%=shopName %></td>
	    <td width="20%"><%=itemName %></td>
	    <td width="20%"><%=author %></td>
	    <td width="20%"><%=press %></td>
	    <%
	    if ("notCertified".equalsIgnoreCase(certifyStatus)) {
	    %>
	    	<td width="20%">未申核</td>
	    <%
	    } else if ("certified".equalsIgnoreCase(certifyStatus)) {
	    %>
	    	<td width="20%">已通过申核</td>
	    <%	
	    }  else if ("failed".equalsIgnoreCase(certifyStatus)) {
	    %>
	    	<td width="20%">申核失败</td>
	    <%	
	    }
	    %>
	    </tr>
    </table>

	<div align="center" style="padding:5px 2px 0px 2px;width:98%;font-size:13px;">
		<input type="hidden" id="shopName" name="shopName" value="<%=shopName%>" />
		<input type="hidden" id="itemName" name="itemName" value="<%=itemName%>" />
		<input type="hidden" id="author" name="author" value="<%=author%>" />
		<input type="hidden" id="press" name="press" value="<%=press%>" />
		<input type="hidden" id="certifyStatus" name="certifyStatus" value="<%=certifyStatus%>" />
		<input type="button" value="通过" onclick="verifyBook('approve');" />
	</div>
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
%>
</FORM>

<div class="copyright"><label>版权所有(C)2002-2010 孔夫子旧书网</label></div>

</body>
</html>
