/**
 * На основе:
 * http://www.flepstudio.org/forum/tutorials/419-bitmap-smoothing-how-reduce-image-distortion.html
 * Имееет set/get свойства width,height,source
 * Отправляет события Event.COMPLETE, ResizeEvent.RESIZE
 */
package com.somewater.display
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.system.LoaderContext;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	[Event(name="resize")]
	[Event(name="completeRes")]
	
	
	
	public class SmoothLoader extends UIComponent
	{
		public const DEFAULT_SIZE:Number = 30;
		public static const COMPLETE:String = "completeRes";
		private var loader:Loader;
		private var _source:String = "";
		private var _width:Number = 0;
		private var _height:Number = 0;
		public var saveRatio:Boolean = false;
		public var sizeForContent:Boolean = false;
		private var tryCounter:int = 0;
		
		public function set source(path:String):void{
			if ((path == null)||(path == "")){
				if (numChildren>0) removeChildAt(0);
				return;
			}
			_source = path;
			loadImage(path);
		
		}
		public function get source():String{
			return _source;
		}
		
		public function SmoothLoader(){
			
		}
				
		private function loadImage(path:String):void{		
			var request:URLRequest = new URLRequest(path);
			loader=new Loader();
			var lc:LoaderContext=new LoaderContext(true);
			lc.checkPolicyFile=true;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,completed);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function (e:IOErrorEvent):void{/*Mybets.t("Не удалось загрузить изображение по адресу\n"+path,true)*/});
			loader.load(request,lc);
		}
		private function dispatchResizeEvent():void{
			var res:ResizeEvent = new ResizeEvent(ResizeEvent.RESIZE);
			dispatchEvent(res);
		}
		private function dispatchCompleteEvent():void{
			var compl:Event = new Event(Event.COMPLETE);
			dispatchEvent(compl);
		}
		private function completed(evt:Event):void{
			if (loader.content == null){
				if(tryCounter<10) loadImage(source);
				tryCounter += 1;
				return;
			}
			tryCounter = 0;
			if (numChildren>0) removeChildAt(0);
			addChild(loader);
			var image:Bitmap=loader.content as Bitmap;
			image.smoothing=true;
			dispatchCompleteEvent();
			if (sizeForContent){
				_width = 0;
				_height = 0;
			}
			// включение saveRatio если один из разеров устанавливается по maxSize
			if (((_width == 0)&&(image.width>maxWidth))||((_height == 0)&&(image.height>maxHeight))){
				saveRatio = true;
			}
			//		dispatch Resize Event
			var res:ResizeEvent = new ResizeEvent(COMPLETE);
			res.oldWidth = image.width; res.oldHeight = image.height;	
			//		/dispatch Resize Event
			width  = (_width>0)?(_width):((image.width>0)?Math.min(image.width,maxWidth):DEFAULT_SIZE);
			height = (_height>0)?(_height):((image.height>0)?Math.min(image.height,maxHeight):DEFAULT_SIZE);
			dispatchEvent(res);
		}
		override public function set width(value:Number):void{
			if (loader != null) if (loader.content != null){
				if (saveRatio){
					setSize(value,height>0 ? height:maxHeight);
				}else{
					loader.width = value;
				}
			}
			_width = value;			
			super.width = value;
			dispatchResizeEvent();
		}
		override public function get width():Number{
			return _width;
		}
		private function moveWnenResize(prop:Number,coef:Number):Number{
			var moving:Number = (prop-prop*coef)/2;
			if (moving>0){
				return moving;
			}
			return 0;
		}
		private function setSize(w:Number, h:Number):void{
			var ratioX:Number = w/loader.width;
			var ratioY:Number = h/loader.height;
			//Mybets.t(loader.width+' '+loader.height);
			var ratio:Number= Math.min(ratioX, ratioY);
			loader.width *= ratio;
			loader.height *= ratio;
			loader.x = 0+(w-loader.width)/2;
			loader.y = 0+(h-loader.height)/2;
		}
		override public function set height(value:Number):void{			
			if (loader != null) if (loader.content != null){
				if (saveRatio){
					setSize(width>0?width:maxWidth,value);
				}else{
					loader.height = value;
				}
			}
			_height = value;
			super.height = value;
			dispatchResizeEvent();
		}
		override public function get height():Number{
			return _height
		}
	}
}