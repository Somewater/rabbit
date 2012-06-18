package com.somewater.rabbit.net {
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.somewater.net.IServerHandler;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.storage.ILocalDb;
	import com.somewater.storage.LocalDb;

	/**
	 * Эмулирует работу сервера для тестов (для standalone игры)
	 */
	public class LocalServerHandler implements IServerHandler{

		private var uid:String;
		private var key:String;
		private var net:int;

		private var globalHandlersSuccess:Array = [];
		private var globalHandlersError:Array = [];

		private var user:LocalDb;
		private var config:Object;

		private const METHOD_TO_HANDLER:Object = {
				'stat':stat
				,'init':initHandler
				,'levels/complete':levelComplete
				,'rewards/move':moveReward
				,'tutorial/inc':incrementTutorial
				,'offer/add':addOffer
				,'money/buy':buyMoney
				,'items/purchase':purchaseItems
				,'items/use':useItem
				,'customize/purchase':purchaseCustomizeItems
			};

		public function LocalServerHandler(config:Object) {
			this.config = config;
			user = new LocalDb('user');
			user.autosave = false;
		}

		public function init(uid:String, key:String, net:int):void {
			this.uid = uid;
			this.key = key;
			this.net = net;
		}

		public function set base_path(value:String):void {
		}

		public function get base_path():String {
			return "";
		}

		public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
			Config.callLater(callImmediately, [method, data, onComplete, onError, base_path, params]);
		}

		private function callImmediately(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
			var handler:Function = METHOD_TO_HANDLER[method];
			var globalHandlers:Array;
			var response:Object;
			if(handler != null)
			{
				response = handler(data);
				if(onComplete != null)
					onComplete(response);
				globalHandlers = globalHandlersSuccess.slice();
			}
			else
			{
				response = {error:'E_IO'}
				if(onError != null)
					onError(response);
				globalHandlers = globalHandlersError.slice();
			}
			for each(var f:Function in globalHandlers)
				f(response);
		}

		public function resetUid(uid:String):void {
			this.uid = uid;
		}

		public function addGlobalHandler(success:Boolean, callback:Function):void {
			var handlers:Array = success ? globalHandlersSuccess : globalHandlersError;
			if(handlers.indexOf(callback) == -1)
				handlers.push(callback);
		}

		public function toJson(object:Object):String {
			return JSON.encode(object);
		}

		public function fromJson(json:String):Object {
			return JSON.decode(json);
		}

		public function encrypt(str:String):String {
			// на любую строку выдает "hello" - таким образом, проверка авторизации всегда работает верно
			return MD5.encrypt(str);
		}

		protected function userToJson():Object
		{
			var field:String;
			var data:Object;
			var uid:String = user.get('uid') as String;
			if(uid == null || uid.length == 0)
			{
				data = allocateInitUserData(false)
				for(field in data)
					user.set(field, data[field]);
				user.save();
			}

			data = {};
			for(field in allocateInitUserData(true))
				data[field] = user.get(field);
			return data;
		}

		protected function allocateInitUserData(onlyFields:Boolean):Object
		{
			return {
				"level":1,
				"score":0,
				"uid":"1-" + int(Math.random() * 10000000),
				"stars":0,
				"day_counter":0,
				"friends_invited":0,
				"money":config['init_user']['money'],
				"postings":0,
				"level_instances":{}, 	// "1":{"c":10,"t":10,"v":16,"s":3}
				"rewards":{},			// "20":{"id":20,"x":4,"y":0,"n":1}
				"offer_instances":{},
				"customize":{},
				"offers":0,
				"roll":0,
				"tutorial":0,
				"items":config['init_user']['items'] 				// "201:1,202:1,203:1"
			}
		}

		private function getUserItems():Object
		{
			var items:Array = [];
			for each(var el:String in (user.get('items') as String).split(','))
			{
				var pair:Array = el.split(':');
				items[pair[0]] = pair[1];
			}
			return items;
		}

		private function setUserItems(items:Object):void
		{
			var itemsStr:String = '';
			for(var id:String in items)
				itemsStr += (itemsStr.length ? ',' : '') + int(id) + ':' + int(items[id]);
			user.set('items', itemsStr);
			user.save();
		}

		private function getCustomizeItems():Object
		{
			return user.get('customize');
		}

		private function setCustomizeItems(items:Object):void
		{
			user.set('customize', items);
			user.save();
		}

		//////////////////////////////////////////////////////////
		//                                  		            //
		//				METHODS IMPLEMENTATION					//
		//                 			                            //
		//////////////////////////////////////////////////////////

		/**
		 * "init"
		 * response['user']['new']
		 * response['user']
		 * response['friends']
		 * response['unixtime']
		 */
		protected function initHandler(data:Object):Object {
			var userData:Object = userToJson();
			return {
					"rewards":[] // показать окно, что такие-то реварды получены off-line (без сервера такое маловозмоно :))
					,"unixtime":new Date().time * 0.001
					,"user":userData
					,"friends":[]
			};
		}

		/**
		 * "level/complete"
		 * {'levelInstance':levelInstanceToJson(levelInstance, {}), items: itemsStr}
		 * response['levelInstance']['succes']
		 * response['user']
		 */
		protected function levelComplete(data:Object):Object
		{
			// добавить новый левел в юзера, добавить реварды левела, снять потраченные паверапы. И сохранить
			//"level_instances":{}, 	// "1":{"c":10,"t":10,"v":16,"s":3}
			//"rewards":{},			// "20":{"id":20,"x":4,"y":0,"n":1}

			var level_instances:Object = user.get('level_instances');
			var rewards:Object = user.get('rewards');
			var level:Object = data['levelInstance'];

			level_instances[level['number']] = {"c":level['carrotHarvested'],"t":level['timeSpended'],"v":level['version'],"s":level['stars']};
			for each(var r:Object in level['rewards'])
			{
				rewards[r['id']] = {"id":r['id'],"x":r['x'],"y":r['y'],"n":level['number']};
			}
			user.set('items', data['items']);
			var levelNumber:int = 0;
			for(var levelStr:String in level_instances){if(int(levelStr) > levelNumber)levelNumber = int(levelStr)};
			user.set('level', levelNumber + 1);
			user.set('level_instances', level_instances);
			user.set('rewards', rewards);
			user.save();

			var userData:Object = userToJson();
			return {
				"levelInstance":{"success":true},
				"user":userData
			}
		}

		protected function incrementTutorial(data:Object):Object
		{
			if(user.get('tutorial') < data['tutorial'])
			{
				user.set('tutorial', data['tutorial'])
				user.save();
			}
			return {tutorial: user.get('tutorial')};
		}

		protected function moveReward(data:Object):Object
		{
			var rewards:Object = user.get('rewards');
			var moved_rewards:Array = [];
			for each(var r:Object in data['rewards'])
			{
				rewards[r['id']].x = r.x;
				rewards[r['id']].y = r.y;
				moved_rewards.push(rewards[r['id']]);
			}
			return {rewards: moved_rewards};
		}

		protected function addOffer(data:Object):Object
		{
			throw new Error('Not implemented');
		}

		protected function buyMoney(data:Object):Object
		{
			throw new Error('Not implemented in netword #' + net);
		}

		protected function purchaseItems(data:Object):Object
		{
			var items:Object = getUserItems();
			for each(var el:String in (data['purchase'] as String).split(','))
			{
				var pair:Array = el.split(':');
				items[pair[0]] = int(items[pair[0]] || 0) + int(pair[1]);
			}
			var userMoney:int = int(user.get('money')) - int(data['prise']);
			if(userMoney < 0)
				return {error:'E_NO_MONEY'}
			user.set('money', userMoney);
			setUserItems(items);
			return {success: 1, user:userToJson()};
		}

		protected function useItem(data:Object):Object
		{
			var items:Object = getUserItems();
			var quantity:int = items[data['item_id']]
			quantity--;
			if(quantity < 0)
				return {error:'E_NO_ITEM'}
			items[data['item_id']] = quantity;
			setUserItems(items);
			return {success: true, quantity: quantity};
		}

		protected function stat(data:Object):Object{
			return {success: true}
		}

		protected function purchaseCustomizeItems(data:Object):Object
		{
			var items:Object = {};
			var el:String;
			for each(el in (data['purchase'] as String).split(','))
			{
				var pair:Array = el.split(':');
				items[pair[0]] = int(pair[1]);
			}
			var userMoney:int = int(user.get('money')) - int(data['prise']);
			if(userMoney < 0)
				return {error:'E_NO_MONEY'}
			user.set('money', userMoney);
			var userCustomize:Object = getCustomizeItems();
			for(el in items)
				userCustomize[el] = items[el];
			setCustomizeItems(userCustomize);
			return {success: 1, user:userToJson()};
		}
	}
}
