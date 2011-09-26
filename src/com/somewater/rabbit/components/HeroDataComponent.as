package com.somewater.rabbit.components
{
	/**
	 * Хранение различных констант, присущих игроку
	 * #Hero.Data
	 */
	public dynamic class HeroDataComponent extends DataComponent
	{
		public static var instance:HeroDataComponent;
		
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
		
		private var _carrot:int;
		public function set carrot(value:int):void
		{
			if(value != _carrot)
			{
				_carrot = value;
			}
		}
		public function get carrot():int{ return _carrot; }
		
		public function set score(value:int):void{carrot = value;}
		public function get score():int {return carrot;} 
	}
}