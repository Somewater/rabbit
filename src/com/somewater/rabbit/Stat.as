package com.somewater.rabbit {

	/**
	 * Константы имен статов
	 */
	public class Stat {

		public static const LOADER_INITED:String = 'loader_inited';// прелоадер инициализирован

		public static const APP_STARTED:String = 'app_started';// приложение успешно стартовало

		public static const LEVEL_STARTED:String = 'level_started';// стартовал уровень

		public static const LEVEL_PASSED:String = 'level_passed';// уровень пройден

		public static const FRIENDS_INVITED:String = 'friends_invited';// кнопка "пригласи друзей" нажата

		public static const POSTING:String = 'posting';// завершен какой-либо постинг

		public static const MY_REWARDS_OPENED:String = 'my_rewards_opened';// были открыты собственные реварды игрока

		public static const FRIEND_REWARDS_OPENED:String = 'friend_rewards_opened';// были открыты реварды (поляна) друга

		public static const LEVELS_PAGE_OPENED:String = 'levels_page_opened';// страница "уровни" была открыта

		public static const ABOUT_PAGE_OPENED:String = 'about_page_opened';// страница "об игре" была открыта

		public static const EXCEPTION_CATCHED:String = 'exception_catched';// отловлена ошибка в процессе игры (ведущая к перезагрузке уровня)

		public static const NEW_USER_REGISTERED:String = 'new_user_registered';// юзер впервые внесн в БД (новый игрок)
	}
}
