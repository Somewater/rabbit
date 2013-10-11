package com.somewater.effects {
import flash.display.BitmapData;
import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

public class Utils {

	private static var matrix:Matrix = new Matrix()

	public function Utils() {
		super();
	}
	
	public static function displayObjectToBitmapData(displayObject:DisplayObject):BitmapDataPart {
		var rect:Rectangle = displayObject.getBounds(displayObject);
		var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
		matrix.tx = -rect.x;
		matrix.ty = -rect.y;
		bitmapData.draw(displayObject, matrix);
		var data:BitmapDataPart = new BitmapDataPart()
		data.bitmapData = bitmapData;
		data.xOffset = rect.x;
		data.yOffset = rect.y;
		return data;
	}
}
}