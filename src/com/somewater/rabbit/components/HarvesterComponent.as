package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.logic.SentientComponent;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Собирает "урожай" заданного типа и подсчитывает собранное количество
	 */
	public class HarvesterComponent extends SentientComponent
	{
		protected static const HARVEST_DETECTED:String = "harvestDetected";
		
		public var harvestType:ObjectType;// тип, который данный контроллер собирает
		protected var tempQueryRectangle:Rectangle;// объект для передачи запросу queryRectangle
		protected var scoreRef:PropertyReference;
		
		public var sense:Boolean = true;// ведет ли себя контроллер по всем правилам SentientComponent, либо как обычный компонент (нужно для Hero)
		
		public var harvestTime:int = 2000;// время сбора (для компонентов, применяющих sense) в мс
		private var harvestStart:Number;// вермя старта сбора в мс
		private var senseHarvest:Array;// объекты для сбора урожая, которые разрешено собрать компоненту
		
		public function HarvesterComponent()
		{
			super();
			
			tempQueryRectangle = new Rectangle();
			scoreRef = new PropertyReference("@Data.score");
		}
		
		override protected function onAdd():void
		{
			owner.eventDispatcher.addEventListener(IsoMover.TILE_REACHED, onTileReached);
		}
		
		override protected function onRemove():void
		{
			owner.eventDispatcher.removeEventListener(IsoMover.TILE_REACHED, onTileReached);
		}
		
		
		protected function onTileReached(e:Event):void
		{
			searchHarvest();
		}


		protected function searchHarvest():void
		{
			// самое время посомтреть, нет ли в новом тайле морковочки
			var harvestSpatials:Array = [];

			var newTile:Point = IsoSpatial(owner.lookupComponentByName("Spatial")).tile;
			tempQueryRectangle.x = newTile.x;
			tempQueryRectangle.y = newTile.y
				
			if(IsoSpatialManager.instance.queryRectangle(tempQueryRectangle, harvestType, harvestSpatials))
			{
				var i:int;
				var harvest:Array = [];
				for(i = 0;i<harvestSpatials.length;i++)
				{
					var entity:IEntity = EntityComponent(harvestSpatials[i]).owner;
					if(entity != owner)// самого себя не стоит собирать
						harvest.push(entity);
				}
				
				if(harvest.length)
				{
					if(sense)
					{
						// попросить разрешения на сбор
						_port(getSense(harvest, HARVEST_DETECTED));
					}
					else
						applyHarvest(harvest);
				}
			}
		}
		
		override public function analyze():void
		{
			// TODO: а можно бы и поискать урожай, для приличия, сука ленивая
		}
		
		
		override public function startAction(sense:SenseEvent):void
		{
			super.startAction(sense);
			senseHarvest = sense.data as Array;
			harvestStart = PBE.processManager.virtualTime;
			owner.setProperty(new PropertyReference("@Render.state"), States.ATTACK);
			owner.setProperty(new PropertyReference("@Mover.destination"), null);// заставить остановиться 
		}
		
		override public function action():void
		{
			if(PBE.processManager.virtualTime - harvestStart >= harvestTime)
			{
				applyHarvest(senseHarvest);
				_port(null);
			}
		}
		
		override public function breakAction():void
		{
			super.breakAction();
			
			senseHarvest = null;
		}


		/**
		 * Внимание! Оверрайдится в HeroHarvesterComponent.
		 * При изменении нижеследующией функции, внести критические изменения в оверрайд
		 * @param harvest
		 */
		protected function applyHarvest(harvest:Array):void
		{
			var scoreAdd:int = 0;
			for(var i:int = 0;i<harvest.length;i++)
			{
				var entity:IEntity = harvest[i];
				var harvestable:HarvestableComponent = entity.lookupComponentByType(HarvestableComponent) as HarvestableComponent;
				if(harvestable == null || harvestable.harvestable(_owner))
				{
					scoreAdd += (harvestable ? harvestable.score : 1);
					entity.destroy();
				}
			}
			
			if(scoreAdd)
			{
				var score:* = owner.getProperty(scoreRef);
				if(score !== null)
					owner.setProperty(scoreRef, score + scoreAdd);
			}
		}
	}
}