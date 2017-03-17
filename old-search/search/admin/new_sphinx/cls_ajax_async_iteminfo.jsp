<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>

<%@ page import="java.util.HashMap"%>
<%@ page import="com.kongfz.sphinx.ajax.AjaxItemInfoController"%>

<%!
/**
* 异步调用得到商品信息
*/
public class AjaxAsyncItemInfo {
	
	/**
	* 得到商品详情
	*/
	public String getImteDescByInfo(HashMap<String, String> params){
		String result = "";
		if (params != null && params.size() > 0) {
			//必选参数全部存在
			if (params.containsKey("userid") && params.containsKey("itemid") && params.containsKey("saleStatus")) {
				AjaxItemInfoController ajaxService = new AjaxItemInfoController();
				result = ajaxService.ajaxGetItemDescByItemId(params);
			}
		}
		return result;
	}
}
%>

<%
String userid = request.getParameter("userid");
String itemid = request.getParameter("itemid");
String saleStatus = request.getParameter("saleStatus");
String result = "";
if (!"".equals(userid) && !"".equals(itemid) && !"".equals(saleStatus)) {
	HashMap<String,String> params = new HashMap<String,String>();
	params.put("userid",userid);
	params.put("itemid",itemid);
	params.put("saleStatus",saleStatus);
	AjaxAsyncItemInfo asyncItem = new AjaxAsyncItemInfo();
	result = asyncItem.getImteDescByInfo(params);
}
%>
<%=result.trim()%>
