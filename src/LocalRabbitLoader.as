package
{
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.loader.RabbitLoaderBase;
	import com.somewater.rabbit.net.LocalServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.social.SocialUser;
	
	import flash.events.Event;

	/**
	 * Эмуляция работы сервера и сошл. апи
	 */
	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class LocalRabbitLoader extends RabbitLoaderBase
	{
		public function LocalRabbitLoader()
		{
			super();
		}
		
		
		override protected function netInitialize():void
		{
			onNetInitializeComplete()
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
						,"Rewards":{preload:true, url:"assets/rabbit_reward.swf"}
						,"Images":{preload:true, url:"assets/rabbit_images.swf"}
						,"Sound":{preload:true, url:"assets/rabbit_sound.swf"}
						,"Lang":{priority:100, preload:true, url:"lang_ru.swf"}
						,"Editor":{priority:1, preload:true, url:"RabbitEditor.swf"}
						
						,"Font":{priority:100, preload:true, url:"assets/fonts_ru.swf"}
						//,"Font":{priority:1000, preload:true, url:"assets/fonts_ru.swf"}
					}
			
			filePaths = {
							 "Levels":"/levels.xml"
							,"Managers":"Managers.xml"
							,"Description":"Description.xml"
							,"Rewards":"Rewards.xml"
						}
		}

		override protected function initializeServerHandler():void
		{
			_serverHandler = new LocalServerHandler();
			_serverHandler.init(getUser().id, 'embed', net);
		}

		//////////////////////////////////////////////////////////////////
		//																//
		//		S O C I A L     A P I    I M P L E M E N T A T I O N 	//
		//																//
		//////////////////////////////////////////////////////////////////
		
		override public function get hasUserApi():Boolean { return true; }
		
		override public function get hasFriendsApi():Boolean { return true; }
		
		override public function getFriends():Array
		{
			recreateFakeUsers();
			return fakeFriends.slice();
		}
		
		override public function getAppFriends():Array
		{
			recreateFakeUsers();
			var arr:Array = [];
			for(var i:int = 0;i<fakeFriends.length;i++)
				if(SocialUser(fakeFriends[i]).isAppFriend)
					arr.push(fakeFriends[i]);
			return arr;
		}
		
		override public function getUser():SocialUser
		{
			recreateFakeUsers();
			return user;
		}
		
		override public function showInviteWindow():void
		{
			recreateFakeUsers();
			trace("[SOCIAL] Invite window opened");
		}
		
		override public function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
		{
			recreateFakeUsers();
			trace("[SOCIAL] payment: " + quantity);
			onFailure && onFailure();
		}
		
		override public function getUsers(uids:Array, onComplete:Function, onError:Function):void
		{
			recreateFakeUsers();
			var arr:Array = [];
			var i:int = 0;
			while(i < uids.length)
			{
				var find:Boolean = false;
				for(var j:int = 0;j<fakeFriends.length;j++)
				{
					if(SocialUser(fakeFriends[j]).id == uids[i])
					{
						arr.push(fakeFriends[j]);
						uids.shift();
						find = true;
						break;
					}
				}
				if(find == false)
				{
					onError && onError();
					return;
				}
			}
			
			onComplete && onComplete(arr);
		}
		
		private var fakeFriends:Array;
		private var user:SocialUser;
		
		private function recreateFakeUsers():void
		{
			if(fakeFriends == null)
			{
				user = new SocialUser();
				user.itsMe = true;
				user.balance = 12;
				user.bdate = new Date(1987, 6, 6).time;
				user.city = "Belgorod";
				user.country = "Russia";
				user.sex = "male";
				user.firstName = "Павел";
				user.lastName = "Найденов";
				
				fakeFriends = [	];
				
				fakeFriends[0] = new SocialUser();
				fakeFriends[0].id = '1';
				fakeFriends[0].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[0].isAppFriend = fakeFriends[0].isFriend = true;
				fakeFriends[0].balance = 12;
				fakeFriends[0].bdate = new Date(1987, 11, 26).time;
				fakeFriends[0].city = "Belgorod";
				fakeFriends[0].country = "Russia";
				fakeFriends[0].sex = "female";
				fakeFriends[0].firstName = "Inna";
				fakeFriends[0].lastName = "Glazynova";
				
				fakeFriends[1] = new SocialUser();
				fakeFriends[1].id = '2';
				fakeFriends[1].photos = ["http://cs10618.vkontakte.ru/u1516396/a_5c77938b.jpg"];
				fakeFriends[1].isAppFriend = fakeFriends[1].isFriend = true;
				fakeFriends[1].balance = 12;
				fakeFriends[1].bdate = new Date(1987, 2, 26).time;
				fakeFriends[1].city = "Belgorod";
				fakeFriends[1].country = "Russia";
				fakeFriends[1].sex = "male";
				fakeFriends[1].firstName = "Иван";
				fakeFriends[1].lastName = "Тарапунов";
				
				fakeFriends[2] = new SocialUser();
				fakeFriends[2].id = '3';
				fakeFriends[2].photos = ["http://cs9637.vkontakte.ru/u1516396/128032186/x_14767d8e.jpg"];
				fakeFriends[2].isAppFriend = fakeFriends[2].isFriend = true;
				fakeFriends[2].balance = 12;
				fakeFriends[2].bdate = new Date(1987, 3, 17).time;
				fakeFriends[2].city = "Belgorod";
				fakeFriends[2].country = "Russia";
				fakeFriends[2].sex = "male";
				fakeFriends[2].firstName = "Олек";
				fakeFriends[2].lastName = "Козельцев";
				
				fakeFriends[3] = new SocialUser();
				fakeFriends[3].id = '4';
				fakeFriends[3].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[3].isAppFriend = fakeFriends[3].isFriend = true;
				fakeFriends[3].balance = 12;
				fakeFriends[3].bdate = new Date(1987, 9, 15).time;
				fakeFriends[3].city = "Belgorod";
				fakeFriends[3].country = "Russia";
				fakeFriends[3].sex = "female";
				fakeFriends[3].firstName = "Сюзанна";
				fakeFriends[3].lastName = "Семенова";
				
				fakeFriends[4] = new SocialUser();
				fakeFriends[4].id = '5';
				fakeFriends[4].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[4].isAppFriend = fakeFriends[4].isFriend = true;
				fakeFriends[4].balance = 12;
				fakeFriends[4].bdate = new Date(1987, 3, 6).time;
				fakeFriends[4].city = "Belgorod";
				fakeFriends[4].country = "Russia";
				fakeFriends[4].sex = "female";
				fakeFriends[4].firstName = "Авелина";
				fakeFriends[4].lastName = "Петровна";
				
				fakeFriends[5] = new SocialUser();
				fakeFriends[5].id = '6';
				fakeFriends[5].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[5].isAppFriend = fakeFriends[5].isFriend = true;
				fakeFriends[5].balance = 12;
				fakeFriends[5].bdate = new Date(1987, 3, 6).time;
				fakeFriends[5].city = "Belgorod";
				fakeFriends[5].country = "Russia";
				fakeFriends[5].sex = "male";
				fakeFriends[5].firstName = "Антон";
				fakeFriends[5].lastName = "Сорокин";
				
				fakeFriends[6] = new SocialUser();
				fakeFriends[6].id = '7';
				fakeFriends[6].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[6].isAppFriend = fakeFriends[6].isFriend = true;
				fakeFriends[6].balance = 12;
				fakeFriends[6].bdate = new Date(1989, 6, 4).time;
				fakeFriends[6].city = "Belgorod";
				fakeFriends[6].country = "Russia";
				fakeFriends[6].sex = "male";
				fakeFriends[6].firstName = "Иннокентий";
				fakeFriends[6].lastName = "Подлжаев";
				
				fakeFriends[7] = new SocialUser();
				fakeFriends[7].id = '8';
				fakeFriends[7].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[7].isAppFriend = fakeFriends[7].isFriend = true;
				fakeFriends[7].balance = 12;
				fakeFriends[7].bdate = new Date(1978, 3, 5).time;
				fakeFriends[7].city = "Belgorod";
				fakeFriends[7].country = "Russia";
				fakeFriends[7].sex = "female";
				fakeFriends[7].firstName = "Елизавета";
				fakeFriends[7].lastName = "Карлова";
				
				fakeFriends[8] = new SocialUser();
				fakeFriends[8].id = '9';
				fakeFriends[8].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[8].isFriend = true;
				fakeFriends[8].balance = 12;
				fakeFriends[8].bdate = new Date(1967, 7, 2).time;
				fakeFriends[8].city = "New York";
				fakeFriends[8].country = "USA";
				fakeFriends[8].sex = "female";
				fakeFriends[8].firstName = "Ангелина";
				fakeFriends[8].lastName = "Протопопова";
				
				fakeFriends[9] = new SocialUser();
				fakeFriends[9].id = '10';
				fakeFriends[9].photos = ["http://cs11005.vkontakte.ru/u245894/a_e4b26ec1.jpg"];
				fakeFriends[9].isFriend = true;
				fakeFriends[9].balance = 12;
				fakeFriends[9].bdate = new Date(1977, 6, 6).time;
				fakeFriends[9].city = "Moscow";
				fakeFriends[9].country = "Russia";
				fakeFriends[9].sex = "male";
				fakeFriends[9].firstName = "Семён";
				fakeFriends[9].lastName = "Кузьмин";
			}
		}
	}
}