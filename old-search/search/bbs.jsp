<%@ page contentType="text/html; charset=GBK" language="java" %>
<%

String query = (String) request.getParameter("query");
try{
    if(query == null) { query = ""; }
	String flag = (String) request.getParameter("flag");
	if(flag != null && flag.equals("index")){
		query = new String(query.getBytes("ISO_8859_1"),"GBK");
		query = java.net.URLEncoder.encode(query,"UTF-8");
	}else{
		query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
		query = java.net.URLEncoder.encode(query,"UTF-8");
	}
}catch(Exception ex){
	query = "";
}

String category = (String) request.getParameter("category");
if(category == null || category.equals("")){
	category = "";
}

String target="forum.jsp?query="+query+"&category="+category;
response.sendRedirect(target);

%>