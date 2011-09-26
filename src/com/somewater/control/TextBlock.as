/**
 * Текстовый блок, у которого при необходимости появляется прокрутка
 * Без возможности редактирования
 */
package com.somewater.control
{
	import com.somewater.text.EmbededTextField;
	
	import fl.containers.ScrollPane;
	
	import flash.display.Sprite;

	public class TextBlock extends Sprite
	{
		public var textField:EmbededTextField;
		private var scroll:ScrollPane;
		//private var holder:Sprite;
		
		public function TextBlock()
		{
			super();
			
			scroll = new ScrollPane();
			addChild(scroll);
			
			textField = new EmbededTextField(EmbededTextField.MYRIAD,null,12,false,true,true);
			textField.width = 100;
			scroll.source = textField;
			
			//graphics.beginFill(0x0000FF);graphics.drawRect(0,0,100,100);
		}
		

		public function set text(value:String):void
		{
			textField.text = value;
			scroll.update();
		}
		public function get text ():String
		{
			return textField.text;
		}
		
		public function setSize(w:Number, h:Number):void{
			scroll.setSize(w,h);
			textField.width = w - 10;
			scroll.update();
		}
		
		override public function get width():Number{
			return scroll.width;
		}
		
		override public function set width(value:Number):void{
			scroll.width = value;
			textField.width - 10;
			scroll.update();
		}
		
		override public function get height():Number{
			return scroll.height;
		}
		
		override public function set height(value:Number):void{
			scroll.height = value;
			scroll.update();
		}
		
	}
}