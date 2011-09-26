package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.EntityComponent;
	
	import flash.events.Event;
	
	/**
	 * Genocide
	 * Выдают событие определенного типа, 
	 * если все контроллеры данного типа уничтожены
	 */
	public class GenocideComponent extends EntityComponent
	{
		public static const GENOCIDE:String = "genocide";
		
		
		private static var registrationNum:int = 0;
		
		public function GenocideComponent()
		{
			super();
		}
		
		
		override protected function onAdd():void
		{
			registrationNum++;
		}
		
		override protected function onRemove():void
		{
			registrationNum--;
			
			if(registrationNum == 0)
				PBE.callLater(onGenocide);// этот тик отработает нормально, в следующем тике миру придет конец
		}
		
		
		/**
		 * Все контроллеры данного типа уничтожены
		 */
		protected function onGenocide():void
		{
			PBE.levelManager.dispatchEvent(new Event(GenocideComponent.GENOCIDE));
		}
	}
}