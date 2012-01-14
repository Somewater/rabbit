package com.somewater.rabbit.application {
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.application.windows.PendingRewardsWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;

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

		public function initRequest(gameUser:GameUser, onComplete:Function, onError:Function):void
		{
			handler = new ServerReceiver(Config.loader.serverHandler, ['init']);

			var appFriends:Array = [];
			var appFriendsIds:Array = [];
			var appFriendsById:Array = [];
			var appfriendsSocial:Array = Config.loader.getAppFriends();
			for(var s:String in appfriendsSocial)
			{
				appFriends.push(appfriendsSocial[s])
				appFriendsIds.push(SocialUser(appfriendsSocial[s]).id);
				appFriendsById[SocialUser(appfriendsSocial[s]).id] = appfriendsSocial[s];
			}

			handler.call("init", {"referer":Config.loader.referer, "user":gameUserToJson(gameUser, {}), 'friendIds': appFriendsIds},
				function(response:Object):void{
					response['user'] = jsonToGameUser(response['user'], gameUser);
					var gameUsersFriends:Array = [];
					for each(var friendJson:Object in response['friends'])
					{
						var gameUserFriend:GameUser = jsonToGameUser(friendJson, new GameUser());
						gameUserFriend.data = appFriendsById[friendJson['uid']];
						gameUsersFriends.push(gameUserFriend);
						gameUser.addAppFriend(gameUserFriend);

					}
					response['friends'] = gameUsersFriends;
					onComplete && onComplete(response);
				}, onError);
		}

		public function onLevelPassed(user:GameUser, levelInstance:LevelInstanceDef, onComplete:Function = null, onError:Function = null):void
		{
			handler.call('levels/complete', {'levelInstance':levelInstanceToJson(levelInstance, {})},
				function(response:Object):void{
					// проверяем user и levelInstance на синхронность с текущими
					if(response['levelInstance']['succes'] == false ||
						arrayElementsIdentical(response['levelInstance']['rewards'] || [], levelInstance.rewards) == false)
					{
						// произошла рассинхронизация сервера и клиента
						Config.application.fatalError('ERROR_SERVER_LOGIC_DESYNCRONIZE')
						onError && onError(response);
					}
					else
					{
						jsonToGameUser(response['user'], user);
						onComplete && onComplete(response);
					}
				}, onError, null, {'secure': true})
		}

		public function onPosting(gameUser:GameUser, onComplete:Function = null, onError:Function = null):void
		{
			handler.call('posting/complete', {'roll': int(gameUser.getRoll() * 1000000)},
				function(response:Object):void{
					// проверяем user и levelInstance на синхронность с текущими
					if(response['reward'] == false )
					{
						// произошла рассинхронизация сервера и клиента
						Config.application.fatalError('ERROR_SERVER_LOGIC_DESYNCRONIZE')
						onError && onError(response);
					}
					else
					{
						response['user'] = jsonToGameUser(response['user'], gameUser);
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
			handler.call('users/show', {'user': gameUserToJson(gameUser, {})},
					function(response:Object):void{
						response['info'] = jsonToGameUser(response['info'], gameUser);
						onComplete && onComplete(response);
					}, onError, null)
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
			if(json['level_instances'] == null)json['level_instances'] = [];
			if(json['level_instances'] is String && json['level_instances'].length > 0) json['level_instances'] = handler.fromJson(json['level_instances']);
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
			if(json['rewards'] == null)json['rewards'] = [];
			if(json['rewards'] is String && json['rewards'].length > 0) json['rewards'] = handler.fromJson(json['rewards']);
			for(id in json['rewards'])
				gameUser.addRewardInstance(jsonToRewardInstance(json['rewards'][id],
						gameUser.getRewardInstanceById(parseInt(id)) || new RewardInstanceDef(RewardManager.instance.getById(parseInt(id)))))

			if(json['roll'])
				gameUser.setRoll(json['roll']);
			gameUser.data = json;

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
	}
}

import com.somewater.net.IServerHandler;
import com.somewater.net.ServerHandler;

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

	public function ServerReceiver(handler:IServerHandler, importantMethods:Array)
	{
		this.handler = handler;
		this.importantMethods = importantMethods;
		requestQueue = [];
		sendedRequestQueue = [];
		timer = new Timer(1000);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
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

		handler.call(method,data, onComplete, function(response:Object):void{
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

	public function stat(name:String):void
	{
		handler.stat(name);
	}

	private function findRequest(request_counter:uint):Request
	{
		for(var i:int = 0; i<sendedRequestQueue.length; i++)
			if(Request(sendedRequestQueue[i]).request_counter == request_counter)
				return sendedRequestQueue.splice(i, 1)[0];
		return null;
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