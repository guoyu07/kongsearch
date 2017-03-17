<%@ page contentType="text/html; charset=utf-8" language="java" %>
<%

if(request.getMethod().equals("GET"))
{
    String queryStr = request.getQueryString();
    String target="auction.jsp?"+queryStr;
    out.println(queryStr);
    response.sendRedirect(target);
}
else
{
    String query = (String) request.getParameter("content");
    try{
        if(query == null) { query=""; }
        query = new String(query.getBytes("ISO_8859_1"),"UTF-8");
        query = java.net.URLEncoder.encode(query,"UTF-8");
    }catch(Exception e){
        e.printStackTrace();
        query="";
    }
    String target="auction.jsp?query="+query;
    out.println(query);
    response.sendRedirect(target);
}

%>