package com.somewater.control
{
	
	import com.somewater.text.TextInputPrompted;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.text.TextFormat;
	
	/**
	 * Аналогичен TextInputPrompted, однако также имеет фон
	 * Необходимо вызвать методо setSize для задания размера
	 */
	public class TextInputGrounded extends Sprite
	{
		public var input:TextInputPrompted;
		private var ground:Sprite;
		private var focusRectang:focusRectSkin;
		private var inputMask:Shape;
		
		private var X_OFFSET:int = 2;
		private var Y_OFFSET:int = -1;
		
		public function TextInputGrounded(font:String=null, color:*=null, size:int=12, bold:Boolean=false, align:String="left",forceSmooth:Boolean = false)
		{
			super();
			input = new TextInputPrompted(font, color, size, bold, align,forceSmooth);
			ground = new TextInput_upSkin();
			focusRectang = new focusRectSkin();
			focusRectang.visible = false;
			focusRectang.x = -2;
			focusRectang.y = -2;
			inputMask = new Shape();
			addChild(ground);
			addChild(focusRectang);
			addChild(input);
			addChild(inputMask);
			input.mask = inputMask;
			input.addEventListener(FocusEvent.FOCUS_IN,focusIn_handler);
			input.addEventListener(FocusEvent.FOCUS_OUT,focusOut_handler);
			//setSize(50,21);
		}
		
		// _description
		private var _enabled:Boolean = true;
		public function set enabled(value:Boolean):void
		{
			if (_enabled != value){
				removeChild(ground);
				ground = new TextInput_upSkin();
				addChildAt(ground,0);
				setSize(_width,_height);
				
			}
			if (focusRectang.visible)
				focusRectang.visible = false;
			input.selectable = value;
			input.visible = value;
			_enabled = value;
		}
		public function get enabled ():Boolean
		{
			return _enabled;
		}
		

		public function set text(value:String):void
		{
			input.text = value;
		}
		public function get text ():String
		{
			return input.text;
		}
		
		public function set prompt(value:String):void
		{
			input.prompt = value;
		}
		public function get prompt ():String
		{
			return input.prompt;
		}
		
		public function set defaultTextFormat(value:TextFormat):void
		{
			input.defaultTextFormat = value;
		}
		public function get defaultTextFormat():TextFormat
		{
			return input.defaultTextFormat;
		}
		
		public function setSize(w:int,h:int = 21):void{
			inputMask.graphics.clear();
			inputMask.graphics.beginFill(0);
			inputMask.graphics.drawRect(0,0,w,h);
			inputMask.graphics.endFill();
			//Y_OFFSET = (input.textHeight - h)-2*(input.size-11);// 11 и 12 шрифты обображаются правильно
			input.x = X_OFFSET;	input.y = Y_OFFSET;
			input.width = w - X_OFFSET;
			input.height = h - Y_OFFSET;
			ground.width = w;
			ground.height = h;
			focusRectang.width = w+5;
			focusRectang.height = h+4;
			_width = w;
			_height = h;
		}
		
		private var _width:Number;
		override public function set width(value:Number):void{			
			_width = value;
			setSize(_width,_height);
		}
		override public function get width():Number{			
			return _width;
		}
		
		private var _height:Number;
		override public function set height(value:Number):void{			
			_height = value;
			setSize(_height,_height);
		}
		override public function get height():Number{			
			return _height;
		}
		
		private function focusIn_handler(e:FocusEvent):void{
			if (_enabled)
				focusRectang.visible = true;
		}
		
		private function focusOut_handler(e:FocusEvent):void{
			if (_enabled)
				focusRectang.visible = false;
		}
	}
}