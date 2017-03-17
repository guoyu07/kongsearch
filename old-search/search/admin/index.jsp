<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%
String site = "notlocal";
String[] keys = {"Doth14vr5zgpCVRhhvQNBUERwtxynAfN","JxAGtMKEPCcC1EtnxVYXSz2a1L2iWm3W", "mgsQeJOMMaTuoMNMhddyoR8lciJkDVRF", "jg7pDmfrLhH9r3Wqb8F9lKsn4vCrDsTb","Ndws8VDWpb7Ktkc0ugNIbnhBemHa1Zvo"};

//重定向到PHP页面取回session id
String remoteSessionId = (String) request.getParameter("code");
if(remoteSessionId == null || remoteSessionId.equals("")){
    String selfUrl = request.getRequestURL().toString();
    String sign = StringUtils.Md5Encode("url="+selfUrl+keys[new Random().nextInt(5)]);
    if(selfUrl != null){ selfUrl = java.net.URLEncoder.encode(selfUrl,"UTF-8"); }
    if(site.equals("local")){
        response.sendRedirect("http://xiesht.v2.local/post_session_id.php?url="+selfUrl);
    }else{
        response.sendRedirect("http://user.kongfz.com/index.php?m=Interface&c=session&a=post&url="+selfUrl+"&requestSignForPostSessionId="+sign);
    }
    return;
}

MemcachedSession MemSession = new MemcachedSession(session, request, response, out, true);

String username = MemSession.get("adminName");//用于网站管理员登录
if(!MemSession.isLogin("admin")){
    if(site.equals("local")){
        response.sendRedirect("http://xiesht.v2.local/admin/login.php");//后台管理员登录
    }else{
        //response.sendRedirect("http://pm.kongfz.com/admin/login.php");//后台管理员登录
        response.sendRedirect("http://common.m.kongfz.com/login.php");//后台管理员登录
    }
    return;
}

//判断管理员权限
//String[] permission = new String[]{"manageIndex", "manAuctioneer"};
Map<String, String> permissionMap = new LinkedHashMap<String, String>();
//permissionMap.put("docBaseManage","<a href=\"doc_base_manage.jsp\">已审核图书管理系统</a>");
permissionMap.put("docBaseManage","<a href=\"new_sphinx/new_sphinx_doc_base_manage.jsp\">已审核图书管理系统【新】</a>");
permissionMap.put("bookVerifyManage","<a href=\"book_verify_manage.jsp\">待审图书管理系统</a>");
permissionMap.put("auctionManage","<a href=\"auction_manage.jsp\">管理拍品索引</a>");
permissionMap.put("forumManage","<a href=\"forum_manage.jsp\">管理论坛索引</a>");
permissionMap.put("suggestIndexManage","<a href=\"suggest_index_manage.jsp\">管理查询建议词库</a>");
permissionMap.put("bookLibraryManage","<a href=\"book_library_manage.jsp\">管理图书资料库</a>");
permissionMap.put("verifyLogManage","<a href=\"verify_log_manage.jsp\">图书审核日志查询</a>");
permissionMap.put("auctionLogManage","<a href=\"auction_log_manage.jsp\">拍品审核日志查询</a>");
permissionMap.put("indexBoostManage","<a href=\"index_boost_manage.jsp\">管理图书索引权重</a>");
// added for bug5590 by zhouyun
permissionMap.put("singleBookVerifyManage","<a href=\"single_book_verify_manage.jsp\">单本图书审核</a>");
// added END
permissionMap.put("indexSetting","<a href=\"setting.jsp\">设置...</a>");
String[] personPermission = MemSession.get("adminAllowOperation").split(",");
boolean f = false;
for(String s:personPermission){
	if(permissionMap.containsKey(s)){
		f = true;
		break;
	}
}
if(!f){
    out.write("您无权限使用此页面。");
    return;
}

// 管理员真实姓名
String adminRealName = MemSession.get("adminRealName");
%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>后台管理首页—孔夫子旧书搜索——全球最大旧书搜索引擎</title>
</head>
<style type="text/css">
form{
margin:0px;
}
.mainbody{
width:970px;
}
.login_box{
text-align:center;
border-top:2px solid #E17825;
border-bottom:1px solid #FBDA97;
border-left:1px solid #FBDA97;
border-right:1px solid #FBDA97;
margin-top:50px;
margin-left:300px;
width:400px;
height:185px;
font-size:13px;
}

.login_box div{
margin:2px;
}

.input_button{
width:200px;
height:18px;
font-size:13px;
border:1px solid #FBDA97;
}
.login_button{
margin-top:5px;
margin-bottom:5px;
width:85px;
height:25px;
padding:2px;
background-image:url(./images/bg_searchsub.gif);
border:1px solid #FBDA97;
}

.funcMenu{
height:50px;
border:1px solid #AEC2DC;
text-align:center;
padding:2px;
}
.funcMenu a{
float:left;
height:12px;
width:100%;
border:1px solid #AEC2DC;
padding:5px 0px 5px 0px;
margin-bottom:2px;
font-size:14px;
text-decoration:none;
color:#000000;
background-color:#E1EAF6;
}
.funcMenu a:hover{
color:#0000FF;
font-weight:bold;
border:1px solid #E17825;
background-color:#FBDA97;
}
.yellowButton{ 
background:url(./images/bg_searchsub.gif); 
border:1px solid #d17528; 
padding-top:2px; 
font-weight:bold; 
color:#fff;
}

</style>
<body>
<div class="mainbody">
<div class="login_box">
<img src="../images/logo08_com.jpg" />
<!--功能菜单-->
<div class="funcMenu">
<div style="text-align:right;">当前登录用户：<%=adminRealName %></div>
<hr/>
<div style="text-align:left;">功能菜单：</div>
<%for (String s : personPermission) {%>
	<%if ("verifyLogManage".equalsIgnoreCase(s.trim())) {%>
		<div><%=permissionMap.get("verifyLogManage")%></div>
	<%continue;}%>
	
	<%if ("auctionLogManage".equalsIgnoreCase(s.trim())) {%>
		<div><%=permissionMap.get("auctionLogManage")%></div>
	<%continue;}%>
	
	<%if ("forumManage".equalsIgnoreCase(s.trim())) {%>
		<div><%=permissionMap.get("forumManage")%></div>
	<%continue;}%>
	
	<%if ("suggestIndexManage".equalsIgnoreCase(s.trim())) {%>
		<div><%=permissionMap.get("suggestIndexManage")%></div>
	<%continue;}%>
	
	<%if ("singleBookVerifyManage".equalsIgnoreCase(s.trim())) {%>
		<div><%=permissionMap.get("singleBookVerifyManage")%></div>
	<%continue;}%>
<%}%>



<%if ("tangjunfeng".equals(username.trim())) {%>
		<div></div>
		<div><b>相关测试脚本</b></div>
		<div><a href="scripts/analyzer.jsp">分词脚本</a></div>
		<div><%=permissionMap.get("docBaseManage")%></div>
		<div><%=permissionMap.get("bookVerifyManage")%></div>
		<div><%=permissionMap.get("auctionManage")%></div>
		<div><%=permissionMap.get("bookLibraryManage")%></div>
		<div><%=permissionMap.get("indexBoostManage")%></div>
		<div><%=permissionMap.get("indexSetting")%></div>
<%}%>

<div><input type="button" class="yellowButton" value="返回搜索首页" onclick="location.href='../'" /></div>
</div>
</body>
</html>
