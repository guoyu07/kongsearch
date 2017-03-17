<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="java.rmi.Naming"%>
<%@ page import="java.net.URLEncoder"%>
<%@ page import="java.math.BigInteger"%>
<%@ page import="com.kongfz.dev.rmi.ServiceInterface"%>
<%@ page import="com.kongfz.dev.util.text.StringUtils"%>
<%@ include file="/admin/cls_memcached_session.jsp"%>
<%@ page import="com.kongfz.dev.biz.util.CategoryHelper"%>

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

<!-- 新审核搜索相关 -->
<%@ page import="com.kongfz.sphinx.domain.IndexBook" %>
<%@ page import="com.kongfz.sphinx.search.impl.DocBaseManage" %>
<%@ page import="com.kongfz.sphinx.trust.interfaces.ITrust,com.kongfz.sphinx.trust.impl.TrustImpl" %>

<!-- ===================java方法开始========================= -->
<%!
	/** 得到图书类型的int值
	*/
	private static Integer getIntBizType(String type){
		if("shop".equals(type)){
	        return 1;
	    }
	    if("bookstall".equals(type)){
	        return 2;
	    }
	    return 0;
	}
	
	/**
	 * 取得业务类型的文字描述
	 */
	private static String getBizTypeEn(String bizType) {
	    if("1".equals(bizType)){
	        return "shop";
	    } else if("2".equals(bizType)){
	        return "bookstall";
	    }else if("3".equals(bizType)){
	        return "shopbookstall";
	    }
	    return "";
	}
    /**
     * 取得提交的违禁图书的列表
     */
    private static List<Map<String, Object>> getViolativeItemList(String[] itemInfoList)
    {
        List<Map<String, Object>> recordList = new LinkedList<Map<String, Object>>();
        if (null == itemInfoList) {
            return recordList;
        }
        
        for (String itemInfo : itemInfoList) {
            String[] items = StringUtils.urldecode(itemInfo).split("\n");
//            if (null != items && items.length >= 14) {
            if (null != items && items.length >= 13) {
                Map<String, Object> record = new HashMap<String, Object>();
//                record.put("indexGroup",   items[0].trim());
				/** 以下所有下标均进行了相应的-1 */
                record.put("bizType",      getBizTypeEn(items[0].trim()+""));
                record.put("bizTypeInt",   items[0].trim());
//                record.put("bizTypeInt",   getIntBizType(items[1].trim()));
                record.put("userId",       items[1].trim());
                record.put("shopId",       items[2].trim());
                record.put("itemId",       items[3].trim());
                record.put("saleStatus",   items[4].trim());
                record.put("shopName",     items[5].trim());
                record.put("itemName",     items[6].trim());
                //取出更多字段
                record.put("author",       items[7].trim());
                record.put("press",        items[8].trim());
                record.put("catId",        items[9].trim());
                record.put("price",        items[10].trim());
                record.put("addTime",      items[11].trim());
                record.put("isbn",         items[12].trim());
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
        if("0000-00".equals(normalDate)){
            normalDate =  "不详";
        }
        return normalDate;
    }


    private String buildCategoryOptions(String id, Map<String, String> itemTopCategories)
    {
        String target = id;
        StringBuffer buffer = new StringBuffer();
        buffer.append("<option value=\"0\" >所有</option>");
        String prefix, postfix, selectOption;
        if(itemTopCategories == null){
        	return "";
        }
        Set<String> catIdSet = itemTopCategories.keySet();
        String tmpCatName;
        for(String tmpCatId : catIdSet){
        	tmpCatName =  itemTopCategories.get(tmpCatId);

            prefix = "<option value=\"" + tmpCatId + "\"";
            if(target.equals(tmpCatId)){
                selectOption = "selected=\"selected\">";
            }else {
                selectOption = ">";
            }
            postfix =  tmpCatName + "</option>" ;
            
            buffer.append(prefix + selectOption + postfix);           
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
        } else if("bookstall".equals(bizType)){
            return "书摊";
        }else if("shopbookstall".equals(bizType)){
            return "书店/书摊";
        }
        return "";
    }


    /**
     * 显示导航页码
     * params [pageCount 总页码数，currentPage 当前页码数，onlyShowPageCount 只能显示的页码数]
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage,int onlyShowPageCount){
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
					if(i > onlyShowPageCount){
						htmlContent += "<a style=\"cursor:not-allowed;\">" + i + "</a>";
					} else {
	                    htmlContent += "<a href=\"javascript:go("+i+")\">" + i + "</a>";
					}
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
		sb.append("y2/");//搜索
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
     * 显示图书查询结果(用于删除图书)
     * @param itemList
     * @return
     */
    private void displayHitsTableForDelete(ArrayList itemList, JspWriter out, String docBaseType) throws Exception
    {
        String shopSite="http://shop.kongfz.com/";
        String bookSite="http://book.kongfz.com/";
        String tanSite="http://tan.kongfz.com/";
        String bookUrl = "";
        StringBuffer buffer = new StringBuffer();

        buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
        buffer.append("<tr height=\"30\" align=\"center\">");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\"><img src=\"../images/smile.gif\" id=\"smile\" title=\"Ahoy!\" onclick=\"checkAll(!m_isCheckAll)\" style=\"cursor:pointer\" /></td>");
//        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\">业务</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">书店名称</td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"8%\">城市</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">图片</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"\">书名</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"7%\">类别</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">作者</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">出版社</td> ");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">出版时间</td>");
        //buffer.append("<td bgcolor=\"#D8D8D8\" width=\"3%\">品相</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"10%\">详情</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"5%\">售价</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"6%\">上书时间</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"4%\">销售状态</td>");
        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"7%\">操作</td>");
//        buffer.append("<td bgcolor=\"#D8D8D8\" width=\"2%\"> </td>");
        buffer.append("</tr></table>");
        buffer.append("<script>var data =[];</script>");
        out.print(buffer.toString());
        
        IndexBook indexBook = null;
        for(int i = 0, length = itemList.size(); i < length; i++){
            buffer.setLength(0);
//            Map map = (Map)itemList.get(i);
//            String indexGroup   = StringUtils.strVal(map.get("indexGroup"));//?
			indexBook = (IndexBook)itemList.get(i);
            int saleStatus      = StringUtils.intVal(indexBook.getSalestatus());//销售状态 * ~
            String userId       = StringUtils.strVal(indexBook.getUserid());//用户ID * ~
            String itemId       = StringUtils.strVal(indexBook.getId());//图书ID *  ~ id
            String itemName     = StringUtils.strVal(indexBook.getItemname()).trim();//图书名称 * ~ 
            String itemName_hl  = StringUtils.strVal(indexBook.getItemname_hl()).trim();//图书名称高亮 ~
            String shopId       = StringUtils.strVal(indexBook.getShopid());//书店ID * ~
            String shopName     = StringUtils.strVal(indexBook.getShopname()).trim();//书店名称 * ~
            String area         = StringUtils.strVal(indexBook.getArea());//地区 ~
            String author       = StringUtils.strVal(indexBook.getAuthor()).trim();//作者 * ~
            String author_hl    = StringUtils.strVal(indexBook.getAuthor_hl()).trim();//作者高亮 ~
            String press        = StringUtils.strVal(indexBook.getPress()).trim();//出版社 * ~
            String press_hl     = StringUtils.strVal(indexBook.getPress_hl()).trim();//出版社高亮 * ~
            String price        = StringUtils.strVal(indexBook.getPrice());//价格 * ~
            String imgurl       = StringUtils.strVal(indexBook.getImgurl());//图片 * ~
//            String addTime      = formatDate(StringUtils.strVal(indexBook.getAddtime()));//上书时间 * ~
            String addTime      = StringUtils.strVal(indexBook.getAddtime());//上书时间 * ~
//            String isCreatePage = StringUtils.strVal(map.get("isCreatePage"));
            String isCreatePage = StringUtils.strVal("");//毛字段？
            String pubDate      = formatDateYM(StringUtils.strVal(indexBook.getPubdate()));//出版时间 ~
            String category     = StringUtils.strVal(indexBook.getCatid());//分类 * ~
//            String categoryName = getBookCategory(category);
            String categoryName = getBookParentCategory(category);//得到顶级分类
            String quality      = getBookQuality(StringUtils.strVal(indexBook.getQuality()));//品像 ~
            boolean hasPic      = ("true".equals(StringUtils.strVal(indexBook.getHaspic())));//是否有图
            int number          = StringUtils.intVal(indexBook.getNumber());//库存 ~
            String itemDesc     = StringUtils.strVal(indexBook.getItemdesc()).trim();//图书描述 ~
            String itemDesc_hl     = StringUtils.strVal(indexBook.getItemdesc_hl()).trim();//图书描述高亮 ~
            String bizType      = StringUtils.strVal(indexBook.getBiztype());//所属类型 * ~
            String showBizType      = StringUtils.strVal(indexBook.getShowBizType());//显示所属类型 * ~
            String isbn         = StringUtils.strVal(indexBook.getIsbn());//isbn号 * ~
            String tag         = StringUtils.strVal(indexBook.getTag());//关键字 * ~

            String site = "";
            if(showBizType.equals("shop")){
                site = shopSite;
                bookUrl = bookSite + shopId + "/" + itemId + "/";
            }else if(showBizType.equals("bookstall")){
                site = tanSite;
//                bookUrl = tanSite + shopId + "/" + itemId + "/";
                bookUrl = bookSite + shopId + "/" + itemId + "/";
            } else if(showBizType.equals("shopbookstall")){
            	BigInteger fiveBillion = new BigInteger("5000000000");// 书摊基数，50亿
            	BigInteger itemIdInteger = new BigInteger(itemId);//当前图书编号
            	BigInteger tmpInteger = itemIdInteger.subtract(fiveBillion);//当前图书编号 - 50亿
            	switch(tmpInteger.compareTo(BigInteger.ZERO)){
	    			case -1://书店
	    			case 0://ID就是50亿
	    				site = shopSite;
	                    bookUrl = bookSite + shopId + "/" + itemId + "/";
	    				break;
	    			case 1://书摊
	    				site = tanSite;
//	                    bookUrl = tanSite + shopId + "/" + itemId + "/";
	                    bookUrl = bookSite + shopId + "/" + itemId + "/";
	    				break;
    			}
            }

            StringBuffer fields = new StringBuffer();
//            fields.append(indexGroup+" \n");
            fields.append(bizType+" \n");
            fields.append(userId+" \n");
            fields.append(shopId+" \n");
            fields.append(itemId+" \n");
            fields.append(saleStatus+" \n");
            fields.append(shopName+" \n");
            fields.append(itemName+" \n");
            fields.append(author+" \n");
            fields.append(press+" \n");
            fields.append(StringUtils.intVal(indexBook.getCatid())+" \n");
            fields.append(price+" \n");
            fields.append(addTime+" \n");
            fields.append(isbn+" \n");
            String item_info = StringUtils.urlencode(fields.toString());

            buffer.append("<script>data["+i+"]='"+item_info+"';</script>");
            buffer.append("<table width=\"98%\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" id=\"List\">");
            buffer.append("<tr bgcolor=\"" + ((i % 2 == 0) ? "#EFEFEF" : "#ffffff") + "\">");
            buffer.append("<td width=\"3%\"><input type=\"checkbox\" name=\"itemInfo[]\" value=\""+item_info+"\" /></td>");
     //       buffer.append("<td width=\"3%\">" + getBizTypeDesc(showBizType) +"&nbsp;</td>");
//            buffer.append("<td width=\"8%\"><a href=\""+site+"book/"+shopId+"/\" target=\"_blank\" title=\""+area+"\">" + shopName +"</a></td>");
			String shopNameOutside = "<a href=\""+site+"book/"+shopId+"/\" target=\"_blank\" style='color:#660000;'>(外)</a>";
            buffer.append("<td width=\"8%\"><a href='javascript:void(0);' onclick='quickQuery(\""+shopName+"\");'>" + shopName +"</a>&nbsp;&nbsp;"+shopNameOutside+"</td>");
            //buffer.append("<td width=\"8%\">" + area +"&nbsp;</td>");
            String big_pic = "<div class=\"big_pic\"><span></span><a class=\"big_pic_img\" href=\"javascript:;\"><img src='"+ showIMG(imgurl,true) +"' /></a></div>";
            buffer.append("<td width=\"3%\"><div style=\"position: relative;z-index: 15;\"><a href='http://book.kongfz.com/item_pic_"+shopId+"_"+itemId+"' class=\"small_pic\" target='_blank'><img src='"+ showIMG(imgurl,false) +"' style='width:60px;'/></a>"+big_pic+"</div></td>");
            //buffer.append("<td width=\"3%\"><a href='http://book.kongfz.com/item_pic_"+shopId+"_"+itemId+"' target='_blank'><img src='"+ showIMG(imgurl) +"' style='width:60px;'/></a>&nbsp;</td>");
            buffer.append("<td>");
/**            if(!"".equals(itemDesc)){
            	buffer.append("<div style=\"overflow:visible;\" onmouseover=\"showTip(this,"+i+")\" onmouseout=\"hideTip(this,"+i+")\">");
            }
*/
			buffer.append("<a href=\""+bookUrl+"\" target=\"_blank\">" + itemName_hl + (hasPic ? "<label style=\"color:#660000\">(图)</label>" : "") + "</a>&nbsp;");
/**            if(!"".equals(itemDesc)){
            	buffer.append("<div id=\"divTip"+i+"\" style=\"overflow-y:auto;border:1px solid #cccccc;text-align:left;padding:10px;background-color:white; position:absolute; display:none; max-height:122px;width:90px;*height:122px;\">" +
            						"<span>" + itemDesc_hl + "</span></div></div>");
            }
*/
            buffer.append("</td>");
            buffer.append("<td width=\"7%\" title=\"" + categoryName + "\">" + categoryName +"&nbsp;</td>");
            buffer.append("<td width=\"10%\" title=\""+author+"\">" + author_hl +"&nbsp;</td>");
            buffer.append("<td width=\"10%\" title=\""+press+"\">" + press_hl +"&nbsp;</td>");
            buffer.append("<td width=\"5%\">" + pubDate +"&nbsp;</td>");
            //buffer.append("<td width=\"3%\">" + quality +"&nbsp;</td>");
            
            buffer.append("<td width=\"10%\">");
	            buffer.append("<div style=\"position: relative;z-index: 15;\" id='showItemDescDiv'>" + quality + "品<br/>" + tag);
	            buffer.append("<div id='async_show_item_desc_div' asyncload='false' canShow='' style='display:none;' userid='"+userId+"' itemid='"+itemId+"' saleStatus='"+saleStatus+"'><textarea style='width:200px;height:300px;resize:none;'>xxx</textarea></div></div>");
            buffer.append("</td>");
            
            buffer.append("<td width=\"5%\">" + price +"&nbsp;</td>");
            buffer.append("<td width=\"6%\">" + addTime +"&nbsp;</td>");
            buffer.append("<td width=\"4%\">" + (0 == saleStatus ? "未售" : "已售") +"&nbsp;</td>");
            buffer.append("<td width=\"7%\">");

            // 显示可执行操作：驳回、删除、待确认、忽略、取消
          //  buffer.append("<a href=\"javascript:verifyBook('delete',data["+i+"]);\">删除</a> ");
            //buffer.append("<a href=\"javascript:verifyBook('reject',data["+i+"]);\">驳回</a> ");

          //  if(StringUtils.inArray(docBaseType, "", "DistrustBannedBook", "DistrustKeywordBook", "DistrustPressBook", "UnknowPressBook")){
           //     buffer.append("<a href=\"javascript:verifyBook('unconfirmed',data["+i+"]);\">待确认</a> ");
          //  }
           // if(StringUtils.inArray(docBaseType, "DistrustBannedBook", "DistrustKeywordBook", "DistrustPressBook", "UnconfirmedBook", "UnknowPressBook")){
          //      buffer.append("<a href=\"javascript:verifyBook('ignore',data["+i+"]);\">忽略</a> ");
           // }
            //if(StringUtils.inArray(docBaseType, "UnconfirmedBook", "IgnoreBook")){
           //     buffer.append("<a href=\"javascript:verifyBook('cancel',data["+i+"]);\">取消</a> ");
          //  }
          
//            buffer.append("<a href=\"http://search.kongfz.com/book.jsp?query=" +URLEncoder.encode(itemName, "utf-8") + "&sale=2&category=\" target=\"_BLANK\">在线</a> ");
            buffer.append("<a href=\"http://search.kongfz.com" +toHexString(itemName) + "\" target=\"_BLANK\">在线</a> ");
            buffer.append("<a href='javascript:searchFromLog(\"/admin/auction_manage.jsp\",\""+itemName+"\");'>拍卖索引</a> <br />");
            buffer.append("<a href='javascript:searchFromLog(\"/admin/verify_log_manage.jsp\",\""+itemName+"\");'>日志</a> ");
            buffer.append("</td>");
//            buffer.append("<td width=\"2%\"><a style=\"color:gray\" href=\""+bookUrl+"\" target=\"_blank\">详</a></td>");
            buffer.append("</tr></table>\n");
            out.write(buffer.toString());
        }
    }
%>
<!-- ===================java方法结束========================= -->

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
//     String adminRealName = "测试数据";
    
    MemcachedSession MemSession = new MemcachedSession(session, request, response, out, false);
    // 从Session中取得管理员的姓名，并记录之。
    String adminRealName = MemSession.get("adminRealName");

    // user login
    String logon_result = "";
    String username = MemSession.get("adminName");//用于网站管理员登录
out.write(username);
    if(!MemSession.isLogin("admin")){
        response.sendRedirect("index.jsp");
        return;
    }

    //判断管理员权限
    //String[] permission = new String[]{"manageIndex", "manAuctioneer"};
    String permission = "docBaseManage";
    if(!MemSession.hasPermission(permission)){
        out.write("您无权限使用此页面。");
		return;
    }

    /****************************************************************************
    * 接收页面求参数
    ****************************************************************************/

    //动作类型
    String act = StringUtils.strVal(request.getParameter("act"));
    if("".equals(act)){ act="search"; }//未选中动作默认为搜索

    //任务类型
    String task = StringUtils.strVal(request.getParameter("task"));
    String docBaseType = StringUtils.strVal(request.getParameter("docBaseType"));//点击的顶部选项卡类别
    if ("".equals(docBaseType)) {
    	docBaseType = "OnlineSale";
    }
    String keywordGroupId = StringUtils.strVal(request.getParameter("keywordGroupId"));//关键字组ID【已被新关键字筛选替换】

    String keywords = StringUtils.strVal(request.getParameter("query"));//关键字
    keywords = filterKeywords(keywords);//过滤关键字特殊字符
out.write(new String(keywords.getBytes("ISO-8859-1"),"UTF-8"));
    String author = StringUtils.strVal(request.getParameter("author")).trim();//作者
    String press = StringUtils.strVal(request.getParameter("press")).trim();//出版社
    String shopname_search = StringUtils.strVal(request.getParameter("shopname_search")).trim();//店铺名称

    String addTimeStart = StringUtils.strVal(request.getParameter("addTimeStart")).trim();//上书时间开始
    String addTimeEnd = StringUtils.strVal(request.getParameter("addTimeEnd")).trim();//上书时间结束

    String beginTrustNum = StringUtils.strVal(request.getParameter("beginTrustNum")).trim();//信任度开始
    String endTrustNum = StringUtils.strVal(request.getParameter("endTrustNum")).trim();//信任度结束
    //对比规则[全部/作者+书名]
    String autoVerifyType = StringUtils.strVal(request.getParameter("autoVerifyType")).trim();
    
    int searchType = StringUtils.intVal(request.getParameter("searchType"));//搜索类型[全文/作者/出版社/……]
    int sortType = StringUtils.intVal(request.getParameter("sorttype"));//排序
    int current_page = StringUtils.intVal(request.getParameter("page"));//页码
    current_page = current_page <= 0 ? 1 : current_page;
    String category = StringUtils.strVal(request.getParameter("category"));//图书类别[报纸/古玩杂项/经济/历史/……]
	//销售状态
    int sale = 0;
    if("".equals(StringUtils.strVal(request.getParameter("sale")))){
        sale = 2;//为空默认选中全部
    }else{//不为空就筛选选中的值[0=未售,1=已售,2=全部]
        sale = StringUtils.intVal(request.getParameter("sale"));
    }
	
    String isNewBook = StringUtils.strVal(request.getParameter("isNewBook"));//新旧书
    String hasPic = StringUtils.strVal(request.getParameter("hasPic"));//图片

    /****************************************************************************
     * 调用远程服务接口
     ****************************************************************************/
    ServiceInterface manager = null;
    Map resultSet = null;
    String serverStatus = "";
    ArrayList documents = new ArrayList();
    String currentPage = "1";//当前页码默认为1
    int bookTotal = 0;
    String pageTotal = "0";//页码总数
    String searchTime = "0";//搜索时间
    String maxCount = "-1";//可搜索最大数据条数
    String onlyShowPageCount = "-1";//只能显示数据页码数
    String searchSQL = "";//当前搜索查询的SQL语句
    
    List<Map<String, Object>> itemInfoList = null;
    List<Map<String, Object>> notQueryItemInfoList = null;
    Map<String, String> distrustKeywordGroupInfo = null;
    String distrustKeywordGroupHtml = "";
    String keywordGroupContent = "";
    Map<String, String> itemTopCategories = null;
    String categoryOptionsHtml ="";
    try{
        //取得远程服务器接口实例, 根据未售或已售调用不同的远程对象
        String rmiURL = "rmi://192.168.1.105:9820/AdminBookSearchService";
        if("TrustBookLib".equalsIgnoreCase(docBaseType)){
            rmiURL = "rmi://192.168.1.105:9824/TrustBookService";
        }
        System.out.println("rmiURL==>"+rmiURL);
//        manager = (ServiceInterface) Naming.lookup(rmiURL);
    }catch(Exception ex){
        manager = null;
        ex.printStackTrace();
    }
    
    /** 使用新搜索进行检索 */
	boolean useNewAction = true;
	
    /*******************************************************************************
     * 请求远程服务：建立索引、查询索引、审核图书（删除索引）
     *******************************************************************************/
    if(useNewAction || (!useNewAction && null != manager)){
        // 审核服务：驳回、删除、待确认、忽略、取消
        // 信任度服务：信任度+1， 标记待确认
        if (StringUtils.inArray(act, "Reject", "Delete", "Unconfirmed", "Ignore", "Cancel", "Frozen","doMarkIncrOne","doToBeMark", "doToBeBatchMark")) {
            //要审核的图书信息列表
            String[] itemInfoArray = request.getParameterValues("itemInfo[]");
            itemInfoList = getViolativeItemList(itemInfoArray);
            
            /** 新搜索审核服务  start */
            final String finalAct = act;//操作类型
//            new Thread(new Runnable() {//使用子线程去向新搜索发送审核消息
//                public void run() {
					//信任度处理审核
					if(StringUtils.inArray(act,"doMarkIncrOne","doToBeMark", "doToBeBatchMark")){
						HashMap<String,String> extension = new HashMap<String,String>();						
			            //对所有搜索结果+1
			            if(act.equals("doToBeBatchMark")){
			            	//上次一查询SQL语句
				            String new_search_use_sql_sentence = request.getParameter("new_search_use_sql_sentence");
				            //当前系统搜索峰值
				            String new_search_max_count_num = request.getParameter("new_search_max_count_num");
				            //上次查询数据总条数
				            String new_search_book_total = request.getParameter("new_search_book_total");
				            int new_search_max_count_num_count = 0;
				            int new_search_book_total_count = 0;
				            //本次查询结果数
				            if(null != new_search_book_total && !"".equals(new_search_book_total.trim())){
				            	new_search_book_total_count = Integer.parseInt(new_search_book_total);
				            }
				            //查询峰值 
				            if(null != new_search_max_count_num && !"".equals(new_search_max_count_num.trim())){
				            	new_search_max_count_num_count = Integer.parseInt(new_search_max_count_num);
				            }
				            //查询峰值 > 0 && 本次查询数 > 0 && 本次查询数 <= 查询峰值
				            if(new_search_max_count_num_count > 0 && new_search_book_total_count > 0 &&
				            		new_search_max_count_num_count >= new_search_book_total_count){
				            	extension.put("search_sql",new_search_use_sql_sentence);
				            } else {//无法审核，直接执行搜索
				            	itemInfoList = null;
				            }
			            }
			            if((null != itemInfoList && itemInfoList.size() > 0) || (extension.size() > 0 && !"".equals(extension.get("search_sql")))){
							System.out.println("信任度处理审核");
							//信任度审核，后续后台数据库值，只提交会对搜索数据有影响的数据，只有【信任度从无到有，或信任度变为待标记】
							ITrust trust = new TrustImpl();
							//进行图书标记，或信任度添加，返回的结果，则是需要进行标记的数据
							itemInfoList = trust.work(act,itemInfoList,extension);
							System.out.println("接收");
			            }
					}
					System.out.println("数据存在才进行审核   itemInfoList ： "+itemInfoList.size());
					//数据存在才进行审核
					if(null != itemInfoList && itemInfoList.size() > 0){
					System.out.println("进入");						
						final List<Map<String, Object>> finalItemList =  itemInfoList;//需要审核的图书数据
						HashMap<String,String> neoBookParams = new HashMap<String,String>();
	                    neoBookParams.put("task",finalAct);
	                    neoBookParams.put("origin",null);
	                    neoBookParams.put("fieldName","itemId");
	                    neoBookParams.put("typeField","bizTypeInt");
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
//	                        neoSearch.work(finalAct,finalItemList,"itemId","bizTypeInt",null);
	                        neoSearch.work(neoBookParams,finalItemList);
	                    }
	                     System.out.println("审核数据库相关内容");
	                    //审核数据库相关内容
	                    neoBookParams.put("userIdfieldName","userId");
	                    neoBookParams.put("itemIdField","itemId");
	                    neoBookParams.put("adminRealName",adminRealName);
			neoBookParams.put("verifyLog","true");//记录日志
	                    INeoDataBookVerify neoBookVerify = new NeoDataBookVerify();
	                    neoBookVerify.work(neoBookParams,finalItemList);
					}
try {
						Thread.sleep(1000);
					} catch (InterruptedException e) {}
					System.out.println("act = search");
					act = "Search";
//                }
//            }).start();
            /** 新搜索审核服务  end */
            
/** 注释就审核

            // 组织参数
            HashMap parameters = new HashMap();
            parameters.put("itemInfoList", itemInfoList);
            parameters.put("docBaseType", docBaseType);//选择业务模块
            parameters.put("groupId", keywordGroupId);
            parameters.put("adminRealName", "test");
            parameters.put("task", act);

            String workMethodName = "";
            if("Reject".equalsIgnoreCase(act)){
                workMethodName = "VerifyBook";
            }
            if("Delete".equalsIgnoreCase(act)){
                if("TrustBookLib".equalsIgnoreCase(docBaseType)){
                   workMethodName = "Delete";
                }else{
                 workMethodName = "VerifyBook";//DeleteViolativeBookDoc
                }
               
            }
            if("Frozen".equalsIgnoreCase(act)){
                workMethodName = "VerifyBook";
            }
            if("Unconfirmed".equalsIgnoreCase(act)){
                workMethodName = "AddUnconfirmedBookDoc";
            }
            if("Ignore".equalsIgnoreCase(act)){
                workMethodName = "AddIgnoreBookDoc";
            }
            if("Cancel".equalsIgnoreCase(act)){
                workMethodName = "RemoveBookDoc";
            }
  
            if(StringUtils.inArray(act,"doMarkIncrOne","doToBeMark")){
               workMethodName = "MarkTrust";
               
              if(StringUtils.inArray(docBaseType,"NotMarked","ToBeMarked")){
                 notQueryItemInfoList = itemInfoList;
               }
            }

            
            if("doToBeBatchMark".equalsIgnoreCase(act)){
                workMethodName = "BatchMarkTrust";
                parameters.put("shopId", keywords);
                parameters.put("docBaseType", docBaseType);//选择业务模块
	            parameters.put("groupId", keywordGroupId);
	            
	            parameters.put("saleStatus", String.valueOf(sale));
	            parameters.put("category", String.valueOf(category));
	            parameters.put("sortType", String.valueOf(sortType));
	            parameters.put("isNewBook", String.valueOf(isNewBook));
	            parameters.put("hasPic", String.valueOf(hasPic));
	            parameters.put("notQueryitemInfoList", notQueryItemInfoList);
	           
	
	            switch(searchType){
	                case 0: parameters.put("keywords", keywords); break;
	                case 1: parameters.put("itemName", keywords); break;
	                case 2: parameters.put("author", keywords);   break;
	                case 3: parameters.put("press", keywords);    break;
	                case 4: parameters.put("itemDesc", keywords); break;
	                case 5: {       
	                parameters.put("bizType", "shop"); 
	                break;
	                }
	                
	                case 6:{
	                parameters.put("bizType", "bookstall"); 
	                break;
	                }
	            }
	            if(!"".equals(author)){
	                parameters.put("author", author);
	            }
	            if(!"".equals(press)){
	                parameters.put("press", press);
	            }
	            //上书时间
	            if(!"".equals(addTimeStart) && !"".equals(addTimeEnd)){
		            parameters.put("addTimeStart", addTimeStart);
					parameters.put("addTimeEnd", addTimeEnd);
	            } else if(!"".equals(addTimeStart) || !"".equals(addTimeEnd)){
	            	if(!"".equals(addTimeStart)){
	            		parameters.put("addTimeStart", addTimeStart);
	            	} else {
	            		parameters.put("addTimeStart", "0000-00-00");
	            	}
	            	if(!"".equals(addTimeEnd)){
	            		parameters.put("addTimeEnd", addTimeEnd);
	            	} else {
	            		parameters.put("addTimeEnd", "9999-99-99");
	            	}
	            }
                
            }

            //删除图书
            try{
 //               resultSet = manager.work(workMethodName, parameters);
            }catch(Exception ex){
                //ex.printStackTrace();
                serverStatus="服务器信息：调用远程服务器工作失败。";
            }
           
            //处理删除请求的结果
            String status = "";
            String error = "";
            if(null != resultSet){
                status = StringUtils.strVal(resultSet.get("status"));
                error = StringUtils.strVal(resultSet.get("error"));
            }           
            
            if(!"".equals(error)){
                serverStatus = error;
                act = "";
            }
            else if("0".equals(status)){
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
            else{
                serverStatus =status;
                act = "search";
            }
            //其它错误，略
*/
        }
        
        // 查询索引服务
        if (StringUtils.inArray(act, "Search", "OnlineSale", "DownRepeal", "RecycleBin", "ShutShop", "NotSellBook")) {
//        if("Search".equalsIgnoreCase(act)){
            HashMap parameters = new HashMap();
            parameters.put("docBaseType", docBaseType);//选择业务模块,点击的顶部选项卡类别
            parameters.put("groupId", keywordGroupId);//关键字组ID
            
            parameters.put("saleStatus", String.valueOf(sale));//销售状态[全部/已售/未售]
            parameters.put("category", String.valueOf(category));//图书类别
            parameters.put("sortType", String.valueOf(sortType));//排序状态
            parameters.put("isNewBook", String.valueOf(isNewBook));//新旧书
            parameters.put("hasPic", String.valueOf(hasPic));//图片
            parameters.put("notQueryitemInfoList", notQueryItemInfoList);
            parameters.put("autoVerifyType", String.valueOf(autoVerifyType));//对比规则[全部/作者+书名]
            parameters.put("inKeywords", keywords);//用户输入的关键字
			
            switch(searchType){//搜索类型
                case 0: parameters.put("keywords", keywords); break;//全文
                case 1: parameters.put("itemName", keywords); break;//书名
                case 2: parameters.put("author", keywords);   break;//作者
                case 3: parameters.put("press", keywords);    break;//出版社
                case 4: parameters.put("itemDesc", keywords); break;//描述
                case 5: {//书店ID
	                parameters.put("shopId", keywords); 
	                parameters.put("bizType", "shop"); 
	                break;
                }
                
                case 6:{//书摊ID
	                parameters.put("shopId", keywords); 
	                parameters.put("bizType", "bookstall"); 
	                break;
                }
            }
            if(!"".equals(author)){//作者[单独的]
                parameters.put("author", author);
            }
            if(!"".equals(press)){//出版社[单独的]
                parameters.put("press", press);
            }
            if(!"".equals(shopname_search)){//店铺名称[单独的]
                parameters.put("shopname_search", shopname_search);
            }
            //上书时间
            if(!"".equals(addTimeStart) && !"".equals(addTimeEnd)){
	            parameters.put("addTimeStart", addTimeStart);//上书时间开始
				parameters.put("addTimeEnd", addTimeEnd);//上书时间结束
            } else if(!"".equals(addTimeStart) || !"".equals(addTimeEnd)){
            	if(!"".equals(addTimeStart)){
            		parameters.put("addTimeStart", addTimeStart);
            	} else {
            		parameters.put("addTimeStart", "0000-00-00");
            	}
            	if(!"".equals(addTimeEnd)){
            		parameters.put("addTimeEnd", addTimeEnd);
            	} else {
            		parameters.put("addTimeEnd", "9999-99-99");
            	}
            }
            
            //查询类配置参数
            parameters.put("currentPage", String.valueOf(current_page));//当前页码
            parameters.put("paginationSize", "200");//每页显示数据条数
            //parameters.put("sortDefault", );
            parameters.put("beginTrustNum", beginTrustNum);
            parameters.put("endTrustNum",  endTrustNum);
            
            //调用远程查询接口
            try{            
	             if("TrustBookLib".equalsIgnoreCase(docBaseType)){//可信任图书库
	                  resultSet = manager.work("Search", parameters);
	             } else {
	               		// 管理全站图书   未标记图书     已标记图书      待标记图书
	            	 if(StringUtils.inArray(docBaseType, "","OnlineSale","DownRepeal","RecycleBin","ShutShop","NotMarked" , "Marked", "ToBeMarked", "NotSellBook" )){
	            	    System.out.println("使用新搜索进行:数据查询...");
	            	   	// 管理全站图书/未标记图书/已标记图书/待标记图书
	//                    resultSet = manager.work("AdminSearch", parameters);
						//新搜索读取数据
	            	   	DocBaseManage docBaseManage = new DocBaseManage();
	                    resultSet = docBaseManage.search(parameters);
	                    System.out.println("新搜索返回内容大小："+resultSet.size());
	                } else {//新需求将删除[以下服务]
	                	//管理可疑违禁图书/管理可疑关键字图书/管理不详出版社图书/管理可疑出版社图书/管理待确认图书/管理被忽略图书
	                    resultSet = manager.work("DocBaseSearch", parameters);
	                }
	             }
             
              
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
                currentPage = StringUtils.strVal(resultSet.get("currentPage"));//当前页码
                bookTotal   = StringUtils.intVal(resultSet.get("hitsCount"));//图书总数
                pageTotal   = StringUtils.strVal(resultSet.get("pageCount"));//页码总数
                searchTime  = StringUtils.strVal(resultSet.get("searchTime"));//搜索耗时
                maxCount  = StringUtils.strVal(resultSet.get("maxCount"));//搜索数据峰值
                onlyShowPageCount  = StringUtils.strVal(resultSet.get("onlyShowPageCount"));//只能显示的页码数
                searchSQL = StringUtils.strVal(resultSet.get("searchSQL"));//当前搜索查询的SQL语句
                /** 注释关键字相关内容
                distrustKeywordGroupInfo = (Map<String, String>) resultSet.get("distrustKeywordGroupInfo");
                distrustKeywordGroupHtml = buildKeywordGroupOptions(distrustKeywordGroupInfo, keywordGroupId);
                keywordGroupContent = StringUtils.strVal(resultSet.get("keywordGroupContent"));
                */
                serverStatus = "ok";
            } else if ("1".equals(result)){
                serverStatus = "服务器信息：索引为空，或未建立，或正在建立索引。";
            } else if ("2".equals(result)){
                serverStatus = "服务器信息：查询受阻，正在将磁盘索引载入内存。";
            } else if ("3".equals(result)){
                serverStatus = "服务器信息：查询过程中出现错误。";
            } else if ("-1".equals(result)){
                serverStatus = "服务器信息：未知条件，无法检索。";
            } else if ("500".equals(result)){
                serverStatus = "服务器信息：数据处理异常。";
            } else if ("999".equals(result)){
                serverStatus = "服务器信息：待完善功能。";
            } else {
                serverStatus = "服务器信息：未知错误。";
            }
		    itemTopCategories  = (Map<String, String>) resultSet.get("itemTopCategories");
		    categoryOptionsHtml = buildCategoryOptions(category, itemTopCategories);            
        }

    }else{
        serverStatus = "请求远程服务器出现异常，可能是远程服务器未启动，请与系统管理员联系。";
    }
    // System.out.println(serverStatus);
%>
<!doctype html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
		<title>已审核图书管理系统</title>
		<style>
body {
	margin: 0;
	padding: 0;
	text-align: center
}

a {
	text-decoration: none;
}

a:hover {
	text-decoration: underline;
	color: red;
}

.sort {
	width: 99%;
	font-size: 14px;
	line-height: 30px;
	background-color: #e1eaf6;
	border: 1px solid #adc1dc;
	margin: 0px 0px 5px 0px;
	height: 28px;
	text-align: left;
	padding-top: 4px;
}

.searchSub {
	background: url(../images/bg_searchsub.gif);
	border: 1px solid #d17528;
	width: 80px;
	padding-top: 2px;
	font-weight: bold;
	color: #fff;
}

#Page td {
	font-size: 12px;
	line-height: 200%;
}

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

.search {
	width: 99%;
	height: 62px;
	border-bottom: 1px solid #adc1dc;
	margin: 0 auto 2px auto;
	background: url(../images/bg_search.gif);
	font-size: 12px;
}

form {
	margin: 0px;
}

.copyright {
	font-size: 12px;
	width: 99%;
	border: 1px solid #EFF2FA;
	padding-top: 20px;
	padding-bottom: 20px;
	text-align: center;
	background-color: #EFF2FA;
}

.result_message {
	font-size: 12px;
	border: 0px solid #003300;
	height: 200px;
	width: 99%;
	text-align: center;
}

.result_message img {
	margin: 20px 20px 20px 200px;
}

.result_message label {
	color: #FF6F02;
}

.float_left {
	float: left;
}

.page_navigation {
	
}

.page_navigation a {
	margin: 2px;
	padding: 2px;
	text-decoration: none;
	color: #100EB0;
	font-size: 14px;
}

.page_navigation a:hover {
	text-decoration: underline;
	color: #FF0000;
}

.page_navigation label {
	margin: 2px;
	padding: 2px;
}

.page_navigation b {
	color: #FF0000;
	margin: 2px;
	padding: 2px;
	font-size: 14px;
}

.page_navigation input {
	border: 1px solid #ADC1DC;
}

.goto_button {
	height: 20px;
	width: 36px;
	border: 1px solid #ADC1DC;
	color: #006E0B;
	padding: 2px;
	background-color: #FFFFFF;
	background-image: url(../images/bg_sort.gif);
	cursor: pointer;
}

.isNewBook {
	font-size: 14px;
	color: #FF0000;
	font-weight: bold;
}

.isNewBookNomal {
	font-size: 14px;
}

.belivePress {
	display: none;
	position: absolute;
	padding: 2px;
	width: 120px;
	height: auto;
	background-color: #C7D5E9;
	border: 1px solid #ADC1DC;
}

.belivePress a {
	float: left;
	padding: 2px;
	width: 100%;
	color: #000000;
	text-align: left;
	font-size: 14px;
}

.belivePress a:hover {
	background-color: #FDDA96;
	color: #FF0000;
}

.distrustKeywords {
	display: none;
	position: absolute;
	padding: 2px;
	width: 120px;
	height: auto;
	background-color: #C7D5E9;
	border: 1px solid #ADC1DC;
}

.distrustKeywords a {
	float: left;
	padding: 2px;
	width: 100%;
	color: #000000;
	text-align: left;
	font-size: 14px;
}

.distrustKeywords a:hover {
	background-color: #FDDA96;
	color: #FF0000;
}

/* 主菜单面板 */
.mainMenuPanel {
	margin: auto;
	padding: 4px 4px 0px 4px;
	height: 18px;
	width: auto;
	text-align: left;
	font-size: 12px;
	border-bottom: 1px solid #E6E6E6;
	background-color: #ECECEC;
}

.menuItemSel {
	color: #FF0000;
	font-weight: bold;
}

/* 业务模块面板 */
.modulePanel {
	margin: 2px 0px 0px 0px;
	padding-top: 2px;
	width: 99%;
	height: 34px;
	border-bottom: 1px solid #adc1dc;
	font-size: 14px;
	line-height: 30px;
	text-align: left;
	background-color: #E1EAF6;
}

.modulePanelItem {
	float: left;
	border: 1px dashed #ADC1DC;
	margin-left: 2px;
	padding: 0px 4px 0px 4px;
	color: #000000;
	text-decoration: none;
}

.modulePanelItem:hover {
	color: white;
	text-decoration: none;
	background-color: #ACC3DF;
}

.modulePanelItemSel {
	float: left;
	border: 1px dashed #ADC1DC;
	margin-left: 2px;
	padding: 0px 4px 0px 4px;
	color: #FFFFFF;
	font-weight: bold;
	text-decoration: none;
	background-color: #ADC1DC;
}

.modulePanelItemSel:hover {
	color: #FFFFFF;
	text-decoration: none;
	background-color: #ACC3DF;
}
</style>
	</head>
	<script type="text/javascript">
    function search_docuemntById(id){return document.getElementById(id);}
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
        search_docuemntById("sorttype").value = type;
        go(1);
    }

    function showNewBook(isNewBook){
        search_docuemntById("isNewBook").value = isNewBook;
        search_docuemntById("page").value="";
        search_docuemntById("frmSearch").submit();
    }

    function go(page){
    	var pageTotal = parseInt("<%=pageTotal%>",10);//总共页码
    	var onlyShowPageCount = parseInt("<%=onlyShowPageCount%>",10);//只能显示的页码
    	//当前准备调整的页码 > 只能显示
    	if(page > onlyShowPageCount){
    		page = onlyShowPageCount;
    	}
        search_docuemntById("page").value = page;
        search_docuemntById("frmSearch").submit();
    }

    function gotopage(){
        var pages = document.getElementsByName("gopage");
        var page = pages[0].value!=""? pages[0].value : pages[1].value;
//        var max = pages[0].getAttribute("maxValue");
        page = page.replace(/ /g,"");
//        if(parseInt(page,10) > parseInt(max,10))
//        	page = max;
        go(page);
    }

    function initSearchForm(){
        search_docuemntById('sorttype').value=0;
        search_docuemntById('isNewBook').value='';
        search_docuemntById('category').value=0;
        search_docuemntById("keywordGroupId").value = "";
        search_docuemntById("hasPic").value="";
        search_docuemntById("page").value="";
    }

    var m_isCheckAll = false;
   
    function checkAll(value){
        m_isCheckAll = value;
        search_docuemntById('smile').src='../images/'+(value?'cry.gif':'smile.gif');
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
        "reject":      "是否驳回所选项目？",
        "delete":      "是否删除所选项目？",
        "unconfirmed": "是否待确认所选项目？",
        "ignore":      "是否忽略所选项目？",
        "cancel":      "是否取消所选项目？",
        "frozen":      "是否冻结所选项目",
        "doMarkIncrOne": "是否将所选项目可信度+1？",
        "doToBeMark":  "是否将所选项目移动至待标记？",
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
        search_docuemntById('act').value = act;
        search_docuemntById('frmSearch').submit();
    }
    
    
    
     function doToBeBatchMark(act)
    {
       var searchType = search_docuemntById("searchType").value;
       var keywords = search_docuemntById("keywords").value;
       if(!(searchType == '5' || searchType == '6' )){
	        alert('搜索类型必须为书店ID或书摊ID');
	        return ;
       }
       
       if(keywords == '' || keywords == ''){
	        alert('书店ID或书摊ID不能为空!');
		    return ;
       }   
        var title = "是否将所有查询结果信任度+1? (!注意：此操作耗时较长，请将结果控制在<%=(!maxCount.equals("") ? maxCount : 1000)%>记录以内, 在执行期间请不要进行其他操作!"
        if(!confirm(title)){return;}
        search_docuemntById('act').value = act;
        search_docuemntById('frmSearch').submit();
    }

    var iframe = null;// 遮罩窗口对象

    /**
     * 显示可疑关键字列表
     */
    function showDistrustKeywords(isVisible){
        function hideDistrustKeywordsPanel(){showDistrustKeywords(false);}
        var panel = search_docuemntById('distrustKeywordsPanel');
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
        var panel = search_docuemntById('belivePressPanel');
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
            search_docuemntById('distrustKeywordsPanel').innerHTML = keywordsHtml.join('');
        }
        //装入可信任出版社列表
        if(m_belivePress){
            var pressHtml = [];
            for(var i=0; i < m_belivePress.length; i++){
                pressHtml.push('<div><a href="javascript:quickQuery(\''+m_belivePress[i].name+'\')" title="'+m_belivePress[i].name+'">'+m_belivePress[i].name+'</a></div>');
            }
            search_docuemntById('belivePressPanel').innerHTML=pressHtml.join('');
        }
    }

    function quickQuery(keywords){
        search_docuemntById('keywords').value = keywords;
        search_docuemntById("page").value="";
        search_docuemntById('frmSearch').submit();
    }

    function selectVerifyModule(module) {
        var map = {
            "0":"", 
            "1":"DistrustBannedBook",
            "2":"DistrustKeywordBook",
            "3":"UnknowPressBook",
            "4":"DistrustPressBook",
            "5":"UnconfirmedBook",
            "6":"IgnoreBook",
            "7":"NotMarked",
            "8":"Marked",
            "9":"ToBeMarked",
            "10":"TrustBookLib",
            "11":"OnlineSale",/** 管理在线销售图书 */
            "12":"DownRepeal",/** 管理下架图书 */
            "13":"RecycleBin",/** 管理回收站图书 */
            "14":"ShutShop",   /** 管理暂停/关闭店铺图书 */
            "15":"NotSellBook"   /** 管理非在售图书 */
        };
        search_docuemntById("docBaseType").value = map[module];
        search_docuemntById("keywordGroupId").value = "";
        search_docuemntById("sorttype").value=0;
        search_docuemntById("isNewBook").value="";
        search_docuemntById("category").value=0;
        search_docuemntById("searchType").value="0";
        search_docuemntById("keywords").value="";
        search_docuemntById("author").value="";
        search_docuemntById("press").value="";
        search_docuemntById("sale").value="2";
        search_docuemntById("hasPic").value="";
        search_docuemntById("page").value="";
        search_docuemntById('frmSearch').submit();
    }
    
    function setModulePanelHighlight(module) {
        var map = {
            "":0, 
            "DistrustBannedBook":1,
            "DistrustKeywordBook":2,
            "UnknowPressBook":3,
            "DistrustPressBook":4,
            "UnconfirmedBook":5,
            "IgnoreBook":6,
            "NotMarked":7,
            "Marked":8,
            "ToBeMarked":9,
            "TrustBookLib":10,
            "OnlineSale":11,/** 管理在线销售图书 */
            "DownRepeal":12,/** 管理下架图书 */
            "RecycleBin":13,/** 管理回收站图书 */
            "ShutShop":14,   /** 管理暂停/关闭店铺图书 */
            "NotSellBook":15   /** 管理非在售图书 */
        };
        var items = search_docuemntById("modulePanel").getElementsByTagName("A");
        items[map[module]].className="modulePanelItemSel";
    }

    function queryKeywordGroup(groupId) {
        search_docuemntById("keywordGroupId").value=groupId;
        search_docuemntById("page").value="";
        search_docuemntById('frmSearch').submit();
    }

    /**
     * 清空查询条件
     */
    function clearQueryCondition()
    {
        search_docuemntById("searchType").value="0";
        search_docuemntById("keywords").value="";
        search_docuemntById("author").value="";
        search_docuemntById("press").value="";
        search_docuemntById("sale").value="2";
    }

    function showHasPic(hasPic)
    {
        search_docuemntById("hasPic").value = hasPic;
        search_docuemntById("page").value="";
        search_docuemntById("frmSearch").submit();
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

</script>
	<script language="javascript" type="text/javascript" src="<%=systemBasePath%>admin/distrust_keywords.js"></script>
	<script language="javascript" type="text/javascript" src="<%=systemBasePath%>admin/belive_press.js"></script>
	<script language="javascript" type="text/javascript" src="<%=systemBasePath%>admin/new_sphinx/new_sphinx_doc_base_manage.js"></script>
	</HEAD>

	<body>

		<div class="mainMenuPanel">
			<a href="/admin/index.jsp">主菜单</a>
			<a href="javascript:void(0);" class="menuItemSel">已审核图书管理系统</a>
			<a href="/admin/book_verify_manage.jsp">待审图书管理系统</a>
		</div>

		<div class="modulePanel" id="modulePanel">
			<a href="javascript:selectVerifyModule(0)" class="modulePanelItem" style="display:none;">管理全站图书</a>
 			<a href="javascript:selectVerifyModule(1)" class="modulePanelItem" style="display:none;">管理可疑违禁图书</a>
			<a href="javascript:selectVerifyModule(2)" class="modulePanelItem" style="display:none;">管理可疑关键字图书</a>
			<a href="javascript:selectVerifyModule(3)" class="modulePanelItem" style="display:none;">管理不详出版社图书</a>
			<a href="javascript:selectVerifyModule(4)" class="modulePanelItem" style="display:none;">管理可疑出版社图书</a>
			<a href="javascript:selectVerifyModule(5)" class="modulePanelItem" style="display:none;">管理待确认图书</a>
			<a href="javascript:selectVerifyModule(6)" class="modulePanelItem" style="display:none;">管理被忽略图书</a>
			<a href="javascript:selectVerifyModule(7)" class="modulePanelItem" style="display:none;">未标记图书</a>
			<a href="javascript:selectVerifyModule(8)" class="modulePanelItem" style="display:none;">已标记图书</a>
			<a href="javascript:selectVerifyModule(9)" class="modulePanelItem" style="display:none;">待标记图书</a>
			<a href="javascript:selectVerifyModule(10)" class="modulePanelItem" style="display:none;">可信图书库</a>
			<a href="javascript:selectVerifyModule(11)" class="modulePanelItem">管理在线销售图书</a>
			<a href="javascript:selectVerifyModule(12)" class="modulePanelItem" style="display:none;">管理下架图书</a>
			<a href="javascript:selectVerifyModule(13)" class="modulePanelItem" style="display:none;">管理回收站图书</a>
			<a href="javascript:selectVerifyModule(14)" class="modulePanelItem" style="display:none;">管理暂停/关闭店铺图书</a>
			<a href="javascript:selectVerifyModule(15)" class="modulePanelItem">管理非在售图书</a>
		</div>
		<script>setModulePanelHighlight("<%=docBaseType%>");</script>

		<form name="frmSearch" id="frmSearch" method="post" action="">
			<div class="search">
				<table width="98%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td width="1px" align="left">
							&nbsp;
						</td>
						<td align="left" valign="bottom">
							<select name="searchType" id="searchType">
								<option value="0">全文</option>
								<option value="1">书名</option>
								<option value="2">作者</option>
								<option value="3">出版社</option>
								<option value="4">详情</option>
								<option value="5">书店ID</option>
								<option value="6">书摊ID</option>
							</select>
							<script>search_docuemntById("searchType").value="<%=searchType%>";</script>
						</td>
						<td height="26" align="left" valign="bottom">

							<input type="text" id="keywords" name="query" size="40"
								maxlength="650" value="<%=keywords%>" title="<%=keywords%>" />

							<select name="sale" id="sale">
								<option value="0">未售</option>
								<option value="1">已售</option>
								<option value="2">全部</option>
							</select>
							<script>search_docuemntById("sale").value = "<%=sale%>";</script>

							<img src="../images/clear_input.gif" style="cursor: pointer" title="清空输入框" onclick="clearQueryCondition();" />
							<input type="submit" value="搜 索" class="searchSub" onclick="initSearchForm()" />
							<input type="hidden" name="isNewBook" id="isNewBook" value="<%=isNewBook%>" />
							<input type="hidden" name="page" id="page" value="<%=currentPage%>" />
							<input type="hidden" name="sorttype" id="sorttype" value="<%=sortType%>" />
							<input type="hidden" id="act" name="act" value="<%=act%>" />
							<input type="hidden" id="docBaseType" name="docBaseType" value="<%=docBaseType%>" />
							<input type="hidden" id="keywordGroupId" name="keywordGroupId" value="<%=keywordGroupId%>" />

							<span>
<!--
								<a href="javascript:showDistrustKeywords(true)">选择可疑关键字</a>
								<div id="distrustKeywordsPanel" class="distrustKeywords"
									style="display: none"></div> 
 -->
							</span>&nbsp;
<!-- 							<span><a href="javascript:showBelivePress(true)">选择可信任出版社</a>
								<div id="belivePressPanel" class="belivePress"
									style="display: none"></div> </span>
 -->
							<% if ("NotMarked".equals(docBaseType)) {%>
							<span><a href="trust_shop_manage.jsp" target="_blank">管理可信任书店</a>
								<div id="trustBookManage" class="belivePress"
									style="display: none"></div> </span>
							<%} %>
							<label style="color: gray">(上书时间数字长度必须为偶数，格式如：20130101)</label>
							<script type="text/javascript">//loadAssistantData();</script>

						</td>
					</tr>
					<tr>
						<td align="left">
							&nbsp;
						</td>
						<td align="right">
							<label style="color: gray">作者：</label>
						</td>
						<td height="26" align="left" valign="bottom">
							<input type="text" id="author" name="author" value="<%=author%>" />
							&nbsp;
							<label style="color: gray">出版社：</label>
							<input type="text" id="press" name="press" value="<%=press%>" />
							&nbsp;
<!-- 							
							<label style="color: gray">店铺名称：</label>
							<input type="text" id="shopname_search" name="shopname_search" value="<%=shopname_search%>" />
							&nbsp;
-->
 							<label style="color: gray">上书时间：</label>
							<input type="text" id="addTimeStart" name="addTimeStart" value="<%=addTimeStart%>" />
							~
							<input type="text" id="addTimeEnd" name="addTimeEnd" value="<%=addTimeEnd%>" />&nbsp;
							<% if ("Marked".equals(docBaseType)){ %>
							&nbsp;
							<label style="color: gray">信任度：</label>
							<input type="text" size="5" id="beginTrustNum" name="beginTrustNum" value="<%=beginTrustNum%>" />
							~
							<input type="text" size="5" id="beginTrustNum" name="endTrustNum" value="<%=endTrustNum%>" />
							<%}%>
						</td>
					</tr>
				</table>
			</div>
			
			<div class="sort">&nbsp;&nbsp;&nbsp;
				<a backgroungfntype="key" searchtype="shop" defaultlevel="" show="search_choice_keywords_show_infomation_dom" 
				closefn="quickQuery" name="search_choice_keywords_dom" href="javascript:void(0);">选择可疑关键字</a>
				<span id="search_choice_keywords_show_infomation_dom"></span>
			</div>
			
			<div class="sort">
				&nbsp;排序：
				<select id="sorttypeSelect" onchange="setSort(this.value)">
					<option value="0" selected="selected">
						默认排序
					</option>
					<option value="1">
						价格 从低到高↑
					</option>
					<option value="2">
						价格 从高到低↓
					</option>
					<option value="3">
						出版日期 从远到近↑
					</option>
					<option value="4">
						出版日期 从近到远↓
					</option>
					<option value="5">
						上书时间 从远到近↑
					</option>
					<option value="6">
						上书时间 从近到远↓
					</option>
					<% if ("Marked".equals(docBaseType)){ %>
					<option value="7">
						信任度 从低到高↑
					</option>
					<option value="8">
						信任度 从高到低↓
					</option>
					<% }%>
				</select>
				<script>search_docuemntById("sorttypeSelect").value="<%=sortType%>";</script>
				&nbsp;&nbsp;筛选&nbsp;&nbsp; &nbsp;
				
				图片：
				<select id="hasPic" name="hasPic" onChange="showHasPic(this.value)">
					<option value="">
						全部
					</option>
					<option value="1">
						有图
					</option>
					<option value="0">
						无图
					</option>
				</select>
				<script>search_docuemntById("hasPic").value="<%=hasPic%>";</script>

				&nbsp;新旧书：
				<select id="bookNewOld" onchange="showNewBook(this.value)">
					<option value="">
						显示所有
					</option>
					<option value="0">
						只显示旧书
					</option>
					<option value="1">
						只显示新书
					</option>
				</select>
				<script>search_docuemntById("bookNewOld").value="<%=isNewBook%>";</script>

				&nbsp;图书类别：
				<select name="category" id="category" onchange="go(1)"><%=categoryOptionsHtml%></select>
				            
            <% if("NotMarked".equalsIgnoreCase(docBaseType)){ %>                      
				&nbsp;对比规则：
				<select name="autoVerifyType" id="autoVerifyType" >
				    <option value="">
						全部
					</option>				
					<option value="1">
						书名+作者
					</option>
				</select>
				<script>search_docuemntById("autoVerifyType").value="<%=autoVerifyType%>";</script>
			<% } %>

<!-- 本次搜索使用的SQL语句，暂时只为方便  “将所有结果信任度+1” 功能服务 -->
<input type="hidden" id="new_search_use_sql_sentence" name="new_search_use_sql_sentence" value="<%=searchSQL%>">
<!-- 当前搜索系统峰值 -->
<input type="hidden" id="new_search_max_count_num" name="new_search_max_count_num" value="<%=maxCount%>">
<!-- 本次搜索出的数据总条数 -->
<input type="hidden" id="new_search_book_total" name="new_search_book_total" value="<%=bookTotal%>">

<%
if ("DistrustKeywordBook".equalsIgnoreCase(docBaseType) && !"".equals(distrustKeywordGroupHtml)) {
%>
				&nbsp;可疑关键字：
				<select name="keywordGroupId" id="keywordGroupId"
					onchange="queryKeywordGroup(this.value)">
					<%=distrustKeywordGroupHtml%>
				</select>
				<script>search_docuemntById("keywordGroupId").value="<%=keywordGroupId%>";</script>
				<br />
				<div style="padding: 2px;">
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
				<img class="float_left" src="../images/none.gif" />
				<div class="float_left">
					<div>
						&nbsp;
					</div>
					<div>
						&nbsp;
					</div>
					<div>
						&nbsp;
					</div>
					<div>
						很抱歉！没有找到符合
						<label><%=keywords%></label>
						的结果。
					</div>
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
// 显示可执行操作：驳回、删除、待确认、忽略、取消
verifyToolbar_contents.append("<input type=\"button\" value=\"   删除   \" onclick=\"verifyBook('delete')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
if(!StringUtils.inArray(docBaseType, "TrustBookLib")){
	verifyToolbar_contents.append("<input type=\"button\" value=\"   驳回   \" onclick=\"verifyBook('reject')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
	verifyToolbar_contents.append("<input type=\"button\" value=\"   冻结   \" onclick=\"verifyBook('frozen')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}

if(StringUtils.inArray(docBaseType, "NotMarked", "Marked", "ToBeMarked")){
     verifyToolbar_contents.append("<input type=\"button\" value=\"   信任度+1   \" onclick=\"verifyBook('doMarkIncrOne')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}

if(StringUtils.inArray(docBaseType, "NotMarked")){
     verifyToolbar_contents.append("<input type=\"button\" value=\"   待标记   \" onclick=\"verifyBook('doToBeMark')\" />");
     verifyToolbar_contents.append("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
     verifyToolbar_contents.append("<input type=\"button\" value=\"   将所有结果信任度+1   \" onclick=\"doToBeBatchMark('doToBeBatchMark')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}
/**
if(StringUtils.inArray(docBaseType, "", "DistrustBannedBook", "DistrustKeywordBook", "DistrustPressBook", "UnknowPressBook")){
    verifyToolbar_contents.append("<input type=\"button\" value=\" 待确认 \" onclick=\"verifyBook('unconfirmed')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}
*/
if(StringUtils.inArray(docBaseType, "DistrustBannedBook", "DistrustKeywordBook", "DistrustPressBook", "UnconfirmedBook", "UnknowPressBook")){
    verifyToolbar_contents.append("<input type=\"button\" value=\"   忽略   \" onclick=\"verifyBook('ignore')\" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
}
if(StringUtils.inArray(docBaseType, "UnconfirmedBook", "IgnoreBook")){
    verifyToolbar_contents.append("<input type=\"button\" value=\"   取消   \" onclick=\"verifyBook('cancel')\" />");
}
verifyToolbar_contents.append("</div>");
out.print(verifyToolbar_contents.toString());
%>

			<!--页码导航开始-->
			<table align="center" border=0 width="98%" id="Page">
				<tr>
					<td height="28" align="left">
						<% 
	StringBuffer strPageNavigation = new StringBuffer();
	if(maxCount != null && !"".equals(maxCount.trim()) && !"-1".equals(maxCount.trim())){
		int maxCountNum = Integer.parseInt(maxCount);
		if(bookTotal > maxCountNum){
			strPageNavigation.append("<lable><b style='color:red;'>警告</b>：当前系统的搜索峰值为");
			strPageNavigation.append("&nbsp;<b style='color:red;'>").append(maxCountNum).append("</b>&nbsp;");
			strPageNavigation.append("请添加更多搜索条件，防止数据无法完整展示。本次搜索最多能展示");
			strPageNavigation.append("&nbsp;<b style='color:red;'>").append(onlyShowPageCount).append("</b>&nbsp;页数据。");
			strPageNavigation.append("</lable><br/>");
			out.print(strPageNavigation.toString());
		}
	}

	strPageNavigation.delete(0,strPageNavigation.length());
    strPageNavigation.append("<font color='#666666'><b>查询的图书总数：</b></font>" + bookTotal + "&nbsp;");
    strPageNavigation.append("共<font color='#0000ff'>" + pageTotal + "</font>页&nbsp;&nbsp;");
    strPageNavigation.append("现为<font color=red>" + currentPage + "</font>页&nbsp;");

    int page_count = StringUtils.intVal(pageTotal);
    current_page = StringUtils.intVal(currentPage);

    strPageNavigation.append(displayNavigation(page_count, current_page,Integer.parseInt(onlyShowPageCount)));
    strPageNavigation.append("<label>第<input type=\"text\" size=\"3\" maxlength=\"4\" maxValue=\""+page_count+"\" value=\"\" name=\"gopage\"  onkeydown=\"if(event.keyCode==13){gotopage();}\" />页&nbsp;<input type=\"button\" onclick=\"gotopage()\" value=\"转到\" class=\"goto_button\" /></label>");

    out.print(strPageNavigation.toString());
    out.print("&nbsp;&nbsp;搜索用时 " + searchTime + " 秒&nbsp;&nbsp;");
%>
					</td>
				</tr>
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
			<table align="center" border=0 width="98%" id="Page">
				<tr>
					<td height="28" align="left">
						<% 
    out.print(strPageNavigation.toString());
%>
					</td>
				</tr>
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
			<div
				style="width: 99%; text-align: left; padding: 5px 0px 5px 0px; margin: 5px 0px 5px 0px; border: 1px solid #FF9900; background-color: #FFFF66; font-size: 14px;">
				<div style="margin: 5px 10px 0px 10px;">
					你的操作不成功，删除的违禁图书无法在网站后台管理系统的管理违禁图书页面中显示。
					<br />
					异常信息：<%=ex%>。
					<br />
					以下是本次提交删除的违禁图书列表：
				</div>
			</div>

			<table style="font-size: 14px; margin-bottom: 5px;" width="99%"
				border="1" cellpadding="1" cellspacing="1">
				<tr>
					<td width="5%">
						序号
					</td>
					<td width="5%">
						业务
					</td>
					<td width="15%">
						书店名称
					</td>
					<td width="10%">
						书店编号
					</td>
					<td>
						书名
					</td>
					<td width="10%">
						图书编号
					</td>
					<td width="15%">
						作者
					</td>
					<td width="15%">
						出版社
					</td>
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
					<td width="5%"><%=i+1%>&nbsp;
					</td>
					<td width="5%"><%=getBizTypeDesc(tmp_bizType)%>&nbsp;
					</td>
					<td width="15%"><%=tmp_shopName%>&nbsp;
					</td>
					<td width="10%"><%=tmp_shopId%>&nbsp;
					</td>
					<td><%=tmp_itemName%>&nbsp;
					</td>
					<td width="10%"><%=tmp_itemId%>&nbsp;
					</td>
					<td width="15%"><%=tmp_author%>&nbsp;
					</td>
					<td width="15%"><%=tmp_press%>&nbsp;
					</td>
				</tr>
				<%
        }
    %>
			</table>
			<%
    }else{
%>			
			<div class="result_message">
				<img class="float_left" src="../images/none.gif" />
				<div class="float_left">
					<div>&nbsp;</div>
					<div>&nbsp;</div>
					<div>&nbsp;</div>
					<div><%=serverStatus%></div>
				</div>
			</div>
			<%
    }
}
//-----
%>
		</FORM>

		<div class="copyright">
			<label>
				版权所有(C)2002-2010 孔夫子旧书网
			</label>
		</div>
		<script type="text/javascript">//loadAssistantData();</script>
		<script type="text/javascript">
/**
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
*/
</script>

	</body>
</html>
