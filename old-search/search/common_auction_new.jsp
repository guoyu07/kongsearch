<%@ page pageEncoding="UTF-8"%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.math.BigDecimal"%>
<%@ page import="java.math.BigInteger"%>
<%@ page import="com.kongfz.dev.util.text.StringUtils" %>
<%@ page import="com.kongfz.dev.biz.util.CategoryHelper" %>
<%@ page import="org.owasp.esapi.ESAPI" %>
<%!

    /**
     * 过滤查询的关键词
     * @param keywords
     * @return
     */
    private String filterKeywords(String keywords)
    {
        int maxlength = 50;
        keywords = keywords.trim();
        if(keywords.equals("支持书名、作者、出版社、店名、省市等多个关键字的复合查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市进行组合查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市进行查询")){
            keywords="";
        }
        if(keywords.equals("可输入书名、作者、出版社、店名、省市查询")){
            keywords="";
        }
        if(keywords.equals("可输入拍卖主题、拍主昵称、作者查询")){
            keywords="";
        }
        if(keywords.equals("可输入帖子主题、内容查询")){
            keywords="";
        }
        if(keywords.equals("请输入书名或作者进行查询！")){
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
        keywords = keywords.trim();
        return keywords;
    }

    /**
     * 取得货币字符串
     */
    private static String getCurrencyString(double d)
    {
        BigDecimal bd = new BigDecimal(d).setScale(2, BigDecimal.ROUND_HALF_UP);
        BigInteger bi = bd.toBigInteger();
        return bi.toString();
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

    /**
     * 取得拍品的类别描述
     * @param catId
     * @return
     */
    private String getBidCategory(String catId)
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

        map.put("1","一");
        map.put("2","二");
        map.put("3","三");
        map.put("4","四");
        map.put("5","五");
        map.put("6","六");
        map.put("6.5","六五");
        map.put("7","七");
        map.put("7.5","七五");
        map.put("8","八");
        map.put("8.5","八五");
        map.put("9","九");
        map.put("9.5","九五");
        //map.put("10","十");

        String value = (String) map.get(quality);
        if(null == value || "".equals(value)){
            value = "一";
        }
        return value+"品";
    }


    /**
     * 转义HTML
     */
    private static String encodeForHTML(String text)
    {
        return ESAPI.encoder().encodeForHTML(text);
    }

    /**
     * 转义JS
     */
    private static String encodeForJavaScript(String text)
    {
        return ESAPI.encoder().encodeForJavaScript(text);
    }

    /**
     * 删除价格的左边多余的零
     * @return
     */
    private String ltrimMoneyFormat(String price)
    {
        DecimalFormat df = new DecimalFormat("#########0.00");
        Number num = 0;
        try{
            num = df.parse(price);
        }catch (Exception e){
            //e.printStackTrace();
            num = 0;
        }
        String str = df.format(num);
        return str;
    }

    private String buildCategoryOptions(String targetCatId)
    {
        List<String> topCatList = CategoryHelper.getTopCatIdList();
        StringBuffer buffer = new StringBuffer();
        buffer.append("<option value=\"\" >所有</option>");
        for (String catId : topCatList) {
            String catName = CategoryHelper.getCategoryName(catId);
            if(catId.equals(targetCatId)){
                buffer.append("<option value=\""+catId+"\" selected=\"selected\" >"+catName+"</option>");
            }else{
                buffer.append("<option value=\""+catId+"\" >"+catName+"</option>");
            }
        }
        return buffer.toString();
    }

    /**
     * 取得拍品区的名称
      * @param id
     * @return
     */
    private String getAuctionArea(int id)
    {
        String[] auctionArea = new String[]{"所有", "珍本拍卖区", "大众拍卖区", "低价拍卖区"};
        return ((0 <= id && id <= 3)? auctionArea[id] :""+id);
    }

    private String buildAuctionAreaOptions(String areaId)
    {
        String[] auctionArea = new String[]{"所有", "珍本拍卖区", "大众拍卖区", "低价拍卖区"};
        if(areaId.equals("")){areaId = "0";}
        int id = StringUtils.intVal(areaId);

        StringBuffer buffer = new StringBuffer();
        for(int i=0; i < auctionArea.length; i++){
            if(i == id){
                buffer.append("<option value=\""+i+"\" selected=\"selected\" >"+auctionArea[i]+"</option>");
            }else{
                buffer.append("<option value=\""+i+"\" >"+auctionArea[i]+"</option>");
            }
        }
        return buffer.toString();
    }

    /**
     * 读取Cookie
     */
    private static String getCookieValue(HttpServletRequest request, String cookieName, String defaultValue) {
        try{
            Cookie cookies[] = request.getCookies();
            for(int i=0; cookies != null && i < cookies.length; i++) {
                Cookie cookie = cookies[i];
                if (cookie != null && cookieName.equals(cookie.getName())){
                    return(cookie.getValue());
                }
            }
            return defaultValue;
        }catch(Exception e){
            //e.printStackTrace();
        }
        return defaultValue;
    }

    /**
     * 取得拍品图片的链接
     */
    private static String getItemImageSrc(String smallImg)
    {
        if (null == smallImg || "".equals(smallImg.trim())){
            return "/images/none.gif";
        }
        // 外链
        if (smallImg.startsWith("http:")){
            return smallImg;
        }
        // 无效外链
        if (smallImg.split("\\.").length > 2){
            return "/images/none.gif";
        }
        smallImg += "_s.jpg";
        // 有效图片
        if (smallImg.contains("/") && smallImg.contains("_") && smallImg.contains(".")) {
	if (smallImg.startsWith("G")) 
        		return "http://www.kfzimg.com/" + smallImg;
        	else
            	return "http://auctionimg.kongfz.com/" + smallImg;        
}
        // 无法识别的图片
        return "/images/none.gif";
    }

    /**
     * 显示导航页码
     * @return
     */
    private String displayNavigation(int pageCount, int currentPage, String queryString, String pageUrl)
    {
        StringBuffer buffer = new StringBuffer();
        if(queryString != null){
            queryString = queryString.replaceAll("&*page=\\d*", "");
        }else{
            queryString = "";
        }
        queryString = pageUrl + "?"+ queryString + "&page=";

        if(pageCount > 0) {
            //htmlContent += "<span><a href=\"javascript:go(1)\">首页</a></span>";
            
            //如果当前页为第一页，则不显示“上一页链接”
            if(currentPage > 1){
                buffer.append("<span><a href=\""+queryString+(currentPage-1)+"\">上一页</a></span>");
            }else{
                buffer.append("<span><a>上一页</a></span>");
            }
            
            //每次从当前页向后显示十页，如果不够十页，则全部显示。
            int pageStep = 9;//显示的页码数量
            int start = ( currentPage - 1 ) / pageStep * pageStep + 1;
            start = start < 1 ? 1 : start;
            int end = start + pageStep;
            end = end > pageCount ? pageCount : end;
            
            if(start > 1){
                buffer.append("<span><a href=\""+queryString+"1"+"\">1</a></span>");
            }
            
            if(start > 2){
                buffer.append("<span>...</span>");
            }
            
            for(int i = start; i <= end ; i++){
                if(currentPage == i){
                    buffer.append("<span><a class=\"current\">"+i+"</a></span>");
                }else{
                    buffer.append("<span><a href=\""+queryString+i+"\">"+i+"</a></span>");
                }
            }
            
            if(end  < pageCount){
                buffer.append("<span>...</span>");
            }
            //htmlContent += "<span><a href=\"javascript:go("+pageCount+")\">"+pageCount+"</a></span>";
            
            //如果当前页为最后一页，则不显示“下一页”链接
            if(currentPage < pageCount){
                buffer.append("<span><a href=\""+queryString+(currentPage+1)+"\">下一页</a></span>");
            }else{
                buffer.append("<span><a>下一页</a></span>");
            }
            //htmlContent += "<a href=\"javascript:go("+pageCount+")\">末页</a>";
            //跳转到指定页
            /*if(pageCount > 1){
            buffer.append("<span>　　到第<input id=\"pageNo\" type=\"text\" maxLength=3 style=\"margin-top:5px;width:25px;\" onkeydown=\"if(event.keyCode==13)go(this.value)\" />页</span>");
            buffer.append("<span><input style=\"margin-top:5px;\" type=\"button\" onclick=\"jumppage()\" value=\"确定\"/></span>");
            }*/
            
        }
        return buffer.toString();
    }

    /**
     * 显示拍卖查询结果（bid_h.jsp和bid_h_adv.jsp）
     * @param bidList
     * @param out
     * @return
     */
    private void displayBidsTable(List bidList, JspWriter out) throws Exception
    {
        String auctionSite = "http://www.kongfz.cn/";
        String imageSite   = "http://auctionimg.kongfz.com/";
        StringBuffer buffer = new StringBuffer();
        buffer.append("<table class=\"List\" width=\"946\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\">");
        buffer.append("<tr height=\"30\" bgcolor=\"#d5e4f1\" align=\"center\">");
        buffer.append("<td width=\"8%\">拍卖区</td>");
        buffer.append("<td width=\"10%\">类别</td>");
        buffer.append("<td width=\"32%\">拍卖主题</td>");
        buffer.append("<td width=\"7%\">起拍价</td>");
        buffer.append("<td width=\"8%\">最高价</td>");
        buffer.append("<td width=\"8%\">卖主</td>");
        buffer.append("<td width=\"8%\">作者</td>");
        buffer.append("<td width=\"8%\">竞标/阅读</td>");
        buffer.append("<td width=\"10%\">结束时间</td>");
        buffer.append("</tr></table>");
        out.write(buffer.toString());

        for(int i = 0; i < bidList.size(); i++)
        {
            buffer.setLength(0);
            Map map = (Map)bidList.get(i);
            int auctionArea       = StringUtils.intVal(map.get("auctionArea"));
            String category       = StringUtils.strVal(map.get("catId"));
            String itemId         = StringUtils.strVal(map.get("itemId"));
            String itemName       = StringUtils.strVal(map.get("itemName"));
            String itemName_hl    = StringUtils.strVal(map.get("itemName_hl"));
            String itemDesc       = StringUtils.strVal(map.get("description"));
            double beginPrice     = StringUtils.doubleVal(map.get("beginPrice"));
            double maxPrice       = StringUtils.doubleVal(map.get("maxPrice"));
            String userId         = StringUtils.strVal(map.get("userId"));
            String nickname       = StringUtils.strVal(map.get("nickname"));
            String author         = StringUtils.strVal(map.get("author"));
            String bidNum         = StringUtils.strVal(map.get("bidNum"));
            String viewedNum      = StringUtils.strVal(map.get("viewedNum"));
            String endTime        = StringUtils.strVal(map.get("endTime")).substring(0, 10);
            int specialArea       = StringUtils.intVal(map.get("specialArea"));
            int buyerId           = StringUtils.intVal(map.get("buyerId"));

            String itemUrl        = auctionSite+itemId+"/";
            String memberInfoUrl = "";
            if (141 == specialArea && !(maxPrice > 0 && buyerId > 0 && buyerId != 2131856)) {
                memberInfoUrl  = "http://help.kongfz.com/?act=detail&contentId=357";
                nickname = "保真专场";
            }
            else {
                memberInfoUrl = "http://user.kongfz.com/member/view_member_info.php?memberId="+userId;
            }

            buffer.append("<table  class=\"List\" width=\"946\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\">");
            buffer.append("<tr height=\"30\" bgcolor=\""+((i % 2 == 0)?"#edf3f8":"#ffffff")+"\" align=\"center\" >");
            buffer.append("<td width=\"8%\" >"+getAuctionArea(auctionArea)+"</td>");
            buffer.append("<td width=\"10%\" >"+getBidCategory(category)+"</td>");
            buffer.append("<td align=\"left\" width=\"32%\"><a class=\"bookName\" style=\"font-size:14px\" href=\""+itemUrl+"\" target=\"_blank\" title=\""+encodeForHTML(itemDesc)+"\">"+(itemName_hl)+"</a></td>");
            buffer.append("<td align=\"left\" width=\"7%\">"+getCurrencyString(beginPrice)+"</td>");
            buffer.append("<td align=\"left\" width=\"8%\">"+(0 == maxPrice ?"无":"<font color=red>"+getCurrencyString(maxPrice)+"</font>元")+"</td>");
            buffer.append("<td align=\"left\" width=\"8%\"><a  class=\"bookName\" style=\"font-size:14px\"  href=\""+memberInfoUrl+"\" target=\"_blank\">"+encodeForHTML(nickname)+"</a></td>");
            buffer.append("<td align=\"left\" width=\"8%\">"+encodeForHTML(author)+"</td>");
            buffer.append("<td align=\"right\" width=\"8%\">"+(encodeForHTML(bidNum) + "/" +encodeForHTML(viewedNum))+"</td>");
            buffer.append("<td width=\"10%\">"+(encodeForHTML(endTime))+"</td>");
            buffer.append("</tr></table>");
            out.write(buffer.toString());
        }
    }

    /**
     * 使用图文方式显示拍品列表（用于auction_pic.jsp）
     */
    private void displayBidsGraphic(List bidList, JspWriter out) throws Exception
    {
        String auctionSite = "http://www.kongfz.cn/";
        String imageSite   = "http://auctionimg.kongfz.com/";
        StringBuffer buffer = new StringBuffer();
        for(int i = 0; i < bidList.size(); i++)
        {
            buffer.setLength(0);
            Map map = (Map)bidList.get(i);
            int auctionArea       = StringUtils.intVal(map.get("auctionArea"));
            String category       = StringUtils.strVal(map.get("catId"));
            String itemId         = StringUtils.strVal(map.get("itemId"));
            String itemName       = StringUtils.strVal(map.get("itemName"));
            String itemName_hl    = StringUtils.strVal(map.get("itemName_hl"));
if (itemId.equals("14511599")) {
String abc = "Banjo\\\'s Bush Ballads 班卓琴的布什民谣 图文本";
out.write(StringUtils.strVal(map.get("itemName")).replace("\\", "\\"));
out.write(new String(itemName).replace("\\", "\\")+"<br/>");
out.write(itemName_hl.replace("\\", "\\"));
}
            String itemDesc       = StringUtils.strVal(map.get("description"));
            String author         = StringUtils.strVal(map.get("author"));
            String press          = StringUtils.strVal(map.get("press"));
            double beginPrice     = StringUtils.doubleVal(map.get("beginPrice"));
            double maxPrice       = StringUtils.doubleVal(map.get("maxPrice"));
            String maxPriceTitle  = (maxPrice == 0 ? "无" : getCurrencyString(maxPrice) + "元");
            String userId         = StringUtils.strVal(map.get("userId"));
            String nickname       = StringUtils.strVal(map.get("nickname"));
            String bidNum         = StringUtils.strVal(map.get("bidNum"));
            String viewedNum      = StringUtils.strVal(map.get("viewedNum"));
            String pubDate        = formatDateYMD(StringUtils.strVal(map.get("pubDate")));
            String endTime        = StringUtils.strVal(map.get("endTime")).substring(0, 10);
            String quality        = getBookQuality(StringUtils.strVal(map.get("quality")));
            String smallImg       = StringUtils.strVal(map.get("smallImg"));
            int specialArea       = StringUtils.intVal(map.get("specialArea"));
            int buyerId           = StringUtils.intVal(map.get("buyerId"));

            String itemUrl        = auctionSite+itemId+"/";
            String memberInfoUrl = "";
            // 拍卖结束，针对保真专场，没有成交的拍品不显示卖主昵称和真实姓名 
            if (141 == specialArea && !(maxPrice > 0 && buyerId > 0 && buyerId != 2131856)) {
                memberInfoUrl  = "http://help.kongfz.com/?act=detail&contentId=357";
                nickname = "保真专场";
            }
            else {
                memberInfoUrl = "http://user.kongfz.com/member/view_member_info.php?memberId="+userId;
            }

            buffer.append("<tr>");
            buffer.append("<td style=\"padding-top:14px;\" valign=\"top\">");
            buffer.append("	<a href=\""+itemUrl+"\" target=\"_blank\">");
            buffer.append("		<img src=\""+getItemImageSrc(smallImg)+"\" onerror=\"this.src='./images/none.gif'\" width=\"80\" height=\"100\" alt=\""+encodeForHTML(itemName)+"\" />");
            buffer.append("	</a>");
            buffer.append("</td>");
            buffer.append("<td align=\"left\"><a href=\""+itemUrl+"\" target=\"_blank\" class=\"blue\" title=\""+encodeForHTML(itemDesc)+"\">"+(itemName_hl)+"</a><br />");
            buffer.append("	<font class=\"gray\">拍卖区："+getAuctionArea(auctionArea)+"　　分类："+getBidCategory(category)+"<br />");
            buffer.append("	作者："+encodeForHTML(author)+"　　出版社："+encodeForHTML(press)+"</font><br />");
            buffer.append("	出版日期："+encodeForHTML(pubDate)+"<br />");
            buffer.append("	卖主：<a href=\""+memberInfoUrl+"\" target=\"_blank\">"+encodeForHTML(nickname)+"</a>");
            buffer.append("</td>");
            
            buffer.append("<td align=\"center\" valign=\"top\" class=\"prace\">"+getCurrencyString(beginPrice)+"/"+maxPriceTitle+"<br /><span style=\"color:black;font-weight:normal\">"+quality+"</span></td>");
            buffer.append("<td align=\"center\" valign=\"top\" class=\"prace\">"+encodeForHTML(bidNum)+"/"+encodeForHTML(viewedNum)+"</td>");
            buffer.append("<td align=\"center\" valign=\"top\" align=\"center\">"+encodeForHTML(endTime)+"</td>");
            buffer.append("</tr>");
            out.write(buffer.toString());
        }
    }

%>
