package com.somewater.arrow {
	import flash.events.Event;

	/**
	 * События враппера соц. сети, собатия получения данных от соц. сети
	 */
	public class ArrowEvent extends Event{

		/**
		 * Соединение с локальной оберткой для api установлено (напримре, с враппером)
		 */
		public static const  CONNECTED_TO_API:String = 'connectedToApi';

		/**
		 * Приложение было установлено
		 */
		public static const APP_INSTALLED:String = 'appInstalled';

		/**
		 * Настройки приложения были изменены
		 */
		public static const PERMISSION_CHANGED:String = 'permissionChanged';

		/**
		 * Баланс пользоватля изменился
		 */
		public static const BALANCE_CHANGED:String = 'balanceChanged';

		/**
		 * Инициализировано соединение с api,
		 * приложение установлено и выставлены пермишны,
		 * загружены основные данные по пользователю
		 */
		public static const INITED:String = 'inited';

		/**
		 * Определено, что приложению не выставлены все необходимые пермишны
		 * (можно подписаться на событие и вызвать в листенере preventDefault чтобы отменить
		 * стандартное поведение - вызов функции IArrow#setPermissions)
		 */
		public static const PERMISSION_ERROR:String = 'permissionError';

		/**
		 * Определено, что приложение не установлено
		 * (можно подписаться на событие и вызвать в листенере preventDefault чтобы отменить
		 * стандартное поведение - вызов функции IArrow#install)
		 */
		public static const INSTALL_APP_ERROR:String = 'installAppError';

		/////

		/**
		 * Ответ от API (успешный)
		 */
		public static const REQUEST_SUCCESS:String = 'requestSuccess';

		/**
		 * Ошибка получения ответа от API
		 */
		public static const REQUEST_ERROR:String = 'requestError';

		/**
		 * hash страницы изменился
		 */
		public static const LOCATION_CHANGED:String = 'locationChanged';


		/**
		 * Название ошибки
		 */
		public var error:String;

		public var method:String;
		public var params:Object;
		public var flags:Object;

		public var response:Object;

		public function ArrowEvent(type:String) {
			super(type)
		}
	}
}
