package com.somewater.rabbit.components {

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

		public function PowerupDataComponent() {
			_health = 0;// по умолчанию это свойство конфига нулевое
		}
	}
}
