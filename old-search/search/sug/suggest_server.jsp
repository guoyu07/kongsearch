<%@ page language="java" %>
<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.util.*" %>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%

/****************************************************************************
 * 接收页面请求参数
 ****************************************************************************/
//设置页面中使用UTF-8编码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

String query = StringUtils.strVal(request.getParameter("query"));
try{
    query = new String(query.getBytes("ISO8859_1"), "UTF-8");
}catch(Exception e){
    System.out.println(e);
}

// 调用Suggest服务器取得Suggest列表
ServiceInterface server = null;
try {
    server = (ServiceInterface) Naming.lookup("rmi://192.168.1.3:9071/QuerySuggestService");
} catch (Exception e) {
    System.out.println(e);
}
List<String> suggestList = null;
if (null != server) {
    Map resultSet = null;
    Map<String, Object> parameters = new HashMap<String, Object>();
    parameters.put("keyword", query);
    try {
        resultSet = server.work("QuerySuggest", parameters);
    } catch (Exception e) {
        System.out.println(e);
    }
    if (null != resultSet) {
        suggestList = (List<String>) resultSet.get("suggestList");
    }
}

// 组织JavaScript脚本内容
StringBuffer contents = new StringBuffer();
contents.append("var sugWords = [");// sugWords亦可由客户端定义和传递
if (null != suggestList && suggestList.size() > 0) {
    contents.append("\"" + StringUtils.join("\",\"", suggestList) + "\"");
}
contents.append("];");

// 输出JavaScript脚本内容
out.println(contents.toString());

%>
