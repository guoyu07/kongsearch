/**
 * Created by Administrator on 2014/6/5.
 */
(function(){
    if(!KFZ) KFZ = {};
    if(!KFZ.ui) KFZ.ui = {};
    // 限定图片最大尺寸等比缩小
    // @author lizixu <zixulee@163.com>
    // @param imgs string|object 图片选择器或图片jQ对象
    // @param maxWidth int 最大宽度
    // @param maxHeight int 最大高度
    // @param isSetPosition boolean 是否设置居中
    KFZ.ui.resizeImage = function(imgs, maxWidth, maxHeight, isSetPosition, callback){
        var $imgs, that = arguments.callee;
        if(typeof imgs == 'object'){
            $imgs = imgs;
        }else{
            $imgs = $(imgs);
        }
        if(!$imgs.length) return;
        that.count = that.count || 0;
        var handler = function(start, stamp){
            var $img = $j('[imgload="img_' + stamp + '"]'),
                w = $img.width(),
                h = $img.height();
            if(!w || !h){
                $img.css({width: 'auto', height: 'auto'});
                $img = null;
                if(+new Date() - start < 15000){
                    var ac = arguments.callee;
                    setTimeout(function(){
                        ac(start, stamp);
                    }, 300);
                }
                return;
            }
            var rateW = w/maxWidth,
                rateH = h/maxHeight;
            if(rateW > 1 || rateH > 1){
                if(rateW/rateH > 1){
                    $img.width(maxWidth).height(h/rateW);
                }else{
                    $img.width(w/rateH).height(maxHeight);
                }
            }
            if(isSetPosition){
                $img.css({'display': 'block', 'position': 'relative', 'left': (maxWidth-$img.width())/2 + 'px', 'top' : (maxHeight-$img.height())/2 + 'px'});
            }
            $img.removeAttr('imgload').attr('imgresized', '1');
            callback && callback($img);
            $img = null;
        };
        $j.each($imgs, function(){
            if($j(this).attr('imgresized') === '1') return;
            var src = $j(this).attr('src');
            if(!src) return;
            var img = new Image(),
                start = +new Date(),
                stamp = start + '_' + (that.count ++);
            $j(this).attr('imgload', 'img_' + stamp);
            img.src = src;
            if(img.complete){
                handler(start, stamp);
                return;
            }
            img.onload = function(){
                handler(start, stamp);
            };
        });
    };
    
    $j(document).ready(function(){
    	//显示图片
        $j('body').delegate('#List .small_pic',{
        	mouseover:function(){
        		var $this = $j(this);
                var $bigImgBox = $this.siblings(".big_pic");
                if($bigImgBox.length){
                    $bigImgBox.show();
                    var $bigImg = $bigImgBox.find('img');
                    KFZ.ui.resizeImage($bigImg, 290, 290, 1);
                }
        	},
        	mouseleave:function(){
        		$j(this).siblings(".big_pic").hide();
        	}
        });
        
        //显示详情
        $j('body').delegate('#showItemDescDiv',{
        	mouseover:function(){
        		var $this = $j(this);
                var $bigImgBox = $this.children("#async_show_item_desc_div");
                if($bigImgBox.length){
                	//是否进行过异步加载
                	var asyncload = $bigImgBox.attr("asyncload");
                	if ("true" == asyncload) {//有进行过加载
                		if ($bigImgBox.attr("canShow")){
                			$bigImgBox.show();
                		}
                	} else {//未进行过加载
                		$bigImgBox.attr("asyncload","true");
                		var textarea = $bigImgBox.children("textarea");
                    	var useridVar = $bigImgBox.attr("userid");
                    	var itemidVar = $bigImgBox.attr("itemid");
                    	var saleStatusVar = $bigImgBox.attr("saleStatus");
                    	var location = window.location;
                    	$j.ajax({
                    		url:location.protocol+"//"+location.host+"/admin/new_sphinx/cls_ajax_async_iteminfo.jsp",
                    		async:false,
                    		type:"post",
                    		data:{userid:useridVar,itemid:itemidVar,saleStatus:saleStatusVar},
                    		success:function(result){
                    			result = result.replace(/\s/g,'');//去除全部空格
                    			if ("" != result){
                    				textarea.val(result);
                    				$bigImgBox.attr("canShow","true");
                                	$bigImgBox.show();
                    			}
                    		}
                    	});
                	}
                	
                }
        	},
        	mouseleave:function(){
        		var $bigImgBox =  $j(this).children("#async_show_item_desc_div");
        		$bigImgBox.hide();
        	}
        });
    });
})();
