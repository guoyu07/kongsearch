<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%!

    /**
     * 取得规范格式的日期(yyyy-mm-dd)
      * @param date
     * @return
     */
    private String formatDate(String date)
    {
        String normalDate = "";
        try{
            normalDate = date.substring(0,4) + "-"
                       + date.substring(4,6) + "-"
                       + date.substring(6,8);
        }catch(Exception ex){
            normalDate = "0000-00-00";
        }
        return normalDate;
    }

    /**
     * 取得规范格式的日期(yyyy-mm)
      * @param date
     * @return
     */
    private String formatDateYM(String date){
        String normalDate = "";
        try{
            normalDate = date.substring(0,4) + "-"
                       + date.substring(4,6);
        }catch(Exception ex){
            normalDate = "0000-00";
        }
        return normalDate;
    }

    /**
     * 取得图书的类别描述
      * @param id
     * @return
     */
    private String getBookCategory(int id)
    {
        if(id == 99){
            return "杂货";
        }

        String[] category=new  String[]{"所有","文学","哲学","历史","艺术","法律","外文古旧书","社会文化","线装古旧书","民国旧书","旧期刊","理科、工程技术","收藏类图书","语言、文字","经济","自然科学","工具书","医药卫生","政治","体育","综合类、其他类","名人墨迹","国学古籍","地理","军事","管理","生活类","少儿类","教育","宗教","心理","计算机/网络","二手大学教材","文革书刊资料","革命（红色）文献","连环画","邮品类","字画类","老照片/唱片/地图"};
        return ((0 <= id && id <= 38)? category[id] :""+id);
    }

    private String buildCategoryOptions(int id, Map<String, Integer> facetCounts)
    {
        String[] category=new  String[]{"0=所有","8=线装古旧书","9=民国旧书","21=名人墨迹","10=旧期刊","6=外文古旧书","22=国学古籍","1=文学","3=历史","23=地理","5=法律","24=军事","14=经济","25=管理","4=艺术","26=生活类","27=少儿类","7=社会文化","28=教育","13=语言、文字","2=哲学","29=宗教","30=心理","18=政治","19=体育","11=理科、工程技术","15=自然科学","17=医药卫生","31=计算机/网络","16=工具书（辞书）","32=二手大学教材","33=文革书刊资料","34=红色文献","35=连环画","12=收藏类图书","36=邮品类","37=字画类","38=老照片/唱片/地图","20=综合类、其他类","99=杂货"};
        String target = String.valueOf(id);
        Integer count = 0;
        StringBuffer buffer = new StringBuffer();
        String prefix, postfix, selectOption;
        for(int i=0; i < category.length; i++){
            String[] items = category[i].split("=");
            if(null != facetCounts){
                count = facetCounts.get(items[0]);
            }

            prefix = "<option value=\"" + items[0] + "\"";
            if(target.equals(items[0])){
                selectOption = "selected=\"selected\">";
            }else {
                selectOption = ">";
            }
            postfix = ("0".equals(items[0]) || count==0) ? items[1] + "</option>" : items[1] + "(" + count + ")</option>";
            
            buffer.append(prefix + selectOption + postfix);
        }
        return buffer.toString();
    }

    private String buildCategoryOptions(int id)
    {
        String[] category=new  String[]{"0=所有","8=线装古旧书","9=民国旧书","21=名人墨迹","10=旧期刊","6=外文古旧书","22=国学古籍","1=文学","3=历史","23=地理","5=法律","24=军事","14=经济","25=管理","4=艺术","26=生活类","27=少儿类","7=社会文化","28=教育","13=语言、文字","2=哲学","29=宗教","30=心理","18=政治","19=体育","11=理科、工程技术","15=自然科学","17=医药卫生","31=计算机/网络","16=工具书（辞书）","32=二手大学教材","33=文革书刊资料","34=红色文献","35=连环画","12=收藏类图书","36=邮品类","37=字画类","38=老照片/唱片/地图","20=综合类、其他类","99=杂货"};
        String target = String.valueOf(id);
        StringBuffer buffer = new StringBuffer();
        for(int i=0; i < category.length; i++){
            String[] items = category[i].split("=");
            if(target.equals(items[0])){
                buffer.append("<option value=\""+items[0]+"\" selected=\"selected\" >"+items[1]+"</option>");
            }else{
                buffer.append("<option value=\""+items[0]+"\" >"+items[1]+"</option>");
            }
        }
        return buffer.toString();
    }

    /**
     * 创建可疑关键词分组的Options元素
     */
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
     * 取得图书品相描述
     */
    private String getBookQuality(String quality)
    {
        Map<String, String> map = new HashMap<String, String>();
        map.put("10","一");
        map.put("20","二");
        map.put("30","三");
        map.put("40","四");
        map.put("50","五");
        map.put("60","六");
        map.put("65","六五");
        map.put("70","七");
        map.put("75","七五");
        map.put("80","八");
        map.put("85","八五");
        map.put("90","九");
        map.put("95","九五");
        map.put("100","十");

        String value = (String) map.get(quality);
        if(null == value || "".equals(value)){
            value = "一";
        }
        // return value+"品";
        return value;
    }

    /**
     * 取得业务类型的文字描述
     */
    private String getBizTypeDesc(String bizType)
    {
        if("shop".equals(bizType)){
            return "书店";
        }
        if("bookstall".equals(bizType)){
            return "书摊";
        }
        return "";
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
     * 显示图书查询结果(用于删除图书)
     * @param bookList
     * @return
     */
    private void displayHitsTableForDelete(ArrayList bookList, JspWriter out, String docBaseType) throws Exception{
        String shopSite="http://shop.kongfz.com/";
        String bookSite="http://book.kongfz.com/";
        String tanSite="http://tan.kongfz.com/";
        String bookUrl = "";
        String shopHomepage = "";
        StringBuffer buffer = new StringBuffer();

        buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"bookList\">");
        buffer.append("<tr height=\"30\" align=\"center\">");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\"><img src=\"./images/smile.gif\" id=\"smile\" title=\"Ahoy!\" style=\"cursor:pointer\" /></td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\">业务</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"12%\">书店名称</td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">城市</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"\">书名</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">类别</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">作者</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">出版社</td> ");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">出版时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\">品相</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">售价</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">上书时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">操作</td>");
        buffer.append("</tr></table>");
        out.print(buffer.toString());
        
        for(int i = 0, length = bookList.size(); i < length; i++){
            buffer.setLength(0);
            Map map = (Map)bookList.get(i);
            String indexGroup   = StringUtils.strVal(map.get("indexGroup"));
            int saleStatus      = StringUtils.intVal(map.get("saleStatus"));
            String bookId       = StringUtils.strVal(map.get("bookId"));
            String bookName     = StringUtils.strVal(map.get("bookName")).trim();
            String bookName_hl  = StringUtils.strVal(map.get("bookName_hl")).trim();
            String shopId       = StringUtils.strVal(map.get("shopId"));
            String shopName     = StringUtils.strVal(map.get("shopName")).trim();
            String area         = StringUtils.strVal(map.get("area"));
            String author       = StringUtils.strVal(map.get("author")).trim();
            String author_hl    = StringUtils.strVal(map.get("author_hl")).trim();
            String press        = StringUtils.strVal(map.get("press")).trim();
            String press_hl     = StringUtils.strVal(map.get("press_hl")).trim();
            String price        = StringUtils.strVal(map.get("price"));
            String addTime      = formatDate(StringUtils.strVal(map.get("addTime")));
            String isCreatePage = StringUtils.strVal(map.get("isCreatePage"));
            String pubDate      = formatDateYM(StringUtils.strVal(map.get("pubDate")));
            int catId           = StringUtils.intVal(map.get("catId"));
            String category     = getBookCategory(StringUtils.intVal(map.get("catId")));
            String quality      = getBookQuality(StringUtils.strVal(map.get("quality")));
            boolean hasPic      = (StringUtils.intVal(map.get("hasPic")) == 1);
            int number          = StringUtils.intVal(map.get("number"));
            String bookDesc     = StringUtils.strVal(map.get("bookDesc")).trim();
            String bizType      = StringUtils.strVal(map.get("bizType"));
            String isbn         = StringUtils.strVal(map.get("isbn"));

            String site = "";
            if(bizType.equals("shop")){
                shopHomepage = "http://shop.kongfz.com/book/" + shopId + "/";
                site = shopSite;
                if(0 == saleStatus){
                    bookUrl = shopSite + "book_detail.php?bookId=" + bookId + "&shopId=" + shopId;
                } else {
                    bookUrl = bookSite + shopId + "/" + bookId + "/";
                }
            }else if(bizType.equals("bookstall")){
                shopHomepage = "http://tan.kongfz.com/book/" + shopId + "/";
                site = tanSite;
                bookUrl = tanSite + shopId + "/" + bookId + "/";
            }

            buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"bookList\">");
            buffer.append("<tr bgcolor=\"" + ((i % 2 == 0) ? "#EFEFEF" : "#ffffff") + "\">");
            buffer.append("<td width=\"3%\">&nbsp;</td>");
            buffer.append("<td width=\"3%\">" + getBizTypeDesc(bizType) +"&nbsp;</td>");
            buffer.append("<td width=\"12%\"><a href=\"javascript:quickQuery('"+shopName+"')\" title=\""+area+"\">" + shopName +"</a><a href=\""+shopHomepage+"\" target=\"_blank\"><img border=\"0\" src=\"./images/bookstore.gif\" /></a></td>");
            //buffer.append("<td width=\"8%\">" + area +"&nbsp;</td>");
            buffer.append("<td width=\"\"><a href=\""+bookUrl+"\" target=\"_blank\" title=\""+bookDesc+"\">" + bookName_hl + (hasPic ? "<label style=\"color:#FF0000\">(图)</label>" : "") + "</a>&nbsp;</td>");
            buffer.append("<td width=\"8%\"><a href=\"javascript:queryCategory('"+catId+"')\">" + category +"</a>&nbsp;</td>");
            buffer.append("<td width=\"10%\">" + author_hl +"&nbsp;</td>");
            buffer.append("<td width=\"10%\"><a href=\"javascript:quickQuery('"+press+"')\">" + press_hl +"</a>&nbsp;</td>");
            buffer.append("<td width=\"5%\">" + pubDate +"&nbsp;</td>");
            buffer.append("<td width=\"3%\">" + quality +"&nbsp;</td>");
            buffer.append("<td width=\"5%\">" + price +"&nbsp;</td>");
            buffer.append("<td width=\"8%\">" + addTime +"&nbsp;</td>");
            buffer.append("<td width=\"6%\">&nbsp;---&nbsp;");
            buffer.append("</td>");
            buffer.append("</tr></table>\n");
            out.write(buffer.toString());
        }
    }
%>
<%
    /****************************************************************************
     * 设置页面中使用UTF-8编码
     ****************************************************************************/
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

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
    String permission = "manageIndex";
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
    String docBaseType = StringUtils.strVal(request.getParameter("docBaseType"));
    String keywordGroupId = StringUtils.strVal(request.getParameter("keywordGroupId"));

    String keywords = StringUtils.strVal(request.getParameter("query"));

    String author = StringUtils.strVal(request.getParameter("author")).trim();
    String press = StringUtils.strVal(request.getParameter("press")).trim();

    int searchType = StringUtils.intVal(request.getParameter("searchType"));
    int sortType = StringUtils.intVal(request.getParameter("sorttype"));
    int current_page = StringUtils.intVal(request.getParameter("page"));
    int category = StringUtils.intVal(request.getParameter("category"));
    //String categoryOptionsHtml = buildCategoryOptions(category);

    String bizType = StringUtils.strVal(request.getParameter("bizType"));
    String isNewBook = StringUtils.strVal(request.getParameter("isNewBook"));
    String hasPic = StringUtils.strVal(request.getParameter("hasPic"));


    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface manager = null;
    Map resultSet = null;
    String serverStatus = "";
    ArrayList documents = new ArrayList();
    String currentPage = "0";
    int bookTotal = 0;
    String pageTotal = "0";
    String searchTime = "0";
    List<Map<String, Object>> bookInfoList = null;
    Map<String, String> distrustKeywordGroupInfo = null;
    String distrustKeywordGroupHtml = "";
    String keywordGroupContent = "";
    Map<String, Integer> facetCounts = null;
    try{
        //取得远程服务器接口实例, 根据未售或已售调用不同的远程对象
        manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.83:9821/BookVerifyService");
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(null != manager){
        // 查询索引服务
        if("Search".equalsIgnoreCase(act)){
            HashMap parameters = new HashMap();
            parameters.put("bizType", bizType);// 业务类型
            parameters.put("docBaseType", docBaseType);//选择业务模块
            parameters.put("groupId", keywordGroupId);
            
            parameters.put("category", String.valueOf(category));
            parameters.put("sortType", String.valueOf(sortType));
            parameters.put("isNewBook", String.valueOf(isNewBook));
            parameters.put("hasPic", String.valueOf(hasPic));

            switch(searchType){
                case 0: parameters.put("keywords", keywords); break;
                case 1: parameters.put("bookName", keywords); break;
                case 2: parameters.put("author", keywords);   break;
                case 3: parameters.put("press", keywords);    break;
                case 4: parameters.put("bookDesc", keywords); break;
            }
            if(!"".equals(author)){
                parameters.put("author", author);
            }
            if(!"".equals(press)){
                parameters.put("press", press);
            }

            //查询类配置参数
            parameters.put("currentPage", String.valueOf(current_page));
            parameters.put("paginationSize", "100");
            //parameters.put("sortDefault", );

            //调用远程查询接口
            try{
                resultSet = manager.work("FilteredSearch", parameters);
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器查询失败。";
            }

            String result = "";
            if(null != resultSet){
                //处理查询结果
                result = StringUtils.strVal(resultSet.get("result"));
                documents = (ArrayList) resultSet.get("documents");
            }else{
                serverStatus = "服务器信息：未知错误。";
            }

            if("0".equals(result)){
                //将查询到的图书列表输出
                currentPage = StringUtils.strVal(resultSet.get("currentPage"));
                bookTotal   = StringUtils.intVal(resultSet.get("hitsCount"));
                pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));
                searchTime  = StringUtils.strVal(resultSet.get("searchTime"));
                distrustKeywordGroupInfo = (Map<String, String>) resultSet.get("distrustKeywordGroupInfo");
                distrustKeywordGroupHtml = buildKeywordGroupOptions(distrustKeywordGroupInfo, keywordGroupId);
                keywordGroupContent = StringUtils.strVal(resultSet.get("keywordGroupContent"));
                facetCounts = (Map<String, Integer>) resultSet.get("facetCounts");
                serverStatus = "ok";
            }else if("1".equals(result)){
                serverStatus = "服务器信息：索引为空，或未建立，或正在建立索引。";
            }else if("2".equals(result)){
                serverStatus = "服务器信息：查询受阻，正在将磁盘索引载入内存。";
            }else if("3".equals(result)){
                serverStatus = "服务器信息：查询过程中出现错误。";
            }else{
                serverStatus = "服务器信息：未知错误。";
            }
        }

    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }
    //System.out.println(serverStatus);
    String categoryOptionsHtml = buildCategoryOptions(category, facetCounts);

%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>查看已筛选图书</title>
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

    .sort{ 
    width:99%; 
    height:28px; 
    margin:0px 0px 5px 0px; 
    padding-top:4px;
    border:1px solid #FFC44C; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#FFF7E6; 
    }

    .searchSub{ 
    background:url(./images/bg_searchsub.gif); 
    border:1px solid #d17528; 
    width:80px;
    padding-top:2px; 
    font-weight:bold; 
    color:#fff;
    }

    #Page td{ font-size:12px; line-height:200%;}
    .bookList td{ font-size:12px; line-height:220%!important; line-height:150%;}
    .bookList td a{ color:#0000ba; text-decoration:none;}
    .bookList td a:hover{ color:red; text-decoration:underline;}

    .search{
    width:99%; 
    height:62px; 
    border-bottom:1px solid #CCCCCC; 
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
    padding-top:20px;
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
    .isNewBookNomal{
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
    border-bottom:1px solid #adc1dc; 
    font-size:14px; 
    line-height:30px; 
    text-align:left; 
    background-color:#FEF0D0; 
    }
    .modulePanelItem{
    float:left;
    border:1px dashed #F6881B;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#000000;
    text-decoration:none;
    }
    .modulePanelItem:hover {
    color:white;
    text-decoration:none;
    background-color:#F6881B;
    }
    .modulePanelItemSel{
    float:left;
    border:1px dashed #F6881B;
    margin-left:2px;
    padding:0px 4px 0px 4px;
    color:#FFFFFF;
    font-weight:bold;
    text-decoration:none;
    background-color:#F6881B;
    }
    .modulePanelItemSel:hover {
    color:#FFFFFF;
    text-decoration:none;
    background-color:#F6881B;
    }
</style>
</head>
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

    function setSort(type){
        $search("sorttype").value = type;
        go(1);
    }

    function showNewBook(isNewBook){
        $search("isNewBook").value = isNewBook;
        $search("frmSearch").submit();
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

    function initSearchForm(){
        $search('sorttype').value=0;
        $search('isNewBook').value='-1';
        $search('category').value=0;
        $search("keywordGroupId").value = "";
        $search("hasPic").value="-1";
    }

    var m_isCheckAll = false;
   
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('bookInfo[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }
    
    /**
     * 审核图书
     */
    function verifyBook(act, bookInfo)
    {
        var titleMap = {
        "approve":     "是否通过所选项目？",
        "reject":      "是否驳回所选项目？",
        "delete":      "是否删除所选项目？",
        "unconfirmed": "是否待确认所选项目？"
        };
        var title = titleMap[act];

        if(null != bookInfo && !confirm(title)){
            return void(0);
        }

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
            alert("请选择要操作的项目，再执行审核操作！");return;
        }
        if((bookInfo == null) && (!confirm(title))){return;}
        
        $search('act').value = act;
        $search('frmSearch').submit();
    }

    var iframe = null;// 遮罩窗口对象

    /**
     * 显示可疑关键字列表
     */
    function showDistrustKeywords(isVisible){
        function hideDistrustKeywordsPanel(){showDistrustKeywords(false);}
        var panel = $search('distrustKeywordsPanel');
        if(!isVisible){
            panel.style.display="none";
            iframe.style.display = 'none';
            removeEventListener(document.documentElement, 'click', hideDistrustKeywordsPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            panel.style.zIndex = 65535;

            iframe.style.left = pos[0] + 'px';
            iframe.style.top = (pos[1]+15) + 'px';
            iframe.style.width = panel.offsetWidth  + 'px';
            iframe.style.height = panel.offsetHeight + 'px';
            iframe.style.display = 'block';

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
            iframe.style.display = 'none';
            removeEventListener(document.documentElement, 'click', hideBelivePressPanel);
            return;
        }else{
            panel.style.display="block";
            var pos = findPos(panel.parentNode);
            panel.style.left=pos[0]+'px';
            panel.style.top=(pos[1]+15)+'px';
            panel.style.zIndex = 65535;

            iframe.style.left = pos[0] + 'px';
            iframe.style.top = (pos[1]+15) + 'px';
            iframe.style.width = panel.offsetWidth  + 'px';
            iframe.style.height = panel.offsetHeight + 'px';
            iframe.style.display = 'block';

            addEventListener(document.documentElement, 'click', hideBelivePressPanel);
        }
    }

    /**
     * 创建遮罩窗口
     */
    function createBoardWindow()
    {
        iframe = document.createElement('IFRAME');
        iframe.frameBorder=0;
        iframe.style.cssText="display:none;position:absolute;left:0px;top:0px;";
        document.body.appendChild(iframe);
    }

    /**
    * 装入辅助数据
    */
    function loadAssistantData(){
        createBoardWindow();
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

    function quickQuery(keywords){
        $search('keywords').value = keywords;
        $search('frmSearch').submit();
    }

    function queryCategory(catId){
        $search('category').value = catId;
        $search('frmSearch').submit();
    }

    function selectVerifyModule(module) {
        var map = {
            "0":""
        };
        $search('docBaseType').value = map[module];
        $search("keywordGroupId").value = "";
        $search('sorttype').value=0;
        $search('isNewBook').value='-1';
        $search('category').value=0;
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search("bizType").value="";
        $search("hasPic").value="-1";
        $search('frmSearch').submit();
    }
    
    function setModulePanelHighlight(module) {
        var map = {
            "":0
        };
        var items = $search("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    function queryKeywordGroup(groupId) {
        $search("keywordGroupId").value=groupId;
        $search('frmSearch').submit();
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search("bizType").value="";
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

    function executeAssistTask(task)
    {
        if(null == task || "" == task ){
            alert("请选择要执行的操作，然后再试！");
            return;
        }
        $search('act').value = 'assist';
        $search('frmSearch').submit();
    }
    
    function showHasPic(hasPic)
    {
        $search("hasPic").value = hasPic;
        $search("frmSearch").submit();
    }

    /**
     * 使选区高亮
     */
    function enableSelectionHighlight()
    {
        var tables = document.getElementsByTagName("table");
        for(var index in tables){
            setHighlight(tables[index]);
        }

        function setHighlight(obj)
        {
            if(obj.className != "bookList"){
                return;
            }
            obj.onmouseover = function(){
                obj.style.backgroundColor="#FFC44C";
            };
            obj.onmouseout = function(){
                obj.style.backgroundColor="#FFFFFF";
            };
        }
    }

</script>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>
</HEAD>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="view_filtered.jsp" class="menuItemSel">查看已筛选图书</a>
</div>

<div class="modulePanel" id="modulePanel">
<a href="javascript:selectVerifyModule(0)" class="modulePanelItem">查看已筛选图书</a>
</div>
<script>setModulePanelHighlight("<%=docBaseType%>");</script>

<form name="frmSearch" id="frmSearch" method="post" action="" >
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="15%" align="left">&nbsp;</td>
    <td width="8%" align="left" valign="bottom">
    <select name="searchType" id="searchType" onChange="hideQueryBox(this.value)">
    <option value="0">全文</option>
    <option value="1">书名</option>
    <option value="2">作者</option>
    <option value="3">出版社</option>
    <option value="4">描述</option>
    </select>
    <script>$search("searchType").value="<%=searchType%>";</script>
    </td>
    <td height="26" colspan="2" align="left" valign="bottom">

    <input type="text" id="keywords" name="query" size="40" maxlength="350" value="<%=keywords%>" title="<%=keywords%>" />

    <select name="bizType" id="bizType">
    <option value="">全部</option>
    <option value="shop">书店</option>
    <option value="bookstall">书摊</option>
    </select>
    <script>$search("bizType").value = "<%=bizType%>";</script>
    
    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="clearQueryCondition();" />
    <input type="submit" value="搜 索" class="searchSub" onClick="initSearchForm()"/>
    <input type="hidden" name="isNewBook" id="isNewBook" value="<%=isNewBook%>" />
    <input type="hidden" name="page" id="page" value="" />
    <input type="hidden" name="sorttype" id="sorttype" value="<%=sortType%>" />
    <input type="hidden" id="act" name="act" value="<%=act%>" />
    <input type="hidden" id="docBaseType" name="docBaseType" value="<%=docBaseType%>" />
    <input type="hidden" id="keywordGroupId" name="keywordGroupId" value="<%=keywordGroupId%>" />

    <span><a href="javascript:showDistrustKeywords(true)">选择可疑关键字</a>
    <div id="distrustKeywordsPanel" class="distrustKeywords" style="display:none" ></div>
    </span>&nbsp;
    <span><a href="javascript:showBelivePress(true)">选择可信任出版社</a>
    <div id="belivePressPanel" class="belivePress" style="display:none" ></div>
    </span>
    <script type="text/javascript">loadAssistantData();</script>    </td>
  </tr>
  <tr>
    <td align="left">&nbsp;</td>
    <td height="26" colspan="3" align="left" valign="middle" style="padding-left:42px;color:gray;">
    <div id="sub_panel" style="float:left;margin-right:10px;">
    作者：<input name="author" type="text" id="author" value="<%=author%>" size="12" /> 出版社：<input name="press" type="text" id="press" value="<%=press%>" size="12" />
    </div>
    </td>
    </tr>
</table>
<script>hideQueryBox(<%=searchType%>);</script>
</div>

<div class="sort">
&nbsp;排序：<select id="sorttypeSelect" onChange="setSort(this.value)">
<option value="0" selected="selected">默认排序</option>
<option value="1">价格　从低到高↑</option>
<option value="2">价格　从高到低↓</option>
<option value="3">出版日期　从远到近↑</option>
<option value="4">出版日期　从近到远↓</option>
<option value="5">上书时间　从远到近↑</option>
<option value="6">上书时间　从近到远↓</option>
</select>
<script>$search("sorttypeSelect").value="<%=sortType%>";</script>

&nbsp;&nbsp;筛选&nbsp;&nbsp;

&nbsp;图片：<select id="hasPic" name="hasPic" onChange="showHasPic(this.value)">
<option value="">全部</option>
<option value="1">有图</option>
<option value="0">无图</option>
</select>
<script>$search("hasPic").value="<%=hasPic%>";</script>

&nbsp;新旧书：<select id="isNewBook" onChange="showNewBook(this.value)">
<option value="">全部</option>
<option value="0">旧书</option>
<option value="1">新书</option>
</select>
<script>$search("isNewBook").value="<%=isNewBook%>";</script>

&nbsp;图书类别：<select name="category" id="category" onChange="go(1)"><%=categoryOptionsHtml%></select>

<%
if ("DistrustKeyword".equalsIgnoreCase(docBaseType) && !"".equals(distrustKeywordGroupHtml)) {
%>
&nbsp;可疑关键字：<select name="keywordGroupId" id="keywordGroupId" onChange="queryKeywordGroup(this.value)">
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

<%
//查询结果为空的情况
if("ok".equals(serverStatus) && 0 == bookTotal){
%>
    <div class="result_message">
    <img class="float_left" src="./images/none.gif" />
    <div class="float_left">
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>&nbsp;</div>
        <div>很抱歉！没有找到符合 <label><%=keywords%></label> 的结果。</div>
    </div>
    </div>
<%
}
else if("ok".equals(serverStatus) && bookTotal > 0){
%>

<!--页码导航开始-->
<table align="center" border=0  width="98%" id="Page">
<tr><td height="28" align="left">
<% 
    StringBuffer strPageNavigation = new StringBuffer();
    strPageNavigation.append("<font color='#666666'><b>查询的图书总数：</b></font>" + bookTotal + "&nbsp;");
    strPageNavigation.append("共<font color='#0000ff'>" + pageTotal + "</font>页&nbsp;&nbsp;");
    strPageNavigation.append("现为<font color=red>" + currentPage + "</font>页&nbsp;");

    int page_count = StringUtils.intVal(pageTotal);
    current_page = StringUtils.intVal(currentPage);

    strPageNavigation.append(displayNavigation(page_count, current_page));
    strPageNavigation.append("<label>第<input type=\"text\" size=\"3\" maxlength=\"4\" value=\"\" name=\"gopage\"  onkeydown=\"if(event.keyCode==13){gotopage();}\" />页&nbsp;<input type=\"button\" onclick=\"gotopage()\" value=\"转到\" class=\"goto_button\" /></label>");

    out.print(strPageNavigation.toString());
    out.print("&nbsp;&nbsp;搜索用时 " + searchTime + " 秒&nbsp;&nbsp;");
%>
</td></tr>
</table>
<!--页码导航结束-->

<div>
<%
    try{
        displayHitsTableForDelete(documents, out, docBaseType);
    }catch(Exception ex){
        ex.printStackTrace();
    }
%>
</div>

<!--页码导航开始-->
<table align="center" border=0  width="98%" id="Page">
<tr><td height="28" align="left">
<% 
    out.print(strPageNavigation.toString());
%>
</td></tr>
</table>
<!--页码导航结束-->
<%
}
//系统异常的情况
else
{
%>
    <div class="result_message">
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div><%=serverStatus%></div>
    </div>
<%
}
//-----
%>
</FORM>

<div class="copyright"><label>版权所有 © 2002-2010 孔夫子旧书网</label></div>
<script>enableSelectionHighlight();</script>
<script>
(function(){var p=[
"\u6625\u6C5F\u6F6E\u6C34\u8FDE\u6D77\u5E73\u3000\u6D77\u4E0A\u660E\u6708\u5171\u6F6E\u751F",
"\u6EDF\u6EDF\u968F\u6CE2\u5343\u4E07\u91CC\u3000\u4F55\u5904\u6625\u6C5F\u65E0\u6708\u660E",
"\u6C5F\u6D41\u5B9B\u8F6C\u7ED5\u82B3\u7538\u3000\u6708\u7167\u82B1\u6797\u7686\u4F3C\u9730",
"\u7A7A\u91CC\u6D41\u971C\u4E0D\u89C9\u98DE\u3000\u6C40\u4E0A\u767D\u6C99\u770B\u4E0D\u89C1",
"\u6C5F\u5929\u4E00\u8272\u65E0\u7EA4\u5C18\u3000\u768E\u768E\u7A7A\u4E2D\u5B64\u6708\u8F6E",
"\u6C5F\u7554\u4F55\u4EBA\u521D\u89C1\u6708\u3000\u6C5F\u6708\u4F55\u5E74\u521D\u7167\u4EBA",
"\u4EBA\u751F\u4EE3\u4EE3\u65E0\u7A77\u5DF2\u3000\u6C5F\u6708\u5E74\u5E74\u53EA\u76F8\u4F3C",
"\u4E0D\u77E5\u6C5F\u6708\u7167\u4F55\u4EBA\u3000\u4F46\u89C1\u957F\u6C5F\u9001\u6D41\u6C34",
"\u767D\u4E91\u4E00\u7247\u53BB\u60A0\u60A0\u3000\u9752\u67AB\u6D66\u4E0A\u4E0D\u80DC\u6101",
"\u8C01\u5BB6\u4ECA\u591C\u6241\u821F\u5B50\u3000\u4F55\u5904\u76F8\u601D\u660E\u6708\u697C",
"\u53EF\u601C\u697C\u4E0A\u6708\u5F98\u5F8A\u3000\u5E94\u7167\u79BB\u4EBA\u5986\u955C\u53F0",
"\u7389\u6237\u5E18\u4E2D\u5377\u4E0D\u53BB\u3000\u6363\u8863\u7827\u4E0A\u62C2\u8FD8\u6765",
"\u6B64\u65F6\u76F8\u671B\u4E0D\u76F8\u95FB\u3000\u613F\u968F\u6708\u534E\u6D41\u7167\u541B",
"\u6C5F\u6C34\u6D41\u6625\u53BB\u6B32\u5C3D\u3000\u6C5F\u6F6D\u843D\u6708\u590D\u897F\u659C",
"\u659C\u6708\u6C89\u6C89\u85CF\u6D77\u96FE\u3000\u78A3\u77F3\u6F47\u6E58\u65E0\u9650\u8DEF",
"\u4E0D\u77E5\u4E58\u6708\u51E0\u4EBA\u5F52\u3000\u843D\u6708\u6447\u60C5\u6EE1\u6C5F\u6811"
];window.status=p[Math.floor(Math.random()*p.length)];})();
</script>
</body>
</html>
