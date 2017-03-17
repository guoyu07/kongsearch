<%@ page contentType="text/html; charset=utf-8" language="java" %>
<%

if(request.getMethod().equals("GET"))
{
	String queryStr = request.getQueryString();
    out.println(queryStr);
	String target="auction.jsp?"+queryStr;
	response.sendRedirect(target);
}
else
{
	String query = (String) request.getParameter("content");
	try{
        if(query == null) { query = ""; }
		query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
		query = java.net.URLEncoder.encode(query,"UTF-8");
	}catch(Exception e){
		e.printStackTrace();
		query="";
	}
    out.println(query);
	String target="auction.jsp?query="+query;
	response.sendRedirect(target);
}

%>