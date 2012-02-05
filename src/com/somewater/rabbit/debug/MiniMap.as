package com.somewater.rabbit.debug
{
	import com.astar.BasicTile;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.TickedComponent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	internal class MiniMap extends TickedComponent
	{
		private static var instance:MiniMap;
		
		private const WIDTH:int = 100;
		private const HEIGHT:int = 100;
		
		private var _visible:Boolean = false;
		private var holder:Sprite;
		private var bmp:BitmapData;
		
		private var refreshRating:Number = 3;
		private var tickAccumulator:Number = 10000;
		
		public function MiniMap()
		{
			super();
			
			registerForTicks = false;
		}
		
		public static function switcher(...args):void
		{
			var refresh:Number = args[0];
			
			if(instance == null)
			{
				instance = new MiniMap();
				instance.visible = true;
			}else{
				instance.visible = !instance._visible || refresh;
			}

			if(refresh)
				instance.refreshRating = refresh;
			else
				instance.refreshRating = 0.1;
		}
		
		public function set visible(value:Boolean):void
		{
			if(value != _visible)
			{
				_visible = value;
				if(_visible)
				{
					if(holder == null)
						createInterface();
					PBE.mainStage.addChild(holder);
					holder.x = PBE.mainStage.stageWidth - WIDTH;
					registerForTicks = true;
				}else{
					PBE.mainStage.removeChild(holder);
					registerForTicks = false;
				}
			}
		}
		
		
		private function createInterface():void
		{
			holder = new Sprite();
			holder.alpha = 0.8;
			
			bmp = new BitmapData(WIDTH, HEIGHT, true, 0);
			var bitmap:Bitmap = new Bitmap(bmp);
			holder.addChild(bitmap);
		}
		
		override public function onTick(deltaTime:Number):void
		{
			tickAccumulator += deltaTime;
			if(tickAccumulator >= refreshRating)
			{
				redraw();
				tickAccumulator = 0;
			}
		}
		
		
		private function redraw():void
		{
			var g:Graphics = holder.graphics;
			var colors:Array = [0x00FF00, 0x0000FF, 0xFF00FF, 0xFF0000];
			
			g.clear();
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,WIDTH,HEIGHT);
			/*
			var boxWidth:Number = WIDTH /  IsoSpatialManager.instance.width;
			var boxHeight:Number  = HEIGHT / IsoSpatialManager.instance.height;
			
			
			var spatials:Array = IsoSpatialManager.instance.mapSpatial;
			
			var xLength:int = spatials.length;
			for(var i:int = 0;i<xLength;i++)
			{
				var line:Array = spatials[i];
				var yLength:int = line.length;
				for(var j:int = 0;j<yLength;j++)
				{
					var objects:Array = line[j];
					if(objects.length)
					{
						g.beginFill(colors[objects.length - 1]);
						g.drawRect(i * boxWidth, j * boxHeight, boxWidth, boxHeight);
					}
				}
			}
			*/
			
			var boxWidth:Number = HEIGHT / IsoSpatialManager.instance.height;
			var boxHeight:Number  = WIDTH /  IsoSpatialManager.instance.width;
			
			var mapPath:Array = IsoSpatialManager.instance.mapPath._map;
			var mapSpatial:Array = IsoSpatialManager.instance.mapSpatial;
			var yLength:int = mapPath.length;
			for(var i:int = 0;i<yLength;i++)
			{
				var line:Array = mapPath[i];
				var xLength:int = line.length;
				for(var j:int = 0;j<xLength;j++)
				{
					var tile:BasicTile = line[j];
					if(tile && tile.mask != 0xFFFFFFFF)
					{
						if(mapSpatial[j][i].length > 1)
						{
							var names:String = '';
							for each(var isp:IsoSpatial in mapSpatial[j][i])
								names += ',' + isp.owner.debugName;
							trace('X: ' + j + ', Y: ' + i + "\t" + names);
							g.beginFill(0);
						}
						else
						g.beginFill(colors[0xFFFFFFFF - tile.mask]);
						g.drawRect(j * boxHeight, i * boxWidth, boxWidth, boxHeight);
					}
				}
			}
		}
	}
}