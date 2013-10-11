package com.somewater.effects {
import flash.display.DisplayObject;
	import flash.geom.Point;

	public interface IEffect {
	function displayObject():DisplayObject
	function start():void
	function tick(msDelta:int):Boolean
	function clear():void
	function getRegistrationPoint():Point
}
}
