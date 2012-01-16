package com.somewater.rabbit.components
{
	import com.pblabs.engine.entity.EntityComponent;

	/**
	 * Хранение различных констант, присущих существам в игре
	 * @Data
	 */
	public dynamic class DataComponent extends EntityComponent
	{
		
		/**
		 * Т.е. здоровье измеряется не в процентах (от 100), а в долях
		 */
		protected var _health:Number = 1;
		
		public function DataComponent()
		{
			this.score = 0;
		}
		
		
		/**
		 * Здоровье персонажа. Если уменьшается в 0, персонаж умерает
		 */
		public function set health(value:Number):void
		{
			if(value != _health)
			{
				_health = value;
				if(_health <= 0 && _owner)
				{
					owner.destroy();
				}
			}
		}
		
		
		public function get health():Number
		{
			return _health;
		}
		
		
		public function toString():String
		{
			var data:String = "";
			var o:Object = this;
			for(var name:String in o)
				data += "				" + name + "->" + o[name] + "\n";
			
			return "[Data \n" + data + "			]"
		}
	}
}