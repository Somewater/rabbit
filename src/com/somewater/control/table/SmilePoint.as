package com.somewater.control.table
{
	import com.somewater.text.EmbededTextField;
	
	import flash.display.Sprite;
	
	public class SmilePoint extends CellRendererBase
	{
		private const DEFAULT_HEIGHT:int = 50;
		
		private var label:EmbededTextField;
		private var icon:Sprite;
		
		public function SmilePoint()
		{
			super();
			_height = DEFAULT_HEIGHT;
			
			label = new EmbededTextField(null,null,14);
			addChild(label);
		}
		
		override protected function draw():void{
			label.text = (_data>0?"+":"")+_data.toString();
			label.x = (_width - label.width)*0.5;
			label.y = 26;
			
			if (icon != null)
				if (contains(icon))
					removeChild(icon);
			if (_data>0)
				icon = new HistorySmile_good();
			else if (_data<0)
				icon = new HistorySmile_bad();
			else
				icon = new HistorySmile_normal();
			icon.x = _width*0.5;
			icon.y = 14;
			addChild(icon);
		}
		
		override public function get height():Number{
			return DEFAULT_HEIGHT;
		}
		
	}
}