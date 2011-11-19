package com.somewater.rabbit.storage {
	import com.somewater.rabbit.xml.XmlController;

	import flash.geom.Point;

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
		public var template:XML;

		public function RewardDef(id:int, type:String, degree:int) {

			this._id = id;
			this._type = type;
			this._degree = degree;
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

		public function get size():Point
		{
			return XmlController.instance.calculateRewardSize(id);
		}
	}
}
