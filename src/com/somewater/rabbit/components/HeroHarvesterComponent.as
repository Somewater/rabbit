package com.somewater.rabbit.components {
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.decor.PopupEffectFactory;

	/**
	 * Издает звуки, эффекты и т.д. при сборе морковок
	 */
	public class HeroHarvesterComponent extends HarvesterComponent{

		private var positionRef;

		public function HeroHarvesterComponent() {
			positionRef = new PropertyReference('@Spatial.position');
		}

		/**
		 * Аналогично базовой функции, но также издает звуки
		 * @param harvest
		 */
		override protected function applyHarvest(harvest:Array):void
		{
			var scoreAdd:int = 0;
			for(var i:int = 0;i<harvest.length;i++)
			{
				var entity:IEntity = harvest[i];
				var harvestable:HarvestableComponent = entity.lookupComponentByType(HarvestableComponent) as HarvestableComponent;
				if(harvestable == null || harvestable.harvestable(_owner))
				{
					scoreAdd += (harvestable ? harvestable.score : 1);

					// создать попап эффекта
					PopupEffectFactory.createEffect('rabbit.CarrotBonusAnimation', entity.getProperty(positionRef), this.owner);

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
