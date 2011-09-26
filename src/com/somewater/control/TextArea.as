package com.somewater.control
{
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.TextInputPrompted;
	
	import fl.containers.ScrollPane;
	import fl.managers.FocusManager;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;

	public class TextArea extends Sprite
	{
		private var scroll:ScrollPane;
		public var textField:EmbededTextField;
		private var groundSprite:Sprite;
		private var focusRectang:Sprite;
		
		public function TextArea(font:String = "Tahoma",color:* = null,size:int = 12,bold:Boolean = false, selectable:Boolean = false,input:Boolean = false,align:String = "left",forseSmooth:Boolean = false)
		{
			super();
			
			scroll = new ScrollPane();
			addChild(scroll);
			
			if (input){
				textField = new TextInputPrompted(font,color,size,bold,align,forseSmooth);
				textField.x = 2;
				textField.multiline = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.addEventListener(Event.CHANGE,textChange_handler,false,0,true);				
				textField.addEventListener(FocusEvent.FOCUS_IN,focusIn_handler,false,0,true);
				textField.addEventListener(FocusEvent.FOCUS_OUT,focusOut_handler,false,0,true);
				groundSprite = new Sprite();
				groundSprite.addEventListener(MouseEvent.CLICK,selectText_handler,false,0,true);
				focusRectang = new focusRectSkin();
				focusRectang.x = -2;
				focusRectang.y = -2;
				addChildAt(focusRectang,0);
				focusRectang.visible = false;
				addChildAt(groundSprite,0);
			}				
			else
				textField = new EmbededTextField(font,color,size,bold,false,selectable,input,align,forseSmooth);
			
			if (input)
			{
				var sprt:Sprite = new Sprite();
				sprt.addChild(textField);
				scroll.source = sprt;
			}				
			else
				scroll.source = textField;
		}
		
		private function textChange_handler(e:Event = null):void{
			if (textField.height > (height - 5)){
				resize();
				scroll.verticalScrollPosition = scroll.maxVerticalScrollPosition;
			}				
		}
		
		public function set htmlText(value:String):void
		{
			if (textField.htmlText ==  value) return;
			textField.htmlText = value;
			resize();
		}
		public function get htmlText ():String
		{
			return textField.htmlText;
		}
		
		public function set text(value:String):void
		{
			if (textField.text ==  value) return;
			textField.text = value;
			resize();
			
		}
		public function get text ():String
		{
			return textField.text;
		}
		
		public function update():void{
			resize();
		}
		
		public function setSize(w:Number,h:Number):void{
			scroll.setSize(w,h);
			textField.width = w - 26;
			resize();
		}
		
		// перенести фокус в текстовое поле, т.к. был щелчек по одному из элементов класса
		private function selectText_handler(e:MouseEvent):void{
			if (textFieldInFocus) return;
			var fm:FocusManager = new FocusManager(this);
			fm.setFocus(textField);
		}
		
		private function resize():void{
			scroll.update();
			if (groundSprite != null){
				groundSprite.width = scroll.width - 26 ;
				groundSprite.height = scroll.height+2;
				focusRectang.width = groundSprite.width + 4 + 1;
				focusRectang.height = groundSprite.height + 4;
			}	
		}
		
		private var textFieldInFocus:Boolean = false;
		private function focusIn_handler(e:FocusEvent):void{
			focusRectang.visible = textFieldInFocus = true;resize()
		}
		
		private function focusOut_handler(e:FocusEvent):void{
			focusRectang.visible = textFieldInFocus = false;resize()
		}
		
	}
}