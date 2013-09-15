package com.somewater.rabbit.creature {
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.components.CowardComponent;
	import com.somewater.rabbit.components.ObviousHarvesterComponent;
	import com.somewater.rabbit.managers.LevelConditionsManager;

	/**
	 * Во воерм собственно сбора морковки, тикает компонент страха, чтобы своевременно среагировать на кролика
	 */
	public class CrowHarvesterComponent extends ObviousHarvesterComponent{
		public function CrowHarvesterComponent() {
		}

		override public function action():void {
			// проверка, что поблизости нет кролика
			var coward:CowardComponent = owner.lookupComponentByName('Coward') as CowardComponent;
			if(coward)
			{
				coward.analyze();
			}

			// если всё еще не испугались, жуем морковку дальше
			if(this._driving)
				super.action();
		}

		override protected function applyHarvest(harvest:Array):void {
			super.applyHarvest(harvest);
			if(LevelConditionsManager.instance){
				var harvested:Array = [];
				for each(var e:IEntity in harvest)
					if(e.owningGroup == null)
						harvested.push(e);
				LevelConditionsManager.instance.addNonHeroHarvested(harvested);
			}
		}
	}
}
