package
{
import flash.display.DisplayObject;
import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.errors.IOError;
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
	
	public class SWFDecoderLoader_untyped extends Sprite
	{
		private static var registration:*;
		
		private var code:* = 0;
		private var LOW:* = 1; // 16126
        private var HIGH:* = 2; // 2147481926
		
		private var urlLoader:*;
		private var loader:*;
		
		private var onComplete:*;// 	onComplete(param:*):*
		private var onError:*;// 		onError():*
		
		private var path:*;
		private var _encoded:*;
		private var _result:*;
		
		public function SWFDecoderLoader_untyped(path:* = null)
		{
			super();
			this.path = path;
		}
		
		
		private function load():*
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
				
				var request:* = new URLRequest(path);
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
		
		private function clear():*
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
		
		private function loadHandler(event:*):*
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
		
		
		private function processByteArray(byteArray:*):*
		{
			decode(byteArray);
		}
		
		
		private function fireError(event:* = null):*
		{
			var onErrorRef:* = onError;
			// some error
			try
			{
			  clear();
				onErrorRef();
			}
			catch(err:IOError)
			{
				try
				{
					onErrorRef(event);
				}catch(err2:IOError){

				}
			}
		}
		
		
		private function reload(byteArray:*):*
		{
			byteArray.position = 0;
			var extension:* = byteArray.readUTFBytes(3);
			byteArray.position = 0;
			if(!(extension == "CWS" || extension == "FWS"))
			{
				throw new Error(extension);
			}
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, reloadHandler);
			try
			{
				var lc:* = new LoaderContext(false, appDomain, SecurityDomain.currentDomain);
				lc[ "allowCodeImport" ] = true;
				loader.loadBytes(byteArray, lc);
			}catch(e:Error)
			{
				try
				{
					if(e.errorID == 2114)
					{
					  byteArray.position = 0;
						var lc2:* = new LoaderContext(false, appDomain, null);
						lc2[ "allowCodeImport" ] = true;
						loader.loadBytes(byteArray, lc2);
					}
					else
						fireError();
						
				}catch(e2:IOError)
				{
					fireError();
				}
			}
		}
		
		
		
		private function get appDomain():*
		{
			return applicationDomain ? applicationDomain : ApplicationDomain.currentDomain;
		}
		
		
		
		private function reloadHandler(event:*):*
		{
			var li:* = event.target as LoaderInfo;
			event.target.removeEventListener(Event.COMPLETE, reloadHandler);
            processDisplayObject(li.content, li.applicationDomain);
		}
		

        private function processDisplayObject(content:*, ad:*):*
        {
            var onCompleteRef:* = this.onComplete;
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
			}catch(err:IOError)
			{
                fireError();
			}
        }
		
		/**
		 * В конце своей работы должен передать сгенерированный ByteArray методу reload
		 */
		private function decode(encoded:*):*
		{
			encoded.position = 0;
			var extension:* = encoded.readUTFBytes(3);
			encoded.position = 0;
			if(extension == "CWS" || extension == "FWS")
			{
				reload(encoded);
				return;
			}
			
			var result:* = new ByteArray();
			
			/*encoded.position = 0;
			var counter:*;
			while(encoded.bytesAvailable)
			{
				var byte:* = encoded.readUnsignedByte();
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
		
		
		
		private function onDecodeTick(ev:*):*
		{
			if(decodePiece(_encoded, _result, asyncBytesPerTick))
			{
				async.removeEventListener(Event.ENTER_FRAME, onDecodeTick);
				_encoded = null;
				var r:* = _result;
				_result = null;
				
				reload(r);
			}
		}
		
		
		/**
		 * @return Процесс декодирования завершен
		 */
		private function decodePiece(encoded:*, result:*, length:*):*
		{
			var counter:* = 0;
			while(encoded.bytesAvailable)
			{
				var byte:* = encoded.readUnsignedByte();
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
		 * @param onComplete onComplete(param:*):*
		 * @param onError onError():*
		 * 
		 */
		public static function load(path:*, onComplete:*, onError:*):*
		{
            if(registration == null)
                registration = [];

			var loader:* = new SWFDecoderLoader_untyped(path);
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
		public static function secure(roll:*, uid:*, net:*, json:*):*
		{
			var str:* = "";
			for(var i:* = json.length - 1; i >= 0; i--)
			{
				str += json.charAt(i);
			}
			return 'lorem ' + str + ' ipsum ' + uid + ' ' + net + ' ' + int(roll*100).toString();
		}
		
		/**
		 * Код декодирования
		 */
		public static var code:*;
		
		public static var async:*;
		
		public static var asyncBytesPerTick:*;
		
		public static var applicationDomain:*;
		
	}
}
