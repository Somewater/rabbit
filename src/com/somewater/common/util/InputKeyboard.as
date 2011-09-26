package com.somewater.common.util
{
	import flash.display.Stage;
	import flash.events.KeyboardEvent;

	public class InputKeyboard
	{
		private static var keyDown    : Array = new Array();
		
		// ** initialize
		public static function initialize( stage : Stage ) {
			stage.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDownHandler );
			stage.addEventListener( KeyboardEvent.KEY_UP, onKeyUpHandler );
		}
		
		// ** isKeyDown
		public static function isKeyDown( key : Number ) : Boolean {
			return keyDown[ key ];
		}
		
		// ** onKeyDownHandler
		private static function onKeyDownHandler( e : KeyboardEvent ) {
			keyDown[ e.keyCode ] = true;
		}
		
		// ** onKeyUpHandler
		private static function onKeyUpHandler( e : KeyboardEvent ) {
			keyDown[ e.keyCode ] = false;
		}
	}
}