package com.somewater.rabbit.application {
	import com.somewater.net.IServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;

	/**
	 * Прокси между IServerHandler и логикой приложения
	 */
	public class AppServerHandler {

		private static var handler:IServerHandler;

		static public function initRequest(onComplete:Function, onError:Function):void
		{
			handler = Config.loader.serverHandler;

			handler.call("init", {"user":{"net":Config.loader.net, "first_name":Config.loader.getUser().firstName, "last_name":Config.loader.getUser().lastName}},
				function(response:Object):void{
					// записать uid, session (и т.д.)
					if(response['user'] && response['user']['new'] === true)
					{
						handler.resetUid(response['user']['uid']);
						var su:SocialUser = Config.loader.getUser();
						su.id = response['user']['uid'];
						Config.loader.setUser(su);
					}

					if(response['user'])
					{
						// юзер возможно ранее уже был записан в БД, однако надо запомнить некторые свойства юзера
					}

					// заполнить UserProfile (и прочие модели)
					new UserProfile(response['user']);

					onComplete(response);
				}, onError);
		}
	}
}
