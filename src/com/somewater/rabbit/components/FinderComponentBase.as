package com.somewater.rabbit.components
{
	import com.pblabs.components.stateMachine.PropertyTransition;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.core.PBSet;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.logic.SentientComponent;
	
	import flash.debugger.enterDebugger;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * Обладает базовыми функциями, служащими для поиска какого-то типа
	 * Ищет жертву victim, заданную одним (или несколькими) из 3-х способов:
	 * - victimName
	 * - victimSet
	 * - victionType
	 * Если какие либо из них не заданы (== NULL), поиск по данному критерию не производится
	 * 
	 * ВНИМАНИЕ: должен быть расширен, самостоятельно не применяется
	 */
	public class FinderComponentBase extends SentientComponent
	{
		/**
		 * Имя entity, которого надо искать
		 */
		public var victimName:String;
		
		/**
		 * Набор, entities из которого пригодны для поиска
		 */
		public var victimSet:String;
		
		/**
		 * Тип, который можно искать
		 */
		public var victionType:ObjectType;
		
		
		/**
		 * Радиус, по которому производится поиск
		 */
		public var searchRadius:Number = 1;
		
		protected var spatialPropertyRef:PropertyReference = new PropertyReference("@Spatial");
		
		
		
		/**
		 * Ссылка на @Spatial, для ускорений поиска позиций и т.д.
		 */
		private var spatialRef:IsoSpatial;
		private var victimNameSpatialRef:IsoSpatial;
		private var victimSetRef:PBSet;
		
		public function FinderComponentBase()
		{
			super();
		}
		
		
		/**
		 * Произвести поиск, согласно критериям среди переменных victim*
		 * @return Array of IsoSpatial
		 */
		protected function searchVictims(radius:Number = NaN):Array
		{
			if(isNaN(radius))
				radius = searchRadius;
			var victims:Array = [];
			var l:int;
			var i:int;
			var addedVictims:Dictionary = new Dictionary();
			
			if(spatialRef == null)
				spatialRef = owner.getProperty(spatialPropertyRef);
			
			// точная позиция, а не tile ! иначе поиск радиуса атаки будет не совсем верный
			var position:Point = spatialRef.centerPosition;
			
			// радиус в квадрате
			var sqrRadius:Number = radius * radius;
			
			if(victimName)
			{
				if(victimNameSpatialRef == null)
				{
					var victimNameRef:IEntity = PBE.nameManager.lookup(victimName);
					if(victimNameRef)
						victimNameSpatialRef = victimNameRef.getProperty(spatialPropertyRef);
				}
				
				if(victimNameSpatialRef)
				{
					if(victimNameSpatialRef.isRegistered)
						addVictim(victimNameSpatialRef, true);
					else
						victimNameSpatialRef = null;
				}
			}
			
			
			if(victimSet)
			{
				if(victimSetRef == null)
					victimSetRef = PBE.nameManager.lookup(victimSet);
				
				if(victimSetRef)
				{
					l = victimSetRef.length;
					for(i = 0;i<l;i++)
						addVictim(IEntity(victimSetRef.getItem(i)).lookupComponentByName("Spatial"), true);
				}
			}
			
			if(victionType)
			{
				var queryResult:Array = []
				if(IsoSpatialManager.instance.queryCircle(position, radius, victionType, queryResult))
				{
					l = queryResult.length;
					
					// TODO: на самом деле queryCircle делает 
					// не совсем точную геометрически, "жадную" проверку
					
					for(i = 0;i<l;i++)
						addVictim(queryResult[i], false);
				}
			}
			
			return victims;
			
			// попытаться добавить victim, подозреваемый в том, что его можно атаковать
			// checkRadius - сделать проверку на "близость" от атакующего
			function addVictim(victim:IsoSpatial, checkRadius:Boolean):void
			{
				if(addedVictims[victim]) 
					return;
				
				if(checkRadius)
				{
					var tempPos:Point = victim.centerPosition;
					if((Math.pow(tempPos.x - position.x, 2) + Math.pow(tempPos.y - position.y, 2)) > sqrRadius)
					{
						// слишком далеко
						return;
					}
				}
				
				victims.push(victim);
				addedVictims[victim] = true;
			}
		}
		
		
		
		/**
		 * Обнулить ссылки, созданные для ускорения процессов searchVictim
		 */
		override protected function onRemove():void
		{
			super.onRemove();
			
			victimNameSpatialRef = null;
			victimSetRef = null;
		}
	}
}