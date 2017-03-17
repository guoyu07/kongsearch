<!-- 
	图书资料库，审核通过
	tangjunfeng
	2013-10-16
 -->
<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ include file="cls_memcached_session.jsp"%>
<%!
    /**
     * 取得提交的图书的列表
     */
    private static List<Map<String, Object>> getPostBookList(String[] bookInfoList)
    {
        List<Map<String, Object>> recordList = new LinkedList<Map<String, Object>>();
        if (null == bookInfoList) {
            return recordList;
        }
        
        for (String bookInfo : bookInfoList) {
            String[] items = StringUtils.urldecode(bookInfo).split("\n");
            if (null != items && items.length >= 5) {
                Map<String, Object> record = new HashMap<String, Object>();
                record.put("bookId",       items[0].trim());
                record.put("bookName",     items[1].trim());
                record.put("author",       items[2].trim());
                record.put("press",        items[3].trim());
                record.put("isbn",         items[4].trim());
                recordList.add(record);
            }
        }
        return recordList;
    }

    /**
     * 过滤查询的关键词
     * @param keywords
     * @return
     */
    private String filterKeywords(String keywords){
        int maxlength = 350;
        keywords = keywords.trim();
        if(keywords.equals("支持书名、作者、出版社、店名、省市等多个关键字的复合查询")){
            keywords="";
        }
        if( keywords.length() > maxlength){
            keywords = keywords.substring(0, maxlength);
        }
        //屏蔽的字符：\ ! ( ) : ^ [ ] { } ~ * ? /
        keywords = keywords.replaceAll("[\\\\\\!\\(\\)\\:\\^\\[\\]\\{\\}\\~\\*\\?/\'\";]", "");
        //替换为空格的字符：全角空格　、制表符\t
        keywords = keywords.replaceAll("[　\t]", " ");
        //多个空格替换为一个空格
        keywords = keywords.replaceAll("( )+", " ");
        keywords = keywords.replaceAll("－－|--", "——");//两个全角减号替换为一个破折号
        
        //全角的＋、－、ＡＮＤ、ＯＲ替换为半角的
        keywords = keywords.replaceAll("＋", "+");
        keywords = keywords.replaceAll("－", "-");
        keywords = keywords.replaceAll("ＡＮＤ", "AND");
        keywords = keywords.replaceAll("ＯＲ", "OR");

        //先去掉+或-前后的空格
        keywords = keywords.replaceAll("( ?\\+ ?)+", "+");
        keywords = keywords.replaceAll("( ?\\- ?)+", "-");
        keywords = keywords.replaceAll("( ?AND ?)+", "AND");
        keywords = keywords.replaceAll("( ?OR ?)+", "OR");
        //再去掉连续的逻辑运算符
        keywords = keywords.replaceAll("(\\+)+", "+");
        keywords = keywords.replaceAll("(\\-)+", "-");
        keywords = keywords.replaceAll("(AND)+", "AND");
        keywords = keywords.replaceAll("(OR)+", "OR");
        //去掉重叠的逻辑运算符
        keywords = keywords.replaceAll("(\\-\\+)+", "-");
        keywords = keywords.replaceAll("(\\+\\-)+", "+");
        keywords = keywords.replaceAll("(ORAND)+", "OR");
        keywords = keywords.replaceAll("(ANDOR)+", "AND");
        //去掉行头和行尾的逻辑运算符
        keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
        //规范化逻辑表达式
        keywords = keywords.replaceAll("\\+", " +");
        keywords = keywords.replaceAll("\\-", " -");
        keywords = keywords.replaceAll("AND", " AND ");
        keywords = keywords.replaceAll("OR", " OR ");
        
        return keywords;
    }

    private String buildKeywordGroupOptions(Map<String, String> distrustKeywordGroupInfo, String currentGroupId)
    {
        if(null == distrustKeywordGroupInfo || 0 == distrustKeywordGroupInfo.size()){
            return "";
        }

        String[] groupIdArr = new String[distrustKeywordGroupInfo.size()];
        distrustKeywordGroupInfo.keySet().toArray(groupIdArr);
        Arrays.sort(groupIdArr);

        String groupName;
        StringBuffer buffer = new StringBuffer();
        buffer.append("<option value=\"\" >全部</option>");
        for(String groupId : groupIdArr){
            groupName = distrustKeywordGroupInfo.get(groupId);
            if(groupId.equals(currentGroupId)){
                buffer.append("<option value=\""+groupId+"\" selected=\"selected\" >"+groupName+"</option>");
            } else {
                buffer.append("<option value=\""+groupId+"\" >"+groupName+"</option>");
            }
        }
        return buffer.toString();
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
     * 显示图书查询结果
     * @param bookList
     * @return
     */
    private String displayHitsTable(ArrayList bookList) throws Exception{
        StringBuffer content = new StringBuffer();
        content.append("<script>var data =[];</script>");
        for(int i = 0; i < bookList.size(); i++){
            Map map = (Map) bookList.get(i);
            String bookId                   = StringUtils.strVal(map.get("bookId"));

            String bookName                 = StringUtils.strVal(map.get("bookName"));
            String bookName_hl              = StringUtils.strVal(map.get("bookName_hl")).trim();
            String press                    = StringUtils.strVal(map.get("press"));
            String press_hl                 = StringUtils.strVal(map.get("press_hl")).trim();
            String catName                  = StringUtils.strVal(map.get("catName"));
            String price                    = StringUtils.strVal(map.get("price"));
            String certifyStatus            = StringUtils.strVal(map.get("certifyStatus"));

            String author                   = StringUtils.strVal(map.get("author"));
            String author_hl                = StringUtils.strVal(map.get("author_hl")).trim();
            String subAuthor                = StringUtils.strVal(map.get("subAuthor"));
            String edition                  = StringUtils.strVal(map.get("edition"));
            String pubDate                  = StringUtils.strVal(map.get("pubDate"));
            String isbn                     = StringUtils.strVal(map.get("isbn"));
            String unifiedIsbn              = StringUtils.strVal(map.get("unifiedIsbn"));

            String authorIntroduction       = StringUtils.strVal(map.get("authorIntroduction"));//描述类
            String authorIntroduction_hl    = StringUtils.strVal(map.get("authorIntroduction_hl"));
            String contentIntroduction      = StringUtils.strVal(map.get("contentIntroduction"));//描述类
            String contentIntroduction_hl   = StringUtils.strVal(map.get("contentIntroduction_hl"));
            String description              = StringUtils.strVal(map.get("description"));//描述类
            String description_hl           = StringUtils.strVal(map.get("description_hl"));
            String editorComment            = StringUtils.strVal(map.get("editorComment"));//描述类
            String editorComment_hl         = StringUtils.strVal(map.get("editorComment_hl"));
            String mediaComment             = StringUtils.strVal(map.get("mediaComment"));//描述类
            String mediaComment_hl          = StringUtils.strVal(map.get("mediaComment_hl"));
            String Illustration             = StringUtils.strVal(map.get("Illustration"));//描述类
            String Illustration_hl          = StringUtils.strVal(map.get("Illustration_hl"));
            String directory                = StringUtils.strVal(map.get("directory"));//描述类
            
            String isExistDescInfo = StringUtils.strVal(map.get("isExistDescInfo"));//是否存在描述信息【 0 不存在，1存在】
            String isExistPic = StringUtils.strVal(map.get("isExistPic"));//是否存在图片【 0 不存在，1存在】
            if("".equals(isExistDescInfo)){
            	isExistDescInfo = "0";
            }
            if("".equals(isExistPic)){
            	isExistPic = "0";
            }
            
            String bookUrl = "http://search.kongfz.com/book.jsp?query="+StringUtils.urlencode(bookName);

            StringBuffer fields = new StringBuffer();
            fields.append(bookId+" \n");
            fields.append(bookName+" \n");
            fields.append(author+" \n");
            fields.append(press+" \n");
            fields.append(isbn+" \n");
            String bookInfo = StringUtils.urlencode(fields.toString());

            String bgcolor = (i % 2 == 0) ? "#F5F5F5" : "#ffffff";

	        content.append("<script>data["+i+"]='"+bookInfo+"';</script>");
	        content.append("<table width=\"99%\" bgcolor=\""+bgcolor+"\" border=\"1\" cellspacing=\"1\" cellpadding=\"0\" style=\"border-collapse:collapse;margin-bottom:5px;\" class=\"bookList\">");
	        content.append("<tr align=\"left\">");
	        content.append("<td width=\"2%\"><input type=\"checkbox\" name=\"bookInfo[]\" title=\""+bookId+"\" value=\""+bookInfo+"\" />&nbsp;</td>");
	        content.append("<td width=\"\"><a target=\"_blank\" href=\""+bookUrl+"\" >"+bookName_hl+"</a>&nbsp;</td>");
	        content.append("<td width=\"20%\">" + author_hl + (!"".equals(subAuthor)?"/"+subAuthor:"")+"&nbsp;</td>");
	        content.append("<td width=\"10%\">" +isbn+"&nbsp;</td>");
	        content.append("<td width=\"15%\">"+press_hl+"&nbsp;</td>");
	        content.append("<td width=\"8%\">"+pubDate+"&nbsp;</td>");
	        content.append("<td width=\"8%\">"+(isExistDescInfo.equals("0") ? "无描述" : "有描述")+"&nbsp;</td>");
	        content.append("<td width=\"8%\">"+(isExistPic.equals("0") ? "无图" : "有图")+"&nbsp;</td>");
	        content.append("</tr>");
/***   tangjunfeng   杨斌提交BUG
	        if(!"".equals(authorIntroduction)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>作者介绍：</font>"+authorIntroduction_hl+"</td></tr>");
	        }
	        if(!"".equals(contentIntroduction)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>内容介绍：</font>"+contentIntroduction_hl+"</td></tr>");
	            }
	        if(!"".equals(description)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>描述：</font>"+description_hl+"</td></tr>");
	        }
	        if(!"".equals(editorComment)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>编辑评论：</font>"+editorComment_hl+"</td></tr>");
	        }
	        if(!"".equals(mediaComment)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>媒体评论：</font>"+mediaComment_hl+"</td></tr>");
	        }
	        if(!"".equals(Illustration)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>插图说明：</font>"+Illustration_hl+"</td></tr>");
	        }
	        if(!"".equals(directory)){
	            content.append("<tr align=\"left\"><td>&nbsp;</td><td colspan=\"5\"><font color=gray>目录：</font>"+directory+"</td></tr>");
	        }
	        content.append("</table>\n");
*/
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

    // user login
    String logon_result = "";
    String username = MemSession.get("adminName");//用于网站管理员登录

    if(!MemSession.isLogin("admin")){
        //response.sendRedirect("index.jsp");
        //return;
    }

    //判断管理员权限
    //String[] permission = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "bookLibraryManage";
    if(!MemSession.hasPermission(permission)){
        //out.write("您无权限使用此页面。");
        //return;
    }


    /****************************************************************************
     * 接收页面求参数
     ****************************************************************************/
    //动作类型
    String act = StringUtils.strVal(request.getParameter("act"));
    if("".equals(act)){ act="search"; }
    //任务类型
    String task = StringUtils.strVal(request.getParameter("task"));

    // 文档库类型
    String docBaseType = StringUtils.strVal(request.getParameter("docBaseType"));
    String keywordGroupId = StringUtils.strVal(request.getParameter("keywordGroupId"));

    //搜索关键词
    int searchType = StringUtils.intVal(request.getParameter("searchType"));
    String keywords = StringUtils.strVal(request.getParameter("keywords"));
    keywords = filterKeywords(keywords);

    String author = StringUtils.strVal(request.getParameter("author")).trim();
    author = filterKeywords(author);

    String press = StringUtils.strVal(request.getParameter("press")).trim();
    press = filterKeywords(press);


    //排序类型
    //String sortType = request.getParameter("sortType");

    //当前页
    String currentPage = String.valueOf(StringUtils.intVal(request.getParameter("page")));

    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface server = null;
    Map resultSet = null;
    String serverStatus = "";
    ArrayList documents = new ArrayList();
    String bookTotal = "0";
    String pageTotal = "0";
    String searchTime = "0";
    List<Map<String, Object>> bookInfoList = null;
    Map<String, String> distrustKeywordGroupInfo = null;
    String distrustKeywordGroupHtml = "";
    String keywordGroupContent = "";
    try{
        //取得远程服务器接口实例
         server = (ServiceInterface) Naming.lookup("rmi://192.168.1.66:8898/BookLibraryService");
    }catch(Exception ex){
        //ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(null != server){
        try{
            //审核图书服务
            if (StringUtils.inArray(act, "Approve", "Reject", "Unconfirmed")) {
                //要审核的图书信息列表
                String[] bookInfoArray = request.getParameterValues("bookInfo[]");
                // 取得要审核的图书信息列表
                bookInfoList = getPostBookList(bookInfoArray);
                HashMap parameters = new HashMap();
                parameters.put("docBaseType", docBaseType);
                parameters.put("groupId", keywordGroupId);
                parameters.put("task", act);
                parameters.put("bookInfoList", bookInfoList);

                String workMethodName = "";
                if(StringUtils.inArray(act, "Approve", "Reject")){
                    workMethodName = "VerifyBook";
                }
                if("Unconfirmed".equalsIgnoreCase(act)){
                    workMethodName = "AddUnconfirmedBookDoc";
                }
                //审核图书
                resultSet = server.work(workMethodName, parameters);

                //处理审核结果
                String result = StringUtils.strVal(resultSet.get("status"));
                if("0".equals(result)){
                    act = "search";
                }
                else if("1".equals(result)){
                    serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
                }
                else if("2".equals(result)){
                    serverStatus = "服务器异常：审核受阻，正在建立索引。";
                }
                else {
                     serverStatus = "服务器信息：未知错误。";
                }
            }

            //查询索引服务
            if("search".equalsIgnoreCase(act)){
                HashMap parameters = new HashMap();
                parameters.put("docBaseType", docBaseType);
                parameters.put("groupId", keywordGroupId);
                switch(searchType){
                    case 0: parameters.put("keywords", keywords); break;
                    case 1: parameters.put("bookName", keywords); break;
                    case 2: parameters.put("author", keywords);   break;
                    case 3: parameters.put("press", keywords);    break;
                }
                if(!"".equals(author)){
                    parameters.put("author", author);
                }
                if(!"".equals(press)){
                    parameters.put("press", press);
                }
                //查询类配置参数
                parameters.put("currentPage", currentPage);
                //每页显示500条，杨斌提交BUG
                parameters.put("paginationSize", "500");//每页显示的总条数
                //parameters.put("sortDefault", );
                
				/**添加只显示审核通过的图书 start   tangjunfeng*/
                parameters.put("certifyStatus","certified");
                /**添加只显示审核通过的图书 end*/
				
                //得到请求的排序方式
                String orderSortInfoTJF = request.getParameter("orderSortInfoTJF");
                //排序方式 不等于默认
                if(null != orderSortInfoTJF && !"default".equals(orderSortInfoTJF)){
                    String[] softsTJF = orderSortInfoTJF.split("_");
                    parameters.put("softRowsName",softsTJF[0]);//字段名
                    parameters.put("softRowsType",softsTJF[1]);//排序方式
                }
	                
                String isExistPicTJF = request.getParameter("isExistPicTJF");//有无图片
                //图片搜索不是全部，并且值等于 0 或 1
                if(null != isExistPicTJF && !"all".equals(isExistPicTJF) && ("0".equals(isExistPicTJF) || "1".equals(isExistPicTJF))){
                	parameters.put("isExistPic",isExistPicTJF.trim());//有误图片
                }
                String isExistDescInfoTJF = request.getParameter("isExistDescInfoTJF");//有无描述
              	//描述搜索不是全部，并且值等于 0 或 1
                if(null != isExistDescInfoTJF && !"all".equals(isExistDescInfoTJF) && ("0".equals(isExistDescInfoTJF) || "1".equals(isExistDescInfoTJF))){
                	parameters.put("isExistDescInfo",isExistDescInfoTJF.trim());//有误图片
                }
                
                //调用远程查询接口
                if ("".equals(docBaseType)) {//正常查询
                	//最终执行方法地址(未确定) search\src\trunk\BookLibrary\src\com\kongfz\search\service\booklibrary\works\SearchBookIndexWorker.java
                    resultSet = server.work("Search", parameters);
                } else  {//查询可疑图书文档库索引
                	//最终执行方法地址(未确定) search\src\trunk\BookLibrary\src\com\kongfz\search\service\booklibrary\works\filter\SearchDocBaseIndexWorker
                    resultSet = server.work("SearchDocBase", parameters);
                }
                //处理查询结果
                String result = StringUtils.strVal(resultSet.get("status"));
                documents     = (ArrayList) resultSet.get("documents");

                if("0".equals(result)){
                    //将查询到的图书列表输出
                    currentPage = StringUtils.strVal(resultSet.get("currentPage"));
                    bookTotal   = StringUtils.strVal(resultSet.get("hitsCount"));
                    pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
                    searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
                    distrustKeywordGroupInfo = (Map<String, String>) resultSet.get("distrustKeywordGroupInfo");
                    distrustKeywordGroupHtml = buildKeywordGroupOptions(distrustKeywordGroupInfo, keywordGroupId);
                    keywordGroupContent = StringUtils.strVal(resultSet.get("keywordGroupContent"));
                }
                if("1".equals(result)){
                    serverStatus = "服务器异常：索引为空，或未建立，或正在建立索引。";
                }
                if("2".equals(result)){
                    serverStatus = "服务器异常：查询受阻，正在建立索引。";
                }
                if("3".equals(result)){
                    serverStatus = "服务器异常：查询过程中出现错误。";
                }
            }
        }catch(Exception ex){
            serverStatus = "JSP页面代码出现异常。";
            ex.printStackTrace();
        }
    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }

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
        StringBuffer verifyToolbar = new StringBuffer();
        //if(!"".equalsIgnoreCase(docBaseType)){
            verifyToolbar.append("<div align=\"left\" style=\"padding:5px 2px 0px 2px;width:98%;font-size:13px;\">");
            verifyToolbar.append("<input type=\"button\" value=\"全选\" onclick=\"checkAll(true)\" />");
            verifyToolbar.append("<input type=\"button\" value=\"全否\" onclick=\"checkAll(false)\" />");
            verifyToolbar.append("　　　　");
            verifyToolbar.append("<input type=\"button\" value=\"通过\" onclick=\"verifyBook('approve')\" />　　");
            verifyToolbar.append("<input type=\"button\" value=\"驳回\" onclick=\"verifyBook('reject')\" />　　");
            if(!"unconfirmed".equalsIgnoreCase(docBaseType)){
                verifyToolbar.append("<input type=\"button\" value=\"待确认\" onclick=\"verifyBook('unconfirmed')\" />");
            }
            verifyToolbar.append("</div>");
        //}

        //分页导航栏
        StringBuffer navigationHtml = new StringBuffer();
        navigationHtml.append("<table align=\"center\" border=0  width=\"98%\" class=\"Page\"><tr><td height=\"28\" align=\"left\" id=\"Page\">");
        navigationHtml.append("<font color='#666666'><b>查询的图书总数：</b></font>" + bookTotal + "&nbsp;");
        navigationHtml.append("共<font color='#0000ff'>" + pageTotal + "</font>页&nbsp;&nbsp;");
        navigationHtml.append("现为<font color=red>" + currentPage + "</font>页&nbsp;");
        navigationHtml.append(displayNavigation(StringUtils.intVal(pageTotal), StringUtils.intVal(currentPage)));
        navigationHtml.append("<label>第<input type=\"text\" size=\"3\" maxlength=\"4\" value=\"\" name=\"gopage\"  onkeydown=\"if(event.keyCode==13){gotopage();}\" />页&nbsp;<input type=\"button\" onclick=\"gotopage()\" value=\"转到\" class=\"goto_button\" /></label>");
        navigationHtml.append("&nbsp;&nbsp;搜索用时 "+searchTime+" 秒&nbsp;&nbsp;");
        navigationHtml.append("</td></tr></table>");

        list_contents = verifyToolbar.toString();
        list_contents += navigationHtml.toString();
        list_contents += "<div>"+displayHitsTable(documents)+"</div>";
        list_contents += navigationHtml.toString();
        list_contents += verifyToolbar.toString();
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>管理图书资料库</title>
</head>
<style>
    body{ 
    margin:0; 
    padding:0; 
    text-align:center
    }
    a{ text-decoration:none;}
    a:hover{ 
    text-decoration:underline; 
    color:red;
    }
    .Sort{
    width:99%; 
    font-size:14px; 
    line-height:30px; 
    background-color:#D1C5DC; 
    border:1px solid #997EB0; 
    margin:0 auto;  
    height:28px; 
    text-align:left; 
    padding-top:2px;
    }
    .searchSub{
    background:url(./images/bg_searchsub.gif); 
    border:1px solid #d17528; 
    width:80px; 
    padding-top:2px; 
    font-weight:bold; 
    color:#fff;}
    .Page td{ 
    font-size:14px; 
    line-height:200%;
    }
    .bookList td{ 
    font-size:14px; 
    line-height:220%!important; 
    line-height:150%;
    }
    .bookList td a{
    color:#0000ba; text-decoration:none;}
    .bookList td a:hover{
    color:red; 
    text-decoration:underline;
    }

    .search{
    width:99%; 
    height:58px;
    border-bottom:1px solid #997EB0; 
    padding-top:4px;
    margin:0 auto 2px auto; 
    background:url(./images/bg_search_2.gif); 
    font-size:12px;
    }

    form{
    margin:0px;
    }
    .copyright{
    font-size:12px;
    width:99%;
    border:1px solid #EFF2FA;
    padding-bottom:20px;
    text-align:center;
    background-color:#EFF2FA;
    }
    .result_message{
    font-size:12px;
    border:0px solid #003300;
    height:200px;
    width:99%;
    text-align:center;
    }
    .result_message img{
    margin:20px 20px 20px 200px;
    }
    .result_message label{
    color:#FF6F02;
    }
    .float_left{
    float:left;
    }

    .sale_on_order{cursor:pointer;}

    .page_navigation{
    }
    .page_navigation a{
    margin:2px;
    padding:2px;
    text-decoration:none;
    color:#100EB0;
    font-size:14px;
    }
    .page_navigation a:hover{
    text-decoration:underline;
    color:#FF0000;
    }
    .page_navigation label{
    margin:2px;
    padding:2px;
    }
    .page_navigation b{
    color:#FF0000;
    margin:2px;
    padding:2px;
    font-size:14px;
    }
    .page_navigation input{
    border:1px solid #ADC1DC;
    }

    .goto_button{
    height:20px;
    width:36px;
    border:1px solid #ADC1DC;
    color:#006E0B;
    padding:2px;
    background-color:#FFFFFF;
    background-image:url(images/bg_sort.gif);
    cursor:pointer;
    }

    .isNewBook{
    font-size:14px;
    color:#FF0000;
    font-weight:bold;
    }
    .isNewBookNormal{
    font-size:14px;
    }
    
    .belivePress{
    display:none;
    position:absolute;
    padding:2px;
    width:120px; 
    height:auto; 
    background-color:#C7D5E9;
    border:1px solid #ADC1DC;
    }
    .belivePress a{
    float:left;
    padding:2px;
    width:100%;
    color:#000000;
    text-align:left;
    font-size:14px;
    }
    .belivePress a:hover{
    background-color:#FDDA96;
    color:#FF0000;
    }
    .distrustKeywords{
    display:none;
    position:absolute;
    padding:2px;
    width:120px; 
    height:auto; 
    background-color:#C7D5E9;
    border:1px solid #ADC1DC;
    }
    .distrustKeywords a{
    float:left;
    padding:2px;
    width:100%;
    color:#000000;
    text-align:left;
    font-size:14px;
    }
    .distrustKeywords a:hover{
    background-color:#FDDA96;
    color:#FF0000;
    }

    /* 主菜单面板 */
    .mainMenuPanel{
    margin:auto;
    padding:4px 4px 0px 4px;
    height:18px; 
    width:auto; 
    text-align:left;
    font-size:12px; 
    border-bottom:1px solid #E6E6E6; 
    background-color:#ECECEC;
    }
    .menuItemSel{
    color:#FF0000;
    font-weight:bold;
    }

    /* 业务模块面板 */
    .modulePanel{
    margin:2px 0px 0px 0px; 
    padding-top:2px;
    width:99%; height:34px; 
    border-bottom:1px solid #997EB0; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#D1C5DC; 
    }
    .modulePanelItem{
    float:left;
    border:1px dashed #997EB0;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#000000;
    text-decoration:none;
    }
    .modulePanelItem:hover {
    color:white;
    text-decoration:none;
    background-color:#997EB0;
    }
    .modulePanelItemSel{
    float:left;
    border:1px dashed #997EB0;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#FFFFFF;
    font-weight:bold;
    text-decoration:none;
    background-color:#997EB0;
    }
    .modulePanelItemSel:hover {
    color:#FFFFFF;
    text-decoration:none;
    background-color:#997EB0;
    }
</style>
<script type="text/javascript">
    function $search(id){return document.getElementById(id);}
    function findPos(obj) {
        var curleft = curtop = 0;
        if (obj.offsetParent) {
            curleft = obj.offsetLeft;
            curtop = obj.offsetTop;
            while (obj = obj.offsetParent) {
                curleft += obj.offsetLeft;
                curtop += obj.offsetTop;
            }
        }
        return [curleft,curtop];
    }
    
    /**
     * 添加事件监听
     */
    function addEventListener(obj, eventName, callback)
    {
        if(document.all){
            obj.attachEvent("on" + eventName,callback);
        }else{
            obj.addEventListener(eventName,callback,true); 
        }
    }
    
    /**
     * 取消事件监听
     */
    function removeEventListener(obj, eventName, callback)
    {
        if(document.all){
            obj.detachEvent("on" + eventName, callback);
        }else{
            obj.removeEventListener(eventName, callback, true); 
        }
    }
    var m_isCheckAll = false;

    function setSort(type){
        $search("sortType").value = type;
        go(1);
    }

    function go(page){
        $search("page").value = page;
        $search("frmSearch").submit();
    }

    function gotopage(){
        var pages = document.getElementsByName("gopage");
        var page = pages[0].value!=""? pages[0].value : pages[1].value;
        page = page.replace(/ /g,"");
        go(page);
    }

    function orderbook(book_id, bs_id, bs_name){
        var url = "http://www.kongfz.com/bookstore/shoppingcart.php";
        window.open(url+"?actiontype=ADD&book_id="+book_id+"&quantity=1&bs_id="+bs_id+"&bs_name="+bs_name,"cart");
    }

    function searchBookPic(){
        $search("frmSearch").action = "book_pic.jsp";
        $search("frmSearch").submit();
    }

    function initSearchForm(){
        $search('act').value = "search";
        $search('page').value = 1;
    }

    function checkAll(value){
        m_isCheckAll = value;
        //$search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('bookInfo[]');
        for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }

    function verifyBookAll(task,bookInfo){
        var title = {"delete":"删除","approve":"通过","reject":"驳回","unconfirmed":"待确认"};
        var elements = document.getElementsByName('bookInfo[]');

        for(var i=0; i < elements.length; i++){
            elements[i].checked = true;
        }
        
        $search('act').value = task;
        $search('frmSearch').submit();
    }

    function verifyBook(task,bookInfo){
        var title = {"delete":"删除","approve":"通过","reject":"驳回","unconfirmed":"待确认"};
        var elements = document.getElementsByName('bookInfo[]');

        if(bookInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == bookInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再执行"+title[task]+"操作！");return;
        }
        if((bookInfo == null) && (!confirm("是否"+title[task]+"所选项目？"))){return;}
        
        $search('act').value = task;
        $search('frmSearch').submit();//未指定地址，提交至本页面
    }
    
    function quickQuery(keywords){
        $search('keywords').value = keywords;
        $search('frmSearch').submit();
    }
    
    function queryCategory(catId){
        $search('bookCategory').value = catId;
        $search('frmSearch').submit();
    }
    
    /**
    * 显示可疑关键字列表
    */
    function showDistrustKeywords(isVisible){
        function hideDistrustKeywordsPanel(){showDistrustKeywords(false);}
        var panel = $search('distrustKeywordsPanel');
        if(!isVisible){
            panel.style.display="none";
            removeEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            addEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
        }
    }

    /**
    * 显示可信任出版社列表
    */
    function showBelivePress(isVisible){
        function hideBelivePressPanel(){showBelivePress(false);}
        var panel = $search('belivePressPanel');
        if(!isVisible){
            panel.style.display="none";
            removeEventListener(document.documentElement, 'click', hideBelivePressPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=(pos[0]-0)+'px';
            panel.style.top=(pos[1]+15)+'px';
            addEventListener(document.documentElement, 'click', hideBelivePressPanel);
        }
    }
    
    /**
    * 装入辅助数据
    */
    function loadAssistantData(){
        //装入可疑关键字列表
        if(m_distrustKeywords){
            var keywordsHtml = [];
            for(var i=0; i < m_distrustKeywords.length; i++){
                keywordsHtml.push('<div><a href="javascript:quickQuery(\''+m_distrustKeywords[i].keywords+'\')" title="'+m_distrustKeywords[i].keywords+'">'+m_distrustKeywords[i].name+'</a></div>');
            }
            $search('distrustKeywordsPanel').innerHTML = keywordsHtml.join('');
        }
        //装入可信任出版社列表
        if(m_belivePress){
            var pressHtml = [];
            for(var i=0; i < m_belivePress.length; i++){
                pressHtml.push('<div><a href="javascript:quickQuery(\''+m_belivePress[i].name+'\')" title="'+m_belivePress[i].name+'">'+m_belivePress[i].name+'</a></div>');
            }
            $search('belivePressPanel').innerHTML=pressHtml.join('');
        }
    
    }

    function selectVerifyModule(module) {
        var map = {
            "0":"", 
            "1":"DistrustBanned",
            "2":"DistrustKeyword",
            "3":"DistrustPress",
            "4":"Unconfirmed"
        };
        $search('docBaseType').value = map[module];
        $search("keywordGroupId").value="";
        $search("act").value="";
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search('frmSearch').action="book_library_manage.jsp";
        $search('frmSearch').submit();
    }
    
    function setModulePanelHighlight(module) {
        var map = {
            "":0,//默认未筛选 
            "DistrustBanned":1,//已去除当前功能
            "DistrustKeyword":2,//已去除当前功能
            "DistrustPress":3,//已去除当前功能
            "Unconfirmed":3//待确认
        };
        var items = $search("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    /**
     * 隐藏查询框
     */
    function hideQueryBox(index)
    {
        if(0 == index ){
            $search("sub_panel").style.display = "block";
        } else {
            $search("sub_panel").style.display = "none";
            $search("author").value="";
            $search("press").value="";
        }
        
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("keywords").value="";
        $search("searchType").value="0";
        $search("author").value="";
        $search("press").value="";
    }

    function queryKeywordGroup(groupId) {
        $search("keywordGroupId").value=groupId;
        $search('frmSearch').submit();
    }

    /**
     * 根据排序方式，重新加载本界面
     * @param value 当前排序的值
     * @returns {boolean}
     */
    function reloadByOrderSortInfoTJF(value){
        if("" === value){
            alert("出现异常，请重新加载界面。");
            return false;
        }else{
            $search('frmSearch').submit();
        }
    }

</script>

<body>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="book_library_manage.jsp" class="menuItemSel">管理图书资料库</a>
</div>

<div class="modulePanel" id="modulePanel">
<a href="javascript:selectVerifyModule(0)" class="modulePanelItem">管理图书资料库(未审核)</a>
<a href="book_library_manage_via_tjf.jsp" class="modulePanelItemSel">管理图书资料库(通过)</a>
<a href="book_library_manage_reject_tjf.jsp" class="modulePanelItem">管理图书资料库(驳回)</a>
<!-- 
	<a href="javascript:selectVerifyModule(1)" class="modulePanelItem">管理可疑违禁图书</a>
	<a href="javascript:selectVerifyModule(2)" class="modulePanelItem">管理可疑关键字图书</a>
	<a href="javascript:selectVerifyModule(3)" class="modulePanelItem">管理可疑出版社图书</a>
 -->
<a href="javascript:selectVerifyModule(4)" class="modulePanelItem">管理图书资料库(待确认)</a>
</div>

<!--表单开始-->
<form name="frmSearch" id="frmSearch" method="POST" action="">
<!--搜索选项栏-->
<div class="search">
<table width="96%" border="0" cellspacing="0" cellpadding="0">
<tr>
    <td width="180" rowspan="2" align="left"></td>
    <td height="26" align="left" valign="bottom">
	<!-- 类型的下拉 -->
    <select name="searchType" id="searchType" onChange="hideQueryBox(this.value)">
	    <option value="0">全文</option>
	    <option value="1">书名</option>
	    <option value="2">作者</option>
	    <option value="3">出版社</option>
    </select>
    <script>$search("searchType").value="<%=searchType%>";</script>
		<!-- 关键字 -->
        <input type="text" size="40" maxlength="250" name="keywords" id="keywords" value="<%=keywords%>" />
        <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onclick="clearQueryCondition();" />
        <input type="submit" value="搜索" class="searchSub" onClick="initSearchForm()"/>
        
        <input type="hidden" id="docBaseType" name="docBaseType" value="<%=docBaseType%>" />
        <input type="hidden" id="act" name="act" value="<%=act%>" />
        <input type="hidden" id="page" name="page" value="<%=page%>" />
        <input type="hidden" id="keywordGroupId" name="keywordGroupId" value="<%=keywordGroupId%>" />

        <span>	<a href="javascript:showDistrustKeywords(true)">选择可疑关键字</a>
        <div id="distrustKeywordsPanel" class="distrustKeywords" style="display:none" ></div>
        <span>&nbsp;
<!--         <span><a href="javascript:showBelivePress(true)">选择可信任出版社</a>
        <div id="belivePressPanel" class="belivePress" style="display:none" ></div>
        </span>
 -->     
        <script type="text/javascript">loadAssistantData();</script>    </td>
    </tr>
<tr>
    <td height="26" colspan="3" align="left" valign="middle" style="padding-left:33px;color:gray;">
    <div id="sub_panel" style="float:left;margin-right:10px;">
    作者：<input name="author" type="text" id="author" value="<%=author%>" size="12" /> 
    出版社：<input name="press" type="text" id="press" value="<%=press%>" size="12" />
    </div>
    </td>
    </tr>
</table>
</div>
<!--查询结果选项栏-->
<div class="Sort">
<%String orderSortInfoTJF = request.getParameter("orderSortInfoTJF");%>
排序：<select id="orderSortInfoTJF" name="orderSortInfoTJF" onchange="reloadByOrderSortInfoTJF(this.value);">
		<option value="default">默认排序</option>
		<%if(null !=orderSortInfoTJF && orderSortInfoTJF.equals("pubDate_asc")){%>
			<option value="pubDate_asc" selected="selected">出版时间 由远到近↑</option>
			<option value="pubDate_desc">出版时间 由近到远↓</option>
		<%}else if(null !=orderSortInfoTJF && orderSortInfoTJF.equals("pubDate_desc")){ %>
			<option value="pubDate_asc">出版时间 由远到近↑</option>
			<option value="pubDate_desc" selected="selected">出版时间 由近到远↓</option>
		<%} else {%>
			<option value="pubDate_asc">出版时间 由远到近↑</option>
			<option value="pubDate_desc">出版时间 由近到远↓</option>
		<%}%>
	</select>
&nbsp;&nbsp;筛选 &nbsp;&nbsp;&nbsp;&nbsp;
<%String isExistPicTJF = request.getParameter("isExistPicTJF");%>
图片：<select id="isExistPicTJF" name="isExistPicTJF" onchange="reloadByOrderSortInfoTJF(this.value);">
		<option value="all">全部</option>
		<%if(null !=isExistPicTJF && isExistPicTJF.equals("1")){%>
			<option value="1" selected="selected">有图</option>
			<option value="0">无图</option>
		<%} else if (null !=isExistPicTJF && isExistPicTJF.equals("0")){%>
			<option value="1">有图</option>
			<option value="0" selected="selected">无图</option>
		<%} else {%>
			<option value="1">有图</option>
			<option value="0">无图</option>
		<%}%>
	 </select>&nbsp;&nbsp;
<%String isExistDescInfoTJF = request.getParameter("isExistDescInfoTJF");%>
描述：<select id="isExistDescInfoTJF" name="isExistDescInfoTJF" onchange="reloadByOrderSortInfoTJF(this.value);">
		<option value="all">全部</option>
		<%if(null !=isExistDescInfoTJF && isExistDescInfoTJF.equals("1")){%>
			<option value="1" selected="selected">有描述</option>
			<option value="0">无描述</option>
		<%} else if (null !=isExistDescInfoTJF && isExistDescInfoTJF.equals("0")){%>
			<option value="1">有描述</option>
			<option value="0" selected="selected">无描述</option>
		<%} else {%>
			<option value="1">有描述</option>
			<option value="0">无描述</option>
		<%}%>
	 </select>	 
<%
if ("DistrustKeyword".equalsIgnoreCase(docBaseType) && !"".equals(distrustKeywordGroupHtml)) {
%>
&nbsp;筛选 &nbsp;可疑关键字：<select name="keywordGroupId" id="keywordGroupId" onChange="queryKeywordGroup(this.value)">
<%=distrustKeywordGroupHtml%>
</select>
<script>$search("keywordGroupId").value="<%=keywordGroupId%>";</script>
<br />
<div style="padding:2px;">
<%
    out.write(keywordGroupContent);
}
%>
</div>
</div>

<!--查询结果列表开始-->
<%=list_contents%>
<!--查询结果列表结束-->

</form>
<!--表单结束-->

<div class="copyright"><label>版权所有 © 2002-2010 孔夫子旧书网</label></div>

</body>
</html>
 