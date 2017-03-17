<%@ page pageEncoding="UTF-8"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.math.BigDecimal"%>
<%@ page import="java.sql.Timestamp"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.util.HashMap"%>
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
    keywords = keywords.replaceAll("[\\\\\\!\\(\\)\\:\\[\\]\\{\\}\\*\\?;]", "");
    //替换为空格的字符：全角空格　、制表符\t
    keywords = keywords.replaceAll("[　\t]", " ");
    //多个空格替换为一个空格
    keywords = keywords.replaceAll("( )+", " ");
    //keywords = keywords.replaceAll("－－|--", "——");//两个全角减号替换为一个破折号
    
    //全角的＋、－、ＡＮＤ、ＯＲ替换为半角的
    //keywords = keywords.replaceAll("＋", "+");
    //keywords = keywords.replaceAll("－", "-");
    keywords = keywords.replaceAll("ＡＮＤ", "AND");
    keywords = keywords.replaceAll("ＯＲ", "OR");

    //先去掉+或-前后的空格
    //keywords = keywords.replaceAll("( ?\\+ ?)+", "+");
    //keywords = keywords.replaceAll("( ?\\- ?)+", "-");
    keywords = keywords.replaceAll("( ?AND ?)+", "AND");
    keywords = keywords.replaceAll("( ?OR ?)+", "OR");
    //再去掉连续的逻辑运算符
    //keywords = keywords.replaceAll("(\\+)+", "+");
    //keywords = keywords.replaceAll("(\\-)+", "-");
    keywords = keywords.replaceAll("(AND)+", "AND");
    keywords = keywords.replaceAll("(OR)+", "OR");
    //去掉重叠的逻辑运算符
    //keywords = keywords.replaceAll("(\\-\\+)+", "-");
    //keywords = keywords.replaceAll("(\\+\\-)+", "+");
    keywords = keywords.replaceAll("(ORAND)+", "OR");
    keywords = keywords.replaceAll("(ANDOR)+", "AND");
    //去掉行头和行尾的逻辑运算符
    //keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
 //   keywords = keywords.replaceAll("^\\+|^\\-|\\-$|\\+$|^AND|^OR|AND$|OR$", "");
    //规范化逻辑表达式
    //keywords = keywords.replaceAll("\\+", " +");
    //keywords = keywords.replaceAll("\\-", " -");
   // keywords = keywords.replaceAll("AND", " AND ");
    //keywords = keywords.replaceAll("OR", " OR ");
    keywords = keywords.trim();
    return keywords;
}

/**
 * 将HTML标记符号转义
 */
private static String htmlEntities(String text)
{
    String newText = text;
    newText = newText.replace("<", "&lt;");
    newText = newText.replace(">", "&gt;");
    newText = newText.replace("\"", "&quot;");
    newText = newText.replace("&", "&amp;");
    return newText;
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

/**
 * 浮点数转货币数字
 */
private BigDecimal double2Currency(double d)
{
    return (new BigDecimal(d).setScale(2, BigDecimal.ROUND_HALF_UP));
}

/**
 * 取得“yyyy-MM-dd HH:mm:ss”格式的当前日期/时间
  * @param date
 * @return
 */
private String getCurrentDate()
{
    return (new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
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
 * 判断一个日期是否在当前日期的两天之前
 */
private Boolean isBeforeCurrent(String time)
{
    try{
        time = time.substring(0, 10);
        Timestamp lastTime = Timestamp.valueOf(time+" 00:00:00");
        long currentMillis = System.currentTimeMillis() - 2 * 24 * 60 * 60 * 1000;
        Timestamp current = new Timestamp(currentMillis);
        return lastTime.before(current);
    }catch(Exception ex){
        return false;
    }
}

/**
 * 计算剩余时间
 * @param	String	date1	要比对的时间
 * @param	String	date2	当前时间
 */
private String getTimeDifference(String date1, String date2)
{
    String difference = "";
    try{
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        Date now = df.parse(date1);
        Date date = df.parse(date2);
        long l = now.getTime() - date.getTime();
        long day = l / (24 * 60 * 60 * 1000);
        
        if(day > 0){
            difference = "" + day + "天";
        }
        
        long hour = (l / (60 * 60 * 1000) - day * 24);
        if(hour > 0 || !difference.equals("")){
            difference += "" + hour + "小时";
        }
        
        long min = ((l / (60 * 1000)) - day * 24 * 60 - hour * 60);
        if(min > 0 || !difference.equals("")){
            difference += "" + min + "分";
        }
        
        long s = (l / 1000 - day * 24 * 60 * 60 - hour * 60 * 60 - min * 60);
        if(s > 0 || !difference.equals("")){
            difference += "" + s + "秒";
        }

    }catch(Exception ex){

    }
    return difference;
}

/**
 * 将数字字符串转整数
 */
private int intval(String str)
{
    int value = 0;
    try{
        value = Integer.parseInt(str);
    }catch(Exception ex){
        value = 0;
    }
    return value;
}

/**
 * 取得图书的类别描述
  * @param id
 * @return
 */
private String getBookCategory(String catId)
{
    return CategoryHelper.getCategoryFullName(catId);
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
 * 取得折扣的文字表述
 */
private String getDiscountLiteral(String discount)
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
    map.put("100","不打");

    String value = (String) map.get(discount);
    if(null == value || "".equals(value)){
        value = "不打";
    }
    return value+"折";
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
 * 切换显示新书或旧书
 */
private String buildIsNewBookBar(String isNewBook)
{
    String[] list = new String[]{"全部", "旧书", "新书"};
    if(isNewBook.equals("")){isNewBook = "-1";}
    int id = intval(isNewBook);

    StringBuffer buffer = new StringBuffer();
    for(int i=0; i < list.length; i++){
        if((i-1) == id){
            buffer.append("<option value=\""+(i-1)+"\" selected=\"selected\" >"+list[i]+"</option>");
        }else{
            buffer.append("<option value=\""+(i-1)+"\" >"+list[i]+"</option>");
        }
    }
    return buffer.toString();
}

/**
 * 取得星级的图标
 */
private String getShopClassImage(String shopClass)
{
    String[] descList = new String[]{"无星","一星","二星","三星","四星","五星","一钻","二钻","三钻","特色三钻"};
    String html = "";
    int value = intval(shopClass);
    String title=descList[value];
    if(1 <= value && value <= 5){
        html = value + "<img src=\"images/icons/red_rank_1.gif\" align=\"absmiddle\" />";
    }else if(6 <= value && value <= 8){
        html = (value - 5) + "<img src=\"images/icons/red_small_rank.gif\" align=\"absmiddle\" />";
    }else if(9 == value){
        html = 3 + "<img src=\"images/icons/red_small_rank_t.gif\" align=\"absmiddle\" />";
    }else{
        html = "无星";
    }
    if(!html.equals("")){
        html = "<a href=\"http://help.kongfz.com/?act=detail&contentId=148\" title=\""+title+"\" target=\"_blank\">"+html+"</a>";
    }
    return html;
}

private String getShopClassImageFull(String shopClass)
{
    String[] descList = new String[]{"无星","一星","二星","三星","四星","五星","一钻","二钻","三钻","特色三钻"};
    String html = "";
    int value = intval(shopClass);
    if(1 <= value && value <= 9){
        html = "<img src=\"/images/icons/red_rank_"+value+".gif\" align=\"absmiddle\" title=\""+descList[value]+"\" />";
    }if(0 == value){
        html = "无星";
    }
    if(!html.equals("")){
        html = "<a href=\"http://help.kongfz.com/?act=detail&contentId=148\" target=\"_blank\">"+html+"</a>";
    }
    return html;
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
 * 取得图书图片的链接
 */
private static String getBookImageSrc(String bizType, String smallImg)
{
    if ("".equals(smallImg.trim())) {
        return "/images/none.gif";
    }
    else {
        if("shop".equals(bizType)){
            return "http://shopimg.kongfz.com/" + smallImg;
        }
        else {
            return "http://tanimg.kongfz.com/" + smallImg;
        }
    }
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
 * 显示图书查询结果(图文方式)
 * @param bookList
 * @return
 */
private void displayHitsPic(List bookList, JspWriter out) throws Exception
{
    String shopSite="http://shop.kongfz.com/";
    String bookSite="http://book.kongfz.com/";
    String tanSite="http://tan.kongfz.com/";
    String bookUrl = "";
    StringBuffer buffer = new StringBuffer();

    for(int i = 0, length = bookList.size(); i < length; i++)
    {
        buffer.setLength(0);
        Map map = (Map) bookList.get(i);
        if(null == map){ continue; }
        int saleStatus      = StringUtils.intVal(map.get("saleStatus"));
        String itemId       = StringUtils.strVal(map.get("itemId"));
        String itemName     = StringUtils.strVal(map.get("itemName"));
        String itemName_hl  = StringUtils.strVal(map.get("itemName_hl"));
        String shopId       = StringUtils.strVal(map.get("shopId"));
        String shopName     = StringUtils.strVal(map.get("shopName"));
        String area         = StringUtils.strVal(map.get("area"));
        String author       = StringUtils.strVal(map.get("author"));
        String press        = StringUtils.strVal(map.get("press"));
        String bookDesc     = StringUtils.strVal(map.get("itemDesc"));
        // String price        = ltrimMoneyFormat(StringUtils.strVal(map.get("price")));
        String price        = StringUtils.strVal(map.get("price"));
        int discount        = StringUtils.intVal(map.get("discount"));
        String realPrice    = String.valueOf(double2Currency(StringUtils.doubleVal(map.get("realPrice"))));

        String smallImg     = StringUtils.strVal(map.get("smallImg"));
        String addTime      = formatDate(StringUtils.strVal(map.get("addTime")));
        String isCreatePage = StringUtils.strVal(map.get("isCreatePage"));
        String shopClass    = StringUtils.strVal(map.get("shopClass"));
        String quality      = getBookQuality(StringUtils.strVal(map.get("quality")));
        String category     = getBookCategory(StringUtils.strVal(map.get("catId")));
        int number          = StringUtils.intVal(map.get("number"));
        String pubDate      = formatDateYM(StringUtils.strVal(map.get("pubDate")));
        String bookHint     = bookDesc + ("".equals(bookDesc) ? "" : " ...");
        String bizType      = StringUtils.strVal(map.get("bizType"));
        String site = "";
        if("shop".equals(bizType)){
            site = shopSite;
            if(isBeforeCurrent(addTime) || isCreatePage.equals("1")){
                //bookUrl = shopSite+"book/"+shopId+"/"+bookId+".html";
                //if(saleStatus == 1){
                //    bookUrl = shopSite+"book/"+shopId+"/"+bookId+".html";
                //}else{
                    bookUrl = bookSite+shopId+"/"+itemId+"/";
                //}
            }else{
                //bookUrl = shopSite+"book_detail.php?bookId="+bookId+"&shopId="+shopId;
                bookUrl = bookSite+shopId+"/"+itemId+"/";
            }
        }else if("bookstall".equals(bizType)){
            site = tanSite;
            bookUrl = tanSite+shopId+"/"+itemId+"/";
        }
        
        buffer.append("<tr>");
        buffer.append("<td class=\"list_td1\">");
        buffer.append("<a href=\""+bookUrl+"\" target=\"_blank\"><img src=\""+getBookImageSrc(bizType, smallImg)+"\" /></a>");
        buffer.append("</td>");
        buffer.append("<td align=\"left\"  class=\"list_td2\">");
        
        buffer.append("<a href=\""+bookUrl+"\" title=\""+encodeForHTML(bookHint)+"\" target=\"_blank\" class=\"blue\">"+(itemName_hl)+"</a><br />");
        buffer.append("<font color=gray>类别：" + category + "<br />");
        buffer.append("作者："+author+" <br />");
        buffer.append("出版社："+press+"<br /></font>");
        buffer.append("书店：<a href=\""+site+"book/"+shopId+"/\" target=\"_blank\">"+shopName+"</a>("+getShopClassImage(shopClass)+")&nbsp;&nbsp;&nbsp;&nbsp;省市："+area);
        buffer.append("</td>");
        
        buffer.append("<td align=\"center\" class=\"list_td3\">");
        buffer.append("<span class=\"prace\">" + realPrice +"</span><br />");
        buffer.append("<span>" + quality + "</span><br />");
        buffer.append("</td>");

        buffer.append("<td align=\"center\" class=\"list_td4\">" + pubDate + "</td>");
        buffer.append("<td align=\"center\" class=\"list_td5\">" + addTime + "<br />");
        if(saleStatus == 0){
            if(number > 0){//未售
                buffer.append("<br /><span class=\"sale_on_order\" onclick=\"addItemForCart(" + itemId + "," + shopId + ",'"+bizType+"',this)\"><a class=\"search_btn_buy\">购买</a></span>");
            }else{//已订完
                buffer.append("<br /><a class=\"search_btn_finished\">已订完</a></div>");
            }
        }else{//已售
            buffer.append("<br /><a class=\"search_btn_sold\">已售</a>");
        }
        buffer.append("</td></tr>\n");
        out.write(buffer.toString());
    }
}

/**
 * 显示图书查询结果
 * @param bookList
 * @return
 */
private void displayHitsTable(List bookList, JspWriter out) throws Exception
{
    String shopSite="http://shop.kongfz.com/";
    String bookSite="http://book.kongfz.com/";
    String tanSite="http://tan.kongfz.com/";
    String bookUrl = "";
    StringBuffer buffer = new StringBuffer();

    buffer.append("<table width=\"946\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"List\">");
    buffer.append("<tr height=\"30\" bgcolor=\"#d5e4f1\">");
    buffer.append("<td width=\"9%\">书店名称</td>");
    buffer.append("<td width=\"10%\">省市</td>");
    buffer.append("<td width=\"20%\">书名</td>");
    buffer.append("<td width=\"10%\">类别</td>");
    buffer.append("<td width=\"10%\">作者</td>");
    buffer.append("<td width=\"10%\">出版社</td>");
    buffer.append("<td width=\"6%\">出版时间</td>");
    buffer.append("<td width=\"5%\">品相</td>");
    buffer.append("<td width=\"5%\">售价</td>");
    buffer.append("<td width=\"7%\">上书时间</td>");
    buffer.append("<td width=\"8%\">定购</td>");
    buffer.append("</tr></table>");
    out.write(buffer.toString());
    
    for(int i = 0, length = bookList.size(); i < length; i++)
    {
        buffer.setLength(0);
        Map map = (Map)bookList.get(i);
        if(null == map){ continue; }
        int saleStatus      = StringUtils.intVal(map.get("saleStatus"));
        String itemId       = StringUtils.strVal(map.get("itemId"));
        String itemName     = StringUtils.strVal(map.get("itemName"));
        String itemName_hl  = StringUtils.strVal(map.get("itemName_hl"));
        String shopId       = StringUtils.strVal(map.get("shopId"));
        String shopName     = StringUtils.strVal(map.get("shopName"));
        String area         = StringUtils.strVal(map.get("area"));
        String author       = StringUtils.strVal(map.get("author"));
        String press        = StringUtils.strVal(map.get("press"));
        String bookDesc     = StringUtils.strVal(map.get("itemDesc"));
        //String price        = ltrimMoneyFormat(StringUtils.strVal(map.get("price")));
        String price        = StringUtils.strVal(map.get("price"));
        int discount        = StringUtils.intVal(map.get("discount"));
        String realPrice    = String.valueOf(double2Currency(StringUtils.doubleVal(map.get("realPrice"))));

        String addTime      = formatDate(StringUtils.strVal(map.get("addTime")));
        String isCreatePage = StringUtils.strVal(map.get("isCreatePage"));
        String pubDate      = formatDateYM(StringUtils.strVal(map.get("pubDate")));
        String quality      = getBookQuality(StringUtils.strVal(map.get("quality")));
        String category     = getBookCategory(StringUtils.strVal(map.get("catId")));
        int number          = StringUtils.intVal(map.get("number"));
        boolean hasPic      = (StringUtils.intVal(map.get("hasPic")) == 1);
        String bookHint     = StringUtils.subStr(bookDesc, 250) + " ...";

        String bizType = StringUtils.strVal(map.get("bizType"));
        String site = "";
        if(bizType.equals("shop")){
            site = shopSite;
            if(isBeforeCurrent(addTime) || isCreatePage.equals("1")){
                //bookUrl = shopSite+"book/"+shopId+"/"+bookId+".html";
                //if(saleStatus == 1){
                //    bookUrl = shopSite+"book/"+shopId+"/"+bookId+".html";
                //}else{
                    bookUrl = bookSite+shopId+"/"+itemId+"/";
                //}
            }else{
                //bookUrl = shopSite+"book_detail.php?bookId="+bookId+"&shopId="+bs_id;
                bookUrl = bookSite+shopId+"/"+itemId+"/";
            }
        }else if(bizType.equals("bookstall")){
            site = tanSite;
            bookUrl = tanSite+shopId+"/"+itemId+"/";
        }
        
        buffer.append("<table width=\"946\" bgcolor=\"#FFFFFF\" align=\"center\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\" class=\"List\">");
        buffer.append((i%2==0) ? "<tr bgcolor=\"#edf3f8\">" : "<tr bgcolor=\"#ffffff\">");
        buffer.append("<td width=\"9%\"><a href=\"" + site + "book/" + shopId + "/\" target=\"_blank\">" + shopName + "</a></td>");
        buffer.append("<td width=\"10%\">" + area + "&nbsp;</td>");
        buffer.append("<td width=\"20%\"><a class=\"itemName\" href=\""+bookUrl+"\" target=\"_blank\" title=\"" + encodeForHTML(bookHint) + "\" >" + itemName_hl + (hasPic ? "<label style=\"color:#FF0000\">(图)</label>" : "") + "</a>&nbsp;</td>");
        buffer.append("<td width=\"10%\">" + category + "&nbsp;</td>");
        buffer.append("<td width=\"10%\">" + author + "&nbsp;</td>");
        buffer.append("<td width=\"10%\">" + press + "&nbsp;</td>");
        buffer.append("<td width=\"6%\">" + pubDate +"&nbsp;</td>");
        buffer.append("<td width=\"5%\">" + quality +"&nbsp;</td>");
        buffer.append("<td width=\"5%\">" + realPrice +"&nbsp;</td>");
        buffer.append("<td width=\"7%\">" + addTime +"&nbsp;</td>");
        if(saleStatus == 0){
            if(number > 0){//未售
                buffer.append("<td width=\"8%\"><span class=\"sale_on_order\" onclick=\"addItemForCart("+itemId+","+shopId+",'"+bizType+"',this)\"><a class=\"search_btn_buy search_btn_buy_list\">购买</a></span></td>");
            }else{//已订完
                buffer.append("<td width=\"8%\"><a class=\"search_btn_finished search_btn_finished_list\">已订完</a></td>");
            }
        }else{//已售
            buffer.append("<td width=\"8%\"><a class=\"search_btn_sold search_btn_sold_list\">已售</a></td>");
        }
        
        buffer.append("</tr></table>\n");
        out.write(buffer.toString());
    }
}

/**
 * 搜索无结果时的提示信息
 */
private static String getNotFoundMessageHtml(String query) throws Exception
{
    String tradeMessage = "<a href=\"http://www.kongfz.com/trade/add_trade.php?tc=matching&tn="
    +java.net.URLEncoder.encode(new String("求购配售"),"GBK")
    +"&ti="+java.net.URLEncoder.encode(query,"GBK")
    +"&subtc="+java.net.URLEncoder.encode(new String("求购"),"GBK")+"\" target=\"_blank\"><img style=\"margin:0px;\" border=\"0\" src=\"images/bt_publish.gif\" title=\"发布求购信息\" /></a>";

    StringBuffer buffer = new StringBuffer();
    buffer.append("<div class=\"hintBox\">");
    buffer.append("<div><img src=\"images/none_message.gif\" /></div>");
    buffer.append("<div>");
    buffer.append("<div style=\"font-size:18px;font-weight:bold\">很抱歉，没有找到与“<label style=\"color:#FF0000;font-size:18px;font-weight:bold\">"+query+"</label>”相关的图书</div><br />");
    buffer.append("<div>建议您：</div><br />");
    buffer.append("<ul><li>看看输入的文字是否有误</li>");
    buffer.append("<li>去掉可能不必要的字词，如“的”、“什么”等</li>");
    buffer.append("<li>调整关键字，如“红楼梦连环画”改成“红楼梦 连环画”</li>");
    buffer.append("<li>使用书名或作者名中包含的部分字词重新搜索 </li>");
    //buffer.append("<li>您还可以"+tradeMessage+" </li>");
    buffer.append("</ul></div>");
    buffer.append("</div>");
    return buffer.toString();
}

/**
 * 精确搜索不到结果时的提示信息
 */
private static String getNotFoundHintHtml(String fuzzy, String fuzzyQueryWord, String youWantFind)
{
    StringBuffer strBuffer = new StringBuffer();
    strBuffer.append("<div class=\"notFoundHint\" style=\"overflow:hidden;font-size:14px;\">");
    strBuffer.append("<div style=\"float:left;margin:16px 0 0 28px;\">");
    strBuffer.append("<img src=\"../images/not_found_hint.gif\" />");
    strBuffer.append("</div>");
    strBuffer.append("<div style=\"float:left;padding:16px 28px 4px 8px\">");
    if("1".equals(fuzzy)){
        strBuffer.append("<p style=\"width:638px;text-align:left;margin:0 0 12px 0;font-size:14px;\">提示：您在使用模糊搜索方式查询与“<label>" + fuzzyQueryWord + "</label>”相关的图书。</p>");
    }
    else {
        strBuffer.append("<p style=\"width:638px;text-align:left;margin:0 0 12px 0;font-size:14px;\">提示：系统使用模糊搜索方式查询与“<label>" + fuzzyQueryWord + "</label>”相关的图书。</p>");
    }
    strBuffer.append("<p style=\"text-align:left;margin:0 0 12px 0;font-size:14px;\">您可以试着搜索：" + youWantFind + ",也可以尝试减少搜索的字词来获得更多的结果。</p>");
    strBuffer.append("</div>");
    strBuffer.append("<style type=\"text/css\">");
    strBuffer.append(".notFoundHint p a{text-decoration:underline;color:blue;font-size:14px;}");
    strBuffer.append("</style>");
    strBuffer.append("</div>");
    return strBuffer.toString();
}


%>
