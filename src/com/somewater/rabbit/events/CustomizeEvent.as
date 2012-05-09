package com.somewater.rabbit.events {
	import flash.display.MovieClip;
	import flash.events.Event;

	/**
	 * Сигнализирует, что на уровне созданы объекты, требующие кастомизации
	 */
	public class CustomizeEvent extends Event{

		public static const CUSTOMIZE_EVENT:String = 'customizeEvent';


		public static const TYPE_HOLE:String = 'hole';
		public static const TYPE_HOLE_CLICK:String = 'hole_click'

		/**
		 * Тип кастомного объекта
		 */
		public var customObjectType:String;

		/**
		 * Кто-то обработал событие, больше диспатчить нет нужды
		 */
		public var applyed:Boolean = false;

		/**
		 * Ссылка на клип, который нужно кастомизировать
		 */
		public var clip:MovieClip;

		public function CustomizeEvent(clip:MovieClip, customObjectType:String) {

			this.clip = clip;
			this.customObjectType = customObjectType;
			super(CUSTOMIZE_EVENT);
		}
	}
}
