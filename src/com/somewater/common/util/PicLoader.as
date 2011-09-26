package com.somewater.common.util
{
	import com.somewater.common.factory.McFactory;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.LoaderContext;
	
	public class PicLoader
	{
		private var user:Object;
		private var loader:Loader;
		private var copy:Bitmap;
		private var callBack:Function;
		
		public function PicLoader():void
		{
			loader = new Loader();
		}
		
		public function getImage(tempUser:Object, callBackFunction:Function):void
		{
			removeEventListeners();
			
			user = tempUser;
			callBack = callBackFunction;
			
			if (user.image)
			{
				returnImage();
			}
			else
			{
				var url:String = user.socialUser.photos[1];
				if (url == '' || url == null)
				{
					trace('url: "' + url + '"');
					errorHandler();
					return;
				}
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedHandler);
				loader.load(new URLRequest(url), new LoaderContext(true));
			}
		}
		
		private function returnImage():void
		{
			copy = new Bitmap(user.image.bitmapData.clone());
			callBack(copy);
		}
		
		private function loadedHandler(event:Event):void
		{
			user.image = Bitmap(loader.content);
			if (!user.image) errorHandler();
			removeEventListeners();
			returnImage();
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace(event + '\nошибка загрузки картинки друга!');
			removeEventListeners();
			errorHandler();
		}
		
		private function errorHandler():void
		{
			var noPhoto:Sprite = McFactory.createMc('NoPhoto','ui') as Sprite;
			var bd:BitmapData = new BitmapData(noPhoto.width, noPhoto.height, true, 0x000000);
			bd.draw(noPhoto);
			user.image = new Bitmap(bd);
			returnImage();
		}
		
		private function removeEventListeners():void
		{
			loader.unload();
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadedHandler);
		}
	}
}