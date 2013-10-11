package com.somewater.effects {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
	import flash.geom.Point;

	public class EffectBase implements IEffect{
	
	protected var bitmap:Bitmap;
	protected var bitmapData:BitmapData;
	
	public var width:int;
	public var height:int;
	
	public function EffectBase() {
		super();
		width ||= 300;
		height ||= 300;
	}
	
	protected function createBitmapData():BitmapData {
		var b:BitmapData = new BitmapData(width, height, true, 0);
		return b;
	}
	
	public function displayObject():DisplayObject {
		return bitmap;	
	}
	
	public function clear():void {
		if(bitmap){
			if(bitmap.parent)
				bitmap.parent.removeChild(bitmap);
			bitmap = null;
		}
		if(bitmapData){
			bitmapData.dispose();
			bitmapData = null;
		}
			
	}
	
	public function start():void {
		bitmap = new Bitmap();
		bitmap.bitmapData = bitmapData = createBitmapData();
	}
	
	public function tick(msDelta:int):Boolean {
		return false;
	}
	
	public static function random(from:Number, to:Number):Number {
		return from + Math.random() * (to - from);
	}

	public function getRegistrationPoint():Point{
		return new Point(width * 0.5, height * 0.5);
	}
}
}