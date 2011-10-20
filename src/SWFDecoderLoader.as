package
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	
	public class SWFDecoderLoader extends Sprite
	{
		private static var registration:Array;
		
		private var code:Number = 0;
		private var _step:int = 1;
		
		private var urlLoader:URLLoader;
		private var loader:Loader;
		
		private var onComplete:Function;// 	onComplete(param:MovieClip):void
		private var onError:Function;// 		onError():void
		
		public function SWFDecoderLoader(path:* = null)
		{
			super();
			
			if(path is String)
			{
				urlLoader = new URLLoader();
				
				var request:URLRequest = new URLRequest(path);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				_step = String("34534.345.65654.16147.567567.4566.53246.65466").split(".")[String("34534.345.65654.16147.567567.4566.53246.65466").charAt()];
				urlLoader.addEventListener(Event.COMPLETE, loadHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadHandler);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadHandler);
				
				urlLoader.load(request);
				
				if(registration == null)
					registration = [];
				registration.push(this);
			}
		}
		
		
		
		private function loadHandler(event:Event):void
		{
			urlLoader.removeEventListener(Event.COMPLETE, loadHandler);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, loadHandler);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loadHandler);
			
			registration.splice(registration.indexOf(this), 1);
			
			if(event is IOErrorEvent || event is SecurityErrorEvent)
			{
				fireError();
			}else{
				// successfull
				var result:ByteArray;
				var extension:String;
				try
				{
					result = urlLoader.data;
					result = decode(result);
					reload(result);
				}catch(err3:Error)
				{
					fireError(event);
				}
			}
		}
		
		
		private function fireError(event:Event = null):void
		{
			// some error
			try
			{
				onError();
			}
			catch(err:Error)
			{
				try
				{
					onError(event);
				}catch(err2:Error){
					
				}
			}
		}
		
		
		
		private function reload(byteArray:ByteArray):void
		{
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, reloadHandler);
			try
			{
				loader.loadBytes(byteArray, new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
			}catch(e:Error)
			{
				try
				{
					if(e.errorID == 2114)
						loader.loadBytes(byteArray, new LoaderContext(false, ApplicationDomain.currentDomain, null));
					else
						fireError();
				}catch(e2:Error)
				{
					fireError();
				}
			}
		}
		
		
		
		private function reloadHandler(event:Event):void
		{
			var li:LoaderInfo = event.target as LoaderInfo;
			event.target.removeEventListener(Event.COMPLETE, reloadHandler);
			try
			{
				if(li.content.hasOwnProperty("scalar") && Object(li.content).scalar is Class)
				{
					var cl:* = Object(li.content).scalar;
					reload(
						decode(
							new cl()
						)
					);
				}else
					onComplete(li.applicationDomain);
			}catch(err:Error)
			{
				try
				{
					onComplete(li.content);
				}catch(err2:Error)
				{
					fireError();
				}
			}
		}
		
		
		
		
		private function decode(encoded:ByteArray):ByteArray
		{
			encoded.position = 0;
			var extension:String = encoded.readUTFBytes(3);
			encoded.position = 0;
			if(extension == "CWS" || extension == "FWS")
			{
				return encoded;
			}
			
			var result:ByteArray = new ByteArray();
			
			encoded.position = 0;
			var counter:uint;
			while(encoded.bytesAvailable)
			{
				var byte:int = encoded.readUnsignedByte();
				code = (code * _step) % 2147483647;
				byte = byte ^ int((code / 2147483647) * 256);
				result.writeByte(byte);
				
				if(counter > 1000) return null;
			}
			
			return result;
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
			var loader:SWFDecoderLoader = new SWFDecoderLoader(path);
			loader.code = code;
			loader.onComplete = onComplete;
			loader.onError = onError;
		}
		
		
		/**
		 * Код декодирования
		 */
		public static var code:int = 0;
		
	}
}