package com.somewater.rabbit
{
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;

	[Event(name="applicationInited", type="flash.events.Event")]

	/**
	 * api для RabbitApplication
	 */
	public interface IRabbitApplication extends IRabbitModule
	{
		function run():void
			
		function message(msg:String):Sprite

		function levelStartMessage(level:LevelDef):void

		function levelFinishMessage(levelInstance:LevelInstanceDef):void

		function addFinishedLevel(levelInstance:LevelInstanceDef):void
			
		function showSlash(process:Number):void
			
		function hideSplash():void
			
		function fatalError(msg:String):void
			
		function startPage(name:String):void
			
		function startGame(level:LevelDef = null):void
			
		// массив всех уровней игры
		function get levels():Array
		function getLevelByNumber(id:int):LevelDef
		function addLevel(level:LevelDef):void
			
		function addPropertyListener(propertyName:String, callback:Function):void
		function removePropertyListener(propertyName:String, callback:Function):void
		function dispatchPropertyChange(propertyName:String):void

			
		function set sound(value:Number):void
		function get sound():Number
			
		function set music(value:Number):void
		function get music():Number
			
		function set musicEnabled(value:Boolean):void
		function get musicEnabled():Boolean
			
		function set soundEnabled(value:Boolean):void
		function get soundEnabled():Boolean

		function createTextField(font:String = null,color:* = null,size:int = 12,bold:Boolean = false,multiline:Boolean = false, selectable:Boolean = false,input:Boolean = false,align:String = "left",bitmapText:Boolean = false):TextField
			
	}
}