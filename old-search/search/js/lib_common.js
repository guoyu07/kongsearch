// JavaScript Document
function $search(id){return document.getElementById(id);}
function trim(str){
	if(typeof(str) == "string"){
		str = str.replace(/(^\s*)|(\s*$)/g, ""); 
	}
	return str;
}
/* 用于查询框的提示信息 */
var hintMessages = [
"请输入书名或作者进行查询！",
"请输入拍卖主题、拍主昵称、作者查询",
"请输入帖子主题、内容查询"
];

function initSearchHintMessage(name)
{
	var hintColor = "#D8D8D8";
	var items = document.getElementsByName(name);
	for(var i=0; i < hintMessages.length; i++){
		initQueryBoxHint(items[i], hintMessages[i], hintColor);
	}
}

function initQueryBoxHint(curItem, hint, color)
{
	if(curItem.value == ""){
		curItem.style.color = color;
		curItem.value = hint;
	}
	
	curItem.onfocus = function(){
		if(this.value == hint){
			this.style.color = "";
			this.value = "";
		}
	}
	
	curItem.onblur = function(){
		if(this.value == "" || this.value == hint){
			changeQueryValue("");
			this.style.color = color;
			this.value = hint;
		}else{
			this.style.color = "";
		}
	}
}
	
function clearSearchHint(name)
{
	var items = document.getElementsByName(name);
	for(var i=0; i < items.length; i++){
		if(items[i].value == hintMessages[i]){
			items[i].value = "";
		}
	}
}

function resetSearchHint(name, value)
{
	var items = document.getElementsByName(name);
	for(var i=0; i < items.length; i++){
		if(items[i].className != "notset" && items[i].type != "hidden"){
			items[i].value = value;
			items[i].style.color = "";
		}
	}
	initSearchHintMessage(name);
}


//设置排序图标
function initSortPanel(type)
{
	$search('priceSort').className="priceGray";
	$search('priceSort').href="javascript:setSort(1)";
	$search('priceSort').title="点击后按价格从低到高排序";
	
	$search('pubDateSort').className="pubDateGray";
	$search('pubDateSort').href="javascript:setSort(4)";
	$search('pubDateSort').title="点击后按出版日期从近到远排序";
	
	$search('addTimeSort').className="addTimeGray";
	$search('addTimeSort').href="javascript:setSort(6)";
	$search('addTimeSort').title="点击后按上书时间从近到远排序";
	
	if(type==1){
		$search('priceSort').className="priceAsc";
		$search('priceSort').href="javascript:setSort(2)";
		$search('priceSort').title="点击后按价格从高到低排序";
	}
	if(type==2){
		$search('priceSort').className="priceDesc";
		$search('priceSort').href="javascript:setSort(1)";
	}
	if(type==3){
		$search('pubDateSort').className="pubDateAsc";
		$search('pubDateSort').href="javascript:setSort(4)";
	}
	if(type==4){
		$search('pubDateSort').className="pubDateDesc";
		$search('pubDateSort').href="javascript:setSort(3)";
		$search('pubDateSort').title="点击后按出版日期从远到近排序";
	}
	if(type==5){
		$search('addTimeSort').className="addTimeAsc";
		$search('addTimeSort').href="javascript:setSort(6)";
	}
	if(type==6){
		$search('addTimeSort').className="addTimeDesc";
		$search('addTimeSort').href="javascript:setSort(5)";
		$search('addTimeSort').title="点击后按上书时间从远到近排序";
	}
}

// 拍卖搜索页
var auctionLinks = {
    "history":"auction.jsp", 
    "current":"http://www.kongfz.cn/search_result.php"
    };
	
// 左侧随屏滚动—主要解决ie下不支持fixed
/**
 * objId  移动层的id
 * iTop   ie6下移动层保持离顶部的距离
 */
function rollElement(objId,iTop) 
{
	//var sUserAgent = window.navigator.userAgent;
	//if(sUserAgent.search('MSIE 6') == -1) return;
	//else {
		var obj = document.getElementById(objId);
		var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
		if(!scrollTop && scrollTop != 0)return;
		else {
			window.onscroll = function() {
				var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
				obj.style.top = scrollTop + iTop + 'px';
			}
		}
	//}
}

