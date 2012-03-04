package com.somewater.text
{	
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	
	public class EmbededTextField extends TextField implements IHinted
	{
		public static var DEFAULT_FONT:String = "Tahoma";
		
		// функция проверки на возможность замены "bitmap text"
		// вызывается как BITMAP_CHECK_FUNC(font:String, size:int):String
		// если возвращает не пустой стринг "", то данный font присваивается тексту
		public static var BITMAP_CHECK_FUNC:Function;
		
		
		private var _hint:String;
		public function set hint(value:String):void
		{
			
			if (value != null && value != "")
				if (_hint == null || _hint == ""){
					_hint = value;
					Hint.bind(this,value);
					return;
				}
			_hint = value;
								
		}
		public function get hint ():String
		{
			return _hint;
		}
		
		/*[Embed(	source="assets/fonts/tahoma.ttf", 
				fontWeight="regular", 
				fontStyle="regular", 
				fontName="Tahoma", 
				unicodeRange="U+0020-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+0400-U+04FF",
				mimeType="application/x-font-truetype")]
		public static const TahomaFont:String;*/
		
		//	My embed set: (space char also!!!)
		//	0123456789№АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщьыъЭэЮюЯяAaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz!@#$%^&*():;"',.\/+-*{}[]~`<>|=_? 

        
		/**
		 *	Задает формат для текстового поля. Если текстовое поле не задано (tf = null), создается и возвращается новое текстовое поле 
		 * @param color цвет шрифта. Если null, то черный. Кроме hex цветов поддерживает String
		 * @param size размер шрифта
		 * @param bold жирный шрифт
		 * @param label однострочное (иначе многострочное, с переносом строк)
		 * @param selectable выделяемое
		 * @param input поле ввода или нет
		 * @param bitmapText включить битмап вариант шрифта, если таковой присутствует
		 * @return текстовое поле, отредактированное согласно аргументам
		 */		
		public function EmbededTextField(font:String = null,color:* = null,size:int = 12,bold:Boolean = false,multiline:Boolean = false, selectable:Boolean = false,input:Boolean = false,align:String = "left",bitmapText:Boolean = false)
		{
			super();
			if (color == null) color = 0x000000;
			if (font == null) font = DEFAULT_FONT;
			var format:TextFormat = EmbededTextField.getEmbededFormat(null,font,strColorToHex(color),size,bold,bitmapText);
			format.align = align;
			defaultTextFormat = format;	
			this.selectable = mouseEnabled = selectable;
			this.multiline = multiline;
			embedFonts = true;
			this.align = align;
			antiAliasType = (format.font.indexOf("pt_st") == -1)?AntiAliasType.ADVANCED:AntiAliasType.NORMAL;
			type = input?TextFieldType.INPUT: TextFieldType.DYNAMIC;
			text = " ";
		}
		
		/**
		 * Выдает запрошенный формат.
		 * Если textField != null присваивает заданный текст формат полю
		 */
		public static function getEmbededFormat(tf:TextField = null,font:String = null,color:* = null,size:int = 11,bold:Boolean = false, bitmapText:Boolean = false):TextFormat{
			if (tf != null){
				tf.embedFonts = true;
			}
			if (font == null) font = DEFAULT_FONT;
			if (bitmapText){
				if (BITMAP_CHECK_FUNC != null){
					if (BITMAP_CHECK_FUNC(font, size) != "")
						font = BITMAP_CHECK_FUNC(font, size)
				}
			}
			var tfmt:TextFormat = new TextFormat(font,size,color,bold);
			if (tf != null){
				tf.defaultTextFormat = tfmt;
				tf.setTextFormat(tfmt);
			}
			return tfmt;
		}
		
		/**
		 * Перевести строковый идентификатор цвета в цифровой
		 * @param color цвет шрифта. Если null, то черный. Кроме hex цветов поддерживает String
		 */
		private function strColorToHex(str:Object):int{
			if (str is String){
				var color:int;
				switch (str) {
					case "w": color = 0xFFFFFF;	break;
					case "b": color = 0x524137;	break;
					case "green": color = 0x4BA024;	break;
					case "orange": color = 0xED6B00;break;
					case "tan": color = 0xC4A26C;break;
					case "gray": color = 0x777777;break;
					default: color = 0x000000; 
				}
				return color;
			}else 
				return int(str);
		}
		
		/**
		 * @param flag какую манипуляцию с координатами проделать
		 * 0 ничего
		 * 1 считать x координатой середины текстового поля, а не края
		 * 2 считать y координатой середины текстового поля, а не края
		 * 3 считать x,y серединами текстового поля, а не края
		 */
		public function move(x:int,y:int,flag:int = 0):void{
			this.x = x - ((flag & 1)?textWidth*0.5:0);
			this.y = y - ((flag & 2)?textHeight*0.5:0);
		}
		
		public function set size(value:int):void{
			setAbstractFormatField("size",value);
		}
		
		public function get size():int{
			return defaultTextFormat["size"]
		}
		
		public function set color(value:int):void{
			setAbstractFormatField("color",value);
		}
		
		public function get color():int{
			return defaultTextFormat["color"]
		}
		
		public function set underline(value:Boolean):void{
			setAbstractFormatField("underline",value);
		}
		
		public function get underline():Boolean{
			return defaultTextFormat["underline"]
		}
		
		public function set bold(value:Boolean):void{
			setAbstractFormatField("bold",value);
		}
		
		public function get bold():Boolean{
			return defaultTextFormat["bold"]
		}
		
		public function set italic(value:Boolean):void{
			setAbstractFormatField("italic",value);
		}
		
		public function get italic():Boolean{
			return defaultTextFormat["italic"]
		}
		
		public function set align(value:String):void{
			autoSize = value == "center" ? TextFieldAutoSize.NONE : value;
			setAbstractFormatField("align",value);
		}
		
		public function get align():String{
			return defaultTextFormat["align"]
		}
		
		public function set font(value:String):void{
			setAbstractFormatField("font",value);
		}
		
		public function get font():String{
			return defaultTextFormat["font"]
		}
		
		public function set input(value:Boolean):void{
			type = value?TextFieldType.INPUT: TextFieldType.DYNAMIC;
		}
		
		override public function set multiline(value:Boolean):void{
			super.multiline = wordWrap = value;
		}
		
		override public function get multiline():Boolean{
			return super.multiline;
		}
		
		public  function setAbstractFormatField(field:String,value:*):void{
			var format:TextFormat = new TextFormat();
			format[field] = value;
			setTextFormat(format);
			defaultTextFormat = format;
		}

	}
}