package com.somewater.text
{
	import flash.events.Event;
	import flash.events.FocusEvent;

	public class TextInputPrompted extends EmbededTextField
	{
		public var promptColor:int = 0x999999;
		
		public function TextInputPrompted(font:String=null, color:*=null, size:int=12, bold:Boolean=false, align:String="left",bitmapText:Boolean = false)
		{
			super(font, color, size, bold, true, true, true, align, bitmapText);
			_color = super.color;
			_bold = bold;
			_textEmpty = false;	
		}	
			
		// подсказка когда text=""
		private var _textEmpty:Boolean;
		private var _currentlyFocused:Boolean = false;
		private var _prompt:String = "";// установлен ли стиль PROMPT для текста
		private var _color:int;// храним значение нормального цвета
		private var _bold:Boolean;
		public function set prompt(value:String):void
		{
			if (value.length && !_prompt.length) {
				addEventListener(Event.CHANGE,textChange_handler,false,0,true);
				addEventListener( FocusEvent.FOCUS_IN, focusIn_handler,false,0,true);
				addEventListener( FocusEvent.FOCUS_OUT, focusOut_handler ,false,0,true);
			}
			if (!value.length) {
				removeEventListener(Event.CHANGE,textChange_handler);
				removeEventListener( FocusEvent.FOCUS_IN, focusIn_handler );
				removeEventListener( FocusEvent.FOCUS_OUT, focusOut_handler );
			}
			_textEmpty = super.text.length == 0?true:(super.text == _prompt?true:false);	
			_prompt = value;
			validate_prompt();
		}
		
		public function get prompt ():String
		{
			return _prompt;
		}
		
		private function textChange_handler(e:Event = null):void{	
			_textEmpty = super.text.length == 0;
			validate_prompt();
		}
		
		private function validate_prompt():void{
			if ( _textEmpty && _prompt != "" && !_currentlyFocused ){
				// применить стиль PROMPT
				super.text = _prompt;
				super.color = promptColor;
				super.bold = false;
			}
			if (!_textEmpty){
				// очистить стиль
				super.color = _color;
				super.bold = _bold;
			}
		}
		
		private function focusIn_handler(e:FocusEvent):void{
			_currentlyFocused = true;		
			// If the text is empty, clear the prompt
			if ( _textEmpty )
			{
				super.text = "";
				validate_prompt();
			}
		}
		
		private function focusOut_handler(e:FocusEvent):void{
			_currentlyFocused = false;		
			// If the text is empty, put the prompt back
			validate_prompt();
		}
		
		private var _text:String = "";
		override public function set text(value:String):void{
			_textEmpty = (!value) || value.length == 0;
			super.text = value;
			validate_prompt();
		}
		override public function get text():String{
			if ( _textEmpty ){
				return "";
			}
			else{
				return super.text;
			}
		}
		
		/**
		 * Возвращает прямой текст - т.е. то, что видит пользователь в поле в данный момент
		 * будь то даже подсказка prompt
		 */
		public function get directText():String{
			return super.text;
		}
		
		override public function set color(value:int):void
		{
			_color = value;
			super.color = value;
		}
		
		override public function get color ():int
		{
			return _color;
		}
		
		override public function set bold(value:Boolean):void
		{
			_bold = value;
			super.bold = value;
		}
		
		override public function get bold ():Boolean
		{
			return _bold;
		}
	}
}