<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%@ page import="com.kongfz.dev.biz.util.CategoryHelper" %>

<!-- ===================java方法开始========================= -->


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
    String permission = "docBaseManage";
    if(!MemSession.hasPermission(permission)){
        out.write("您无权限使用此页面。");
		return;
    }

    /****************************************************************************
    * 接收页面求参数
    ****************************************************************************/
    
    
        Map<String, Object> resultSet = null;
		ServiceInterface manager = null;
		String queryShopId = StringUtils.strVal(request.getParameter("queryShopId"));
		String addShopId = StringUtils.strVal(request.getParameter("addShopId"));
		String[] shopIdArray = request.getParameterValues("shopIds[]");
		List<String> deleteShopIdList = new ArrayList<String>();
		if(shopIdArray != null){
			for(String shopId : shopIdArray){
			   deleteShopIdList.add(shopId);
			}
		}
		
		Map<String, Object> parameters = new HashMap<String, Object>();
		parameters.put("queryShopId", queryShopId);
		parameters.put("addShopId", addShopId);
		parameters.put("operatorName", adminRealName);
        parameters.put("deleteShopIdList", deleteShopIdList);
		
		
        List<Map<String, Object>> trustShops = null;
        int totalShopCount = 0;
		String act = StringUtils.strVal(request.getParameter("act"));
		String serverStatus = "";
		if ("".equals(act)) {
			act = "SearchTrustShop";
		}
		try {
			// 取得远程服务器接口实例, 根据未售或已售调用不同的远程对象
			manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.83:9821/BookVerifyService");
		} catch (Exception ex) {
			manager = null;
			ex.printStackTrace();
		}

		String workMethodName = "";
		if (null != manager) {
			if (StringUtils.inArray(act, "Add", "Delete")) {
				if ("Add".equalsIgnoreCase(act)) {
					workMethodName = "AddTrustShop";
				}

				if ("Delete".equalsIgnoreCase(act)) {
					workMethodName = "DeleteTrustShop";
				}

				try {
					resultSet = manager.work(workMethodName, parameters);
					serverStatus = StringUtils.strVal(resultSet.get("error"));
				} catch (Exception e1) {
					serverStatus = "服务器信息1：调用远程服务器查询失败。"+e1;
					e1.printStackTrace();
				}
				act = "SearchTrustShop";
			}

			

			// 查询索引服务
			if ("SearchTrustShop".equalsIgnoreCase(act) && "".equals(serverStatus)) {

				try {
					resultSet = manager.work("SearchTrustShop", parameters);
					trustShops = (List<Map<String, Object>>)resultSet.get("trustShops");
					if(trustShops != null){
					    totalShopCount = trustShops.size();
					}
				} catch (Exception e) {
					e.printStackTrace();
					serverStatus = "服务器信息2：调用远程服务器查询失败。";
				}

			}

		} else {
			serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
		}
		
		if(totalShopCount == 0 && "".equals(serverStatus)){
	     	serverStatus = "查询结果为空";
		}
		
%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>违禁图书审查系统</title>
<style>
  body {
	margin: 0;
	padding: 0;
	text-align: center
}

a {
	text-decoration: none;
}

a:hover {
	text-decoration: underline;
	color: red;
}

.sort {
	width: 99%;
	font-size: 14px;
	line-height: 30px;
	background-color: #e1eaf6;
	border: 1px solid #adc1dc;
	margin: 0px 0px 5px 0px;
	height: 28px;
	text-align: left;
	padding-top: 4px;
}

.searchSub {
	background: url(./images/bg_searchsub.gif);
	border: 1px solid #d17528;
	width: 80px;
	padding-top: 2px;
	font-weight: bold;
	color: #fff;
}

#Page td {
	font-size: 12px;
	line-height: 200%;
}

#List td {
	font-size: 12px;
	line-height: 220% !important;
	line-height: 150%;
}

#List td a {
	color: #0000ba;
	text-decoration: none;
}

#List td a:hover {
	color: red;
	text-decoration: underline;
}

.search {
	width: 99%;
	height: 62px;
	border-bottom: 1px solid #adc1dc;
	margin: 0 auto 2px auto;
	background: url(./images/bg_search.gif);
	font-size: 12px;
}

form {
	margin: 0px;
}

.copyright {
	font-size: 12px;
	width: 99%;
	border: 1px solid #EFF2FA;
	padding-top: 20px;
	padding-bottom: 20px;
	text-align: center;
	background-color: #EFF2FA;
}

.result_message {
	font-size: 12px;
	border: 0px solid #003300;
	height: 200px;
	width: 99%;
	text-align: center;
}

.result_message img {
	margin: 20px 20px 20px 200px;
}

.result_message label {
	color: #FF6F02;
}

.float_left {
	float: left;
}

.page_navigation {
	
}

.page_navigation a {
	margin: 2px;
	padding: 2px;
	text-decoration: none;
	color: #100EB0;
	font-size: 14px;
}

.page_navigation a:hover {
	text-decoration: underline;
	color: #FF0000;
}

.page_navigation label {
	margin: 2px;
	padding: 2px;
}

.page_navigation b {
	color: #FF0000;
	margin: 2px;
	padding: 2px;
	font-size: 14px;
}

.page_navigation input {
	border: 1px solid #ADC1DC;
}

.goto_button {
	height: 20px;
	width: 36px;
	border: 1px solid #ADC1DC;
	color: #006E0B;
	padding: 2px;
	background-color: #FFFFFF;
	background-image: url(images/bg_sort.gif);
	cursor: pointer;
}

.isNewBook {
	font-size: 14px;
	color: #FF0000;
	font-weight: bold;
}

.isNewBookNomal {
	font-size: 14px;
}

.belivePress {
	display: none;
	position: absolute;
	padding: 2px;
	width: 120px;
	height: auto;
	background-color: #C7D5E9;
	border: 1px solid #ADC1DC;
}

.belivePress a {
	float: left;
	padding: 2px;
	width: 100%;
	color: #000000;
	text-align: left;
	font-size: 14px;
}

.belivePress a:hover {
	background-color: #FDDA96;
	color: #FF0000;
}

.distrustKeywords {
	display: none;
	position: absolute;
	padding: 2px;
	width: 120px;
	height: auto;
	background-color: #C7D5E9;
	border: 1px solid #ADC1DC;
}

.distrustKeywords a {
	float: left;
	padding: 2px;
	width: 100%;
	color: #000000;
	text-align: left;
	font-size: 14px;
}

.distrustKeywords a:hover {
	background-color: #FDDA96;
	color: #FF0000;
}

/* 主菜单面板 */
.mainMenuPanel {
	margin: auto;
	padding: 4px 4px 0px 4px;
	height: 18px;
	width: auto;
	text-align: left;
	font-size: 12px;
	border-bottom: 1px solid #E6E6E6;
	background-color: #ECECEC;
}

.menuItemSel {
	color: #FF0000;
	font-weight: bold;
}

/* 业务模块面板 */
.modulePanel {
	margin: 2px 0px 0px 0px;
	padding-top: 2px;
	width: 99%;
	height: 34px;
	border-bottom: 1px solid #adc1dc;
	font-size: 14px;
	line-height: 30px;
	text-align: left;
	background-color: #E1EAF6;
}

.modulePanelItem {
	float: left;
	border: 1px dashed #ADC1DC;
	margin-left: 2px;
	padding: 0px 4px 0px 4px;
	color: #000000;
	text-decoration: none;
}

.modulePanelItem:hover {
	color: white;
	text-decoration: none;
	background-color: #ACC3DF;
}

.modulePanelItemSel {
	float: left;
	border: 1px dashed #ADC1DC;
	margin-left: 2px;
	padding: 0px 4px 0px 4px;
	color: #FFFFFF;
	font-weight: bold;
	text-decoration: none;
	background-color: #ADC1DC;
}

.modulePanelItemSel:hover {
	color: #FFFFFF;
	text-decoration: none;
	background-color: #ACC3DF;
}


  
</style>
</head>
<script type="text/javascript">
    function $search(id){return document.getElementById(id);}
    
    var m_isCheckAll = false;
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('shopIds[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }
    
      function doAdd()
    {
        $search('act').value = "Add";
        $search('frmSearch').submit();
    }
    
    
      function doDelete(shopId)
    {
      
        var elements = document.getElementsByName('shopIds[]');

        if(shopId != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == shopId);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再执行审核操作！");return;
        }
        if((shopId == null) && (!confirm("确定进行批评删除!"))){return;}
        $search('act').value = "Delete";
        $search('frmSearch').submit();
    }
</script>


<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>

<a href="trust_book_manage.jsp" class="menuItemSel">管理信任书店</a>
</div>



<form name="frmSearch" id="frmSearch" method="post" action="" >
<input type="hidden" id="act" name="act" value="<%=act%>" />
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0">
  <tr>
   
    <td height="26" align="left" valign="bottom">
          书店编号:
    <input type="text" id="queryShopId" name="queryShopId" size="40" maxlength="650" value="<%=queryShopId%>" title="<%=queryShopId%>" />
  
    <input type="submit" value="搜 索" class="searchSub" onclick="initSearchForm()"/>
 
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      书店编号:<input type="text" id="addShopId" name="addShopId" size="40" maxlength="650" value="<%=addShopId%>" title="<%=addShopId%>" />
    <input type="button" value="添加信任书店" onclick="doAdd()" />
  
    </td>
  </tr>
  
</table>

</div>


<%if("".equals(serverStatus)){%>

<div align="left" style="padding:5px 2px 0px 2px;width:98%;font-size:13px;">
    <input type="button" value="全选" onclick="checkAll(true)" />
    <input type="button" value="全否" onclick="checkAll(false)" />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <input type="button" value="   删除   " onclick="doDelete()" />
</div>

<table align="center" border=0 width="98%" id="Page">
    <tr>
        <td height="28" align="left">
            <font color='#666666'><b> 查询到信任书店总数：</b> </font> <font color='#0000ff'><%=totalShopCount %></font>个&nbsp;&nbsp;
         </td>                    
    </tr>
</table>

<!--页码导航结束-->

<div>
    <table width="98%" bgcolor="#FFFFFF" align="center" border="0" cellspacing="1"
    cellpadding="0" id="List">
        <tr height="30" align="center">
            <td bgcolor="#D8D8D8" width="3%">
                <img src="./images/smile.gif" id="smile" title="Ahoy!" onclick="checkAll(!m_isCheckAll)" style="cursor:pointer" />
            </td>
            <td bgcolor="#D8D8D8" width="20%"> 书店编号 </td>
            <td bgcolor="#D8D8D8" width="60%"> 书店名称 </td>
            <td bgcolor="#D8D8D8" width=""> 操作 </td>   
        </tr>
    </table>
   
    <table width="98%" bgcolor="#FFFFFF" align="center" border="0" cellspacing="1"  cellpadding="0" id="List">
    <% for (Map<String, Object> shop: trustShops){ %>
     <tr bgcolor="#EFEFEF">
            <td width="3%">
                <input type="checkbox" name="shopIds[]" value="<%=shop.get("shopId") %>"/>
            </td>
            <td width="20%"><%=shop.get("shopId") %>&nbsp;</td>
            <td width="60%">
                <a href="http://shop.kongfz.com/book/<%=shop.get("shopId") %>/" target="_blank" title="<%=shop.get("shopName") %>"> <%=shop.get("shopName") %></a>
            </td>
            <td>
                <a href="javascript:doDelete(<%=shop.get("shopId")%>)">删除</a>
            </td> 
        </tr>
    <% } %>
        
    </table>
</div>
<%} else { %>
	<%=serverStatus%>		
<%}%>



</form>

<div class="copyright"><label>版权所有(C)2002-2010 孔夫子旧书网</label></div>

</body>
</html>
