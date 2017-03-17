<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<!-- 使用方法：
	1.在页面中使用 include 进行引入dialogimports.jsp，不能使用jsp模式进行引入，会与
	原始界面中的监听事件冲突。
	2.在界面中定义按钮或超链接，按以下模式定义
	finally：实现以上两步后，点击指定的按钮或超链接，则可实现自动装置功能.
 -->
<%@ include file="/admin/keywords/artDialogImports.jsp"%>
<!-- 控件名称必须是search_choice_keywords_dom -->
<!-- closeFn：{dialog模式为关闭dialog后执行，非dialog模式，则是在选择了分类后执行函数的名称} -->
<!-- show：{dialog模式该值无效，非dialog模式则读取name=当前值的控件，进行显示后续内容} -->
<!-- defaultLevel：{dialog模式该值无效，非dialog模式该值为默认选中的级别值，该值存在则不显示级别选项卡} -->

<a href="javascript:void(0);" name="search_choice_keywords_dom"
	closeFn="quickQuery" show="search_choice_keywords_show_infomation_dom"
	defaultLevel="">选择可疑关键字</a>
<div id="search_choice_keywords_show_infomation_dom"></div>
<script type="text/javascript">
	function quickQuery(keywords) {
		alert(keywords);
	}
</script>