package com.somewater.rabbit.application {
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.windows.PendingRewardsWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.OfferDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;
	import com.somewater.utils.Helper;

	/**
	 * Прокси между IServerHandler и логикой приложения
	 */
	public class AppServerHandler {

		protected static var _instance:AppServerHandler;

		private var handler:IServerHandler;

		public static function get instance():AppServerHandler
		{
			if(_instance == null)
				_instance = new AppServerHandler();
			return _instance;
		}

		public function initRequest(gameUser:UserProfile, onComplete:Function, onError:Function):void
		{
			handler = new ServerReceiver(Config.loader.serverHandler, ['init']);
			if(Config.loader.basePath && Config.loader.basePath.length > 0)
				handler.base_path = Helper.basePath(Config.loader.basePath) + '/';

			var appFriends:Array = [];
			var appFriendsIds:Array = [];
			var appFriendsById:Array = [];
			var appfriendsSocial:Array = Config.loader.hasFriendsApi ? Config.loader.getAppFriends() : [];
			for(var s:String in appfriendsSocial)
			{
				appFriends.push(appfriendsSocial[s])
				appFriendsIds.push(SocialUser(appfriendsSocial[s]).id);
				appFriendsById[SocialUser(appfriendsSocial[s]).id] = appfriendsSocial[s];
			}

			var startRequestTime:Number = new Date().time;

			var params:Object = {"user":gameUserToJson(gameUser, {}), 'friendIds': appFriendsIds};
			if(Config.loader.referer && Config.loader.referer.length && Config.loader.referer != Config.loader.getUser().id){
				params["referer"] = Config.loader.referer;
				var autoNeighboursPostings:Array = ['fip', 'lpp', 'rp'];
				var su:SocialUser = Config.loader.getCachedUser(Config.loader.referer);
				if(su && su.isFriend && Config.loader.postingCode && autoNeighboursPostings.indexOf(String(Config.loader.postingCode[0])) != -1){
					params['add_neighbour'] = true;
				}
			}

			handler.call("init", params,
				function(response:Object):void{
					if(response && response['user'] && response['user']['new'])
						Config.stat(Stat.NEW_USER_REGISTERED);

					UserProfile.instance.msDelta = response['unixtime'] * 1000 - (new Date().time + startRequestTime) / 2;
					response['user'] = jsonToGameUser(response['user'], gameUser);
					var gameUsersFriends:Array = [];
					for each(var friendJson:Object in response['neighbours'])
					{
						var gameUserFriend:GameUser = jsonToGameUser(friendJson,
								RabbitApplication(Config.application).createGameUser(appFriendsById[friendJson['uid']] as SocialUser));
						gameUsersFriends.push(gameUserFriend);
						gameUser.addNeighbour(gameUserFriend);

					}
					response['neighbour_requests'];
					response['friends'] = gameUsersFriends;
					onComplete && onComplete(response);
				}, onError);
		}

		public function onLevelPassed(user:GameUser, levelInstance:LevelInstanceDef, onComplete:Function = null, onError:Function = null):void
		{
			var itemsStr:String = '';
			for(var id:String in UserProfile.instance.items)
				itemsStr += (itemsStr.length ? ',' : '') + id + ':' + UserProfile.instance.items[int(id)];
			handler.call('levels/complete', {'levelInstance':levelInstanceToJson(levelInstance, {}), items: itemsStr},
				function(response:Object):void{
					// проверяем user и levelInstance на синхронность с текущими
					if(!Config.memory['portfolioMode'] && response['levelInstance']['succes'] == false /*||
						arrayElementsIdentical(response['levelInstance']['rewards'] || [], levelInstance.rewards) == false*/)
					{
						// произошла рассинхронизация сервера и клиента
						Config.application.fatalError('ERROR_SERVER_LOGIC_DESYNCRONIZE_LEVEL')
						onError && onError(response);
					}
					else
					{
						jsonToGameUser(response['user'], user);
						Config.stat(Stat.LEVEL_PASSED);
						onComplete && onComplete(response);
					}
				}, onError, null, {'secure': true})
		}

		public function onLevelStarted(user:UserProfile, level:LevelDef, onComplete:Function = null, onError:Function = null):void
		{
			if(Config.memory['disableEnergySpend'])
				return;
			user.spendEnergy();
			handler.call('levels/start', {'levelNumber':level.number},
					function(response:Object):void{
						if(!Config.memory['portfolioMode'] && response['succes'] == false)
						{
							// произошла рассинхронизация сервера и клиента
							Config.application.fatalError('Level !pass error')
							onError && onError(response);
						}
						else
						{
							jsonToGameUser(response['user'], user);
							onComplete && onComplete(response);
						}
					}, onError, null)
		}

		public function onPosting(gameUser:GameUser, onComplete:Function = null, onError:Function = null):void
		{
			handler.call('posting/complete', {'roll': int(gameUser.getRoll() * 1000000)},
				function(response:Object):void{
					// проверяем user и levelInstance на синхронность с текущими
					if(response['reward'] == false )
					{
						// произошла рассинхронизация сервера и клиента
						Config.application.fatalError('ERROR_SERVER_LOGIC_DESYNCRONIZE_REWARD')
						onError && onError(response);
					}
					else
					{
						response['user'] = jsonToGameUser(response['user'], gameUser);
						Config.stat(Stat.POSTING);
						onComplete && onComplete(response);
					}
				}, onError, null, {'secure': true})
		}

		public function moveRewards(rewards:Array, onComplete:Function = null, onError:Function = null):void
		{
			var rewardsToJson:Array = [];
			for each(var r:RewardInstanceDef in rewards)
				rewardsToJson.push(rewardInstanceToJson(r,  {}));
			handler.call('rewards/move', {'rewards': rewardsToJson},
				function(response:Object):void{
					onComplete && onComplete(response);
				}, onError, null)
		}

		public function refreshUserInfo(gameUser:GameUser, onComplete:Function = null, onError:Function = null):void
		{
			var isFriend:Boolean = gameUser.socialUser.isFriend;
			handler.call('users/show', {'user': gameUserToJson(gameUser, {}), friend: isFriend},
					function(response:Object):void{
						response['info'] = jsonToGameUser(response['info'], gameUser);
						if(response['friend'])
						{
							gameUser.visitRewarded = false;
							gameUser.visitRewardTime = response['next_reward_time'] * 1000;
						}
						if(isFriend && !response['friend'])// друг давненько не заходил
							response['needInviteFriendInGame'] = true;
						onComplete && onComplete(response);
					}, onError, null)
		}

		public function incrementTutorial(newValue:int):void
		{
			//if(UserProfile.instance.tutorial < newValue)
			//	handler.call('tutorial/inc', {'tutorial':newValue});
		}

		public function addOffer(offer:OfferDef):void {
			handler.call('offer/add', {'offers':[offer.id]}, function(response:Object):void{
				// сервер успешно принял оффер
				Config.stat(Stat.OFFER_HARVESTED);
			}, function(response:Object):void{
				// сервер не принял оффер
				UserProfile.instance.removeOfferInstanceById(offer.id);
			}, null, {'secure': true});
		}

		public function topIndex(onComplete:Function = null, onError:Function = null):void
		{
			handler.call('top/index', null, function(data:Object):void{
				TopManager.instance.read(data);
				onComplete && onComplete(data);
			}, onError, null, setServerUnsecureFlag());
		}

		public function buyMoney(money:int, netmoney:int, onComplete:Function, onError:Function):void {
			handler.call('money/buy', {money: money, netmoney: netmoney}, function(response:Object):void{
				if(response && response['success'])
				{
					// выдать бабла
					UserProfile.instance.money = response['user_money'];
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError);
		}

		public function refreshMoney(onComplete:Function, onError:Function):void {
			handler.call('money/get', {}, function(response:Object):void{
				if(response && response['success'])
				{
					UserProfile.instance.money = response['user_money'];
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError);
		}

		public function purchaseItems(itemIdsToQuantity:Array, sumPrise:int, onComplete:Function, onError:Function):void
		{
			// todo: для покупки декора использовать другую ф-ю!!!
			var purchaseStr:String = '';
			for(var id:String in itemIdsToQuantity)
			{
				purchaseStr += (purchaseStr.length ? ',' : '') +  id + ':' + itemIdsToQuantity[id]
			}
			if(purchaseStr.length == 0)
				throw new Error('Cant`t buy empty items set');
			handler.call('items/purchase', {purchase: purchaseStr, prise: sumPrise}, function(response:Object):void{
				// сервер всё продал, как надо
				if(response && response['success'])
				{
					response['user'] = jsonToGameUser(response['user'], UserProfile.instance);
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError);
		}

		public function purchaseCustomize(customizes:Array, sumPrise:int, onComplete:Function, onError:Function):void
		{
			// todo: для покупки декора использовать другую ф-ю!!!
			var purchaseStr:String = '';
			for each(var it:CustomizeDef in customizes)
			{
				purchaseStr += (purchaseStr.length ? ',' : '') +  it.type + ':' + it.id;
			}
			if(purchaseStr.length == 0)
				throw new Error('Cant`t buy empty items set');
			handler.call('customize/purchase', {purchase: purchaseStr, prise: sumPrise}, function(response:Object):void{
				// сервер всё продал, как надо
				if(response && response['success'])
				{
					response['user'] = jsonToGameUser(response['user'], UserProfile.instance);
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError);
		}

		public function purchaseEnergy(onComplete:Function, onError:Function):void
		{
			handler.call('energy/purchase', {}, function(response:Object):void{
				// сервер всё продал, как надо
				if(response && response['success'])
				{
					response['user'] = jsonToGameUser(response['user'], UserProfile.instance);
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError);
		}

		public function friendVisitReward(friend:GameUser, onComplete:Function, onError:Function):void
		{
			handler.call('friends/visit', {friend_id: friend.uid}, function(response:Object):void{
				// success
				if(response['success'])
				{
					UserProfile.instance.money = response['money'];
					friend.visitRewarded = true;
					friend.visitRewardTime = response['next_reward_time'] * 1000;
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError, null, {secure: true})
		}


		/**
		 * Послать на сервер запрос списания указанного айтема
		 */
		public function useItem(itemId:int, onComplete:Function = null, onError:Function = null):void
		{
			handler.call('items/use', {item_id: itemId}, function(response:Object):void{
				if(response['success'])
				{
					UserProfile.instance.items[itemId] = int(response['quantity'])
					UserProfile.instance.dispatchChange();
					if(onComplete != null)
						onComplete(response);
				}
				else if(onError != null)
					onError(response);
			}, onError)
		}

		/**
		 *
		 * @param friends array of SocialUser
		 */
		public function sendNeighboursAccepts(friends:Array):void
		{
			var friendsIds:Array = [];
			var uidToSocialUser:Object = {};
			for each(var f:SocialUser in friends){
				friendsIds.push(f.id);
				uidToSocialUser[f.id] = f;
			}
			if(friendsIds.length)// если друзей нет, бессмысленно слать запрос
				handler.call('neighbours/add',{friend_uids: friendsIds.join(',')}, function(response:Object){
					if(response['success']){
						if(response['new_friends'])
							for each(var jsonUser:Object in response['new_friends']){
								var newFriend:GameUser = jsonToGameUser(jsonUser,
										(Config.application as RabbitApplication).createGameUser(uidToSocialUser[jsonUser.uid]));
								UserProfile.instance.addNeighbour(newFriend);
							}
					}
				});
		}


		//////////////////////////////////
		//                              //
		//		P R O T E C T E D		//
		//                              //
		//////////////////////////////////

		protected function jsonToGameUser(json:Object, gameUser:GameUser):GameUser
		{
			var id:String;

		 	// записать uid, session (и т.д.)
			if(json['new'] == true && gameUser.itsMe())
			{
				handler.resetUid(json['uid']);
				var su:SocialUser = Config.loader.getUser();
				su.id = json['uid'];
				Config.loader.setUser(su);
			}

			gameUser.clearLevelInstances();
			json['level_instances'] = toJsonSafety(json['level_instances'])
			for(id in json['level_instances'])
			{
				var li:LevelInstanceDef = gameUser.getLevelInsanceByNumber(parseInt(id));
				if(li == null)
				{
					var level:LevelDef = Config.application.getLevelByNumber(parseInt(id));
					if(level == null)
						continue;// пройденный игроком левел был исключен из уровней, сичтаем что игрок его и не проходил
					li = new LevelInstanceDef(level);
					li.success = true;
				}
				gameUser.addLevelInstance(jsonToLevelInstance(json['level_instances'][id], li));
			}

			gameUser.clearRewards();
			json['rewards'] = toJsonSafety(json['rewards'])
			for(id in json['rewards'])
				gameUser.addRewardInstance(jsonToRewardInstance(json['rewards'][id],
						gameUser.getRewardInstanceById(parseInt(id)) || new RewardInstanceDef(RewardManager.instance.getById(parseInt(id)))))

			gameUser.clearOfferInstances();
			for(id in toJsonSafety(json['offer_instances']))
			{
				var offer:OfferDef = OfferManager.instance.getOfferById(parseInt(id));
				if(offer)
					gameUser.addOfferInstance(offer);
				else
					trace('[OFFER] Creation error, offer id=' + id);// если у игрока оффер, которого нет в природе, не возбуждаем исключения
			}

			gameUser.clearCustomize();
			for each(id in toJsonSafety(json['customize']))
			{
				var customize:CustomizeDef = ItemDef.byId(parseInt(id)) as CustomizeDef;
				if(customize)
					gameUser.setCustomize(customize);
			}

			if(json['roll'])
				gameUser.setRoll(json['roll']);
			gameUser.data = json;

			if(gameUser is UserProfile)
			{
				// речь о текущем юзере игры
				UserProfile.instance.clearItems();
				var itemsArr:Array = String(json['items'] || '').split(',');
				for each(var pair:String in itemsArr)
					if(pair.length)
						UserProfile.instance.addItem(pair.split(':')[0], pair.split(':')[1]);
				UserProfile.instance.setEnergyData(json['energy'], new Date(json['energy_last_gain'] * 1000));
			}

			return gameUser;
		}

		protected function gameUserToJson(gameUser:GameUser, json:Object):Object
		{
			json['uid'] = gameUser.uid;
			json['net'] = Config.loader.net;
			json['first_name'] = gameUser.socialUser.firstName;
			json['last_name'] = gameUser.socialUser.lastName;
			return json;
		}

		protected function jsonToLevelInstance(json:Object, levelInstance:LevelInstanceDef):LevelInstanceDef
		{
			levelInstance.data = json;
			return levelInstance;
		}

		protected function levelInstanceToJson(levelInstance:LevelInstanceDef, json:Object):Object
		{
			json['carrotHarvested'] = levelInstance.currentCarrotHarvested;
			json['timeSpended'] = int(levelInstance.currentTimeSpended * 0.001);
			json['version'] = levelInstance.version;
			json['number'] = levelInstance.number;
			json['success'] = levelInstance.success;
			json['stars'] = levelInstance.stars;
			json['rewards'] = levelInstance.rewards.map(function(r:RewardInstanceDef, ...args):Object{
															return rewardInstanceToJson(r, {});
														});
			return json;
		}

		protected function jsonToRewardInstance(json:Object, rewardInstance:RewardInstanceDef):RewardInstanceDef
		{
			rewardInstance.data = json;
			return rewardInstance;
		}

		protected function rewardInstanceToJson(rewardInstance:RewardInstanceDef, json:Object):Object
		{
			json['id'] = rewardInstance.id;
			json['x'] = rewardInstance.x;
			json['y'] = rewardInstance.y;
			return json;
		}

		/**
		 * ПРоверяет, что оба массива содержат одинаковые эл-ты, судя по полю "id"
		 * (подразумевается, что массив не может содержать 2 эл-та с одинаковыми id)
		 * @param arr1
		 * @param arr2
		 * @return
		 */
		protected function arrayElementsIdentical(arr1:Array, arr2:Array):Boolean
		{
			var id:String = 'id'
			var i:int;
			if(arr1.length != arr2.length)
				return false;
			if(arr1.length == 0 && arr2.length == 0)
				return true;
			var arr1Ids:Array = []
			for(i = 0;i<arr1.length;i++)
				arr1Ids.push(String(arr1[id]));
			var arr2Ids:Array = []
			for(i = 0;i<arr2.length;i++)
				arr2Ids.push(String(arr2[id]));
			for (i = 0; i < arr1Ids.length; i++)
				if(arr2Ids.indexOf(arr1Ids[i]) == -1)
					return false;
			return true;
		}

		/**
		 * Десериализует любую информацию в объект
		 */
		private function toJsonSafety(data:*):Object
		{
			if(data == null)
				data = [];
			else if(data is String && data.length > 0)
				data = handler.fromJson(data);
			return data;
		}

		private function setServerUnsecureFlag(params:Object = null):Object
		{
			if(params == null)
				params = {};
			params['server_unsecure'] = true;
			return params;
		}
	}
}

import com.somewater.net.IServerHandler;
import com.somewater.net.ServerHandler;
import com.somewater.rabbit.storage.Config;

import flash.events.TimerEvent;
import flash.utils.Timer;


/**
 * Проксирующий класс, совершающий запросы к сереру повторно, если сервер не отвечает
 */
class ServerReceiver implements IServerHandler
{
	public static const MAX_REQUESTS:int = 7;

	private var handler:IServerHandler;
	private var timer:Timer;
	private var requestQueue:Array;
	private var requestCounter:uint = 0;
	private var sendedRequestQueue:Array;
	private var importantMethods:Array;

	private var uid:String;
	private var net:int;
	private var secure:Function;

	public function ServerReceiver(handler:IServerHandler, importantMethods:Array)
	{
		this.handler = handler;
		this.importantMethods = importantMethods;
		requestQueue = [];
		sendedRequestQueue = [];
		timer = new Timer(1000);
		timer.addEventListener(TimerEvent.TIMER, onTimer);

		this.uid = Config.loader.getUser().id;
		this.net = Config.loader.net;
		this.secure = Config.loader.secure;
	}

	private function onTimer(event:TimerEvent):void {
		var requestForSend:Array;
		var i:int;
		for(i = 0;i<requestQueue.length;i++)
		{
			var request:Request = requestQueue[i];
			request.seconds--;
			if(request.seconds <= 0)
			{
				requestQueue.splice(i, 1);
				sendedRequestQueue.push(request);
				if(requestForSend == null) requestForSend = [];
				requestForSend.push(request);
			}
		}

		if(requestForSend)
		{
			requestForSend.sortOn('request_counter', Array.NUMERIC);
			for(i = 0;i<requestForSend.length;i++)
				Request(requestForSend[i]).call(this);
		}

		if(requestQueue.length == 0)
			timer.stop();
	}

	public function init(uid:String, key:String, net:int):void {
		handler.init(uid, key,  net)
	}

	public function set base_path(value:String):void {
		handler.base_path = value;
	}
	
	public function get base_path():String
	{
		return handler.base_path;
	}

	public function call(method:String, data:Object = null, onComplete:Function = null, onError:Function = null, base_path:String = null, params:Object = null):void {
		if(params == null)
			params = {};
		if (params['_request_counter'] == null)
			params['_request_counter'] = requestCounter++;

		handler.call(method,data, function(response:Object):void{
			// проверить ответ сервера на валидность (не подделан ли он злостным хакером)
			if(params['server_unsecure'] == null && !(uid == '0' || uid == null || uid == 'null'))
			{
				// тестим
				var responseStr:String = response['_response'];
				var secureTagIndex:int = responseStr.indexOf('<secure>');
				var serverSecure:String = responseStr.substr(secureTagIndex + 8);// 8 - длина стринги "<secure>"
				if(serverSecure != handler.encrypt(secure(245894 * 0.01, uid, net.toString(), responseStr.substring(0, secureTagIndex))))
				{
					CONFIG::debug
					{
						throw new Error('Hack error')
					}
					response = {};
				}
			}
			if(onComplete != null)
				onComplete(response);
		}, function(response:Object):void{
			if(importantMethods.indexOf(method) != -1 || (response && response.hasOwnProperty('error') && response['error'] == 'E_IO'))
			{
				var request:Request = findRequest(params['_request_counter'])
				if(request)
					request.increment();
				else
					request = new Request(method, data, onComplete, onError, base_path, params)

				if(request.counter < MAX_REQUESTS)
				{
					requestQueue.push(request);
					if(!timer.running)
						timer.start();
				}
				else if(onError != null)
					onError(response);
			}
			else if(onError != null)
				onError(response);
		}, base_path, params);
	}

	public function resetUid(uid:String):void {
		handler.resetUid(uid);
	}

	public function addGlobalHandler(success:Boolean, callback:Function):void {
		handler.addGlobalHandler(success, callback);
	}

	public function toJson(object:Object):String {
		return handler.toJson(object);
	}

	public function fromJson(json:String):Object {
		return handler.fromJson(json);
	}

	private function findRequest(request_counter:uint):Request
	{
		for(var i:int = 0; i<sendedRequestQueue.length; i++)
			if(Request(sendedRequestQueue[i]).request_counter == request_counter)
				return sendedRequestQueue.splice(i, 1)[0];
		return null;
	}

	public function encrypt(str:String):String {
		return handler.encrypt(str);
	}
}

class Request
{
	private var method:String;
	private var data:Object;
	private var onComplete:Function;
	private var onError:Function;
	private var base_path:String;
	private var params:Object;

	private var _counter:int = 0;
	private var _seconds:int = 1;

	public function Request(method:String, data:Object, onComplete:Function, onError:Function, base_path:String, params:Object)
	{
		this.method = method;
		this.data = data;
		this.onComplete = onComplete;
		this.onError = onError;
		this.base_path = base_path;
		this.params = params;

		if(params == null || params['_request_counter'] == null)
			throw new Error('Undefined request counter');
	}

	public function call(handler:IServerHandler):void
	{
		handler.call(method, data, onComplete, onError, base_path, params);
	}

	public function get request_counter():uint
	{
		return params['_request_counter'];
	}

	public function increment():void
	{
		_counter++;
		_seconds = 1 * Math.pow(_counter, 1.5);
	}

	public function get counter():int
	{
		return _counter;
	}

	public function set seconds(value:int):void
	{
		_seconds = value;
	}

	public function get seconds():int
	{
		return _seconds;
	}
}