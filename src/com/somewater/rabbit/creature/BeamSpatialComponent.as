package com.somewater.rabbit.creature
{
	import com.astar.BasicTile;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.entity.IEntityComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.astar.IThinkWall;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Обеспечивает логику поведения бревна
	 * Бревно занимает 3 тайла, центральный тайл проходим только в определенном направлении (непроходим?)
	 * Один из крайних тайлов бревна проходим, а другой - непроходим
	 */
	final public class BeamSpatialComponent extends IsoSpatial implements IThinkWall
	{
		/**
		 * "возраст" компонента
		 */
		protected var age:uint;
		
		/**
		 * ссылка на рендерер
		 */
		protected var renderStateRef:PropertyReference;
		protected var renderRotationRef:PropertyReference;
		
		/**
		 * Состояние
		 * -1 упор налево
		 * 0 в процессе изменения
		 * 1 упор направо
		 */
		protected var sideMode:int;
		
		/**
		 * Как воздействует на карту "проходимая" область бревна
		 * т.е. даже будучи опущенным, бревно не дает пройти некоторым персонажам
		 * 
		 * Поднятые участки бревна оцениваются по параметру occupyMask
		 */
		public var partialOccupyMask:uint;
		
		/**
		 * аргумент для проведения запроса 
		 * IsoSpatialManager.instance.queryRectangle
		 */
		private var box:Rectangle = new Rectangle();
		
		
		
		/**
		 * Флаг, означающий были ли персонажи на бревне 
		 * при прошлой проверке наличия персоажей на бревне
		 */
		private var lastCheckHasGuests:Boolean = false;
		
		/**
		 * Персонажи, которые находятся на бревне
		 * (ссылки на их IsoRenderer)
		 */
		private var guestsIsoRenderers:Array = [];

		/**
		 * Стартовый наклон бревна. Если 0, то рандомный
		 */
		public var initialSide:int;
		
		public function BeamSpatialComponent()
		{
			sideMode = 0;
			age = RandomizeUtil.rnd * 10;// чтобы у разных одновременно созданных инстансов была десинхронизация
			
			super();
			
			occupyMaskRule = 2;
			
			renderStateRef = new PropertyReference("@Render.state");
			renderRotationRef = new PropertyReference("@Render.rotation");
		}
		
		
		public function getOccupyMask(x:int, y:int):int
		{
			// если бревно в равновесии, оно полностью проходимо
			if(sideMode == 0)
				return partialOccupyMask
			// позиции запрашиваемого тайла в локальных координатах бревна
			x = x - int(_position.x);
			//y =y - int(_position.y);
			
			if(x == 1)
			// середина проходима, если на бревне кто-то есть
				return lastCheckHasGuests?partialOccupyMask:occupyMask;
			// края проходимы/непроходимы в зависимости от положения бревна 
			else if((x == 0 && sideMode == -1) || (x == 2 && sideMode == 1))
				return partialOccupyMask
			else
				return occupyMask;
		}
		
		public function hook(tile:BasicTile, spatial:IsoSpatial, startTile:Point):Boolean
		{
			//return (~getOccupyMask(tile.x, tile.y) & spatial.passMask) == spatial.passMask;
			var verticalMovement:Boolean = int(startTile.y - tile.y) != 0;// кто то движется через бревно поперек, а не вдоль
			var mask:uint;
			if(sideMode == 0)
			{
				// mask = verticalMovement?occupyMask:partialOccupyMask// раньше авновесное бревно было полностью проходимо

				// если бревно в равновесии, оно полностью проходимо для персонажей на бревне и непроходимо для любых других
				var travellerRenderComponent:IEntityComponent = spatial.owner ? spatial.owner.lookupComponentByName('Render') : null;
				mask = travellerRenderComponent && guestsIsoRenderers.indexOf(travellerRenderComponent) != -1 ? partialOccupyMask : occupyMask;
			}
			else
			{
				// позиции запрашиваемого тайла в локальных координатах бревна
				var x:int = tile.x - int(_position.x);
				
				if(x == 1)
					// середина проходима, если на бревне кто-то есть
					mask = verticalMovement?occupyMask:partialOccupyMask;
					// края проходимы/непроходимы в зависимости от положения бревна 
				else if((x == 0 && sideMode == -1) || (x == 2 && sideMode == 1))
					mask = partialOccupyMask
				else
					mask = occupyMask;
			}
			return (~mask & spatial.passMask) == spatial.passMask;
		}
		
		override protected function onAdd():void
		{
			if(sideMode == 0)
			{
				// самостоятельно "придумываем" координату для бревра, чтоб не возникло ошибки в связи с тем, что координата бревна непроинициализирована
				if(this._position.x == int.MIN_VALUE || this._position.y == int.MIN_VALUE)
				{
					this._position.x = 0;
					this._position.y = 0;
				}
				changeSide(initialSide ? initialSide : RandomizeUtil.rnd > 0.5?1:-1);
			}
			super.onAdd();
			registerForTicks = true;
		}
		
		override public function onTick(deltaTime:Number):void
		{
			//super.onTick(deltaTime);
			
			//if(lastCheckHasGuests || age++ % 2 == 0)
			//{
				// каждый десятый тик делаем проверку
				box.x = _position.x;
				box.y = _position.y;
				box.width = _size.x;
				box.height = _size.y;
				var guests:Array = [];
				IsoSpatialManager.instance.queryRectangle(box, null, guests);
				
				// спустить в исходное состояние песонажей, которые ранее числились на бревне
				while(guestsIsoRenderers.length)
					(guestsIsoRenderers.pop() as IsoRenderer).positionOffset = new Point();
				
				// запрос вернет как минимум 1 объект - само бревно
				if(guests.length > 1)
				{
					// кто-то шастает по бревну
					var beamCenterX:Number = _position.x + _size.x * 0.5;// позиция центра бревна
					var rotation:Number = owner.getProperty(renderRotationRef, -1) / BeamRendererComponent.ANGLE_AMP;// в долях!
					var vector:Number = 0;
					for(var i:int = 0;i<guests.length;i++)
					{
						var guest:IsoSpatial = guests[i];
						if(guest == this)
							continue;
						
						var x:Number = guest._position.x - beamCenterX;
						vector += x;
						
						// позиционируем guest
						var x_abs:Number = (x < 0? -x:x);
						var isoRender:IsoRenderer = IsoRenderer(guest.owner.lookupComponentByName("Render"));
						var positionOffset:Point = isoRender.positionOffset;
						positionOffset.y = 
							x_abs >= 1 ? 0 : (-0.5 + 0.5 * x * rotation);
										/*    -0.5 высота пенька
										 *    0.5 коэф.  поднятия от повотора бревна
										 */
						isoRender.positionOffset = positionOffset;
						guestsIsoRenderers.push(isoRender);
					}
					
					if(Math.abs(vector) < 0.2)
						changeSide(0);
					else
						changeSide(vector > 0?1:-1);
					
					lastCheckHasGuests = true;
					
				}else{
					// на бревне никого. если в прошлый раз тоже никого не было, пересчет положения бревна делать не нужно
					if(lastCheckHasGuests)
					{
						// на бревне ранее кто-то был, а теперь нет - заблочить центр
						lastCheckHasGuests = false;
						IsoSpatialManager.instance.refreshPathTile((int(_position.y) << 16) + int(_position.x) + 1);
						if(sideMode == 0)
							changeSide(RandomizeUtil.rnd > 0.5 ? 1 : -1);// нарушаем баланс
					}
				}
			//}
		}
		
		
		protected function changeSide(side:int):void
		{
			sideMode = side;
			owner.setProperty(renderStateRef, side == 0?BeamRendererComponent.STATE_BALANCE:(side == -1?BeamRendererComponent.STATE_LEFT:BeamRendererComponent.STATE_RIGHT));
			
			// обновить карту проходимости
			var tileX:int = _position.x;
			var tileY:int = int(_position.y) << 16;
			IsoSpatialManager.instance.refreshPathTile(tileY + tileX);
			tileX++;
			IsoSpatialManager.instance.refreshPathTile(tileY + tileX);
			tileX++;
			IsoSpatialManager.instance.refreshPathTile(tileY + tileX);
		}
	}
}