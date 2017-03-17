<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ include file="cls_ajax_keyword.jsp"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.sql.Statement"%>
<%@ page import="java.sql.SQLException"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.util.TreeMap"%>
<%@ page import="java.util.Iterator"%>
<%@ page import="java.net.URLDecoder"%>
<%@ page import="java.net.URLEncoder"%>

<%!
/**
 * 关键字使用类
 */
public class SearchReadKeywords {
	/**
	 * 得到所有的分类级别,需要进行审核但不影响上书的级别
	 * @return
	 */
	public Map<String, String> findAllGroupLevel() {
		Map<String, String> level = new TreeMap<String, String>();
		level.put("0", "一审需人工审核关键词");
		level.put("1", "二审复查关键词库(一级)");
		level.put("2", "二审复查关键词库(二级)");
		level.put("3", "二审复查关键词库(三级)");
		/**
		level.put("4", "用户注册关键词");
		level.put("5", "上书屏蔽关键词");
		level.put("6", "消息屏蔽关键词");
		level.put("7", "未开放分类一");
		level.put("8", "未开放分类二");
		level.put("9", "未开放分类三");
		*/
		return level;
	}
}
%>

<%
//处理请求中文乱码
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");

/* ################################################################# */
/* ##################### 类     定     义     完     成 ####################### */
/* ################################################################# */
String shape = request.getParameter("showShape");//显示方式
SearchReadKeywords key = new SearchReadKeywords();
Map<String, String> level = key.findAllGroupLevel();
//得到key的迭代器
Iterator<String> keys = level.keySet().iterator();
String tmpKey = "";
%>
<%if(shape == "" || shape.equals("dialog")){%>
<div>
	　选中分类：<lable name="search_group_info_select_dom_lable">无</lable>
	<span style="float: right;">
		<a href="javascript:void(0);" name="search_group_info_select_dom_backgroung_index" arrtNet="backgroung" attrVal="">无选项</a>
		<!-- 
			<a href="javascript:void(0);" name="search_group_info_select_dom_outer_net_index" attrNet="index" attrVal="">无选项</a>
		 -->
	</span>
	<br/>
	选中关键字：<lable name="search_key_word_select_dom_lable">无</lable>
	<span style="float: right;">
		<a href="javascript:void(0);" name="search_key_word_select_dom_outer_net_index" attrNet="index" attrVal="">无选项</a>
		<a href="javascript:void(0);" name="search_key_word_select_dom_backgroung_index" arrtNet="backgroung" attrVal="">无选项</a>
	</span>
</div>
<hr/>
<div>
	<!-- 分类级别 -->
	关键字分类： <select style="width:200px;" id="search_group_level_select_dom"
		name="search_group_level_select_dom"
		childName="search_group_info_select_dom" domType="level">
		<option value="">--请选择--</option>
		<%while(keys.hasNext()){tmpKey = keys.next();%>
		<option value="<%=tmpKey%>"><%=tmpKey%> -
			<%=level.get(tmpKey)%></option>
		<%}%>
	</select>
	<!-- 关键字分类 -->
	<select style="width:200px;" id="search_group_info_select_dom"
		name="search_group_info_select_dom"
		childName="search_key_word_select_dom" domType="group">
		<option value="">--请选择--</option>
	</select> <br />
	<!-- 关键字 -->
	可疑关键字： <select style="width:200px;" id="search_key_word_select_dom"
		name="search_key_word_select_dom" domType="key">
		<option value="">--请选择--</option>
	</select>
</div>
<%} else {%>

<%/** 该模式下为非弹出 */
String defaultLevel = request.getParameter("defaultLevel");//默认选中的级别,改值存在，则不显示级别选择框
String showName = request.getParameter("showKeywordsDomIDName");//显示控件的ID
String backgroung = request.getParameter("searchKeywordBackgroungFnName");//回调函数
String groupLevel = request.getParameter("level");//之前选中的分类级别
String act = request.getParameter("act");//是否需要主动查询分类下的级别[0 : not,1 : need]
String groupId = request.getParameter("groupId");//之前选中的分类ID
String searchType = request.getParameter("searchType");//外网检索点击类型
String hiddenThreeOption = request.getParameter("hiddenThreeOption");//第三级选项中的隐藏值
String backgroungFnType = request.getParameter("searchBackgroungFnType");//回调类型[group = 二级回调,key = 三级回调]

Map<String, String> groupInfoList = null;
if(act.equals("1")){//需要主动加载分类
//	SearchReadKeywordsAjax ajax = new SearchReadKeywordsAjax();
	if(!defaultLevel.equals("")){
		groupLevel = defaultLevel;//默认级别高于手选级别
	}
//	groupInfoList = ajax.findAllGroupNotJSONByValues(groupLevel,"level");//因为是非弹出模式，所以只有分类跟级别
}
String threeOption = request.getParameter("threeOption");//第三级的选项html

try {
	threeOption = URLDecoder.decode(threeOption, "UTF-8");
	hiddenThreeOption = URLDecoder.decode(hiddenThreeOption, "UTF-8");
} catch (Exception e) {
	e.printStackTrace();
}
%>
<input type="hidden" name="showKeywordsDomIDName" value="<%=(showName != null ? showName : "")%>"/>
<input type="hidden" name="searchKeywordBackgroungFnName" value="<%=(backgroung != null ? backgroung : "")%>"/>
<input type="hidden" name="searchKeywordBackgroungFnType" value="<%=(backgroungFnType != null ? backgroungFnType : "")%>"/>
关键分类：
<%if(defaultLevel.equals("")){%>
	<!-- 分类级别 -->
	<select style="width:190px;" id="search_group_level_select_dom"
		name="search_group_level_select_dom"
		childName="search_group_info_select_dom" domType="level">
		<option value="">--请选择--</option>
		<%while(keys.hasNext()){tmpKey = keys.next();%>
			<%if(groupLevel.equals(tmpKey)){%>
				<option value="<%=tmpKey%>" selected="selected"><%=tmpKey%> - <%=level.get(tmpKey)%></option>
			<%} else {%>
				<option value="<%=tmpKey%>"><%=tmpKey%> - <%=level.get(tmpKey)%></option>
			<%}%>
		<%}%>
	</select>
<%} else {%>
	<!-- 有默认选中的级别，取默认级别 -->
	<input type="hidden" name="searchKeywordDefaultLevelID" value="<%=(defaultLevel != null ? defaultLevel : "")%>"/>
<%}%>
	<input type="hidden" name="searchTypeOnlineQuery" value="<%=(searchType != null ? searchType : "")%>"/>
	<!-- 关键字分类 -->
	<select style="width:170px;" id="search_group_info_select_dom"
		name="search_group_info_select_dom"
		childName="search_key_word_select_dom" domType="group">
		<option value="">--请选择--</option>
		<%if(act.equals("1") && groupInfoList != null && groupInfoList.size() > 0){
			keys = groupInfoList.keySet().iterator();
			while(keys.hasNext()){tmpKey = keys.next();if(!"".equals(groupId) && tmpKey.equals(groupId)){%>
				<option value="<%=tmpKey%>" selected="selected"><%=groupInfoList.get(tmpKey)%></option>
			<%} else {%>
				<option value="<%=tmpKey%>"><%=groupInfoList.get(tmpKey)%></option>
		<%}}}%>
	</select>
	<input type="hidden" name="search_group_info_find_all_keyword_none_info_value_dom_hidden" value="<%=hiddenThreeOption%>"/>
	<select id="search_group_info_find_all_keyword_none_info" name="search_group_info_find_all_keyword_none_info" style="width:98px;">
		<option value="">--请选择--</option>
		<%=threeOption%>
	</select>
	<%if(searchType != null && !searchType.equals("")){%>
	<a href="javascript:void(0);" name="search_group_info_three_selected_online_ck" searchType="<%=searchType%>">外网检索</a>
	<%}%>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>
<script type="text/javascript" src="<%=basePath%>js/jquery.min.js"></script>
<!-- 引入所有的关键字 -->
<script type="text/javascript" src="<%=basePath%>admin/distrust_keywords.js?_=new Date()"></script>
<script type="text/javascript">
jQuery(function($){
	//关键字数组存在，并且当前需要主动加载
	if(m_distrustKeywords != undefined && m_distrustKeywords != null && m_distrustKeywords.length > 0 && "<%=act%>" == "1"){
		initiativeFindAllGroupInfo();
	}
	
	//外网检索click事件
	$("[name='search_group_info_three_selected_online_ck']").die();
	$("[name='search_group_info_three_selected_online_ck']").live("click",function(){
		var _this = $(this),queryTemplate = {};
		var netIndexQueryTemplate = {shop:{url:"http://search.kongfz.com/product/z[whereCondition]y2/",decode:true},
				auction:{url:"http://search.kongfz.com/auction.jsp?query=[whereCondition]",decode:false}};
		//得到检索路径
		if("shop" == _this.attr("searchType")){
			queryTemplate = netIndexQueryTemplate.shop;
		} else if ("auction" == _this.attr("searchType")){
			queryTemplate = netIndexQueryTemplate.auction;
		}

		var allKeywordVal = $("[name='search_group_info_find_all_keyword_none_info']").val();
		allKeywordVal = allKeywordVal.replace(/(^\s*|\s*$)/, '');
		if (allKeywordVal != "" && allKeywordVal.length > 0) {
			var url = (queryTemplate.url).replace("[whereCondition]", (queryTemplate.decode ? toUnicode(allKeywordVal) : allKeywordVal));
//			var url = queryTemplateURL.replace("[whereCondition]", toUnicode(allKeywordVal));
			self.open(url);
		}
	});
	
	//主动加载分类数据
	function initiativeFindAllGroupInfo(){
		var groupInfo = $("[name='search_group_info_select_dom']");
		var html = "<option value=''>--请选择--</option>";
		for(var i = 0; i < m_distrustKeywords.length; i++){
			if(m_distrustKeywords[i].level == "<%=groupLevel%>"){
				if(m_distrustKeywords[i].id == "<%=groupId%>"){
					html += "<option value='"+m_distrustKeywords[i].id+"' selected='selected'>"+m_distrustKeywords[i].name+"</option>";
				} else {
					html += "<option value='"+m_distrustKeywords[i].id+"'>"+m_distrustKeywords[i].name+"</option>";
				}
			}
		}
		groupInfo.html(html);
	}
	
	//将字符转换成unicode代码
	function toUnicode(str) {
		if (!str) return;
	    var unicode = '', i = 0, len = (str = '' + str).length;
		for (; i < len; i ++) {
			unicode += 'k' + str.charCodeAt(i).toString(16).toLowerCase();
		}
		return unicode;
	}
});
</script>
	
	
<%}%>
