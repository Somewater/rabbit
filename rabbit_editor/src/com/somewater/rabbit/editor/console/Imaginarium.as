package com.somewater.rabbit.editor.console
{
	import flash.display.*
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import com.adobe.images.JPGEncoder;

    import flash.net.*;
    import flash.utils.ByteArray;
    import flash.events.Event;

    public class Imaginarium
    {
        public function Imaginarium()
        {
            // uploadImage(createBitmap(imagedo, 100, 100), 'http://rabbit.asflash.ru/images/manage', {'foo':'bar'});
        }

        public static function uploadImage(image:BitmapData, upload_url:String, callback:Function, params:Object = null):void
        {
            var paramsStr:String = '';
            if(params)
                for(var k:String in params)
                    paramsStr += k + '="' + params[k] + '"; ';
            var jpgEncode:ByteArray= new JPGEncoder(90).encode(image);
			var header:URLRequestHeader=new flash.net.URLRequestHeader("Content-type", "multipart/form-data; boundary=abc");
			var byteArray:ByteArray=new flash.utils.ByteArray();
			byteArray.writeUTFBytes("--abc\r\nContent-Disposition: form-data; " + paramsStr + "name=\"file_my_name\"; filename=\"post.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n");
			byteArray.writeBytes(jpgEncode);
			byteArray.writeUTFBytes("\r\n--abc--\r\n");
			var request:URLRequest=new flash.net.URLRequest();
			request.requestHeaders.push(header);
			request.url = upload_url;
			request.method = URLRequestMethod.POST;
			request.data = byteArray;

			var saver:URLLoader = new flash.net.URLLoader();
			saver.addEventListener(Event.COMPLETE, function(event:Event):void{
                event.currentTarget.removeEventListener(Event.COMPLETE, arguments.callee);
				callback(event.target.data);
                //trace("[RESPONSE] " + event.target.data);
            });
			saver.load(request);
        }


        public static function createBitmap(source:DisplayObject, width:int, height:int, source_width:int = 0, source_height:int = 0):BitmapData
        {
            var bd:BitmapData = new BitmapData(width, height, true, 0);
            var bounds:Rectangle = source.getBounds(source);
            if(source_width <= 0)
                source_width = source.width;
            if(source_height <= 0)
                source_height = source.height;
            var size:Number = Math.min(width/source_width, height/source_height);
            var m:Matrix = new Matrix(size, 0, 0, size, 0,0);
            bd.draw(source, m);
            return bd;
        }
    }
}