package com.somewater.effects {
import flash.display.BitmapData;

public class Particle extends BitmapDataPart{
	
	public var x:Number = 0;  
	public var y:Number = 0;
	public var alpha:Number = 1;
	
	public var arg1:Number;
	public var arg2:Number;
	public var arg3:Number;
	public var arg4:Number;
	public var arg5:Number;
	public var sign:int;   
	public var age:int;
	
	public function Particle() {
		super()
	}
}
}