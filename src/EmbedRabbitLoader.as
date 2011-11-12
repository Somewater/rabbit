package
{
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.loader.ILocalDb;
	import com.somewater.rabbit.loader.LocalDb;
	import com.somewater.rabbit.loader.RabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialAdapter;
	import com.somewater.social.SocialUser;
	
	import flash.events.Event;

	/**
	 * Для использования вне соц. сетей, эмуляця взаимодействия с соц. сетью
	 */
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class EmbedRabbitLoader extends RabbitLoaderBase
	{
		private var localDb:ILocalDb;

		public function EmbedRabbitLoader()
		{
			localDb = LocalDb.instance;
			super();
		}
		
		
		override protected function netInitialize():void
		{
			onNetInitializeComplete();
		}
		
		override protected function createSpecificPaths():void
		{
			swfs = {
				"Game":{priority:-1,preload:true,url:"RabbitGame.swf"}
				,
				"Application":{priority:int.MIN_VALUE,
					preload:true,url:"RabbitApplication.swf"}
				,"Interface":{preload:true, url:"assets/interface.swf"}
				,"Assets":{preload:true, url:"assets/rabbit_asset.swf"}
				,"Rewards":{preload:false, url:"assets/rabbit_reward.swf"}
				,"Lang":{priority:100, preload:true, url:"lang_ru.swf"}
				,"Editor":{priority:1, preload:true, url:"RabbitEditor.swf"}
				
				,"Font":{priority:100, preload:true, url:"assets/fonts_ru.swf"}
				//,"Font":{priority:1000, preload:true, url:"assets/fonts_ru.swf"}
			}
			
			filePaths = {
				"Levels":"levels.xml"
				,"Managers":"Managers.xml"
				,"Description":"Description.xml"
				,"Rewards":"Rewards.xml"
			}
		}
		
		override protected function initializeServerHandler():void
		{
			_serverHandler = new ServerHandler();
			_serverHandler.base_path = /asflash.ru/.test(loaderInfo.url) ? "http://rabbit.asflash.ru/" : "http://localhost:3000/";
			_serverHandler.init(getUser().id, 'embed', net);
		}
		
		//////////////////////////////////////////////////////////////////
		//																//
		//		S O C I A L     A P I    I M P L E M E N T A T I O N 	//
		//																//
		//////////////////////////////////////////////////////////////////

		override public function get net():int { return 1; }

		override public function get hasUserApi():Boolean { return true; }
		
		override public function get hasFriendsApi():Boolean { return false; }
		
		override public function getFriends():Array
		{
			CONFIG::debug
			{
				throw new Error('Not implemented');
			}
			return [];
		}
		
		override public function getAppFriends():Array
		{
			CONFIG::debug
			{
				throw new Error('Not implemented');
			}
			return [];
		}
		
		override public function getUser():SocialUser
		{
			if(user == null)
				loadUserData();
			return user;
		}

		override public function setUser(user:SocialUser):void {
			saveUserData(user);
		}

		override public function showInviteWindow():void
		{
			CONFIG::debug
			{
				throw new Error('Not implemented');
			}
		}
		
		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			CONFIG::debug
			{
				throw new Error('Not implemented');
			}
			if(onFailure != null)
				onFailure();
		}
		
		override public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			CONFIG::debug
			{
				throw new Error('Not implemented');
			}
			if(onError != null)
				onError({});
		}
		
		private var user:SocialUser;
		
		private function loadUserData():void
		{
			var userParams:Object = localDb.get('user');
			if(userParams == null)
				userParams = {};
			user = new SocialUser();
			user.id = userParams['id'] ? userParams['id'] : null;
			user.itsMe = true;
			user.balance = 0;
			user.bdate = new Date(1980, 0, 0).time;
			user.firstName = userParams['firstName'] ? userParams['firstName'] : "Rabbit";
			user.lastName = userParams['lastName'] ? userParams['lastName'] : "";
		}

		private function saveUserData(user:SocialUser):void {
			var userParams:Object = {"id": user.id};
			localDb.set('user', userParams);
		}
	}
}