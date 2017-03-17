<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="com.kongfz.sphinx.script.IScript" %>
<%@ page import="com.kongfz.sphinx.script.AnalyzerScript" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils"%>
<%@ page import="java.util.HashMap"%>

<%
    /****************************************************************************
     * 设置页面中使用UTF-8编码
     ****************************************************************************/
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String keyword = StringUtils.strVal(request.getParameter("keyword"));
    String result = "";
    if (null != keyword && !"".equals(keyword.trim())) {
	    IScript script = new AnalyzerScript();
	    HashMap<String,String> hs = new HashMap<String,String>();
	    hs.put("keyword",keyword.trim());
	    hs = script.execute(hs);
	    if (hs != null && hs.size() > 0) {
	    	result = hs.get("keyword");
	    	String[] rs = result.split(";");
	    	result = "[";
	    	for (String k : rs) {
	    		if (null != k && !"".equals(k.trim()))
	    			result += k + ",  ";
	    	}
	    	result += "]";
	    } else {
	    	result = "无法正常获取分词结果。";
	    }
    }
%>
<!doctype html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>分词测试</title>
	</head>

	<body>
		<a href="/admin/index.jsp" style="color: blue;">返回首页</a><hr/>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;关键词：<b><%=keyword%></b><br/>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;分词结果：<b><%=result%></b><hr/>		
<form action="" method="post">
			关键字：<input name="keyword" style="width:300px;"/>
			<input type="submit" value="查验分词结果">
		</form>
	</body>
</html>
