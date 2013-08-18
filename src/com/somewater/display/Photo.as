package com.somewater.display
{

	import com.greensock.TweenMax;
	import com.greensock.easing.Sine;
	import com.somewater.control.IClear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	
	[Event(name="resize", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="render", type="flash.events.Event")]
	
	/**
	 * scaleType:int - метод выравнивания
	 * -1 - без ресайза, как есть
	 * 0 - растягивание по макс. высоте и ширине
	 * 1 - растягивание по высоте и ширине, если растягивание по высоте, то ширина равна высоте (уменьшение белых краёв)
	 * 2 - аналогично п.1, если картинка растягивается по ширине, то как лимит используется высота (или широкая. или квадратик)
	 * 3 - получить заданое изображение из любой картинки, оставив только верхний кусок (если требуется)
	 * 4 - аналогично type=3, однако ограничение только по максимальной высоте
	 * 5 - заданная ширина (сужает или растягивает по ней) и высоты сколько есть, но не более максимальной
	 *  
	 * 0 =======	 =======
	 *   |     |	 |  r  |
	 *   |rrrrr|	 |  r  |
	 *   |     |	 |  r  |
	 *   =======	 =======
	 * 
	 * 1 ===========	============	 =======
	 *   |rrrrrrrrr|	|          |	 |  r  |
	 *   |rrrrrrrrr|	|rrrrrrrrrr|	 |  r  |
	 *   |rrrrrrrrr|	|          |	 |  r  |
	 *   ===========	============	 =======
	 * 
	 * 2 ===========	=======		 =======
	 *   |rrrrrrrrr|	|     |		 |  r  |
	 *   |rrrrrrrrr|	|rrrrr|		 |  r  |
	 *   |rrrrrrrrr|	|     |		 |  r  |
	 *   ===========	=======		 =======
	 * 
	 * 3 =======	 ==========
	 *   |  _  |	 | /^^^^^^|\
	 *   |( ..}|	 |(  @   @| )
	 *   | | | |	 | \   L  |/
	 *   =======	 ========== 
	 *   /{   }\	    | -0- |
	 * 	/  | |  \	 __/       \_
	 * 
	 * 
	 * 4 =======	===============    ==============
	 *   |  _  |	|  /^^^^^^^\  |    |/ ^\_( ^^^^ |
	 *   |( ..}|	| (  @   @  ) |    |\*_/ (_____ |
	 *   | | | |	|  \   L   /  |    ==============
	 *   =======	===============    
	 *   /{   }\        | -0- |
	 * 	/  | |  \    __/       \_
	 * 
	 * 
	 * 
	 * 5 =======	   =========
	 *   |  _  |	   /|^^^^^^|\
	 *   |( ..}|	  ( |@   @ | )
	 *   | | | |	   \|  L   |/
	 *   =======	   ========= 
	 *   /{   }\	    | -0-  |
	 * 	/  | |  \	 __/        \_
	 * 
	 * 
	 * 6 замостить фоткой отведенное пространство
	 */
	public class Photo extends HintedSprite implements IClear
	{
		public static const SIZE_WIDTH:uint = 1;// растянуть по ширине, "замостив" все пространство
		public static const SIZE_HEIGHT:uint = 2;// растянуть по высоте, "замостив" все пространство
		public static const SIZE_MAX:uint = 4;
		public static const SIZE_MIN:uint = 8;
		
		public static const ORIENT_HOR_LEFT:uint = 16;// выровнять по левому краю
		public static const ORIENT_HOR_CENTER:uint = 32;
		public static const ORIENT_HOR_RIGHT:uint = 64;
		
		
		public static const ORIENT_VER_TOP:uint = 128;// выровнять по левому краю
		public static const ORIENT_VER_MIDDLE:uint = 256;
		public static const ORIENT_VER_BOTTOM:uint = 512;
		public static const ORIENTED_CENTER:uint = ORIENT_HOR_CENTER | ORIENT_VER_MIDDLE;
		
		private static var context:LoaderContext = new LoaderContext(true);
		
		public var FILL_COLOR:int = -1;//0xF07021;
		public var ROUNDS:int = 0;
		
		
		private var self:Object;
		
		public var maxWidth:uint;
		public var maxHeight:uint;

		public var maxScale:Number = 1000;
		public var minScale:Number = 0.001;
		
		public var scaleType:uint = ORIENTED_CENTER;
		
		public var centerX:int;
		public var centerY:int;
		
		public var pictureLoader:Loader;
		public var image:DisplayObject;
		public var imageMask:Shape;
		
		private var _onCompleteParams:Object;
		
		// показывать ли анимацию при появлении картинки (возрастание alpha от 0 до 1)
		public var animatedShowing:Boolean = true;
		
		public function Photo(url:* = null,scaleType:int = 0, maxWidth:uint = 150, maxHeight:uint = 80, centerX:int = int.MIN_VALUE, centerY:int = int.MIN_VALUE)
		{
			self = this;
			
			this.scaleType = scaleType;
			this.maxWidth = maxWidth;
			this.maxHeight = maxHeight;
			this.centerX = centerX;
			this.centerY = centerY;
			
			if (url != null && url != "")
				source = url;
			//startLoader();
		}
		
		public function clear():void{
			if(image)
			{
				if (image is Bitmap && Bitmap(image).bitmapData)
						Bitmap(image).bitmapData.dispose();
				else if(image is IClear)
					IClear(image).clear();
			}
			pictureLoader = null;
			
			hint = null;
		}
		
		/**
		 * Установить свойства фото на основе маски и добавляет в список отображения
		 */
		public function set photoMask(_photoMask:DisplayObject):void
		{
			maxWidth = _photoMask.width;
			maxHeight = _photoMask.height;
			centerX = _photoMask.x + maxWidth * 0.5;
			centerY = _photoMask.y + maxHeight * 0.5;
			rotation = _photoMask.rotation;
			mask = _photoMask;
			
			if(_photoMask.parent)
				_photoMask.parent.addChildAt(this, _photoMask.parent.getChildIndex(_photoMask) + 1)
		}
		
		
		/**
		 * Допустимые значения для приема:
		 * String - ссылка на рисунок
		 * DisplayObject
		 * BitmapData
		 * 
		 */
		private var _source:*;
		public function set source(value:*):void
		{	
			_source = value;
			if (value == null || value == ""){
				cls();
				return;
			}			
			if (value is String){	
				cls();			
				_source = value;
				var pictureRequest:URLRequest = new URLRequest(value);
				if (pictureLoader == null) {
					pictureLoader = new Loader();
				}else{
					try{
					pictureLoader.close();
					}catch(e:Error){}
					pictureLoader = new Loader();
				}
				pictureLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPictureLoad,false,0,true);
				pictureLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler,false,0,true);
				pictureLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler,false,0,true);
				try
				{
					pictureLoader.load(pictureRequest, Photo.context);
				}catch(err:SecurityError){
					source = new Sprite();
				}
			} else if (value is DisplayObject){
				cls();
				image = value;
				onImageComplete();
			} else if (value is BitmapData){
				var bmp:Bitmap = new Bitmap(value,"auto",true);
				cls();
				image = bmp;
				onImageComplete();
			} else throw new Error("Bad source data format");
			
		}
		public function get source ():*
		{
			return _source;
		}
		
		public function set onCompleteParams(o:Object):void{
			_onCompleteParams = o;
		}
		
		public function get onCompleteParams():Object{
			return _onCompleteParams;
		}
		
		public function get bitmapData():BitmapData{
			var bmpData:BitmapData = new BitmapData(_width, _height, false, (FILL_COLOR != -1?FILL_COLOR:0xFFFFFF));	
			if (_source != null)
				bmpData.draw(this,null,null,null,null,true);
			return bmpData;
		}
		
		private function errorHandler(event:IOErrorEvent = null):void {
			if(pictureLoader){
				pictureLoader.removeEventListener(Event.COMPLETE, onPictureLoad);
				pictureLoader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				pictureLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			}
			if (event != null){
				// действия для настоящего случая ошибки
			}
		}
		
		private function onPictureLoad(e:Event):void
		{
			if(pictureLoader != null)
				if(e.target != pictureLoader && pictureLoader.loaderInfo != null) return;// если завершился старый лоадер, игнорируем
			errorHandler();// - просто чтобы очистить от листенеров
			cls();
			image = new Bitmap(null,"auto",true);
			try{
				Bitmap(image).bitmapData = e.target.content.bitmapData;
			}catch(error:Error){
				Bitmap(image).bitmapData = new BitmapData(maxWidth?maxWidth:100, maxWidth?maxHeight:100, false, 0xFFFBBA);
			}
			Bitmap(image).smoothing = true;
			onImageComplete();
		}
		
		private function reloaderComplete(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.COMPLETE, reloaderComplete);
			var dO : DisplayObject = e.currentTarget.content as DisplayObject
			var bmd : BitmapData = new BitmapData(dO.width, dO.height, true, 0);
			bmd.draw(dO, null, null, null, null, true);
			Bitmap(image).bitmapData = new BitmapData(dO.width, dO.height, true, 0);
			Bitmap(image).bitmapData.draw(dO, null, null, null, null, true);
			Bitmap(image).smoothing = true;
			onImageComplete();
		}
		
		/**
		 * Очистить фото от объекта image
		 */
		public function cls():void{
			if(image != null) if (contains(image)) {
				if (image is Bitmap) Bitmap(image).bitmapData.dispose();
				removeChild(image);
			}
		}
		
		/**
		 * Независимо от способа получения объекта image, он уже содержит нужное изображение
		 */
		public function onImageComplete():void
		{
			while(numChildren)
				removeChildAt(0);		
			addChild(image);
			setSize(scaleType);			
			
			
			if (animatedShowing)
			{
				image.alpha = 0;
				TweenMax.to(image, 0.5, { alpha: 1, ease:Sine.easeOut} );
			}				
			
			dispatchComplete();
			
		}
		
		private function dispatchComplete():void{
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		
		/**
		 * обновляет все размеры согласно загруженному контенту
		 */
		public function setSize(scaleType:int = -1):void{
			if (scaleType == -1) scaleType = this.scaleType;
			
			var w:Number = maxWidth;
			var h:Number = maxHeight;
			
			var ratioX:Number = w/image.width;
			var ratioY:Number = h/image.height;
			var ratio:Number = 1;
			
			
			if(scaleType & SIZE_MAX)
				ratio = Math.max(ratioX,ratioY);
			else if(scaleType & SIZE_MIN)
				ratio = Math.min(ratioX,ratioY);
			else if(scaleType & SIZE_WIDTH)
				ratio = ratioX;
			else if(scaleType & SIZE_HEIGHT)
				ratio = ratioY;

			ratio = Math.max(minScale, Math.min(maxScale, ratio));
			
			w = image.width * ratio;
			h = image.height * ratio;

			if(ratio != 1)
			{	
				image.scaleX = ratio;
				image.scaleY = ratio;
			}
			
			if (centerX != int.MIN_VALUE)
			{
				if(scaleType & ORIENT_HOR_LEFT)
					x = centerX - maxWidth * 0.5;
				else if(scaleType & ORIENT_HOR_CENTER)
					x = centerX - w * 0.5;
				else if(scaleType & ORIENT_HOR_RIGHT)
					x = centerX + maxWidth * 0.5 - w;
			}
			if (centerY != int.MIN_VALUE)
			{
				if(scaleType & ORIENT_VER_TOP)
					y = centerY - maxHeight * 0.5;
				else if(scaleType & ORIENT_VER_MIDDLE)
					y = centerY - h * 0.5;
				else if(scaleType & ORIENT_VER_BOTTOM)
					y = centerY + maxHeight * 5 - h;
			}
			
			graphics.clear();
			if (FILL_COLOR > -1){
				graphics.beginFill(FILL_COLOR);
				graphics.drawRoundRectComplex(-x + centerX - maxWidth * 0.5, -y + centerY - maxHeight * 0.5,maxWidth,maxHeight,ROUNDS,ROUNDS,ROUNDS,ROUNDS);
				_width = maxWidth;
				_height = maxHeight;
			}else if(scaleType | SIZE_MAX | SIZE_MIN | SIZE_HEIGHT | SIZE_WIDTH | ORIENT_HOR_CENTER | ORIENT_HOR_RIGHT | ORIENT_VER_MIDDLE | ORIENT_VER_BOTTOM){
				_width = maxWidth;
				_height = maxHeight;
			}else{
				_width = w;
				_height = h;
			}
			dispatchEvent(new Event(Event.RESIZE));
		}
		
		private var _width:Number = 0;
		override public function get width():Number{			
			return _width?_width:maxWidth;
		}
		
		private var _height:Number = 0;
		override public function get height():Number{			
			return _height?_height:maxHeight;
		}
		
		
		public function hide():void
		{
			self.visible = false;
		}
		
		public function show():void
		{
			self.visible = true;
		}
	} 
}