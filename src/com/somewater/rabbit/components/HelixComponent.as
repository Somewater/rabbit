package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.core.TemplateManager;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.logic.SentientComponent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.util.GeomUtil;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;
	
	/**
	 * Необходим для подвижных существ, связанных с неподвижным объектом в мире
	 * (например, собака и будка)
	 * При старте и наличии @Spatial, создает в заданной точке карты
	 * entity типа shellType
	 */
	public class HelixComponent extends SentientComponent
	{
		/**
		 * Название template, отвечающего за создание раковины
		 */
		public var shellType:String;
		
		/**
		 * Ссылка на раковину
		 */
		public var shell:IEntity;
		
		/**
		 * Ссылка на Spatial-компонент раковины
		 */
		public var shellSpatial:IsoSpatial;
		
		/**
		 * Если величина больше 0, то компонент следит, чтобы персонаж
		 * не отодвишался от раковины более чем на leadLength тайлов
		 * (иначе останавливает персонаж Mover)
		 */
		public var leadLength:int = 0;
		
		
		private var destinationRef:PropertyReference;
		
		/**
		 * Массив из точек около раковины, чтобы идтик ней при натяжении поводка. 
		 * Если не удалось дойти до 1-й точки из данного массива, выбирается 2-я и так,
		 * пока массив не закончится
		 */
		private var helixNeighbourPointsQueue:Array = [];
		
		
		public function HelixComponent()
		{
			super();
			_priority = 1000000;
			destinationRef = new PropertyReference("@Mover.destination");
		}
		
		
		override protected function onAdd():void
		{
			if(shell == null)
				tryCreateShell();
			
			PBE.callLater(tryCreateShell);
			
			registerForTicks = leadLength > 0;
		}
		
		
		override protected function onReset():void
		{
			if(shell == null)
				tryCreateShell();
		}
		
		override public function analyze():void
		{
			// nothing
		}
		
		
		override public function onTick(deltaTime:Number):void
		{
			if(!_driving)
				checkLead();
		}
		
		
		/**
		 * Добавить на карту раковину, если уже добавлен @Spatial
		 * (а значит извесны начальные координаты существа в пространстве)
		 */
		private function tryCreateShell():void
		{
			if(shell)
				return;
			
			if(owner && owner.lookupComponentByName("Spatial"))
			{
				var position:Point = IsoSpatial(owner.lookupComponentByName("Spatial")).tile;
				
				if(position.x == int.MIN_VALUE || position.y == int.MIN_VALUE)
					return;// позиция @Spatial невалидна, видимо ее еще не задали
				
				shell = PBE.templateManager.instantiateEntity(shellType);
				if(shell)
				{
					shell.owningGroup = owner.owningGroup;
					shellSpatial = shell.lookupComponentByName("Spatial") as IsoSpatial; 
					if(shellSpatial)
					{
						shellSpatial.tile = position;
					}
				}
			}
		}
		
		
		/**
		 * При удалении "улитки", "раковина" тем не менее не уходит с карты
		 */
		override protected function onRemove():void
		{
			shell = null;
			shellSpatial = null;
		}
		
		
		
		/**
		 * Проверить, не превысил ли персонаж длину поводка leadLength
		 */
		protected function checkLead(...args):void
		{
			// если текущий компонент ведущий, не делаем проверку (т.е. он ведущий, когда ошибка уже была замечана
			// и улитка отправлена к раковине)
			if(!_driving && leadLength > 0 && shellSpatial)
			{
				var shellPos:Point = shellSpatial.position;
				var position:Point = IsoSpatial(owner.lookupComponentByName("Spatial")).position;
				var dist:Number = Math.sqrt((Math.pow(shellPos.x - position.x, 2) + Math.pow(shellPos.y - position.y, 2)));
				var elasticLeadLength:Number = leadLength + RandomizeUtil.rnd * (1 + leadLength - dist);
				if(dist	> elasticLeadLength)
				{
					// переставить персонажа, чтобы он не превышал длины поводка
					var prevPoss:Array = 
						GeomUtil.circlePartInrersections(shellPos, leadLength, shellPos, position);
					
//					if(prevPoss)
//					{
//						owner.setProperty(new PropertyReference("@Spatial.position"), prevPoss[0]);
//					}
					
					// выдать ведущему компоненту ошибку перемещения
					owner.setProperty(destinationRef, null);
					
					// самому стать ведущим компонентом
					_port(getSense({"position":position}));
				}
			}
		}
		
		override public function startAction(sense:SenseEvent):void
		{
			recreateHelixNeighbourPoints();
			moveToNextHelixNeighbourPoint();
		}
		
		private function moveToNextHelixNeighbourPoint():void
		{
			var tile:Point = helixNeighbourPointsQueue.shift();
			if(tile)
			{
				// tile вычислен относительно координат будки, перевычисляем его относительно глобальных координат карты
				tile.x += shellSpatial.tile.x;
				tile.y += shellSpatial.tile.y;
				IsoMover(owner.lookupComponentByName("Mover")).setDestination(tile, onMovindSuccess, onMovingError);
			}
			else
			{
				// до будки невозможно дойти ?
				throw new Error("Helix pathfinding error");
			}
		}
		
		private function onMovindSuccess():void
		{
			_port(null);
		}
		
		private function onMovingError():void
		{
			moveToNextHelixNeighbourPoint();
		}
		
		/**
		 * Генерирует очередь точек, близь будки
		 */
		private function recreateHelixNeighbourPoints():void
		{
			var tile:Point = shellSpatial.tile;
			var position:Point = IsoSpatial(owner.lookupComponentByName("Spatial")).tile;
			var dx:int = position.x - tile.x;
			var dy:int = position.y - tile.y;
			
			dx = dx > 0 ? 1: ( dx < 0 ? -1 : 0 );
			dy = dy > 0 ? 1: ( dy < 0 ? -1 : 0 );
			
			if(dx == 0)
			{
				// с середины по вертикали
				helixNeighbourPointsQueue = [
					new Point(0, dy),	new Point(-1, dy),	new Point(1, dy),
					new Point(-1, 0),						new Point(1, 0),
					new Point(-1, -dy),	new Point(1, -dy),	new Point(0, -dy)
				];
			}else if(dy == 0)
			{
				// с середины по горизонтали
				helixNeighbourPointsQueue = [
					new Point(dx, 0),	new Point(dx, -1),	new Point(dx, 1),
					new Point(0, -1),						new Point(0, 1),
					new Point(-dx, -1),	new Point(-dx, 1),	new Point(-dx, 0)
				];
			}else
			{
				// с угла
				helixNeighbourPointsQueue = [
					new Point(dx, dy),	new Point(dx, 0),	new Point(0, dy),
					new Point(-dx, dy),						new Point(dx, -dy),
					new Point(-dx, 0),	new Point(0, -dy),	new Point(-dx, -dy)
				];
			}
		}
	}
}