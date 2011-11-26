package com.somewater.rabbit.application {
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.GameUser;
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
			handler = Config.loader.serverHandler;

			handler.call("init", {"user":gameUserToJson(gameUser, {})},
				function(response:Object):void{
					response['user'] = jsonToGameUser(response['user'], gameUser);
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


		//////////////////////////////////
		//                              //
		//		P R O T E C T E D		//
		//                              //
		//////////////////////////////////

		protected function jsonToGameUser(json:Object, gameUser:GameUser):void
		{
			var id:String;

		 	// записать uid, session (и т.д.)
			if(json['new'] == true)
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
					li = new LevelInstanceDef(Config.application.getLevelByNumber(parseInt(id)));
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

			if(json['score'])
				gameUser.score = json['score'];
			if(json['roll'])
				gameUser.setRoll(json['roll']);
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
			json['carrotHarvested'] = levelInstance.carrotHarvested;
			json['timeSpended'] = int(levelInstance.timeSpended * 0.001);
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
