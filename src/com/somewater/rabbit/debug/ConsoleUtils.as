package com.somewater.rabbit.debug
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.debug.Console;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoLayer;
	import com.somewater.rabbit.storage.Config;
	
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	
	import nl.demonsters.debugger.MonsterDebugger;

	public class ConsoleUtils
	{
		public static function initCommands():void
		{
			Console.registerCommand("info", spatialinfo, "Entitys properties");
			
			Console.registerCommand("recursivesorting", recursiveSorting, "Sort all objects for recursively algorythm");
		
			Console.registerCommand("minimap", MiniMap.switcher, "Show/hide minimap, 'minimap 3' set refresh every 3 seconds");
			
			Console.registerCommand("p", playPause, "Play/Payse game execution");
			
			Console.registerCommand("inspect", inspect, "Inspect stage in MonsterDebugger");
			
			
		
			PBE.inputManager.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private static function spatialinfo(...args):void
		{
			var i:int;
			var j:int;
			for(var s:String in args)
			{
				var entity:IEntity = PBE.lookupEntity(args[s]);
				if(entity)
				{
					var spatial:IsoSpatial = entity.getProperty(new PropertyReference("@Spatial"));
					var mover:IsoMover = entity.getProperty(new PropertyReference("@Mover"));
					var render:IsoRenderer = entity.getProperty(new PropertyReference("@Render"));
					
					if(spatial)
					{
						var p:Point = spatial.position; 
						
						Logger.info(ConsoleUtils,
							"info", " about \"" + args[s] + "\"");
						Logger.print(ConsoleUtils, "x:" + p.x.toFixed(2) + ", y:" + p.y.toFixed(2) + 
							", passMask=" + spatial.passMask.toString(2) + ", occupyMask=" + spatial.occupyMask.toString(2));
						if(mover && mover.destination)
						{
							var destPath:Array = mover.destinationPath;
							Logger.print(ConsoleUtils, "destination: " + mover.destination + 
								", p-mode=" + mover.patienceMode + ", c-patience=" + mover.currentPatience.toFixed(2) + ", c-astar=" + mover.currentAstarRequestNum);
							for(i = 0;i<destPath.length;i++)
								Logger.print(ConsoleUtils, i + ") " + destPath[i]); 
						}
						Logger.print(ConsoleUtils, "	");
					}
				}
			}
		}
		
		private static function playPause(...args):void
		{
			if(Config.game.isTicking)
				Config.game.pause();
			else
				Config.game.start();
		}
		
		private static function onKeyDown(e:KeyboardEvent):void
		{
			if(e.keyCode == String("L").charCodeAt())
			{
				Console.processLine(Console.lastCommandLine);
			}
			if(e.keyCode == 19)// PAUSE/BREAK
			{
				playPause();
			}
			if(e.keyCode == String("C").charCodeAt())
			{
				Console.processLine("clear");
			}
		}
		
		
		private static function inspect(...args):void
		{
			//MonsterDebugger.inspect(Rabbit.instance);
			MonsterDebugger.inspect(PBE.scene);
		}
		
		
		
		private static function recursiveSorting(...args):void
		{
			IsoLayer(PBE.scene.getLayer(0)).markDirty();
		}
	}
}