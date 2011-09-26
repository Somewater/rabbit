package com.somewater.control.table
{
	import flash.text.TextFieldAutoSize;
	
	public class TextFieldCellRendererResized extends TextFieldCellRenderer
	{
		private const PADDING:int = 5;
		private const VPADDING:int = 3;// отсутп возниает только снизу
		
		public function TextFieldCellRendererResized(font:String="Tahoma", color:Object = null, size:int=12, bold:Boolean=false, _label:Boolean=true, align:String="left", forseSmooth:Boolean=true)
		{
			super(font, color, size, bold, _label, align, forseSmooth);
			//label.background = true;
			label.multiline = true;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.height = 20;
			label.x = PADDING;
		}
		
		override public function set width(value:Number):void{
			super.width = value;
		}
		
		override protected function resize():void{			
			super.resize();
			label.width = _width - PADDING*2;
			label.height = _height - VPADDING;
		}

		override public function set height(value:Number):void{
			// nothing
		}
		
		override public function get width():Number{
			return label.width + PADDING*2;
		}
		
		override public function get height():Number{
			return label.height + VPADDING;
		}
		
		override protected function draw():void{
			setText(_data);
			/*if (!_data.hasOwnProperty("align")){
				label.x = (_width - label.textWidth) * 0.5;
				label.y = (_height - label.textHeight) * 0.5 - 2;// KLUDGE		
			}*/
					
		}
		
	}
}