package com.somewater.control.table
{
	import com.progrestar.storage.Const;
	
	import flash.display.Sprite;
	
	public class SignatureRender extends CellRendererBase
	{
		public function SignatureRender()
		{
			super();
		}
		
		private var lastSign:int = -1;// -1 значит еще ни разу не устанавливалось
		override protected function draw():void{
			if (lastSign != -1)
				Const.flushHolder(this);
			var icon:Sprite;
			
			if (_data == 1)
				icon =  new HistoryIcon_plus();
			else
				icon = new HistoryIcon_minus();
				
			icon.x = _width*0.5;
			icon.y = _height*0.5;
			
			addChild(icon);	
		}
		
	}
}