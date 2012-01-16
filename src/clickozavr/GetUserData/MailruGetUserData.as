package clickozavr.GetUserData
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mailru.MailruCall;
	
	public class MailruGetUserData extends EventDispatcher implements IGetUserData
	{
		public function MailruGetUserData()
		{
			super(null);
		}
		
		public function getUserData(apiData:Object):void
		{
			try {
				MailruCall.addEventListener(Event.COMPLETE, mailruReadyHandler);
				MailruCall.init("flash-app", apiData.pKey);
			}
			catch (e:Error) {
				dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_FAILED));
			}
		}
		
		public function get networkId():String
		{
			return "1";
		}
		
		private function mailruReadyHandler(event:Event):void
		{
			MailruCall.exec("mailru.common.users.getInfo", getUserInfoCallback);
		}
		
		private function getUserInfoCallback(users:Object):void
		{
			var userInfo:XML;
			
			if (users.hasOwnProperty("error"))
			{
				var err:Object = users.error;
				dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_FAILED));
			}
			else
			{
				userInfo = <userinfo/>;
				var usersArr:Array = users as Array;
				
				if (usersArr && usersArr.length > 0)
				{
					var user:Object = usersArr[0];
					if (user.uid) userInfo.@id = String(user.uid);
					if (user.sex) userInfo.@sex = "female" else userInfo.@sex = "male";
					if (user.birthday) userInfo.@birthday = String(user.birthday);
					if (user.location)
					{
						var loc:XML = <location/>;
						if (user.location.country)
						{
							var item:XML = <country/>;
							item.@id = String(user.location.country.id);
							item.@name = String(user.location.country.name);
							loc.appendChild(item);
						}
						if (user.location.city)
						{
							item = <city/>;
							item.@id = String(user.location.city.id);
							item.@name = String(user.location.city.name);
							loc.appendChild(item);
						}
						userInfo.appendChild(loc);
					}
				}
			}
			
			dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_SUCCESS, userInfo));
		}
	}
}