package com.somewater.rabbit.components
{
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.storage.Config;

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
		
		private var _carrot:int = 0;
		public function set carrot(value:int):void
		{
			if(value != _carrot)
			{
				if(value > _carrot)
					Config.application.play(Sounds.HARVEST, SoundTrack.GAME_HARVEST, true);
				_carrot = value;
			}
		}
		public function get carrot():int{ return _carrot; }
		
		public function set score(value:int):void{carrot = value;}
		public function get score():int {return carrot;}

		override public function set health(value:Number):void
		{
			if(value != _health)
			{
				if(_health > value)
					Config.application.play(Sounds.DAMAGE, SoundTrack.GAME_DAMAGE);
				_health = value;
				if(_health <= 0 && _owner)
				{
					owner.destroy();
				}
			}
		}
	}
}