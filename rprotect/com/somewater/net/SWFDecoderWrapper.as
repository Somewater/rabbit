package com.somewater.net
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;

	public class SWFDecoderWrapper
	{
		//[Embed(source="SWFDecoderLoader_debug.swf", mimeType="application/octet-stream")]
		//[Embed(source="SWFDecoderLoader_secure.swf", mimeType="application/octet-stream")]
		[Embed(source="SWFDecoderLoader.swf", mimeType="application/octet-stream")]
		private static var core:Class;
		
		private static var engine:*;
		
		
		public function SWFDecoderWrapper()
		{
			
		}
		
		
		/**
		 * 
		 * @param path
		 * @param onComplete onComplete(param:MovieClip):void
		 * @param onError onError():void
		 * 
		 */
		public static function load(path:*, onComplete:Function, onError:Function):void
		{
			if(engine)
			{
				engine['async'] = async;
				engine['code'] = code;
				engine['asyncBytesPerTick'] = asyncBytesPerTick;
				engine.load(path, onComplete, onError);
			}
			else
			{
				initialize(path, onComplete, onError);
			}
		}
		
		public static function secure(roll:Number, uid:String, net:String, json:String):String
		{
			return engine.secure(roll, uid, net, json);		
		}
		
		
		private static function initialize(path:*, onComplete:Function, onError:Function):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void{
				event.target.removeEventListener(event.type, arguments.callee);
				engine = event.target.content.constructor;
				try
				{
					//engine['return'] = code;
					engine["code"] = code;
				}catch(errr:Error){}
				if(path) load(path, onComplete, onError);
			});
			var bytes:ByteArray = new core();
			try
			{
				loader.loadBytes(bytes, new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
			}catch(err:Error)
			{
				try
				{
					loader.loadBytes(bytes, new LoaderContext(false, ApplicationDomain.currentDomain, null));
				}catch(err2:Error)
				{
					onError();
				}
			}
		}
		
		
		/**
		 * Код декодирования
		 */
		public static var code:int = 8;
		public static var async:*;
		public static var asyncBytesPerTick:uint = 1048576;// 1 Mb
	}
}
