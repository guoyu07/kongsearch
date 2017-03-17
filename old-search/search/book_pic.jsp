<%@ page contentType="text/html; charset=utf-8" language="java" %>
<%
String queryStr = "";
if(request.getMethod().equals("GET"))
{
    queryStr = request.getQueryString();
    out.println(queryStr);
}
String target="book.jsp?"+queryStr;
response.sendRedirect(target);
%>
