package com.somewater.common.util
{
	import com.greensock.TweenLite;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	public class Counter extends Sprite
	{
		private var tf:TextField;
		private var format:TextFormat;
		private var fpsCount:uint;
		private var last:uint;
		private var memoryUsed:Number;
		private var bytesInMegabyte:uint;
		private var fix:Boolean;
		
		public function Counter()
		{
			last = getTimer();
			
			format = new TextFormat("Courier new", 14, 0x00FF00);
			tf = createTextField();
			tf.defaultTextFormat = format;
			tf.text = ' xxx.xxx fps \n xxx.xxx MB ';
			tf.y = 5 - tf.height;
			addChild(tf);
			
			tf.addEventListener(MouseEvent.MOUSE_OVER, showCounter);
			tf.addEventListener(MouseEvent.MOUSE_OUT, hideCounter);
			tf.addEventListener(MouseEvent.CLICK, lockCounter);
			addEventListener(Event.ENTER_FRAME, calculation);
			
			bytesInMegabyte = 1024 * 1024;
			fpsCount = 0;
			memoryUsed = 0;
		}
		
		private function createTextField():TextField
		{
			var textField:TextField = new TextField();
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.multiline = true;
			textField.wordWrap = true;
			textField.selectable = false;
			textField.background = true;
			textField.backgroundColor = 0x000000;
            return textField;
		}
		
		private function calculation(event:Event):void
		{
			fpsCount++;
			memoryUsed += System.totalMemory;
			var now:uint = getTimer();
            var delta:uint = now - last;
			
            if (delta > 1000)
			{
				var fps:Number = fpsCount / delta * 1000;
				memoryUsed /= (fpsCount * bytesInMegabyte);
				tf.text = ' ' + fps.toFixed(1) + ' fps \n ' + memoryUsed.toFixed(1) + ' MB ';
				fpsCount = 0;
				memoryUsed = 0;
				last = now;
			}
		}
		
		private function showCounter(event:MouseEvent):void
		{
			if (!fix) TweenLite.to(tf, 0.5, {y:0});
		}
		
		private function hideCounter(event:MouseEvent):void
		{
			if (!fix) TweenLite.to(tf, 0.5, {y:(5 - tf.height)});
		}
		
		private function lockCounter(event:MouseEvent):void
		{
			fix = !fix;
		}
	}
}