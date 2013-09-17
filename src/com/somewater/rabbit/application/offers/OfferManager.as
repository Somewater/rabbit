package com.somewater.rabbit.application.offers {
	import com.somewater.rabbit.application.*;
	import com.somewater.rabbit.events.OfferEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.OfferDef;
	import com.somewater.rabbit.storage.UserProfile;

	public class OfferManager {

		private static var _instance:OfferManager;
		private var offersById:Array = [];
		private var _quantity:int = 0;
		private var levelToOfferTypeCache:Object = {};
		private var _types:Array;

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
			_quantity++;
		}

		/**
		 * Офферы в данный момент активны
		 * (но возможно уже собраны игроком)
		 */
		public function get active():int
		{
			return _quantity;
		}

		/**
		 * Сколько следует собрать офферов для получения приза
		 */
		public function prizeQuantityByType(type:int):int
		{
			return 20;
		}

		public function allOffersHarvested():Boolean {
			for each(var type:int in this.types){
				if(UserProfile.instance.offersByType(type) < prizeQuantityByType(type)){
					return false;
				}
			}
			return true;
		}

		public function get types():Array {
			if(!_types){
				_types = [];
				var addedTypes:Object = {};
				for each(var offer:OfferDef in offersById){
					if(!addedTypes[offer.type]){
						_types.push(offer.type);
						addedTypes[offer.type] = true;
					}
				}
				_types.sort(Array.NUMERIC);
			}
			return _types;
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
				Config.game.createOffer(offer.x, offer.y, {type: offer.type});
		}

		public function offerTypeByLevel(level:int):int {
			if(levelToOfferTypeCache[level] === undefined){
				for each(var offer:OfferDef in offersById){
					if(offer.level == level){
						levelToOfferTypeCache[level] = offer.type;
						break;
					}
				}
			}
			return int(levelToOfferTypeCache[level]);
		}
	}
}
