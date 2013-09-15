package com.somewater.rabbit {

	/**
	 * Константы имен статов
	 */
	public class Stat {

		public static const LOADER_INITED:String = 'loader_inited';// прелоадер инициализирован

		public static const APP_STARTED:String = 'app_started';// приложение успешно стартовало

		public static const LEVEL_STARTED:String = 'level_started';// стартовал уровень

		public static const LEVEL_PASSED:String = 'level_passed';// уровень пройден
		public static const LEVEL_FAILED:String = 'level_failed';// уровень пройден

		public static const FRIENDS_INVITED:String = 'friends_invited';// кнопка "пригласи друзей" нажата

		public static const POSTING:String = 'posting';// завершен какой-либо постинг

		public static const MY_REWARDS_OPENED:String = 'my_rewards_opened';// были открыты собственные реварды игрока

		public static const FRIEND_REWARDS_OPENED:String = 'friend_rewards_opened';// были открыты реварды (поляна) друга

		public static const LEVELS_PAGE_OPENED:String = 'levels_page_opened';// страница "уровни" была открыта

		public static const ABOUT_PAGE_OPENED:String = 'about_page_opened';// страница "об игре" была открыта

		public static const EXCEPTION_CATCHED:String = 'exception_catched';// отловлена ошибка в процессе игры (ведущая к перезагрузке уровня)

		public static const NEW_USER_REGISTERED:String = 'new_user_registered';// юзер впервые внесн в БД (новый игрок)

		public static const OFFER_HARVESTED:String = 'offer_harvested';// юзер собрал оффер (уникальный, который ранее не собирал)

		public static const LIVECARD_AD:String = 'livecard_ad';

		public static const SHOP:String = 'shop';
		public static const WND_SHOP:String = 'wnd_shop';
		public static const WND_BUY_COINS:String = 'wnd_buy_coins';
		public static const WND_NEIGHBOURS:String = 'wnd_neighbours';
		public static const WND_NEED_ENERGY:String = 'wnd_need_energy';

		public static const ON_PAUSE:String = 'on_pause';
		public static const ON_PAUSE_POWERUP:String = 'on_powerup_pause';
		public static const ON_POWERUP_USE:String = 'on_powerup_use';
		public static const ON_POWERUP_BUY:String = 'on_powerup_buy';

		public static const ERROR_INACCESSIBLE_LEVEL:String = 'error_inacc_level';
		public static const ERROR_INVALID_CARROT_HARVEST_VALUE:String = 'error_wrong_carrot_harvest';
		public static const ERROR_SERVER_LOGIC_DESYNCRONIZE_LEVEL:String = 'error_desync_level';
		public static const ERROR_LEVEL_START:String = 'error_level_start';
		public static const ERROR_SERVER_LOGIC_DESYNCRONIZE_REWARD:String = 'error_desync_reward';
		public static const ERROR_ASSET_LOADING:String = 'error_asset_loading';
		public static const ERROR_XML_LOADING:String = 'error_xml_loading';
		public static const ERROR_SERVER_RESPONSE:String = 'error_server_response';
		public static const ERROR_INIT_REQUEST:String = 'error_init_request';
		public static const ERROR_STATIC_LOADING:String = 'error_static_loading';
		public static const ERROR_MONEY_DISCARDING:String = 'error_money_discarding';
	}
}
