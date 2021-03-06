package com.somewater.rabbit {

	/**
	 * Класс приянтых в игре звуковых дорожек
	 * КОнцепция такова: есть несколько одновременно звучащих дорожк.
	 * Если стартует звук на дорожке, на которой уже звучал какой-то звук,
	 * старый звук стопится и играет новый.
	 * Иначе новый звук играет вместе с остальными звуками, играющими на других дорожках
	 */
	public class SoundTrack {

		/**
		 * Дорожка для фоновой музыки
		 */
		public static var MUSIC:String = 'music';

		public static var INTERFACE:String = 'interface';

		public static var GAME_HARVEST:String = 'game_harvest';
		public static var GAME_DAMAGE:String = 'game_damage';
	}
}
