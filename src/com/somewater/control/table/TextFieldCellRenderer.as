package com.somewater.control.table
{
	import com.somewater.text.TruncatedTextField;
	
	public class TextFieldCellRenderer extends CellRendererBase implements ICellRenderer
	{
		public var label:TruncatedTextField;
		private var PADDING:int = 2;
		
		public function TextFieldCellRenderer(font:String="Tahoma", color:*=null, size:int=12, bold:Boolean=false, _label:Boolean=true, align:String="left",forseSmooth:Boolean = true)
		{
			super();
			label = new TruncatedTextField(font, color, size, bold, _label, align, forseSmooth);
			addChild(label);
		}
		
		/**
		 * Кординирует и отрисовывает, согласно уже заданным координатам. размерам и данным
		 */
		override protected function draw():void{
			setText(_data);
			if (!_data.hasOwnProperty("align")){
				label.x = (_width - label.textWidth) * 0.5;
				label.y = (_height - label.textHeight) * 0.5 - 2;// KLUDGE		
			}
					
		}
		
		protected function setText(data:Object):void{
			if (data is String)
				label.htmlText = data.toString();
			else
				// задание расширенного формата текста
				if (data != null){
					if (data.text != null)label.htmlText = data.text;
					if (data.bold != null) label.bold = data.bold;
					if (data.size != null) label.size = data.size;
					if (data.color != null) label.color = data.color;
					if (data.align != null){
						if (data.align == "left")
							label.x = PADDING;
						if (data.align == "center")
							label.x = (_width - label.textWidth) * 0.5;
						if (data.align == "right")
							label.x = _width - label.textWidth - PADDING;
					}
				}
		}
		
		override protected function resize():void{
			label.width = _width;
			label.height = _height;
			super.resize();
		}

	}
}