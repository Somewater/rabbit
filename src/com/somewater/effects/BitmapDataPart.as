package com.somewater.effects {
import flash.display.BitmapData;

public class BitmapDataPart {
	
	public var bitmapData:BitmapData;
	public var xOffset:Number;
	public var yOffset:Number;
	
	public function BitmapDataPart() {
	}
	
	public function clear():void {
		if(bitmapData){
			bitmapData.dispose();
			bitmapData = null;
		}
	}
}
}