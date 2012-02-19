package com.somewater.rabbit.components
{
	import com.pblabs.engine.components.DataComponent;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.storage.PowerupInfo;

	/**
	 * Таким компонентом должен обладать любой собираемый объект со сложным поведением при сборе
	 * Данный компонент содержит информацию: можно ли собирать персонаж, 
	 * сколько персонаж принесет урожая и т.д.
	 */
	public class HarvestableComponent extends DataComponent
	{
		private var _score:int = 1;
		private var _harvestable:Boolean = true;
		
		public function HarvestableComponent()
		{
			super();
		}
		
		/**
		 * Можно ли собирать данный компонет
		 */
		public function harvestable(harvester:IEntity):Boolean
		{
			if(_harvestable)
				return true;
			else
			{
				// если компонент в общем случае нельзя собрать, всёже разрешаем это сделать собирателю, у которого есть павреап защиты
				// (кролик под паверапом умеет собирать злых морковок)
				var powerupController:PowerupControllerComponent = harvester.lookupComponentByType(PowerupControllerComponent) as PowerupControllerComponent;
				if(powerupController)
				{
					for each (var pinfo:PowerupInfo in powerupController.temporaryPowerups)
						if(pinfo.data.protection)
							return true;
				}

				return false;
			}
		}
		
		public function set harvestableFlag(value:Boolean):void
		{
			_harvestable = value;
		}
		
		/**
		 * Сколько очков дает компонент при сборе
		 */
		public function get score():int
		{
			return _score;
		}
		
		public function set score(value:int):void
		{
			_score = value;
		}
	}
}