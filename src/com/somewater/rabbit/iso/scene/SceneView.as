package com.somewater.rabbit.iso.scene
{
	import com.pblabs.rendering2D.ui.SceneView;
	import com.somewater.rabbit.storage.Config;
	
	public class SceneView extends com.pblabs.rendering2D.ui.SceneView
	{
		public function SceneView()
		{
			super();
		}
		
		public function setSize(w:Number, h:Number):void
		{
			
			graphics.clear();
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, w, h);
			
			CONFIG::debug
			{
				graphics.lineStyle(1, 0x00FF00, 0.2);
				var i:Number;
				for(i = 0;i<=w;i += Config.TILE_WIDTH)
				{
					graphics.moveTo(i, 0);
					graphics.lineTo(i, h);
				}
				for(i = 0;i<=h;i += Config.TILE_HEIGHT)
				{
					graphics.moveTo(0, i);
					graphics.lineTo(w, i);
				}
			}
		}
		
		override public function set width(value:Number):void
		{
			super.width = value;
			setSize(width, height);
		}
		
		
		
		override public function set height(value:Number):void
		{
			super.height = value;
			setSize(width, height);
		}
	}
}