<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ include file="cls_keywordFinal.jsp"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.sql.Statement"%>
<%@ page import="java.sql.SQLException"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.util.TreeMap"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.Iterator"%>
<%@ page import="org.json.JSONObject"%>

<%!
/**
 * 定义Ajax使用类
 */
public class SearchReadKeywordsAjax {
	
	public SearchReadKeywordsAjax(){
		newConnection();//加载数据库连接
		if(typeAndTable.size() <= 0){
			//级别就查询分类表
			typeAndTable.put("level",KeywordFinal.groupName);
			//分类就查询关键字表
			typeAndTable.put("group",KeywordFinal.keywordName);
		}
	}
	
	private Statement st = null;
	
	private Map<String,String> typeAndTable = new HashMap<String,String>();
	
	/**
	 * 创建数据库连接
	 */
	private synchronized void newConnection() {
		if (st == null) {
			try {
				Class.forName("com.mysql.jdbc.Driver");
				String url = "jdbc:mysql://" + KeywordFinal.host + ":" + KeywordFinal.port + "/"
						+ KeywordFinal.dataSourceName + "?useUnicode=true&characterEncoding=UTF-8";
				Connection conn = DriverManager.getConnection(url, KeywordFinal.username, KeywordFinal.password);
				st = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
	}
	
	/**
	 * 根据级别查询该级别下所有的关键词分类
	 * @param level
	 * @return json字符串
	 */
	public String findAllGroupByValues(String val,String type) {
		String json = "";
		try {
			//根据类型得到SQL并执行
			ResultSet rs = st.executeQuery(getSQL(type,val));
			json = parseJson(rs,type);//将结果集转换成json
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return json;
	}
	
	/**
	 * 根据级别查询该级别下所有的关键词分类，不使用JSON方式返回
	 * @param level
	 * @return map
	 */
	public Map<String, String> findAllGroupNotJSONByValues(String val,String type){
		Map<String, String> list = null;
		try {
			//根据类型得到SQL并执行
			ResultSet rs = st.executeQuery(getSQL(type,val));
			list = parseMap(rs,type);//将结果集转换成map
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return list;
	}
	
	/** 
	* 得到查询SQL语句
	* @param type 类别
	* @param val 选中的值
	*/
	private String getSQL(String type,String val){
		String sql = "";
		if(type.equals("level")){//级别查询
			sql = "select groupId,groupName from " + typeAndTable.get(type) + " where groupLevel = " + val;
		} else {//分类查询
			sql = "select id,keywords from "+typeAndTable.get(type)+" where groupId = "+val;
		}
		System.out.println(sql);
		return sql;
	}
	
	/** 
	* 将查询结果转换成json
	* @param rs 查询结果
	* @param type 类别
	*/
	private String parseJson(ResultSet rs,String type){
		String json = "";
		try{
			Map<String, String> list = parseMap(rs,type);
			if (null != list && list.size() > 0) {
				JSONObject j = new JSONObject(list);
				json = j.toString();
			}
		}catch(Exception e){
			e.printStackTrace();
		}
		return json;
	}
	
	/** 
	* 将查询结果转换成map
	* @param rs 查询结果
	* @param type 类别
	*/
	private Map<String, String> parseMap(ResultSet rs,String type){
		Map<String, String> list = null;
		try{
			while (rs.next()) {
				if (list == null)
					list = new TreeMap<String, String>();
				if(type.equals("level")){//级别查询
					list.put(rs.getString("groupId"), rs.getString("groupName"));
				} else {//分类查询
					list.put(rs.getString("id"), rs.getString("keywords"));
				}
			}
		}catch(SQLException e){
			e.printStackTrace();
		}
		return list;
	}
}
%>

<%//定义servlet请求处理函数
String result = "";
String val = request.getParameter("val");//得到当前选择框的值
String type = request.getParameter("domType");//得到当前选择框的类型
if(val != null && val != "" && val.length() > 0 && type != null && type != "" && type.length() > 0){
	SearchReadKeywordsAjax ajax = new SearchReadKeywordsAjax();
	result = ajax.findAllGroupByValues(val,type);
}
%>
<%=result.trim()%>