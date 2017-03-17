<%@ page language="java" %>
<%@ page pageEncoding="gbk" %>
<%@ page contentType="text/html; charset=gbk" %>
<%@ page import="java.util.*" %>
<%@ page import="java.rmi.Naming" %>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%

/****************************************************************************
 * ����ҳ���������
 ****************************************************************************/
//����ҳ����ʹ��UTF-8����
request.setCharacterEncoding("gbk");
response.setCharacterEncoding("gbk");

String query = StringUtils.strVal(request.getParameter("query"));
try{
    query = new String(query.getBytes("ISO8859_1"), "gbk");
}catch(Exception e){
    System.out.println(e);
}

// ����Suggest������ȡ��Suggest�б�
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

// ��֯JavaScript�ű�����
StringBuffer contents = new StringBuffer();
contents.append("var sugWords = [");// sugWords����ɿͻ��˶���ʹ���
if (null != suggestList && suggestList.size() > 0) {
    contents.append("\"" + StringUtils.join("\",\"", suggestList) + "\"");
}
contents.append("];");

// ���JavaScript�ű�����
out.println(contents.toString());

%>
