var mouseX = 0;
var mouseY = 0;
var shopCartX = 400;
var shopCartY = 200;
var g_shopSite = "http://shop.kongfz.com/";

function addItemForCart(itemId,shopId,bizType,obj)
{
    shopCartX = getElementLeft(obj);
    shopCartY = getElementTop(obj);
    
    shopCartX = shopCartX-395;
    shopCartY = shopCartY-80;
    createBoardWindow(bizType,shopId,itemId);
}

function getElementLeft(element)
{
    var actualLeft = element.offsetLeft;
    var current = element.offsetParent;

    while (current !== null){
      actualLeft += current.offsetLeft;
      current = current.offsetParent;
    }

    return actualLeft;
}

function getElementTop(element)
{
    var actualTop = element.offsetTop;
    var current = element.offsetParent;

    while (current !== null)
    {
      actualTop += current.offsetTop;
      current = current.offsetParent;
    }

    return actualTop;
  }

/**
 * 创建遮罩窗口
 */
function createBoardWindow(bizType,shopId,itemId)
{
    if((shoppingCartDivObj = document.getElementById("shoppingCartDiv")))
    {
        document.body.removeChild(shoppingCartDivObj);
    }

    var shoppingCartCloseButtonDiv = document.createElement('div');
    shoppingCartCloseButtonDiv.style.cssText='float:left; margin-left:10px; width:50px;';

    var shoppingCartFrameDiv = document.createElement('div');
    shoppingCartFrameDiv.style.cssText='float:left; margin-left:5px; width:390px; height:90px;';
    
    var frm = document.createElement('IFRAME');
    frm.name="shoppingCartIframe";
    frm.id="shoppingCartIframe";
    frm.scrolling="no";
    frm.src=g_shopSite+"shopping_cart/shopping_cart.php?act=newAddBook&businessType="+bizType+"&itemId="+itemId+"&shopId="+shopId;
    frm.frameBorder=0;
    frm.style.cssText="width:370px;height:100px;background-color:#F0FFE5;";
    shoppingCartFrameDiv.appendChild(frm);

    var shoppingCartCloseButtonSpan = document.createElement('span');
    shoppingCartCloseButtonSpan.style.cssText='cursor:pointer;';
    shoppingCartCloseButtonSpan.innerHTML="<img src='"+g_shopSite+"image/cart_close.gif' onclick='closeShoppingCartDiv();'>";
    shoppingCartCloseButtonDiv.appendChild(shoppingCartCloseButtonSpan);

    var shoppingCartTopDiv = document.createElement('div');
    shoppingCartTopDiv.style.cssText='width:460px; margin:1px;';
    shoppingCartTopDiv.appendChild(shoppingCartFrameDiv);
    shoppingCartTopDiv.appendChild(shoppingCartCloseButtonDiv);

    var shoppingCartButtonDiv = document.createElement('div');
    shoppingCartButtonDiv.style.cssText='float:right; margin-right:40px;margin-top:15px;';
    shoppingCartButtonDiv.innerHTML='<img style="margin-right:10px;cursor:pointer;" onclick="location.href=&quot;'+g_shopSite+'shopping_cart/shopping_cart.php?act=shoppingCartList&quot;" src="'+g_shopSite+'image/cart_checkout.jpg"><img style="cursor:pointer;" onclick="closeShoppingCartDiv();" src="'+g_shopSite+'image/cart_shopping.jpg">';

    var shoppingCartDiv = document.createElement('div');
    shoppingCartDiv.name="shoppingCartDiv";
    shoppingCartDiv.id="shoppingCartDiv";
    shoppingCartDiv.style.cssText="display:block;position:absolute;left:"+shopCartX+"px;top:"+shopCartY+"px;width: 460px; height: 140px; background-color: rgb(240, 255, 229); text-align: center; border: 1px solid rgb(77, 191, 0);";

    shoppingCartDiv.appendChild(shoppingCartTopDiv);
    shoppingCartDiv.appendChild(shoppingCartButtonDiv);
    document.body.appendChild(shoppingCartDiv);
}

function mousePosition(ev)
{
    if(ev.pageX || ev.pageY){
        return {x:ev.pageX, y:ev.pageY};
    }
    return {
        x:ev.clientX + document.body.scrollLeft - document.body.clientLeft,
        y:ev.clientY + document.body.scrollTop  - document.body.clientTop
    };
}

function closeShoppingCartDiv()
{
    var shoppingCartDivObj = document.getElementById("shoppingCartDiv");
    document.body.removeChild(shoppingCartDivObj);
}

function addToShoppingCart(itemId,shopId,carDomain)
{
    var url = null;
    var random=Math.random();
    try
    {
        if(carDomain == null)
        {
            carDomain = "http://shop.kongfz.com/";
        }
    
        itemId = parseInt(itemId);
        shopId = parseInt(shopId);

        if(shopId > 0 && itemId > 0)
        {
            url = carDomain + "shopping_cart/shopping_cart.php?act=addBook&itemId="+itemId+"&shopId="+shopId+"&businessType=bookstall&random="+random;
        }
        else
        {
            url = carDomain + "shopping_cart/shopping_cart.php?act=shoppingCartList"+"&random="+random;
        }
        var popup=window.open(url);
        popup.focus();
    }
    catch (e)
    {
        location.href=g_shopSite + "shopping_cart/shopping_cart.php?act=shoppingCartList"+"&random="+random;;
    }
}