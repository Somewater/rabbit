package com.somewater.common.util
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;

	public class SnapshotUploader
	{
		private static var ldr	: URLLoader;
		private static var req	: URLRequest;
		private static var fr	: FileReference;
		private static var active : Boolean = false;
		
		public static function take(obj : DisplayObject, largestWidth:Number, fileName:String='file.png', dlMode:Boolean = true) : void {
			if(!active) {
				var bmd : BitmapData = new BitmapData(int(obj.width), int(obj.height), true, 0x000000);
				var m : Matrix = new Matrix();
				if(obj.width > 2500 || obj.height > 2500) {
					bmd  = new BitmapData(int(obj.width/2), int(obj.height/2), true, 0x000000);
					m.scale(.5, .5);
				}
				var r : Rectangle = obj.getBounds(obj);
				m.translate(-r.x, -r.y);
				bmd.draw(obj, m, null, null, null, true);
				var colorBoundsRect : Rectangle = bmd.getColorBoundsRect(0xFF000000, 0x00000000, false);
				bmd.draw(obj, m, null, null, colorBoundsRect, true);
				
				var scale : Number = 1;//237/colorBoundsRect.width;

				var bmd2 : BitmapData = new BitmapData(colorBoundsRect.width, colorBoundsRect.width, true, 0x000000);
				bmd2.copyPixels(bmd, colorBoundsRect, new Point(0,0));
				var bitmap : Bitmap = new Bitmap(bmd2.clone(), PixelSnapping.AUTO, true);
				bmd2 = new BitmapData(int(colorBoundsRect.width*scale), int(colorBoundsRect.height*scale), true, 0x000000);				
				m = new Matrix();
				m.scale(scale, scale);
				bmd2.draw(bitmap, m, null, null, null, true);
				
				req = new URLRequest('http://www.local/kopai_server/trunk/admin/mappng.php?save=1&filename='+fileName+'&dlmode='+dlMode);
				req.requestHeaders = [new URLRequestHeader("Content-type", "application/octet-stream")];
				req.method = URLRequestMethod.POST;
				req.data = PNGEncoder.encode(bmd2);
				ldr = new URLLoader();
				ldr.load(req);
				ldr.addEventListener(Event.COMPLETE, completeHandler);
				active = dlMode;
			} else {				
				req = new URLRequest('http://www.local/kopai_server/trunk/admin/mappng.php');
				fr = new FileReference();
				fr.download(req, fileName);				
				active = false;
			}
		}
		
		private static function completeHandler(e:Event) : void {
			
		}
	}
}