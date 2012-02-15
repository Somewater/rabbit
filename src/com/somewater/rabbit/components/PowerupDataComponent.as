package com.somewater.rabbit.components {
	import com.somewater.rabbit.iso.IsoRenderer;

	import flash.display.DisplayObject;

	/**
	 * Приклеплен к конкретному паверапу и описывает свойства паверапа
	 */
	public class PowerupDataComponent extends DataComponent{

		/**
		 * Сколько миллисекунд действует паверап
		 */
		public var time:int = 0;

		/**
		 * На какую величину увеличивается скорость
		 */
		public var speedAdd:Number = 0;

		/**
		 * Паверап создает защитное поле вокруг персонажа
		 */
		public var protection:Boolean = false;

		/**
		 * На сколько миллисекунд увеличивает паверап время, отведенное под уровень
		 */
		public var timeAdd:int = 0;

		/**
		 * Имя ассета иконки паверапа
		 */
		public var icon:String;

		public function PowerupDataComponent() {
			_health = 0;// по умолчанию это свойство конфига нулевое
		}

		public function get slug():String
		{
			if(icon == null)
				icon = (owner.lookupComponentByName('Render') as IsoRenderer).slug;
			return icon;
		}

		override protected function onAdd():void {
			super.onAdd();

			// инициализация параметров
			this.slug;
		}
	}
}
