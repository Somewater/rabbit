package com.somewater.rabbit.ui
{
	import com.pblabs.engine.PBE;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Point;

	/**
	 * Текущая реализация поддерживает ширину экрана до 1800 пикселей
	 */
	public class HorizontRender extends DisplayObjectRenderer
	{
		protected static const BARRIER_WIDTH:int = 900;
		protected static const HILL_WIDTH:int = 985;
		
		// забор
		private var barrierHolder:Sprite;
		
		// все зверюшки на горизонте (волк, деревья, солнце...)
		private var hillHolder:Sprite;
		
		// линия горизонта (в виде кривой)
		private var horizontGroundHolder:Sprite;
		
		private var mainHolder:Sprite;
		
		
		private var barriers:Array = [];
		
		private var minBarrierPos:int = int.MAX_VALUE;// комбинация, которая при инициализации в любом случае приведет к созданию забора
		private var maxBarrierPos:int = int.MIN_VALUE;
		
		private var hills:Array = [];
		
		private var minHillPos:int = int.MAX_VALUE;// комбинация, которая при инициализации в любом случае приведет к созданию забора
		private var maxHillPos:int = int.MIN_VALUE;
		
		private var sky:DisplayObjectContainer;
		private var skyDefaultWidth:int;
		private var skyDefaultHeight:int;
		private var sun:DisplayObject;
		
		private var _darkness:Number = 0;
		private var sun_y:int;
		
		public function HorizontRender()
		{
			super();
			
			mainHolder = new Sprite();
			
			horizontGroundHolder = new Sprite();
			mainHolder.addChild(horizontGroundHolder);
			
			hillHolder = new Sprite();
			mainHolder.addChild(hillHolder);
			
			barrierHolder = new Sprite();
			mainHolder.addChild(barrierHolder);
			
		}
		
		
		private function onResize(e:Event):void
		{
			onReset();
		}
		
		
		override protected function onAdd():void
		{
			displayObject = mainHolder;
			registerForUpdates = false;
			PBE.lookupEntity("SceneDB").eventDispatcher.addEventListener(IsoSpatialManager.EVENT_SCENE_RESIZE, onResize);
			IsoCameraController.getInstance().addCallback(onSceneMove);
			InitializeManager.bindRestartLevel(onLevelRestarted);
		}
		
		
		override protected function onRemove():void
		{
			PBE.lookupEntity("SceneDB").eventDispatcher.removeEventListener(IsoSpatialManager.EVENT_SCENE_RESIZE, onResize);
			IsoCameraController.getInstance().removeCallback(onSceneMove);
			InitializeManager.unbindRestartLevel(onLevelRestarted);
			super.onRemove();
			
			clearHill();
		}

		private function onLevelRestarted():void {
			// снова делаем светлый горизонт
			darkness = 0;
		}
		
		
		/**
		 * Переустанавливает длину забора и горизонта (и прочие эл-ты) согласно изменениям
		 */
		override protected function onReset():void
		{
			clearHill();
			recreateHill();
		}

		private function clearHill():void
		{
			if(sky)
			{
				if(sky.parent)
					sky.parent.removeChild(sky);
				if(sun.parent)
					sun.parent.removeChild(sun);
				sky = null;
				sun = null;
			}

			var i:int = 0;
			for(i = 0;i<barriers.length;i++)
				DisplayObject(barriers[i]).parent.removeChild(barriers[i]);
			barriers = [];
			for(i = 0;i<hills.length;i++)
				DisplayObject(hills[i]).parent.removeChild(hills[i]);
			hills = [];
			minBarrierPos = int.MAX_VALUE;
			maxBarrierPos = int.MIN_VALUE;
			minHillPos = int.MAX_VALUE;
			maxHillPos = int.MIN_VALUE;
		}

		private function recreateHill():void
		{
			if(!sky)
			{
				sky = Lib.createMC("rabbit.SkyHorizont");
				skyDefaultWidth = sky.width;
				skyDefaultHeight = sky.height;
				sun = Lib.createMC("rabbit.SunHorizont");
				horizontGroundHolder.addChild(sky);
				horizontGroundHolder.addChild(sun);
				//RabbitGame.instance.addChildAt(sky, 0);
				//RabbitGame.instance.addChildAt(sun, 0);
			}
			sky.y = -Config.HORIZONT_HEIGHT * Config.TILE_HEIGHT;
			sky.scaleX = Config.WIDTH / skyDefaultWidth;
			sun.x = sky.x + 0.3506798 * sky.width;
			sun.y = sun_y = sky.y + 0.3216216 * sky.height;
		}
		
		
		override public function onFrame(elapsed:Number):void
		{
			//super.onFrame(elapsed);
		}

		/**
		 * Сила затемнения гориизонта
		 */
		public function set darkness(value:Number):void
		{
			if(_darkness != value)
			{
				_darkness = value;

				if(_darkness < 0.01)
				{
					if(horizontGroundHolder) horizontGroundHolder.transform.colorTransform = new ColorTransform();
				}
				else
				{
					var v:Number = 1 - value * 0.7;
					if(horizontGroundHolder) horizontGroundHolder.transform.colorTransform = new ColorTransform(v,v,v);
				}

				if(sun) sun.y = sun_y + (value * Config.TILE_HEIGHT * 2);
			}
		}

		public function get darkness():Number
		{
			return _darkness;
		}
		
		protected function onSceneMove(shift:Point):void
		{
			var shift_x:int = -shift.x;
			if(shift_x < 0) shift_x = 0;
			horizontGroundHolder.x = shift_x;

			checkAndCreateBarriers(shift_x);
			checkAndCreateHill(shift_x);
		}
		
		protected function createHillDisplayObject():DisplayObject
		{
			var hill:DisplayObjectContainer = Lib.createMC("rabbit.Hill");
			var randomTreesAll:int;
			var randomTrees:int = randomTreesAll = Math.random() * 4 + 3;
			var lastTreePos:int = 100;
			while(randomTrees >= 0)
			{
				var tree:DisplayObject = Lib.createMC("rabbit.HillTree_" + (Math.random() > 0.5?"0":"1"));
				hill.addChild(tree);
				tree.y = -25 * Math.random() - 10;
				lastTreePos = lastTreePos + Math.random() * (HILL_WIDTH / (1 + randomTreesAll) * 0.75);
				if(randomTrees == 0 || lastTreePos + 100 > HILL_WIDTH)
				{
					tree.x = HILL_WIDTH;
					break;
				}
				else
					tree.x = lastTreePos;
				lastTreePos += (HILL_WIDTH / (1 + randomTreesAll) * 0.25);
				randomTrees--;
			}
			return hill
		}

		protected function checkAndCreateBarriers(shift_x:int):void
		{
			var barrier:DisplayObject;
			var i:int;

			if(shift_x < minBarrierPos)
			{
				// слева область без забора
				minBarrierPos = Math.floor(shift_x / BARRIER_WIDTH) * BARRIER_WIDTH;
				var createBarrier:Boolean = true;
				for(i = 0;i<barriers.length || createBarrier;i++, createBarrier = false)
				{
					barrier = barriers[i];
					if(!barrier)
					{

						barrier = Lib.createMC("rabbit.Barrier");
						barrierHolder.addChild(barrier);
						barriers.push(barrier);
					}
					maxBarrierPos = minBarrierPos + i * BARRIER_WIDTH;
					barrier.x = maxBarrierPos;
					maxBarrierPos += BARRIER_WIDTH;
				}
			}
			if(shift_x + Config.WIDTH > maxBarrierPos)
			{
				// справа область без забора
				// попробовать пернести 1-дну заборину слева направо (если заборин 3 штуки)
				if(barriers.length > 2)
				{
					barrier = barriers.shift();
					minBarrierPos += BARRIER_WIDTH;
				}
				else
				{
					// создать новую заборину
					barrier = Lib.createMC("rabbit.Barrier");
					barrierHolder.addChild(barrier);
				}
				barrier.x = minBarrierPos + barriers.length * BARRIER_WIDTH;
				barriers.push(barrier);
				maxBarrierPos = minBarrierPos + barriers.length * BARRIER_WIDTH;
			}
		}

		protected function checkAndCreateHill(shift_x:int):void
		{
			var hill:DisplayObject;
			var i:int;

			// логика холмов практически идентична логике заборов. Однако, к холмам добавляются деревья, холдмы на паренте лежат в порядке следования по оси x
			if(shift_x < minHillPos)
			{
				// слева область без забора
				minHillPos = Math.floor(shift_x / HILL_WIDTH) * HILL_WIDTH;
				var createHill:Boolean = true;
				for(i = 0;i<hills.length || createHill;i++, createHill = false)
				{
					hill = hills[i];
					if(!hill)
					{
						hill = createHillDisplayObject();
						hills.push(hill);
					}
					hillHolder.addChildAt(hill, 0);
					maxHillPos = minHillPos + i * HILL_WIDTH;
					hill.x = maxHillPos;
					maxHillPos += HILL_WIDTH;
				}
			}
			if(shift_x + Config.WIDTH > maxHillPos)
			{
				// справа область без забора
				// попробовать пернести 1-дну заборину слева направо (если заборин 3 штуки)
				if(hills.length > 2)
				{
					hill = hills.shift();
					minHillPos += HILL_WIDTH;
				}
				else
				{
					// создать новую заборину
					hill = createHillDisplayObject();
				}
				hillHolder.addChildAt(hill, 0);
				hill.x = minHillPos + hills.length * HILL_WIDTH;
				hills.push(hill);
				maxHillPos = minHillPos + hills.length * HILL_WIDTH;
			}
		}
	}
}