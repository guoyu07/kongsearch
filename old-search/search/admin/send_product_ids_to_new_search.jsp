<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%@ page import="com.kongfz.neo.search.interfaces.INeoSearchBookVerify" %>
<%@ page import="com.kongfz.neo.search.impl.NeoSearchBookVerify" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.FileNotFoundException" %>
<%@ page import="java.io.FileReader" %>
<%@ page import="java.io.IOException" %>

<%!

/****************************************************************/
/*******************修复指定文件中的ID数据*************************/
/*****************（不可对审核组开放当前文件）**********************/
/****************************************************************/

public class VerifyNewSearch {
	
	public void verify(String itemId) {
		String[] itemIds = itemId.split(",");
		
		ArrayList logList = new ArrayList();
		
		HashMap<String,String> has = null;
		
		//创建新搜索审核实例
		INeoSearchBookVerify neoSearch = new NeoSearchBookVerify();
		
		for (String str : itemIds) {
			String[] attr = str.trim().split("=");
			has = new HashMap<String,String>();
			has.put("itemId",attr[0].trim());
			has.put("bizType",attr[1].trim());
			logList.add(has);
			if (logList.size() >= 200) {
				neoSearch.work("Approve",logList,"itemId","bizType","AUTO");
				logList.clear();
			}
		}
		
		//当前值发送通过的请求
		neoSearch.work("Approve",logList,"itemId","bizType","AUTO");
	}
	
	public int read(String fileName){
		int count = 0;
		try {
			BufferedReader read = new BufferedReader(new FileReader(new File(fileName)));
			String line = null;
			while ((line = read.readLine()) != null) {
				if (line.indexOf("{") > 0 && line.indexOf("}") > 0) {
					line = line.substring(line.indexOf("{") + 1,line.indexOf("}"));
					this.verify(line);
					count++;
				}
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return count;
	}
}
%>

<%
VerifyNewSearch v = new VerifyNewSearch();

String fileName = "/data/webroot/search/admin/1.txt";

int count = v.read(fileName);

out.write("执行完成，总共执行审核  "+count+"  次...");
%>
