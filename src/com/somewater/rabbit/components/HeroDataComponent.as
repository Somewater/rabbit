package com.somewater.rabbit.components
{
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.events.HeroHealthEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.util.AnimationHelper;

	/**
	 * Хранение различных констант, присущих игроку
	 * #Hero.Data
	 */
	public dynamic class HeroDataComponent extends DataComponent
	{
		public static var instance:HeroDataComponent;

		/**
		 * Флаг означает, что нельзя менять здоровье персонажа, т.е. он под защитой, елси флаг больше нуля
		 * (количество означает сколько паверапов протекта применено)
		 */
		public var protectedFlag:int = 0;

		/**
		 * Какая скорость может быть максимальной
		 */
		public var maxSpeed:Number = 8;

		public function HeroDataComponent()
		{
			super();
			
			if(instance)
				throw new Error("Singletone");
			
			instance = this;
		}
		
		override protected function onRemove():void
		{
			instance = null;
			super.onRemove();
		}

		public static var lastCarrotValue:int;
		private var _carrot:int = 0;
		public function set carrot(value:int):void
		{
			if(value != _carrot)
			{
				if(value > _carrot)
					Config.application.play(Sounds.HARVEST, SoundTrack.GAME_HARVEST, true);
				_carrot = lastCarrotValue = value;
			}
		}
		public function get carrot():int{ return _carrot; }
		
		public function set score(value:int):void{carrot = value;}
		public function get score():int {return carrot;}

		override public function set health(value:Number):void
		{
			if(value != _health)
			{
				if(_health > value && _owner)
				{
					Config.application.play(Sounds.DAMAGE, SoundTrack.GAME_DAMAGE);
					AnimationHelper.instance.blink((owner.lookupComponentByName('Render') as ProxyIsoRenderer).displayObject, 0, 0.8);
				}
				if(_owner){
					_owner.eventDispatcher.dispatchEvent(new HeroHealthEvent(_health, value));
				}
				_health = value;
			}
		}
	}
}