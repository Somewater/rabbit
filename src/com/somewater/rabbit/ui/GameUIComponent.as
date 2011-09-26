package com.somewater.rabbit.ui
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.components.HeroDataComponent;
	import com.somewater.rabbit.managers.InitializeManager;
	
	public class GameUIComponent extends PBObject implements ITickedObject
	{
		private static var created:Boolean = false;
		
		/**
		 * Ссылка на компонент, хранящий данные игрока
		 */
		private var heroDataRef:HeroDataComponent;
		
		public function GameUIComponent()
		{
			super();
			
			initialize("Interface");
			PBE.processManager.addTickedObject(this, -1000000);// после всех игровых
			
			created = true;
			
			InitializeManager.bindRestartLevel(onLevelRestarted);
		}
		
		
		private function onLevelRestarted():void
		{
			// перевести все конторолы в исходное положение
		}
		
		
		public function onTick(deltaTime:Number):void
		{
			if(heroDataRef == null)
			{
				var hero:IEntity = PBE.lookupEntity("Hero");
				if(hero)
				{
					heroDataRef = hero.lookupComponentByName("Data") as HeroDataComponent;
				}
			}
			
			if(heroDataRef == null)
				return;
		}
		
		
		public static function recreate():void
		{
			if(created == false)
				new GameUIComponent();
		}
	}
}