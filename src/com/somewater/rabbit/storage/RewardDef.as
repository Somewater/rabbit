package com.somewater.rabbit.storage {
	/**
	 * Отвечает за различные типы бонусов, выдаваемые клинетом (и, синхронно, сервером)
	 * после успешного прохождения уровня
	 */
	public class RewardDef {

		public static const TYPE_FAST_TIME:String = 'fast_time';
		public static const TYPE_ALL_CARROT:String = 'all_carrots';
		public static const TYPE_CARROT_PACK:String = 'carrot_pack';
		public static const TYPE_SPECIAL:String = 'special';

		private var _id:int;

		private var _type:String;
		private var _degree:int;
		private var _index:int;

		public function RewardDef(id:int, type:String, degree:int, index:int) {

			this._id = id;
			this._type = type;
			this._degree = degree;
			this._index = index;
		}

		/**
		 * Уникальный id (соответствует уникальности по type,degree,index)
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Тип, за какое событие дается награда
		 */
		public function get type():String
		{
			return _type;
		}

		/**
		 * Ступень "улучшения" по сравнению с наградами одинакового типа. Чем выше => тем лучше
		 */
		public function get degree():int
		{
			return _degree;
		}

		/**
		 * Для нескольких наград одного тапа и одной ступени, позволяет их отличать друг от друга
		 */
		public function get index():int
		{
			return _index;
		}
	}
}
