<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="java.net.URLEncoder"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface" %>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ include file="cls_memcached_session.jsp"%>
<%@ page import="com.kongfz.dev.biz.util.CategoryHelper" %>

<%@ page import="com.kongfz.sphinx.utils.CategoryUtils"%>
<!-- 新搜索审核 -->
<%@ page import="com.kongfz.verify.interfaces.INeoSearchBookVerify" %>
<%@ page import="com.kongfz.verify.impl.NeoSearchBookVerify" %>

<%@ page import="com.kongfz.verify.impl.NeoDataBookVerify" %>
<%@ page import="com.kongfz.verify.interfaces.INeoDataBookVerify" %>
<%@ page import="java.lang.Thread" %>
<%@ page import="java.lang.Runnable" %>

<!-- 添加新版关键字检索  使用@ include/admin/keywords/artDialogImports.jsp-->
<%@ include file="/admin/keywords/artDialogImports.jsp"%>

<%!

    /**
     * 取得提交的违禁图书的列表
     */
    private static List<Map<String, Object>> getViolativeItemList(String[] itemInfoList){
        List<Map<String, Object>> recordList = new LinkedList<Map<String, Object>>();
        if (null == itemInfoList) {
            return recordList;
        }
        
        for (String itemInfo : itemInfoList) {
            String[] items = StringUtils.urldecode(itemInfo).split("\n");
            if (null != items && items.length >= 13) {
                Map<String, Object> record = new HashMap<String, Object>();
                record.put("indexGroup",   items[0].trim());
                record.put("bizType",      items[1].trim());
                record.put("userId",       items[2].trim());
                record.put("shopId",       items[3].trim());
                record.put("itemId",       items[4].trim());
                record.put("saleStatus",   items[5].trim());
                record.put("shopName",     items[6].trim());
                record.put("itemName",     items[7].trim());
                //取出更多字段
                record.put("author",       items[8].trim());
                record.put("press",        items[9].trim());
                record.put("catId",        items[10].trim());
                record.put("price",        items[11].trim());
                record.put("addTime",      items[12].trim());
                record.put("isbn",         items[13].trim());
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
        int maxlength = 650;
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

    private String formatDateYMD(String date){
        String normalDate = "";
        try{
            normalDate = date.substring(0,4) + "-"
                       + date.substring(4,6) + "-"
                       + date.substring(6,8);
        }catch(Exception ex){
            normalDate = "0000-00-00";
        }
        if("0000-00-00".equals(normalDate)){
            normalDate =  "不详";
        }
        return normalDate;
    }



    private String buildCategoryOptions(String id, Map<String, Integer> facetCounts, Map<String, String> itemTopCategories)
    {
        String target = id;
        Integer count = 0;
        StringBuffer buffer = new StringBuffer();
        buffer.append("<option value=\"0\" >全部</option>");
        String prefix, postfix, selectOption;
        if(itemTopCategories == null){
        	return "";
        }
        Set<String> catIdSet = itemTopCategories.keySet();
        String tmpCatName;
        for(String tmpCatId : catIdSet){
        	tmpCatName =  itemTopCategories.get(tmpCatId);
            if(null != facetCounts){
                count = facetCounts.get(tmpCatId);
            }        	

            prefix = "<option value=\"" + tmpCatId + "\"";
            if(target.equals(tmpCatId)){
                selectOption = "selected=\"selected\">";
            }else {
                selectOption = ">";
            }
            postfix = (count==0) ? tmpCatName + "</option>" : tmpCatName + "(" + count + ")</option>";
            
            buffer.append(prefix + selectOption + postfix);
        }
        
        return buffer.toString();	
    }

    /**
     * 创建可疑关键词分组的Options元素
     */
    private String buildKeywordGroupOptions(Map<String, String> distrustKeywordGroupInfo, String currentGroupId, Map<String, Integer> distrustKeywordFacetCounts)
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

        Integer count = 0;
        String prefix, postfix, selectOption;
        for(String groupId : groupIdArr){
            groupName = distrustKeywordGroupInfo.get(groupId);
            
            if(null != distrustKeywordFacetCounts){
                count = distrustKeywordFacetCounts.get(groupId);
            }

            prefix = "<option value=\""+groupId+"\"";
            selectOption = groupId.equals(currentGroupId) ? "selected=\"selected\">" : ">";
            postfix = count > 0 ? groupName + "("+count+")</option>" : groupName + "</option>";

            buffer.append(prefix + selectOption + postfix);
        }
        return buffer.toString();
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
        if("1".equals(bizType)){
            return "书店";
        }
        if("2".equals(bizType)){
            return "书摊";
        }
        if("3".equals(bizType)){
            return "书店&书摊";
        }
        return "";
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage)
    {
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
    
    private String getBookCategory(String catId)
    {
        if ("".equals(StringUtils.strVal(catId))) {
            return "";
        }
        String catName = CategoryHelper.getCategoryFullName(catId);
        if (!"".equals(catName)) {
            return catName;
        }
        return catId;
    }
	
    /**
   	 * 将当前字符转换成16进制
   	 * @param str 需要转换的字符串
   	 * @return 返回转换并加密后的字符串
   	 */
   	private String toHexString(String str) {
   		StringBuffer sb = new StringBuffer("/product/z");//添加开始
   		int tmp = 0;
   		// 循环字符串的长度
   		for (int i = 0; i < str.length(); i++) {
   			tmp = str.codePointAt(i);// 得到Unicode代码点
   			sb.append("k");// 添加加密字符串
   			sb.append(Integer.toHexString(tmp).toLowerCase());// 转换成16进制
   		}
   		sb.append("y2/");//搜索全部
   		return sb.toString();
   	}
	
	/**
	* 拼接小图片路径
	* @params imgurl 图片地址
	*/
	private String showIMG(String imgurl,boolean big) {
		String oldPicUrl = "http://shopimg.kongfz.com/";
		String newPicUrl = "http://www.kfzimg.com/";
		String showurl = imgurl.startsWith("G") ? newPicUrl : oldPicUrl;
		//显示小图
		showurl += imgurl.replaceAll("(?i)(/_[bns]\\.$|_[bns]$|(_[bns])?\\.(jp(e)?g|gif|png))","");
		if (big) //大图
			showurl += "_b.jpg";
		else //小图
			showurl += "_s.jpg";
		return showurl;
	}
    
   /**
    * 得到指定类型的顶级描述
    */
    private String getBookParentCategory(String catId) {
        if ("".equals(StringUtils.strVal(catId))) {
            return "";
        }
        List<String> allParent = CategoryUtils.getAllParentCatIdPath(catId);
        if (null == allParent || allParent.size() <= 0) {
        	return CategoryUtils.getCategoryName(catId);
        }
        String catName = CategoryUtils.getCategoryName(allParent.get(allParent.size()-1));
        if (!"".equals(catName)) {
            return catName;
        }
        return catId;
    }
   
    /**
     * 得到指定类型的顶级ID
     */
     private String getBookParentCategoryId(String catId) {
         if ("".equals(StringUtils.strVal(catId))) {
             return "";
         }
         List<String> allParent = CategoryUtils.getAllParentCatIdPath(catId);
         if (null == allParent || allParent.size() <= 0) {
         	return catId;
         }
         return allParent.get(allParent.size()-1);
     }
	   
    /**
     * 显示图书查询结果(用于删除图书)
     * @param bookList
     * @return
     */
    private void displayHitsTableForDelete(ArrayList itemList, JspWriter out, String docBaseType) throws Exception
    {
        String shopSite="http://shop.kongfz.com/";
        String bookSite="http://book.kongfz.com/";
        String tanSite="http://tan.kongfz.com/";
        String bookUrl = "";
        String shopHomepage = "";
        StringBuffer buffer = new StringBuffer();
        buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
        buffer.append("<tr height=\"30\" align=\"center\">");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\"><img src=\"./images/smile.gif\" id=\"smile\" title=\"Ahoy!\" onclick=\"checkAll(!m_isCheckAll)\" style=\"cursor:pointer\" /></td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">业务</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">书店名称</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">图片</td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">城市</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"\">书名</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"7%\">类别</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">作者</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">出版社</td> ");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">出版时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">详情</td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\">品相</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">售价</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">上书时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">操作</td>");
        buffer.append("</tr></table>");
        buffer.append("<script>var data =[];</script>");
        out.print(buffer.toString());
        
        for(int i = 0, length = itemList.size(); i < length; i++){
            buffer.setLength(0);
            Map map = (Map)itemList.get(i);
            String indexGroup   = StringUtils.strVal(map.get("indexGroup"));
            int saleStatus      = StringUtils.intVal(map.get("saleStatus"));
            String userId       = StringUtils.strVal(map.get("userId"));
            String itemId       = StringUtils.strVal(map.get("itemId"));
            String itemType       = StringUtils.strVal(map.get("itemType"));
            String itemName     = StringUtils.strVal(map.get("itemName")).trim();
            String itemName_hl  = StringUtils.strVal(map.get("itemName_hl")).trim();
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
            String catId        = getBookParentCategoryId(StringUtils.strVal(map.get("catId")));
            String categoryName = getBookParentCategory(catId);
            String quality      = getBookQuality(StringUtils.strVal(map.get("quality")));
            boolean hasPic      = (1 == StringUtils.intVal(map.get("hasPic")));
            int number          = StringUtils.intVal(map.get("number"));
            String itemDesc     = StringUtils.strVal(map.get("itemDesc")).trim();
            String itemDesc_hl     = StringUtils.strVal(map.get("itemDesc_hl")).trim();
            String bizType      = StringUtils.strVal(map.get("bizType"));
            String isbn         = StringUtils.strVal(map.get("isbn"));
            String personReject = StringUtils.strVal(map.get("personReject"));
            String imgurl		= StringUtils.strVal(map.get("smallImg"));

            String site = "";
            shopHomepage = shopSite + "book/" + shopId + "/";
            site = shopSite;
            bookUrl = bookSite + shopId + "/" + itemId + "/";

            StringBuffer fields = new StringBuffer();
            fields.append(indexGroup+" \n");
            fields.append(bizType+" \n");
            fields.append(userId+" \n");
            fields.append(shopId+" \n");
            fields.append(itemId+" \n");
            fields.append(saleStatus+" \n");
            fields.append(shopName+" \n");
            fields.append(itemName+" \n");
            fields.append(author+" \n");
            fields.append(press+" \n");
            fields.append(StringUtils.intVal(map.get("catId"))+" \n");
            fields.append(price+" \n");
            fields.append(addTime+" \n");
            fields.append(isbn+" \n");
            String item_info = StringUtils.urlencode(fields.toString());
            
            buffer.append("<script>data["+i+"]='"+item_info+"';</script>");
            buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
            buffer.append("<tr bgcolor=\"" + ((i % 2 == 0) ? "#EFEFEF" : "#ffffff") + "\">");
            buffer.append("<td width=\"3%\"><input type=\"checkbox\" name=\"itemInfo[]\" value=\""+item_info+"\" /></td>");
//            buffer.append("<td width=\"6%\">"+getBizTypeDesc(bizType) +"&nbsp;</td>");
           
            buffer.append("<td width=\"8%\"><a href=\"javascript:quickQuery('"+shopName+"')\" title=\""+area+"\">" + shopName +"</a><a href=\""+shopHomepage+"\" target=\"_blank\"><img border=\"0\" src=\"./images/bookstore.gif\" /></a></td>");
            String big_pic = "<div class=\"big_pic\"><span></span><a class=\"big_pic_img\" href=\"javascript:;\"><img src='"+ showIMG(imgurl,true) +"' /></a></div>";
            buffer.append("<td width=\"3%\"><div style=\"position: relative;z-index: 15;\"><a href='http://book.kongfz.com/item_pic_"+shopId+"_"+itemId+"' class=\"small_pic\" target='_blank'><img src='"+ showIMG(imgurl,false) +"' style='width:60px;'/></a>"+big_pic+"</div></td>");
            //buffer.append("<td width=\"8%\">" + area +"&nbsp;</td>");
            buffer.append("<td>");
/**
            if(!"".equals(itemDesc)){
            	buffer.append("<div style=\"overflow:visible;\" onmouseover=\"showTip(this,"+i+")\" onmouseout=\"hideTip(this,"+i+")\">");
            }
*/
            buffer.append("<a href=\""+bookUrl+"\" target=\"_blank\" >" + itemName_hl + (hasPic ? "<label style=\"color:#660000\">(图)</label>" : "") + "</a>&nbsp;");
/**
			if(!"".equals(itemDesc)){
            	buffer.append("<div id=\"divTip"+i+"\" style=\"overflow-y:auto;border:1px solid #cccccc;text-align:left;padding:10px;background-color:white; position:absolute; display:none; max-height:122px;width:90px;*height:122px;\">" +
            						"<span>" + itemDesc_hl+"</span></div></div>");
            }
*/
           // +"【personReject："+personReject+"】" 
            buffer.append("</td>");

            buffer.append("<td width=\"7%\"><a href=\"javascript:queryCategory('"+catId+"')\">" + categoryName +"</a>&nbsp;</td>");
            buffer.append("<td width=\"10%\">" + author_hl +"&nbsp;</td>");
            buffer.append("<td width=\"10%\"><a href=\"javascript:quickQuery('"+press+"')\">" + press_hl +"</a>&nbsp;</td>");
            buffer.append("<td width=\"5%\">" + pubDate +"&nbsp;</td>");
            
            buffer.append("<td width=\"5%\">");
	            buffer.append("<div style=\"position: relative;z-index: 15;\" id='showItemDescDiv'>" + quality + "品");
	            buffer.append("<div id='async_show_item_desc_div' asyncload='false' canShow='' style='display:none;' userid='"+userId+"' itemid='"+itemId+"' saleStatus='"+saleStatus+"'><textarea style='width:200px;height:300px;resize:none;'>xxx</textarea></div></div>");
        	buffer.append("</td>");
            
            //buffer.append("<td width=\"3%\">" + quality +"&nbsp;</td>");
            buffer.append("<td width=\"5%\">" + price +"&nbsp;</td>");
            buffer.append("<td width=\"6%\">" + addTime +"&nbsp;</td>");
            buffer.append("<td width=\"6%\">");
            // 显示可执行操作：通过、驳回、删除、待确认
            /* 2012.11.30 mantis 8081
            buffer.append("<a href=\"javascript:verifyBook('approve',data["+i+"]);\">通过</a> ");
            buffer.append("<a href=\"javascript:verifyBook('reject',data["+i+"]);\">驳回</a> ");
            buffer.append("<a href=\"javascript:verifyBook('delete',data["+i+"]);\">删除</a> ");
            */
            //buffer.append("<a href=\"http://search.kongfz.com/book.jsp?query=" +URLEncoder.encode(itemName, "utf-8") + "&sale=2&category=\" target=\"_BLANK\">在线</a> ");
            buffer.append("<a href=\"http://search.kongfz.com" +toHexString(itemName) + "\" target=\"_BLANK\">在线</a> ");
            buffer.append("<a href='javascript:searchFromLog(\"/admin/new_sphinx/new_sphinx_doc_base_manage.jsp\",\""+itemName+"\");'>已审核</a> <br />");
            buffer.append("<a href='javascript:searchFromLog(\"/admin/verify_log_manage.jsp\",\""+itemName+"\");'>日志</a> ");
            buffer.append("<a href=\"javascript:sendMessage(" + userId +", '"+ itemName +"');\">发消息</a> ");
            if("1".equals(personReject)){
             buffer.append("<label style=\"color:#660000\">(重新上传)</label>");
            }
            buffer.append("</td>");
            buffer.append("</tr></table>\n");
            out.write(buffer.toString());
        }
    }
%>
<%
	String systemPath = request.getContextPath();
	String systemBasePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+systemPath+"/";
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

	if(!MemSession.isLogin("admin")){//未登陆
		response.sendRedirect("index.jsp");
		return;
	}

    //判断管理员权限
    String[] permissions = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "bookVerifyManage";
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
    String docBaseType = StringUtils.strVal(request.getParameter("docBaseType"));//点击的顶部选项卡类别
    String keywordGroupId = StringUtils.strVal(request.getParameter("keywordGroupId"));

    String keywords = StringUtils.strVal(request.getParameter("query"));//关键字
    keywords = filterKeywords(keywords);//过滤关键字特殊字符
	
    String author = StringUtils.strVal(request.getParameter("author")).trim();//作者
    String press = StringUtils.strVal(request.getParameter("press")).trim();//出版社

    int searchType = StringUtils.intVal(request.getParameter("searchType"));//搜索类型[全文/作者/出版社/……]
    int sortType = StringUtils.intVal(request.getParameter("sorttype"));//排序
    int current_page = StringUtils.intVal(request.getParameter("page"));//页码
    String category = StringUtils.strVal(request.getParameter("category"));//图书类别[报纸/古玩杂项/经济/历史/……]

    String bizType = StringUtils.strVal(request.getParameter("bizType"));//所属类型[书店/书摊/书店&书摊]
    String isNewBook = StringUtils.strVal(request.getParameter("isNewBook"));//新旧书[新书/旧书(查询品相)]
    String hasPic = StringUtils.strVal(request.getParameter("hasPic"));//图片[有图/无图]

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
    List<Map<String, Object>> itemInfoList = null;
    Map<String, String> distrustKeywordGroupInfo = null;
    String keywordGroupContent = "";
    Map<String, Integer> facetCounts = null;
    Map<String, Integer> distrustKeywordFacetCounts = null;
    Map<String, String> itemTopCategories = null;
    try{
        //取得远程服务器接口实例, 根据未售或已售调用不同的远程对象
        manager = (ServiceInterface) Naming.lookup("rmi://192.168.1.105:9821/BookVerifyService");
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }

    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(null != manager){
        // 读取未审核图书
        if("Assist".equalsIgnoreCase(act)){
        	//得到读取未审核图书选的当前选中的界面
            String assistTask = StringUtils.strVal(request.getParameter("assistTask"));
            if("ReadUnauditedBook".equalsIgnoreCase(assistTask)){//管理非可疑图书
                //调用远程查询接口
                try{
                    resultSet = manager.work("ReadUnauditedBook", null);
                }catch(Exception ex){
                    ex.printStackTrace();
                }
                //处理请求的结果
                String status = "";
                if(null != resultSet){
                    status = StringUtils.strVal(resultSet.get("status"));
                }

                docBaseType = "";
                if("0".equals(status)){
                    act = "search";
                }
                else if("9".equals(status)){
                    serverStatus = "服务器信息：正在过滤可疑违禁图书，暂时不能读取未审核图书，请稍后再试！";
                    act = "";
                }
                else{
                    serverStatus = "服务器信息：未知错误。";
                    act = "";
                }
            }//管理待复审图书
            else if("BuildWaitApprovedBook".equalsIgnoreCase(assistTask)){
                //调用远程查询接口
                try{
                    resultSet = manager.work("BuildWaitApprovedBook", null);
                }catch(Exception ex){
                    ex.printStackTrace();
                }
                //处理请求的结果
                String status = "";
                if(null != resultSet){
                    status = StringUtils.strVal(resultSet.get("status"));
                }

                docBaseType = "WaitApproved";
                if("0".equals(status)){
                    act = "search";
                }
                else if("9".equals(status)){
                    serverStatus = "服务器信息：正在读取待复审图书，请稍后再试！";
                    act = "";
                }
                else{
                    serverStatus = "服务器信息：未知错误。";
                    act = "";
                }
            }else if ("BuildFrozenBook".equalsIgnoreCase(assistTask)){//管理冻结图书
                //调用远程查询接口
                try{
                    resultSet = manager.work("BuildFrozenBook", null);
                }catch(Exception ex){
                    ex.printStackTrace();
                }
                //处理请求的结果
                String status = "";
                if(null != resultSet){
                    status = StringUtils.strVal(resultSet.get("status"));
                }

                docBaseType = "FrozenBook";
                if("0".equals(status)){
                    act = "search";
                }
                else if("9".equals(status)){
                    serverStatus = "服务器信息：正在读取冻结图书，请稍后再试！";
                    act = "";
                }
                else{
                    serverStatus = "服务器信息：未知错误。";
                    act = "";
                }
            }
            else {
                act = "search";
            }
        }

        // 审核服务：删除、待确认、忽略、取消
        if (StringUtils.inArray(act, "Approve", "Reject", "Delete", "Unconfirmed", "Frozen")) {
            //要审核的图书信息列表
            String[] itemInfoArray = request.getParameterValues("itemInfo[]");
            itemInfoList = getViolativeItemList(itemInfoArray);

            // 组织参数
            HashMap parameters = new HashMap();
            parameters.put("itemInfoList", itemInfoList);
            parameters.put("docBaseType", docBaseType);//选择业务模块
            parameters.put("groupId", keywordGroupId);
            parameters.put("adminRealName", adminRealName);
            parameters.put("task", act);
            parameters.put("verifyMode", "Manual");//人工审核

            //审核图书
            try{
                if("Unconfirmed".equalsIgnoreCase(act)){
                    resultSet = manager.work("AddUnconfirmedBookDoc", parameters);
                } else {
                    resultSet = manager.work("VerifyBook", parameters);
                }
                
                /** 新搜索审核服务  start */
                final String finalAct = act;
              //数据存在才进行审核
				if(null != itemInfoList && itemInfoList.size() > 0){
					final List<Map<String, Object>> finalItemList =  itemInfoList;//需要审核的图书数据
					HashMap<String,String> neoBookParams = new HashMap<String,String>();
                    neoBookParams.put("task",finalAct);
                    neoBookParams.put("origin",null);
                    neoBookParams.put("fieldName","itemId");
                    neoBookParams.put("typeField","bizType");
                   	System.out.println("创建新搜索审核实例");
                    //创建新搜索审核实例
                    INeoSearchBookVerify neoSearch = new NeoSearchBookVerify();
                    /**
                     * 开始审核图书
                     * params.1 : 当前按钮的状态名称["Approve", "Reject", "Delete", "Unconfirmed", "Frozen"]
                     * params.2 : 解析后所选中的图书信息
                     * params.3 : 当前图书唯一标示，在params.2中的key Name
                     * params.4 : 当前图书所属类型，在params.2中的key Name[书店、书摊]
                     * params.5 : 审核操作对象[n = 人工审核]
					 */
                    synchronized (neoSearch){
                    	System.out.println("neoSearch.work");
                        neoSearch.work(neoBookParams,finalItemList);
                    }
                    System.out.println("审核数据库相关内容");
                  	//审核数据库相关内容
                    neoBookParams.put("userIdfieldName","userId");
                    neoBookParams.put("itemIdField","itemId");
                    neoBookParams.put("adminRealName",adminRealName);
                    neoBookParams.put("verifyLog","false");//不记录日志
                    INeoDataBookVerify neoBookVerify = new NeoDataBookVerify();
                    neoBookVerify.work(neoBookParams,finalItemList);
				}
               /** 新搜索审核服务  end */
               
            }catch(Exception ex){
                ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器工作失败。";
            }
           
            //处理删除请求的结果
            String status = "";
            if(null != resultSet){
                status = StringUtils.strVal(resultSet.get("status"));
            }
            
            if("0".equals(status)){
                act = "search";
            }
            else if("5".equals(status)){
                serverStatus = "服务器信息：远程调用出现错误。";
                act = "";
            }
            else if("6".equals(status)){
                serverStatus = "服务器信息：索引清理管理器没有启动。";
                act = "";
            }
            else if("7".equals(status)){
                serverStatus = "服务器信息：删除操作出现异常。";
                act = "";
            }
            else if("8".equals(status)){
                serverStatus = "服务器信息：系统维护中，暂时不能删除索引。请稍等...";
                act = "";
            }
            else if("9".equals(status)){
                serverStatus = "服务器信息：不能执行待确认操作。";
                act = "";
            }
            else{
                serverStatus = "服务器信息：未知错误。";
                act = "";
            }
            //其它错误，略
        }
        
        // 查询索引服务
        if("Search".equalsIgnoreCase(act)){
            HashMap parameters = new HashMap();
            parameters.put("bizType", bizType);// 业务类型
            parameters.put("docBaseType", docBaseType);//选择业务模块[管理全部未审核图书/管理非可疑图书/管理可疑违禁图书/管理可疑关键字图书/管理不详出版社图书/管理待确认图书/管理待复审图书/管理冻结图书]
            parameters.put("groupId", keywordGroupId);//可疑关键字组ID
            
            parameters.put("category", String.valueOf(category));//图书类型
            parameters.put("sortType", String.valueOf(sortType));//排序类型
            parameters.put("isNewBook", String.valueOf(isNewBook));//新旧书
            parameters.put("hasPic", String.valueOf(hasPic));//图片

            switch(searchType){//搜索类型
                case 0: parameters.put("keywords", keywords); break;//全文
                case 1: parameters.put("itemName", keywords); break;//书名
                case 2: parameters.put("author", keywords);   break;//作者
                case 3: parameters.put("press", keywords);    break;//出版社
                case 4: parameters.put("itemDesc", keywords); break;//描述
            }
            if(!"".equals(author)){//有填作者
                parameters.put("author", author);
            }
            if(!"".equals(press)){//有填出版社
                parameters.put("press", press);
            }

            //查询类配置参数
            parameters.put("currentPage", String.valueOf(current_page));//当前页码
            parameters.put("paginationSize", "200");//每页显示数量
            //parameters.put("sortDefault", );

            //调用远程查询接口
            try{
                resultSet = manager.work("DocBaseSearch", parameters);
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
                //distrustKeywordGroupHtml = buildKeywordGroupOptions(distrustKeywordGroupInfo, keywordGroupId);
                keywordGroupContent = StringUtils.strVal(resultSet.get("keywordGroupContent"));
                facetCounts = (Map<String, Integer>) resultSet.get("facetCounts");
                distrustKeywordFacetCounts  = (Map<String, Integer>) resultSet.get("distrustKeywordFacetCounts");
                itemTopCategories  = (Map<String, String>) resultSet.get("itemTopCategories");
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
    String categoryOptionsHtml = buildCategoryOptions(category, facetCounts,itemTopCategories);
    String distrustKeywordGroupHtml = buildKeywordGroupOptions(distrustKeywordGroupInfo, keywordGroupId, distrustKeywordFacetCounts);
%>
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>待审图书管理系统[NOW]</title>
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
#List td {
	font-size: 12px;
	line-height: 220% !important;
	line-height: 150%;
}

#List td a {
	color: #0000ba;
	text-decoration: none;
}
#List td .big_pic{
    background: none repeat scroll 0 0 #FFFFFF;
    display: none;
    left: 70px;
    position: absolute;
    top: 0;
    z-index: 16;
}
#List td  #async_show_item_desc_div{
	background: none repeat scroll 0 0 #FFFFFF;
    display: none;
    left: -200px;
    position: absolute;
    top: 0;
    width:200px;
    height:300px;
    z-index: 16;
}
#List td .big_pic span{
    background: url("../images/search_ico.gif") no-repeat scroll -62px -373px rgba(0, 0, 0, 0);
    height: 18px;
    left: -7px;
    position: absolute;
    top: 20px;
    width: 9px;
    z-index: 19;
}
#List td .big_pic .big_pic_img{
    border: 1px solid #CCCCCC;
    display: block;
    height: 290px;
    overflow: hidden;
    padding: 4px;
    position: relative;
    width: 290px;
}big_pic
#List td .big_pic .big_pic_img img{
	position: relative;
}
#List td a:hover {
	color: red;
	text-decoration: underline;
}

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
        $search("page").value="";
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
        $search('isNewBook').value='';
        $search('category').value=0;
        $search("keywordGroupId").value = "";
        $search("hasPic").value="";
        $search("page").value="";
    }

    var m_isCheckAll = false;
   
    function checkAll(value){
        m_isCheckAll = value;
        $search('smile').src='./images/'+(value?'cry.gif':'smile.gif');
        var elements = document.getElementsByName('itemInfo[]');
            for(var i=0; i < elements.length; i++){
            elements[i].checked=value;
        }
    }
    
    /**
     * 审核图书
     */
    function verifyBook(act, itemInfo)
    {
        var titleMap = {
        "approve":     "是否通过所选项目？",
        "reject":      "是否驳回所选项目？",
        "delete":      "是否删除所选项目？",
        "frozen":      "是否冻结所选项目？",
        "unconfirmed": "是否待确认所选项目？"
        };
        var title = titleMap[act];

        if(null != itemInfo && !confirm(title)){
            return void(0);
        }

        var elements = document.getElementsByName('itemInfo[]');

        if(itemInfo != null){
            for(var i=0; i < elements.length; i++){
                elements[i].checked = (elements[i].value == itemInfo);
            }
        }

        var unchecked = true;
        for(var i=0; i < elements.length; i++){
            if(elements[i].checked){unchecked = false;}
        }
        if(unchecked){
            alert("请选择要操作的项目，再执行审核操作！");return;
        }
        if((itemInfo == null) && (!confirm(title))){return;}
        
        $search('act').value = act;
        $search('frmSearch').submit();
    }

    /**
     * 给店主发信息
     */
    function sendMessage(userId, bookName){
    	if(window.clipboardData) {   
            window.clipboardData.clearData();   
            window.clipboardData.setData("Text", bookName);   
	    } else if(navigator.userAgent.indexOf("Opera") != -1) {   
	         window.location = bookName;   
	    } else if (window.netscape) {   
	         try {   
	              netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");   
	         } catch (e) {   
	              alert("被浏览器拒绝！\n请在浏览器地址栏输入'about:config'并回车\n然后将'signed.applets.codebase_principal_support'设置为'true'");   
	         }   
	         var clip = Components.classes['@mozilla.org/widget/clipboard;1'].createInstance(Components.interfaces.nsIClipboard);   
	         if (!clip)   
	              return;   
	         var trans = Components.classes['@mozilla.org/widget/transferable;1'].createInstance(Components.interfaces.nsITransferable);   
	         if (!trans)   
	              return;   
	         trans.addDataFlavor('text/unicode');   
	         var str = new Object();   
	         var len = new Object();   
	         var str = Components.classes["@mozilla.org/supports-string;1"].createInstance(Components.interfaces.nsISupportsString);   
	         var copytext = bookName;   
	         str.data = copytext;   
	         trans.setTransferData("text/unicode",str,copytext.length*2);   
	         var clipid = Components.interfaces.nsIClipboard;   
	         if (!clip)   
	              return false;   
	         clip.setData(trans,null,clipid.kGlobalClipboard);    
	    }
    	window.open("http://xiaoxi.kongfz.com/member/send_message.php?friendId=" + userId);
    	return;
    }
    
    function searchFromLog(url, itemName){
    	var postForm = document.createElement("form");//表单对象   
        postForm.method="post" ;   
        postForm.action =  url;   
        postForm.target="_blank";
        //查询关键词
        var queryInput = document.createElement("input") ;
        queryInput.setAttribute("name", "query") ;   
        queryInput.setAttribute("value", itemName);   
        postForm.appendChild(queryInput) ;
        //执行的操作
        var actInput = document.createElement("input"); 
        actInput.setAttribute("name","act"); 
        actInput.setAttribute("value", "search");
        postForm.appendChild(actInput);
        //违禁时，销售为全部
        var actInput = document.createElement("input"); 
        actInput.setAttribute("name","sale"); 
        actInput.setAttribute("value", "2"); 
        postForm.appendChild(actInput); 
         
        document.body.appendChild(postForm) ;   
        postForm.submit() ;   
        document.body.removeChild(postForm) ; 
        return;
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
        $search("page").value="";
        $search('frmSearch').submit();
    }

    function queryCategory(catId){
        $search('category').value = catId;
        $search("page").value="";
        $search('frmSearch').submit();
    }

    function selectVerifyModule(module) {
        var map = {
            "0":"",//管理全部未审核图书 
            "1":"NonSuspicious",//管理非可疑图书
            "2":"DistrustBanned",//管理可疑违禁图书
            "3":"DistrustKeyword",//管理可疑关键字图书
            "4":"UnknowPress",//管理不详出版社图书
            "5":"Unconfirmed",//管理待确认图书
            "6":"WaitApproved",//管理待复审图书
            "7":"FrozenBook"//管理冻结图书
        };
        $search('docBaseType').value = map[module];
        $search("keywordGroupId").value = "";
        $search('sorttype').value=0;
        $search('isNewBook').value='';
        $search('category').value=0;
        $search("searchType").value="0";
        $search("keywords").value="";
        $search("author").value="";
        $search("press").value="";
        $search("bizType").value="";
        $search("hasPic").value="";
        $search("page").value="";
        $search('frmSearch').submit();
    }
    
    function setModulePanelHighlight(module) {
        var map = {
            "":0, 
            "NonSuspicious":1,
            "DistrustBanned":2,
            "DistrustKeyword":3,
            "UnknowPress":4,
            "Unconfirmed":5,
            "WaitApproved":6,
            "FrozenBook":7
        };
        var items = $search("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    function queryKeywordGroup(groupId) {
        $search("keywordGroupId").value=groupId;
        $search("page").value="";
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
        $search("page").value="";
        $search("frmSearch").submit();
    }
</script>
<script language="javascript" type="text/javascript" src="distrust_keywords.js"></script>
<script language="javascript" type="text/javascript" src="belive_press.js"></script>
<script language="javascript" type="text/javascript" src="<%=systemBasePath%>admin/new_sphinx/new_sphinx_doc_base_manage.js"></script>
</HEAD>

<body>

<div class="mainMenuPanel">
<a href="index.jsp">主菜单</a>
<a href="new_sphinx/new_sphinx_doc_base_manage.jsp">已审核图书管理系统</a>
<a href="book_verify_manage.jsp" class="menuItemSel">待审图书管理系统</a>
</div>

<div class="modulePanel" id="modulePanel">
<a href="javascript:selectVerifyModule(0)" class="modulePanelItem">管理全部未审核图书</a>
<a href="javascript:selectVerifyModule(1)" class="modulePanelItem">管理非可疑图书</a>
<a href="javascript:selectVerifyModule(2)" class="modulePanelItem">管理可疑违禁图书</a>
<a href="javascript:selectVerifyModule(3)" class="modulePanelItem">管理可疑关键字图书</a>
<a href="javascript:selectVerifyModule(4)" class="modulePanelItem">管理不详出版社图书</a>
<a href="javascript:selectVerifyModule(5)" class="modulePanelItem">管理待确认图书</a>
<a href="javascript:selectVerifyModule(6)" class="modulePanelItem">管理待复审图书</a>
<a href="javascript:selectVerifyModule(7)" class="modulePanelItem">管理冻结图书</a>
</div>
<script>setModulePanelHighlight("<%=docBaseType%>");</script>

<FORM name="frmSearch" id="frmSearch" method="post" action="" accept-charset="utf-8" onsubmit="document.charset='utf-8';">
<div class="search">
<table width="98%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="1px" align="left">&nbsp;</td>
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

    <input type="text" id="keywords" name="query" size="40" maxlength="650" value="<%=keywords%>" title="<%=keywords%>" />

    <select name="bizType" id="bizType">
    <option value="">全部</option>
    <option value="1">书店</option>
    <option value="2">书摊</option>
    <option value="3">书店&书摊</option>
    </select>
    <script>$search("bizType").value = "<%=bizType%>";</script>
    
    <img src="images/clear_input.gif" style="cursor:pointer" title="清空输入框" onClick="clearQueryCondition();" />
    <input type="submit" value="搜 索" class="searchSub" onClick="initSearchForm()"/>
    <input type="hidden" name="page" id="page" value="<%=currentPage%>" />
    <input type="hidden" name="sorttype" id="sorttype" value="<%=sortType%>" />
    <input type="hidden" id="act" name="act" value="<%=act%>" />
    <input type="hidden" id="docBaseType" name="docBaseType" value="<%=docBaseType%>" />
    <input type="hidden" id="keywordGroupId" name="keywordGroupId" value="<%=keywordGroupId%>" />

    <span>
<!--
    	<a href="javascript:showDistrustKeywords(true)">选择可疑关键字</a>
    	<div id="distrustKeywordsPanel" class="distrustKeywords" style="display:none" ></div>
 -->
    </span>&nbsp;
<!--     <span><a href="javascript:showBelivePress(true)">选择可信任出版社</a>
    <div id="belivePressPanel" class="belivePress" style="display:none" ></div>
    </span>
 -->
    <script type="text/javascript">loadAssistantData();</script>    </td>
  </tr>
  <tr>
    <td align="left">&nbsp;</td>
    <td height="26" colspan="3" align="left" valign="middle" style="padding-left:42px;color:gray;">
    <div id="sub_panel" style="float:left;margin-right:10px;">
    作者：<input name="author" type="text" id="author" value="<%=author%>" size="12" /> 出版社：<input name="press" type="text" id="press" value="<%=press%>" size="12" />
    </div>
    <div style="float:right;margin-right:10px;">
    <select name="assistTask" id="assistTask">
    <option value="">请选择操作...</option>
<%
if ("WaitApproved".equalsIgnoreCase(docBaseType)) {
%>
    <option value="BuildWaitApprovedBook">读取待复审图书</option>
<%
}else if ("FrozenBook".equalsIgnoreCase(docBaseType)) {
%>
    <option value="BuildFrozenBook">读取冻结图书</option>
<%
}
else {
%>
    <option value="ReadUnauditedBook">读取未审核图书</option>
<%
}
%>
    </select>
    <input type="button" value="执行" onclick="executeAssistTask($search('assistTask').value)" />
    </div>
    </td>
    </tr>
</table>
<script>hideQueryBox(<%=searchType%>);</script>
</div>

<!-- 新版关键字 start-->
<div class="sort">&nbsp;&nbsp;&nbsp;
<!-- 相关配置方式，查看 admin/keywords/choiceKeywords.jsp -->
	<a href="javascript:void(0);" name="search_choice_keywords_dom" closeFn="quickQuery" 
	show="search_choice_keywords_show_infomation_dom" defaultLevel="0" searchType="shop" backgroungFnType="group">选择可疑关键字</a>
	<span id="search_choice_keywords_show_infomation_dom"></span>
</div>
<!-- 新版关键字 end-->

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

&nbsp;新旧书：<select id="isNewBook" name="isNewBook" onChange="showNewBook(this.value)">
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
//----

//审核工具栏
StringBuffer verifyToolbar_contents = new StringBuffer();
verifyToolbar_contents.append("<div align=\"left\" style=\"padding:5px 2px 0px 2px;width:98%;font-size:13px;\">");
verifyToolbar_contents.append("<input type=\"button\" value=\"全选\" onclick=\"checkAll(true)\" />");
verifyToolbar_contents.append("<input type=\"button\" value=\"全否\" onclick=\"checkAll(false)\" />");
verifyToolbar_contents.append("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
// 显示可执行操作：通过、驳回、删除、待确认
verifyToolbar_contents.append("<input type=\"button\" value=\"  通过  \" onclick=\"verifyBook('approve')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
verifyToolbar_contents.append("<input type=\"button\" value=\"  驳回  \" onclick=\"verifyBook('reject')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
verifyToolbar_contents.append("<input type=\"button\" value=\"  删除  \" onclick=\"verifyBook('delete')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
if(!StringUtils.inArray(docBaseType, "FrozenBook")){
    verifyToolbar_contents.append("<input type=\"button\" value=\"  冻结  \" onclick=\"verifyBook('frozen')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}
if(!StringUtils.inArray(docBaseType, "Unconfirmed", "WaitApproved")){
    verifyToolbar_contents.append("<input type=\"button\" value=\" 待确认 \" onclick=\"verifyBook('unconfirmed')\" />");
}
verifyToolbar_contents.append("</div>");
out.print(verifyToolbar_contents.toString());
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
out.print(verifyToolbar_contents.toString());
}
//系统异常的情况
else
{
    String status = "";
    Exception ex = null;
    if(null != resultSet){
        status = StringUtils.strVal(resultSet.get("status"));
        ex = (Exception) resultSet.get("exception");
    }

    if("7".equals(status)){
    %>
    <div style="width:99%; text-align:left; padding:5px 0px 5px 0px; margin:5px 0px 5px 0px; border:1px solid #FF9900; background-color:#FFFF66; font-size:14px;">
    <div style="margin:5px 10px 0px 10px;">你的操作不成功，删除的违禁图书无法在网站后台管理系统的管理违禁图书页面中显示。<br />异常信息：<%=ex%>。<br />以下是本次提交删除的违禁图书列表：
    </div>
    </div>

    <table style="font-size:14px; margin-bottom:5px;" width="99%" border="1" cellpadding="1" cellspacing="1">
    <tr>
    <td width="5%">序号</td>
    <td width="5%">业务</td>
    <td width="15%">书店名称</td>
    <td width="10%">书店编号</td>
    <td>书名</td>
    <td width="10%">图书编号</td>
    <td width="15%">作者</td>
    <td width="15%">出版社</td>
    </tr>
    <%
        for(int i=0; null != itemInfoList && i < itemInfoList.size(); i++){
            Map record = (Map) itemInfoList.get(i);
            String tmp_bizType  = StringUtils.strVal(record.get("bizType"));
            String tmp_shopName = StringUtils.strVal(record.get("shopName"));
            String tmp_shopId   = StringUtils.strVal(record.get("shopId"));
            String tmp_itemName = StringUtils.strVal(record.get("itemName"));
            String tmp_itemId   = StringUtils.strVal(record.get("itemId"));
            String tmp_author   = StringUtils.strVal(record.get("author"));
            String tmp_press    = StringUtils.strVal(record.get("press"));
        %>
            <tr>
            <td width="5%"><%=i+1%>&nbsp;</td>
            <td width="5%"><%=getBizTypeDesc(tmp_bizType)%>&nbsp;</td>
            <td width="15%"><%=tmp_shopName%>&nbsp;</td>
            <td width="10%"><%=tmp_shopId%>&nbsp;</td>
            <td><%=tmp_itemName%>&nbsp;</td>
            <td width="10%"><%=tmp_itemId%>&nbsp;</td>
            <td width="15%"><%=tmp_author%>&nbsp;</td>
            <td width="15%"><%=tmp_press%>&nbsp;</td>
            </tr>
        <%
        }
    %>
    </table>
    <%
    }else{
%>
    <div class="result_message">
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div>&nbsp;</div>
    <div><%=serverStatus%></div>
    </div>
<%
    }
}
//-----
%>
</FORM>

<div class="copyright"><label>版权所有(C)2002-2010 孔夫子旧书网</label></div>
<script type="text/javascript">loadAssistantData();</script>
<script type="text/javascript">
	function showTip(e, i){
		var oDiv=document.getElementById("divTip" + i);
		oDiv.style.display="block";
		e.style.position='relative';
		var a = e.childNodes[0];
		var left = (e.offsetWidth - a.offsetWidth)/2+a.offsetWidth;
		oDiv.style.left=left  + "px";
		oDiv.style.top= 2 + "px";
		var totalHeight = oDiv.offsetTop + oDiv.offsetHeight;
		if(totalHeight > document.body.offsetHeight){
			var offset = document.body.offsetHeight - oDiv.offsetTop;
			oDiv.style.top = oDiv.offsetTop - oDiv.offsetHeight + offset + 'px';
		}
	}
	function hideTip(oEvent, i){
			var oDiv=document.getElementById("divTip" + i);
			oDiv.style.display="none";
			oEvent.style.position='static';
	}
</script>

</body>
</html>
