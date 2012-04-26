package
{
import flash.display.DisplayObject;
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
		private var LOW:int = 1; // 16126
        private var HIGH:int = 2; // 2147481926
		
		private var urlLoader:URLLoader;
		private var loader:Loader;
		
		private var onComplete:Function;// 	onComplete(param:MovieClip):void
		private var onError:Function;// 		onError():void
		
		private var path:*;
		private var _encoded:ByteArray;
		private var _result:ByteArray;
		
		public function SWFDecoderLoader(path:* = null)
		{
			super();
			this.path = path;
		}
		
		
		private function load():void
		{
			var path:* = this.path;
			this.path = null;
			LOW = new Error('lorem ',String("3434.3435.16122.16126.16147.3566.3246.16123").split(".")[String("3434.3435.16122.16126.16147.3566.3246.16123").charAt()]).errorID;
            HIGH = new Error('ipsum ',Math.sin(0.216434) * Math.pow(10,10)).errorID;
            
      if(registration == null)
					registration = [];
			registration.push(this);
			
			if(path is String)
			{
				urlLoader = new URLLoader();
				
				var request:URLRequest = new URLRequest(path);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.addEventListener(Event.COMPLETE, loadHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadHandler);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadHandler);
				
				urlLoader.load(request);
				
				if(registration == null)
					registration = [];
				registration.push(this);
			}else if(path is ByteArray)
			{
				processByteArray(path);
			}else if(path is DisplayObject)
            {
                processDisplayObject(path,
                        DisplayObject(path).loaderInfo ? DisplayObject(path).loaderInfo.applicationDomain : null)
            }else
            {
							fireError();
							return;
			}
		}
		
		private function clear():void
		{
            if(registration.indexOf(this) != -1)
			    registration.splice(registration.indexOf(this), 1);
			path = null;
			onComplete = null;
			onError = null;
			urlLoader = null;
            loader = null;
      if(async)
	      async.removeEventListener(Event.ENTER_FRAME, onDecodeTick);
			_encoded = null;
			_result = null;
		}
		
		private function loadHandler(event:Event):void
		{
			urlLoader.removeEventListener(Event.COMPLETE, loadHandler);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, loadHandler);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loadHandler);
			
			if(event is IOErrorEvent || event is SecurityErrorEvent)
			{
				fireError();
			}else{
				// successfull
				processByteArray(urlLoader.data);
			}
		}
		
		
		private function processByteArray(byteArray:ByteArray):void
		{
			decode(byteArray);
		}
		
		
		private function fireError(event:Event = null):void
		{
			var onErrorRef:Function = onError;
			// some error
			try
			{
			  clear();
				onErrorRef();
			}
			catch(err:Error)
			{
				try
				{
					onErrorRef(event);
				}catch(err2:Error){

				}
			}
		}
		
		
		private function reload(byteArray:ByteArray):void
		{
			byteArray.position = 0;
			var extension:String = byteArray.readUTFBytes(3);
			byteArray.position = 0;
			if(!(extension == "CWS" || extension == "FWS"))
			{
				throw new Error(extension);
			}
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, reloadHandler);
			try
			{
				var lc:LoaderContext = new LoaderContext(false, appDomain, SecurityDomain.currentDomain);
				lc[ "allowCodeImport" ] = true;
				loader.loadBytes(byteArray, lc);
			}catch(e:Error)
			{
				try
				{
					if(e.errorID == 2114)
					{
					  byteArray.position = 0;
						var lc2:LoaderContext = new LoaderContext(false, appDomain, null);
						lc2[ "allowCodeImport" ] = true;
						loader.loadBytes(byteArray, lc2);
					}
					else
						fireError();
						
				}catch(e2:Error)
				{
					fireError();
				}
			}
		}
		
		
		
		private function get appDomain():ApplicationDomain
		{
			return applicationDomain ? applicationDomain : ApplicationDomain.currentDomain;
		}
		
		
		
		private function reloadHandler(event:Event):void
		{
			var li:LoaderInfo = event.target as LoaderInfo;
			event.target.removeEventListener(Event.COMPLETE, reloadHandler);
            processDisplayObject(li.content, li.applicationDomain);
		}
		

        private function processDisplayObject(content:DisplayObject, ad:ApplicationDomain):void
        {
            var onCompleteRef:Function = this.onComplete;
			try
			{
				if(content.hasOwnProperty("scalar") && Object(content).scalar is Class)
				{
					var cl:* = Object(content).scalar;
						decode(
							new cl()
						);
				}else
                {
                    try
                    {
                        clear();
					    onCompleteRef(ad);
                    }catch(err2:TypeError)
                    {
                        if(err2.errorID == 1034)
                            onCompleteRef(content);
                    }
                }
			}catch(err:Error)
			{
                fireError();
			}
        }
		
		/**
		 * В конце своей работы должен передать сгенерированный ByteArray методу reload
		 */
		private function decode(encoded:ByteArray):void
		{
			encoded.position = 0;
			var extension:String = encoded.readUTFBytes(3);
			encoded.position = 0;
			if(extension == "CWS" || extension == "FWS")
			{
				reload(encoded);
				return;
			}
			
			var result:ByteArray = new ByteArray();
			
			/*encoded.position = 0;
			var counter:uint;
			while(encoded.bytesAvailable)
			{
				var byte:int = encoded.readUnsignedByte();
				code = (code * LOW) % HIGH;
				byte = byte ^ int((code / HIGH) * 256);
				result.writeByte(byte);
			}
			
			reload(result);*/
			if(async == null || encoded.length < asyncBytesPerTick)
			{
				decodePiece(encoded, result, 4294967295);
				reload(result);
			}
			else
			{
				_encoded = encoded;
				_result = result;
				async.addEventListener(Event.ENTER_FRAME, onDecodeTick);
			}	
		}
		
		
		
		private function onDecodeTick(ev:Event):void
		{
			if(decodePiece(_encoded, _result, asyncBytesPerTick))
			{
				async.removeEventListener(Event.ENTER_FRAME, onDecodeTick);
				_encoded = null;
				var r:ByteArray = _result;
				_result = null;
				
				reload(r);
			}
		}
		
		
		/**
		 * @return Процесс декодирования завершен
		 */
		private function decodePiece(encoded:ByteArray, result:ByteArray, length:uint):Boolean
		{
			var counter:uint = 0;
			while(encoded.bytesAvailable)
			{
				var byte:int = encoded.readUnsignedByte();
				code = (code * LOW) % HIGH;
				byte = byte ^ int((code / HIGH) * 256);
				result.writeByte(byte);
				counter++;
				if(counter > length)	
				{
					return false;
				}
			}		
			return true;
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
            if(registration == null)
                registration = [];

			var loader:SWFDecoderLoader = new SWFDecoderLoader(path);
            registration.push(loader);
			loader.code = code;
			loader.onComplete = onComplete;
			loader.onError = onError;
            loader.load();
		}
		
		/**
		 * Создает 'secure' подпись серверного запроса
		 * "lorem #{@params['json'].reverse} ipsum #{@params['uid']} #{@params['net']} #{roll}"
		 */
		public static function secure(roll:Number, uid:String, net:String, json:String):String
		{
			var str:String = "";
			for(var i:int = json.length - 1; i >= 0; i--)
			{
				str += json.charAt(i);
			}
			return 'lorem ' + str + ' ipsum ' + uid + ' ' + net + ' ' + int(roll*100).toString();
		}
		
		/**
		 * Код декодирования
		 */
		public static var code:int;
		
		public static var async:*;
		
		public static var asyncBytesPerTick:uint;
		
		public static var applicationDomain:ApplicationDomain;
		
	}
}
