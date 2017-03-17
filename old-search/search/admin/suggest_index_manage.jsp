<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.util.io.SimpleTemplate"%>
<%@ include file="cls_memcached_session.jsp"%>
<%!

    /**
     * 过滤查询的关键词
     * @param keywords
     * @return
     */
    private String filterKeywords(String keywords){
        int maxlength = 350;
        keywords = keywords.trim();
        //if(keywords.equals("支持书名、作者、出版社、店名、省市等多个关键字的复合查询")){
        //    keywords="";
        //}
        if( keywords.length() > maxlength){
            keywords = keywords.substring(0, maxlength);
        }
        //屏蔽的字符：\ ! ( ) : ^ [ ] { } ~ * ? /
        //keywords = keywords.replaceAll("[\\\\\\!\\(\\)\\:\\^\\[\\]\\{\\}\\~\\*\\?/\'\";]", "");
        //替换为空格的字符：全角空格　、制表符\t
        //keywords = keywords.replaceAll("[　\t]", " ");
        //多个空格替换为一个空格
        //keywords = keywords.replaceAll("( )+", " ");
        //keywords = keywords.replaceAll("－－|--", "——");//两个全角减号替换为一个破折号
        
        //全角的＋、－、ＡＮＤ、ＯＲ替换为半角的
        //keywords = keywords.replaceAll("＋", "+");
        //keywords = keywords.replaceAll("－", "-");
        //keywords = keywords.replaceAll("ＡＮＤ", "AND");
        //keywords = keywords.replaceAll("ＯＲ", "OR");

        //先去掉+或-前后的空格
        //keywords = keywords.replaceAll("( ?\\+ ?)+", "+");
        //keywords = keywords.replaceAll("( ?\\- ?)+", "-");
        //keywords = keywords.replaceAll("( ?AND ?)+", "AND");
        //keywords = keywords.replaceAll("( ?OR ?)+", "OR");
        //再去掉连续的逻辑运算符
        //keywords = keywords.replaceAll("(\\+)+", "+");
        //keywords = keywords.replaceAll("(\\-)+", "-");
        //keywords = keywords.replaceAll("(AND)+", "AND");
        //keywords = keywords.replaceAll("(OR)+", "OR");
        //去掉重叠的逻辑运算符
        //keywords = keywords.replaceAll("(\\-\\+)+", "-");
        //keywords = keywords.replaceAll("(\\+\\-)+", "+");
        //keywords = keywords.replaceAll("(ORAND)+", "OR");
        //keywords = keywords.replaceAll("(ANDOR)+", "AND");
        //去掉行头和行尾的逻辑运算符
        //keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        //keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        //规范化逻辑表达式
        //keywords = keywords.replaceAll("\\+", " +");
        //keywords = keywords.replaceAll("\\-", " -");
        keywords = keywords.replaceAll("AND", " AND ");
        keywords = keywords.replaceAll("OR", " OR ");
        keywords = keywords.replaceAll("( )+", " ");
        return keywords;
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage){
        String htmlContent = "<label class=\"page_navigation\">";
        if(pageCount > 0) {
            htmlContent += "<a href=\"javascript:go(1)\">首页</a>";
            //如果当前页为第一页，则不显示“上一页链接”
            if(currentPage > 1){
                htmlContent += "<a href=\"javascript:go("+(currentPage-1)+")\">上一页</a>";
            }
            //每次从当前页向后显示十页，如果不够十页，则全部显示。
            int max = (currentPage < 100 ? 11 : 6);//显示的页码数量
            int maxhalf = max / 2;
            int start = (currentPage <= maxhalf) ? 1 : (currentPage - maxhalf);
            int end = ((currentPage + maxhalf) <= pageCount) ? (currentPage + maxhalf) : pageCount;

            for(int i = start; i <= end; i++){
                if(currentPage == i){
                    htmlContent += "<b>" + i + "</b>";
                }else{
                    htmlContent += "<a href=\"javascript:go("+i+")\">" + i + "</a>";
                }
            }
            //如果当前页为最后一页，则不显示“下一页”链接
            if(currentPage < pageCount){
                htmlContent += "<a href=\"javascript:go("+(currentPage+1)+")\">下一页</a>";
            }
            htmlContent += "<a href=\"javascript:go("+pageCount+")\">末页</a>";	
        }
        htmlContent += "</label>";
        return htmlContent;
    }

    /**
     * 显示查询结果列表
     * @param bookList
     * @return
     */
    private String displayHitsTable(ArrayList bookList) throws Exception{
        StringBuffer content = new StringBuffer();
        content.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
        content.append("<tr height=\"30\" align=\"center\">");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">");
        content.append("<img src=\"./images/smile.gif\" id=\"smile\" title=\"Ahoy!\" onclick=\"checkAll(!m_isCheckAll)\" style=\"cursor:pointer\" />");
        content.append("</td>");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"30%\">主键</td>");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"\">书名</td>");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">查询次数</td>");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">更新时间</td>");
        content.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">操作</td>");
        content.append("</tr></table>");
        content.append("<script>var data =[];</script>");
        
        for(int i = 0; i < bookList.size(); i++){
            Map map = (Map) bookList.get(i);
            String primaryKey = StringUtils.strVal(map.get("primaryKey"));
            String keyword = StringUtils.strVal(map.get("keyword"));
            String queryCount = StringUtils.strVal(map.get("queryCount"));
            String updateTime = StringUtils.strVal(map.get("updateTime"));

            String keywordUrl = "http://search.kongfz.com/book.jsp?query="+StringUtils.urlencode(keyword);

            String bookInfo = primaryKey+"\n"+keyword;
            bookInfo = StringUtils.urlencode(bookInfo);

            content.append("<script>data["+i+"]='"+bookInfo+"';</script>");
            content.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
            content.append("<tr bgcolor=\""+((i % 2 == 0)?"#EFEFEF":"#ffffff")+"\">");
            content.append("<td width=\"5%\"><input type=\"checkbox\" name=\"bookInfo[]\" value=\""+bookInfo+"\" /></td>");
            content.append("<td width=\"30%\" class=\"primaryKey\">" + primaryKey +"</td>");
            content.append("<td width=\"\" align=\"left\"><a target=\"_blank\" href=\""+keywordUrl+"\" >" + keyword +"</a></a></td>");
            content.append("<td width=\"10%\" align=\"right\">" + queryCount +"</td>");
            content.append("<td width=\"10%\">" + updateTime +"</td>");
            content.append("<td width=\"10%\">");
            content.append("<a href=\"javascript:confirm('是否要删除选定图书？')?verifyBook('delete', data["+i+"]):void(0);\">删除</a>&nbsp;");
            content.append("</td>");
            content.append("</tr></table>\n");
        }
        return content.toString();
    }
%>
<%
/****************************************************************************
 * 设置页面中使用UTF-8编码
 ****************************************************************************/
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");
/*****************************************************************************/

/****************************************************************************
 * 验证用户登录状态和管理权限
 ****************************************************************************/
MemcachedSession MemSession = new MemcachedSession(session, request, response, out, false);
// 从Session中取得管理员的姓名，并记录之。
String adminRealName = MemSession.get("adminRealName");

// user login
String logon_result = "";
String username = MemSession.get("adminName");//用于网站管理员登录

if(!MemSession.isLogin("admin")){
    response.sendRedirect("index.jsp");
    return;
}

//判断管理员权限
//String[] permission = new String[]{"manageIndex", "manAuctioneer"};
String permission = "suggestIndexManage";
if(!MemSession.hasPermission(permission)){
    out.write("您无权限使用此页面。");
    return;
}

/****************************************************************************
 * 接收页面求参数
 ****************************************************************************/
//动作类型
String act = StringUtils.strVal(request.getParameter("act"));
if("".equals(act)){ act="search"; }

//任务类型
String task = StringUtils.strVal(request.getParameter("task"));

//搜索关键词
String keywords = StringUtils.strVal(request.getParameter("keywords"));
keywords = filterKeywords(keywords);

//搜索字段
String queryType = StringUtils.strVal(request.getParameter("queryType"));
if("".equals(queryType)){queryType = "0";}

//排序类型
//String sortType = request.getParameter("sortType");

//当前页
String currentPage = StringUtils.strVal(request.getParameter("page"));
if("".equals(currentPage)){ currentPage = "1"; }

/****************************************************************************
 * 调用远程服务接口
 ****************************************************************************/
ServiceInterface server = null;
String serverStatus = "";
ArrayList documents = new ArrayList();
String bookTotal = "0";
String pageTotal = "0";
String searchTime = "0";
String workHits="Welcome";
try{
    //取得远程服务器接口实例
     server = (ServiceInterface) Naming.lookup("rmi://192.168.1.3:9071/QuerySuggestService");
}catch(Exception ex){
    //ex.printStackTrace();
}

/*******************************************************************************
 * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
 *******************************************************************************/
if(null != server){
    try{
        
        //删除关键词索引
        if(act != null && act.equals("delete")){
            
            //要审核的图书信息列表
            String[] sugInfoList = request.getParameterValues("bookInfo[]");
            HashMap parameters = new HashMap();
            parameters.put("task", task);
            parameters.put("sugInfoList", sugInfoList);
            
            //审核图书
            Map resultSet = server.work("DeleteIndex", parameters);

            //处理审核结果
            String result = StringUtils.strVal(resultSet.get("status"));
            if("0".equals(result)){
                act = "search";
            }
            if("1".equals(result)){
                serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
                workHits = serverStatus;
            }
            if("2".equals(result)){
                serverStatus = "服务器异常：审核受阻，正在建立索引。";
                workHits = serverStatus;
            }
        }

        //查询关键词索引服务
        if(act != null && act.equals("search")){
            HashMap parameters = new HashMap();
            parameters.put("keywords", keywords);
            parameters.put("queryType", queryType);
            parameters.put("queryType", queryType);
            //parameters.put("author", author);
            //parameters.put("press", press);
            
            //查询类配置参数
            parameters.put("currentPage", currentPage);
            parameters.put("paginationSize", "200");
            //parameters.put("sortDefault", );

            //调用远程查询接口
            Map resultSet = server.work("Search", parameters);
            //处理查询结果
            String result = StringUtils.strVal(resultSet.get("status"));
            documents     = (ArrayList) resultSet.get("documents");

            if("0".equals(result)){
                //将查询到的图书列表输出
                currentPage = StringUtils.strVal(resultSet.get("currentPage"));
                bookTotal   = StringUtils.strVal(resultSet.get("hitsCount"));
                pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
                searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
            }
            if("1".equals(result)){
                serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
                workHits = serverStatus;
            }
            if("2".equals(result)){
                serverStatus = "服务器异常：查询受阻，正在建立索引。";
                workHits = serverStatus;
            }
            if("3".equals(result)){
                serverStatus = "服务器异常：查询过程中出现错误。";
                workHits = serverStatus;
            }
        }
    }catch(Exception ex){
        serverStatus = "JSP页面代码出现异常。";
        //ex.printStackTrace();
    }
}else{
    serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
}
//System.out.println(serverStatus);

/****************************************************************************
 * 组织模板数据
 ****************************************************************************/

//查询图书列表
String list_contents = "";
if(null == documents || 0 == documents.size()){
    //远程服务器正常启动
    if(serverStatus.equals("")){
        list_contents = "<div class=\"result_message\"><img class=\"float_left\" src=\"./images/none.gif\" /><div class=\"float_left\"><div>&nbsp;</div><div>&nbsp;</div><div>&nbsp;</div><div style=\"color:#FF0000;font-size:14px;\">抱歉，搜索不到任何您想要的东西！</div></div></div>";
    }else{
        list_contents = "<div class=\"result_message\"><img class=\"float_left\" src=\"./images/none.gif\" /><div class=\"float_left\"><div>&nbsp;</div><div>&nbsp;</div><div>&nbsp;</div><div style=\"color:#FF0000;font-size:14px;\">"+serverStatus+"</div></div></div>";
    }
}else{
    //审核工具栏
    String verifyToolbar_contents = "";
    verifyToolbar_contents = "<div align=\"left\" style=\"padding:5px 2px 0px 2px;width:98%;font-size:13px;\">"
    +"<input type=\"button\" value=\"全选\" onclick=\"checkAll(true)\" />"
    +"<input type=\"button\" value=\"全否\" onclick=\"checkAll(false)\" />"
    +"<label>　　　　</label>"
    +"<input type=\"button\" value=\"删除所选图书\" onclick=\"verifyBook('delete')\" />"
    +"</div>";


    //分页导航栏
    String navigation_contents = "";
    navigation_contents += "<table align=\"center\" border=0  width=\"98%\" id=\"Page\"><tr><td height=\"28\" align=\"left\" id=\"Page\">";
    navigation_contents += "<font color='#666666'><b>查询的图书总数：</b></font>" + bookTotal + "&nbsp;";
    navigation_contents += "共<font color='#0000ff'>" + pageTotal + "</font>页&nbsp;&nbsp;";
    navigation_contents += "现为<font color=red>" + currentPage + "</font>页&nbsp;";
    navigation_contents += displayNavigation(Integer.parseInt(pageTotal), Integer.parseInt(currentPage));
    navigation_contents += "<label>第<input type=\"text\" size=\"3\" maxlength=\"4\" value=\"\" name=\"gopage\"  onkeydown=\"if(event.keyCode==13){gotopage();}\" />页&nbsp;<input type=\"button\" onclick=\"gotopage()\" value=\"转到\" class=\"goto_button\" /></label>";
    navigation_contents += "&nbsp;&nbsp;搜索用时 "+searchTime+" 秒&nbsp;&nbsp;";
    navigation_contents +="</td></tr></table>";

    list_contents = verifyToolbar_contents;
    list_contents += navigation_contents;
    list_contents += "<div>"+displayHitsTable(documents)+"</div>";
    list_contents += navigation_contents;
    list_contents += verifyToolbar_contents;
}

//out.write(list_contents);
/****************************************************************************
 * 调用模板输出结果
 ****************************************************************************/
SimpleTemplate template = new SimpleTemplate();
template.setCharacterSet("UTF-8");

template.assign("act", act);
template.assign("keywords", keywords);
template.assign("queryType", queryType);
template.assign("page", currentPage);

template.assign("list_contents", list_contents);
template.assign("workHits", workHits);

String path = application.getRealPath("admin/template/suggest_index_manage.html");
out.println(template.display(path));

%>
