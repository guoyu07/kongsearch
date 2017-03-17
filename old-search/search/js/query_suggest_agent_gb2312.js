/**
 * ��ѯ�������
 * @desc ���ڲ�ѯʱ���û�������轨�飬��ʾ��ش����б?�û�ѡ��
 * @param string inputName
 * @author xieshengtao
 * @email xie.s.t@163.com
 */
function QuerySuggestAgent(inputName)
{
    var serverUrl = "http://search.kongfz.com/sug/suggest_server_gb2312.jsp";
    var self = this;
    var inputId = inputName;
    var suggestFontSize = 12;
    var leftOffset = 0;// ˮƽƫ��
    var topOffset = -1;// ��ֱƫ��
    var suggestInput = null;//�����
    var suggestBox = null;//������б��
    var suggestItems = [];//������б�Ԫ��
    var suggestPos = -1;
    var suggestData = [];
    var isMouseSelected = false;
    var isArrowKeySelected = false;
    var iframe = null;// ���ִ��ڶ���
    var timer = null;
    var scriptElement = null; // Script��ǩԪ��
    var currentQuery = "";
    var queryCache = {};//��ѯ����
    var cacheExpire = 300;// �������ʱ�䣬��λΪ��
    
    /**
     * ����������������
     */
    this.start = function()
    {
        initSuggest();
    };
    
    /**
     * ���÷��������
     * @param url
     */
    this.setServerUrl = function(url)
    {
        if (null != url && "" != url) {
            serverUrl = url;
        }
    };
    
    /**
     * ��������������λ��ƫ��
     */
    this.setPosOffset = function(left)
    {
        leftOffset = left;
        //topOffset  = top;
    };
    
    /**
     * �������������������С
     */
    this.setFontSize = function(size)
    {
        suggestFontSize = size;
    };
    
    /**
     * �������ִ���
     */
    function createBoardWindow()
    {
        iframe = document.createElement('IFRAME');
        iframe.frameBorder=0;
        iframe.style.cssText="display:none;position:absolute;left:0px;top:0px;";
        document.body.appendChild(iframe);
    }
    
    /**
     * ��ʼ�������
     */
    function initSuggest() 
    {
        // ȡ���������󣬲���������
        suggestInput = $search(inputId);
        if(null == suggestInput){ return; }
        suggestInput.setAttribute("autocomplete","off");
        suggestInput.setAttribute("maxLength","50");
        
        // ���������б��Ԫ�أ���׷�ӵ�ҳ����
        suggestBox = document.createElement("DIV");
        suggestBox.style.cssText = "display:none;position:absolute;border:1px solid #817F82;background-color:#FFFFFF";
        document.body.appendChild(suggestBox); 
        
        // ��IE��ʹ��iframe��סselect�?Ԫ��
        if(document.all){ createBoardWindow(); }
        
        // ����Script��ǩ������ӵ�ҳ����
        if(document.all){
            initCommunicationEquipment(suggestCallback);
        }
        
        // ����ҳ�洰�ڱ仯�¼����Զ����������б��
        addEventListener(window, "resize", resizeWindow);
        
        // ����ҳ�����¼����������ʧȥ������¼����������������б��
        addEventListener(document.documentElement, "click", hideSuggestBox);
        addEventListener(suggestInput, "blur", hideSuggestBox);
        
        // ���������ļ����¼������ڲ����������ݣ��������ʾ��ǰѡ����б���Ŀ
        addEventListener(suggestInput, "keydown", suggestInputKeydown);
        addEventListener(suggestInput, "keyup", suggestInputKeyup);
        
        // ÿ 5 �������һ�β�ѯ����
        clearQueryCache();
    }
    
    /**
     * ��ղ�ѯ����
     * Ĭ��Ϊÿ��5���Ӿ���ղ�ѯ���档
     */
    function clearQueryCache()
    {
        queryCache = {};
        setTimeout(clearQueryCache, cacheExpire * 1000);
    }
    
    /**
     * ��ʼ������������������ݵ�ͨ����
     * ����JavaScript�ű�ע��ķ�ʽʵ���ύ�?���
     */
    function initCommunicationEquipment(callback)
    {
        scriptElement = document.createElement( "script" ); 
        scriptElement.language = "javascript"; 
        scriptElement.type     = "text/javascript"; 
        scriptElement.defer    = true; 
        //scriptElement.src      = serverUrl;//'&rand='+Math.random()
        if (document.all) {
            scriptElement.onreadystatechange = callback;
            //oScript.onload = callback;
        } else {
            scriptElement.onload = callback;
        }
        var oHead = document.getElementsByTagName('HEAD').item(0); 
        oHead.appendChild(scriptElement);
    }
    
    /**
     * ʹ�����·����ѡ��������б���е���Ŀ
     */
    function selectSuggestItem(e)
    {
        e = e || window.event;
        var code = e.keyCode;
        if (38 != code && 40 != code) {
            isArrowKeySelected = false;
            return; 
        }
        isArrowKeySelected = true;
        
        if(null == suggestData || 0 == suggestData.length){ return; }
        if(null == suggestItems || 0 == suggestItems.length){ return; }
        if(null == suggestBox || null == suggestInput){ return; }
        // ȡ����ǰ��ѡ��
        if(suggestPos > -1){
            darkenSuggestItem(suggestItems[suggestPos]);
        }
        // �ƶ���ǰ��
        if(38 == code){ suggestPos--; }
        if(40 == code){ suggestPos++; }
        if(suggestPos < 0 ){ suggestPos = suggestData.length -1; }
        if(suggestPos > suggestData.length - 1 ){ suggestPos = 0; }
        // ������ǰѡ���
        brightenSuggestItem(suggestItems[suggestPos]);
        if("none" == suggestBox.style.display){
            suggestBox.style.display = "block";
        }
        // ��ѡ�����ֵ���������
        suggestInput.value = suggestData[suggestPos];
    }
    
    function suggestInputKeydown(e)
    {
        selectSuggestItem(e);
    }

    function suggestInputKeyup(e)
    {
        if(null == suggestInput){ return; }
        var query = trim(suggestInput.value);
        query = query.substr(0, 25);
        if("" != query){
            if(!isArrowKeySelected){
                requestQuerySuggest(query);
            } else {
                if(0 == suggestData.length){
                    requestQuerySuggest(query);
                }
            }
        } else {
            hideSuggestBox();
        }
    }
    
    /**
     * �����ѯ�ؼ��
     */
    function requestQuerySuggest(query)
    {
        // 1�����ڻ����в��ң�����������ȡ����ʾ�����������˷�������
        if (inCache(query)) {
            hideSuggestBox();
            suggestData = queryCache[query];
            loadSuggestBox(suggestData);
            return;
        }
        
        // 2�������������GET�����ڻص�������ȡ�ý����ʾ��������б�
        currentQuery = query;
        var content = "query=" + query;
        var url = serverUrl + "?" + content + "&r=" + Math.random();
        if (document.all && (null != scriptElement)) {
            scriptElement.src = url;
            window.status= "";
        } else {
            crossDomainRequest(url, suggestCallback);
        }
        // ���ͽ���ȴ�������Ӧ���󲢷��ؽ��
    }
    
    /**
     * �Ƿ��ڲ�ѯ������
     */
    function inCache(query)
    {
        return ("undefined" != typeof(queryCache[query]));
    }
    
    /**
     * �ص�������ʾ������б�
     */
    function suggestCallback()
    {
        // ���� sugWords �Ǵӷ����ע��ġ������Ҫ���Դӷ����ע�벻ͬ��JS������
        if("undefined" == typeof(sugWords)){sugWords = null;}
        // IE����Ҫ�Ӵ��жϣ���ֹ�ص������ε��á�FF�޴����⡣
        if(null == sugWords || !(sugWords instanceof Array)){return;}

        hideSuggestBox();
        
        suggestData = sugWords;
        queryCache[currentQuery] = sugWords;
        
        if ("" != trim(suggestInput.value)) {
            loadSuggestBox();
        }

        currentQuery = "";
        // ʹ���� sugWords ��������Ҫ����Ϊnull��
        sugWords = null;
    }
    
    /**
     * ��������(GET)
     * @param url
     * @param callback
     */
    function crossDomainRequest(url, callback)
    {
        var oHead   = document.getElementsByTagName('HEAD').item(0); 
        var oScript = document.createElement( "script" ); 
        oScript.language = "javascript"; 
        oScript.type     = "text/javascript"; 
        oScript.defer    = true; 
        oScript.src      = url;//'&rand='+Math.random()
        if (document.all) {
            oScript.onreadystatechange = callback;
            //oScript.onload = callback;
        } else {
            oScript.onload = callback;
        }
        oHead.appendChild(oScript);
    }

    /**
     * �����ҳ��ʱ�Զ��������������λ��
     */
    function resizeWindow()
    {
        if(null == timer){
            timer = setTimeout(function(){ fixedSuggestBox(); timer = null; }, 200);
        }
    }

    /**
     * �̶������б��λ�úͿ��
     */
    function fixedSuggestBox()
    {
        if(null == suggestInput || null == suggestBox){ return; }
        var pos = findPos(suggestInput);
        var x = (document.all ? (pos[0] + leftOffset) : pos[0]);
        var y = (pos[1] + suggestInput.offsetHeight + topOffset);
        var w = (suggestInput.offsetWidth - 2);
        suggestBox.style.left = x + "px";
        suggestBox.style.top = y + "px";
        suggestBox.style.width = w  + "px";
        if(document.all){
            iframe.style.left = x + 'px';
            iframe.style.top = y + 'px';
            iframe.style.width = suggestInput.offsetWidth  + 'px';
        }
    }
    
    /**
     * ���������б��
     */
    function hideSuggestBox()
    {
        if(isMouseSelected){ return; }
        isArrowKeySelected = false;
        suggestPos = -1;
        suggestData = [];
        if(null != suggestBox){
            suggestBox.innerHTML = "";
            suggestBox.style.display = "none";
            if(document.all){
                iframe.style.display = 'none';
            }
        }
    }

    /**
     * ���������б��
     */
    function loadSuggestBox()
    {
        if (!("undefined" != typeof(suggestData) && (suggestData instanceof Array) && suggestData.length > 0)) {
            return;
        }
        suggestPos = -1;
        createSuggestItems();
        fixedSuggestBox();
        if(null != suggestBox){
            suggestBox.style.display = "block";
            suggestBox.style.zIndex = 65535;
            if(document.all){
                iframe.style.height = suggestBox.offsetHeight + "px";
                iframe.style.display = 'block';
            }
        }
    }

    /**
     * װ����������б�
     */
    function createSuggestItems()
    {
        if (null == suggestBox || null == suggestInput) { return; }
        if (null == suggestData || "undefined" == typeof(suggestData) || 0 == suggestData.length) { return; }
        // �����б��ĸ���ĿԪ��
        var width = suggestInput.offsetWidth;
        var htmlStr = "";
        var cssText="padding:2px 4px 2px 4px;line-height:normal;cursor:default;width:"+width+"px;font-size:"+suggestFontSize+"px";
        htmlStr = "<table onselectstart=\"return false\" cellpadding=\"2\" cellspacing=\"0\"><tbody>";
        for(var i=0; i < suggestData.length; i++){
            htmlStr += "<tr><td align=\"left\" valign=\"middle\" style=\"" + cssText + "\">" + suggestData[i] + "</td></tr>";
        }
        htmlStr += "</tbody></table>";
        suggestBox.innerHTML = htmlStr;
        // �����б�����Ŀ������¼�
        suggestItems = suggestBox.getElementsByTagName("TR");
        if(null == suggestItems || 0 == suggestItems.length){ return; }
        for(var i=0; i < suggestItems.length; i++){
            setSuggestMouseEvent(suggestItems[i], suggestData[i], i);
        }
    }
    
    /**
     * ������������Ŀ������¼�
     */
    function setSuggestMouseEvent(obj, value, index)
    {
        if(null == obj){ return; }

        obj.onmouseover = function(){
            if(suggestPos > -1){
                darkenSuggestItem(suggestItems[suggestPos]);
            }
            suggestPos = index;
            brightenSuggestItem(this);
        };
        
        obj.onmouseout = function(){
            darkenSuggestItem(this);
        };
        
        obj.onmousedown = function(){ isMouseSelected = true; };
        
        obj.onmouseup = function(){ isMouseSelected = false; };
        
        obj.onclick = function(){
            suggestInput.value = value;
            submitQuery(suggestInput);
        };
    }
    
    /**
     * �ύ��ѯ
     */
    function submitQuery(input)
    {
        var objForm = getParentFormElement(input);
        if (null != objForm && "submit" in objForm) {
            objForm.query.value = encodeURI(input.value);
            objForm.submit();
        }
    }

    /**
     * ����
     */
    function brightenSuggestItem(obj)
    {
        if (null == obj) { return; }
        obj.style.backgroundColor="#3366CC"; 
        obj.style.color="#FFFFFF";
    }

    /**
     * �䰵
     */
    function darkenSuggestItem(obj)
    {
        if (null == obj) { return; }
        obj.style.backgroundColor="#FFFFFF"; 
        obj.style.color="#000000";
    }
    
    /**
     * ȡ�ø�����FORM�?����
     * @param obj
     */
    function getParentFormElement(obj)
    {
        var tagName = "";
        var element = obj;
        while(undefined != element){
            tagName = element.tagName;
            if("string" == typeof(tagName) || (tagName instanceof String)){
                if("FORM" == tagName.toUpperCase()){
                    return element;
                }
            }
            element = element.parentNode;
        }	
        return null;
    }
    
    /**
     * �ж�һ��Ԫ���Ƿ������һ��������
     */
    function inArray(array, element)
    {
        if ("undefined" != typeof(array) && (array instanceof Array)) {
            for(var i in array){
                if(element == array[i]){
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * ����ַ��ǰ��հ��ַ�
     */
    function trim(str)
    {
        if(null == str && "string" != typeof(str)){ return str; }
        var regExp = /^\s*(.*?)\s+$/;
        return str.replace(regExp,"$1");
    }
    
    function $search(id){return document.getElementById(id);}
    function findPos(obj)
    {
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
     * ����¼�����
     */
    function addEventListener(obj, eventName, callback)
    {
        if (document.all) {
            obj.attachEvent("on" + eventName, callback);
        } else {
            obj.addEventListener(eventName, callback, false); 
        }
    }
    
    /**
     * ȡ���¼�����
     */
    function removeEventListener(obj, eventName, callback)
    {
        if (document.all) {
            obj.detachEvent("on" + eventName, callback);
        } else {
            obj.removeEventListener(eventName, callback, false); 
        }
    }

} // end class
