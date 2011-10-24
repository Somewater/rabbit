package com.somewater.rabbit.storage {
	/**
	 * Отвечает за различные типы бонусов, выдаваемые клинетом (и, синхронно, сервером)
	 * после успешного прохождения уровня
	 */
	public class RewardDef {

		public static const TYPE_FAST_TIME:String = 'FAST_TIME';
		public static const REWARD_FAST_TIME:RewardDef = new RewardDef(TYPE_FAST_TIME)

		/**
		 * Тип, за какое событие дается награда
		 */
		public var type:String;

		/**
		 * Ступень "улучшения" по сравнению с наградами одинакового типа. Чем выше => тем лучше
		 */
		public var degree:int;

		/**
		 * Для нескольких наград одного тапа и одной ступени, позволяет их отличать друг от друга
		 */
		public var index:int;

		public function RewardDef(type:String, degree:int = 0, index:int = 0) {
			this.type = type;
			this.degree = degree;
			this.index = index;
		}
	}
}
