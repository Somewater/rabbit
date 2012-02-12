package com.somewater.rabbit.application {
	import com.somewater.rabbit.events.OfferEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.OfferDef;
	import com.somewater.rabbit.storage.UserProfile;

	public class OfferManager {

		private static var _instance:OfferManager;
		private var offersById:Array = [];

		public static function get instance():OfferManager
		{
			if(_instance == null)
				_instance = new OfferManager();
			return _instance;
		}

		public function OfferManager() {
			Config.application.addEventListener(OfferEvent.OFFER_EVENT, onOfferHarvested);
		}

		private function onOfferHarvested(event:OfferEvent):void {
			CONFIG::debug
			{
				trace("[OFFER] " + event.x + " " + event.y);
			}
			var offerId:int = paramsToId(event.x,  event.y, Config.game.level.number)
			if(UserProfile.instance.getOfferInstanceById(offerId) != null)
			{
				CONFIG::debug
				{
					throw new Error('User already has offer x=' + event.x + ' y=' + event.y + ' level=' + Config.game.level.number)
				}
				return;
			}

			var offer:OfferDef = getOfferById(offerId);
			if(offer == null)
			{
				CONFIG::debug
				{
					throw new Error('Offer id ' + offerId + ' does not exist');
				}
				return;
			}

			// добавить юзеру и послать запросо на сервер
			UserProfile.instance.addOfferInstance(offer);
			AppServerHandler.instance.addOffer(offer);
		}

		public function createOffer(xml:XML):void
		{
			var offer:OfferDef = new OfferDef(xml);
			offer.id = paramsToId(offer.x,  offer.y, offer.level);
			if(offersById[offer.id])
				throw new Error('Offer already added: x=' + offer.x + ', y=' + offer.y + ', level=' + offer.level);
			offersById[offer.id] = offer;
		}

		public function getOfferById(id:int):OfferDef
		{
			return offersById[id];
		}

		public function getOfferByParams(x:int,  y:int, level:int):OfferDef
		{
			return offersById[paramsToId(x, y, level)]
		}

		public function levelOffers(level:int,  unharvestedOnly:Boolean = false):Array
		{
			var offers:Array = [];
			for each(var offer:OfferDef in offersById)
				if(offer.level == level && (
						unharvestedOnly == false
						|| UserProfile.instance.getOfferInstanceById(offer.id) == null))
				{
					offers.push(offer);
				}
			return offers;
		}

		public static function paramsToId(x:int, y:int, level:int):int {
			return 1000000000 + level * 1000000 + x * 1000 + y;
		}

		/**
		 * @return Array [x, y, level]
		 */
		public static function idToParams(id:int):Array
		{
			var str:String = id.toString();
			if(str.length < 10)
				throw new Error('Bad offer id format: ' + id);
			return [int(str.substr(4,3)), int(str.substr(7,3)), int(str.substr(1,3))]
		}

		/**
		 * Новый (обычный) уровень стартовал, следует добавить офферы на сцену
		 * @param level
		 */
		public function onLevelStarted(level:LevelDef):void {
			for each(var offer:OfferDef in levelOffers(level.number, true))
				Config.game.createOffer(offer.x, offer.y);
		}
	}
}
