package com.somewater.rabbit.storage {
	import com.somewater.rabbit.xml.XmlController;

	import flash.display.MovieClip;

	import flash.geom.Point;

	/**
	 * Отвечает за различные типы бонусов, выдаваемые клинетом (и, синхронно, сервером)
	 * после успешного прохождения уровня
	 */
	public class RewardDef {

		public static const TYPE_SPECIAL:String = 'special';            // специальные, непризовые объекты поляны (нора)
		public static const TYPE_FAST_TIME:String = 'fast_time';    	// быстрое время прохождения уровня
		public static const TYPE_ALL_CARROT:String = 'all_carrots';     // собрано морковок (интегрально по уровням)
		public static const TYPE_CARROT_PACK:String = 'carrot_pack';    // собрано много морковок на уровне
		public static const TYPE_FAMILIAR:String = 'familiar';			// заходил несколько дней подряд
		public static const TYPE_POSTING:String = 'posting';            // запостил сообщения
		public static const TYPE_REFERER:String = 'referer';            // пригласил друзей (дается пригласившему (!!!))
		public static const TYPE_CONSOLING:String = 'consoling';        // утешительные призы

		private var _id:int;

		private var _type:String;
		private var _degree:int;
		public var template:XML;

		public function RewardDef(id:int, type:String, degree:int, template:XML) {

			this._id = id;
			this._type = type;
			this._degree = degree;
			this.template = template;
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

		public function get slug():String {
			return template..slug;
		}

		public function get name():String
		{
			return  Config.application.translate('REWARD_NAME_ID_' + this.id);
		}
	}
}
