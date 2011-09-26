package com.somewater.text
{
	import flash.events.Event;
	import flash.text.TextField;
	
	[Event(name="truncated", type="com.somewater.text.TruncatedTextField")]
	
	/**
	 * Обеспечивает появление точек, если ширины текста не хватает для полноценного отображения всего введенного текста
	 */
	public class TruncatedTextField extends EmbededTextField
	{
		public static const TRUNCATED:String = "truncated";
		
		public var autoHint:Boolean = true;// автоматически включать подсказку, если текст не вмещается
		private var _maxWidth:Number = 100;
		
		public function TruncatedTextField(font:String=null, color:*=null, size:int=12, bold:Boolean=false, bitmapText:Boolean = false)
		{
			super(font, color, size, bold, false, false, false,"left",bitmapText);
			//autoSize = TextFieldAutoSize.NONE;
		}
		
		public function set maxWidth(value:Number):void
		{
			if(_maxWidth != value)
			{
				_maxWidth = Math.max(5,value);
				setAbstractText(_text);
			}
		}
		
		public function get maxWidth():Number
		{
			return _maxWidth;
		}
		
		override public function set htmlText(value:String):void{
			setAbstractText(value,true);
		}
		
		override public function set text(value:String):void{
			setAbstractText(value,false);				
		}
		
		// установить текст (text / htmlText)
		private var _text:String;
		private function setAbstractText(value:String, htmlText:Boolean = false):void{
			_text = value;
			if (multiline){
				if (htmlText)
					super.htmlText = value;
				else
					super.text = value;
				if (height < textHeight)// если весь текст не вмещается в занимаемую textField область
					hint = value;
			}else{
				var truncated:Boolean = false;
				if (htmlText)
					super.htmlText = value;
				else
					super.text = value;
				var trunc:int = 3;
				// если значение типа htmlText то в textValue в отличае от value находится обычный текст (без тэгов)
				var textValue:String = super.text;
				while((isNaN(_maxWidth)?width: _maxWidth)<textWidth+2){
					truncated = true;
					trunc++;
					if(trunc > 200) {super.text = "..."; break;}
					if (htmlText)
						super.htmlText = textValue.substr(0,textValue.length-trunc)+"...";
					else
						super.text = textValue.substr(0,textValue.length-trunc)+"...";
				}
				if (autoHint)
					if (!truncated)
						hint = null;
					else
						if (!htmlText)
							hint = value;
						else{
							// KLUDGE
							var txt:TextField = new TextField();
							txt.htmlText = value;
							hint = txt.text;
						}
				if(truncated)
					dispatchEvent(new Event(TruncatedTextField.TRUNCATED));
			}
		}
		
		override public function get text():String{
			return _text;
		}
		
		/**
		 * Если меняеться ширина, то переопределить текст
		 */
		override public function set width(value:Number):void{
			if (super.width != value){				
				super.width = value;
				if (isNaN(_maxWidth) || value > _maxWidth) maxWidth = value;
				if (_text != null && _text != "") text = _text;
			}				
		}
		
		override public function set height(value:Number):void{
			if (super.height != value){				
				super.height = value;
				if (_text != null && _text != "" && multiline) text = _text;
			}				
		}
	}
}