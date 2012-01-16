package clickozavr.GetUserData
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import vk.APIConnection;
	
	public class VKGetUserData extends EventDispatcher implements IGetUserData
	{
		private var _VK:APIConnection;
		
		private var _cityId:int;
		private var _countryId:int;
		private var _viewerId:String;
		private var _userInfo:XML;
		
		public function VKGetUserData()
		{
			super(null);
		}
		
		public function getUserData(apiData:Object):void
		{
			_viewerId = String(apiData.viewer_id);
			
			_VK = new APIConnection(apiData);
			_VK.addEventListener("onConnectionInit", VKReadyHandler);
		}
		
		public function get networkId():String
		{
			return "2";
		}
		
		private function VKReadyHandler(event:Event):void
		{
			_VK.api("getProfiles", { uids: _viewerId, fields: "uid,sex,bdate,city,country" },
				getUserInfoCallback, getUserInfoFailedCallback);
		}
		
		private function getUserInfoFailedCallback(responce:Object):void
		{
			dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_FAILED));
		}
		
		private function getUserInfoCallback(users:Object):void
		{
			_userInfo = <userinfo/>;
			var usersArr:Array = users as Array;
			
			if (usersArr && usersArr.length > 0)
			{
				var user:Object = usersArr[0];
				if (user.uid) _userInfo.@id = String(user.uid);
				if (user.sex != "0") { if (user.sex == "1") _userInfo.@sex = "female" else _userInfo.@sex = "male"; }
				if (String(user.bdate).match(/\d{1,2}\.\d{1,2}\.\d{4}/)) _userInfo.@birthday = String(user.bdate);
				
				_cityId = int(user.city);
				_countryId = int(user.country);
				
				if (_cityId || _countryId)
				{
					_userInfo.appendChild(<location/>);
					
					if (_countryId)
						_VK.api("places.getCountryById", { cids: String(_countryId) },
						getCountryUserInfoCallback, getUserInfoFailedCallback);
					else
						_VK.api("places.getCityById", { cids: String(_cityId) },
						getCityUserInfoCallback, getUserInfoFailedCallback);
				}
				else
				{
					dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_SUCCESS, _userInfo));
				}
			}
			else
			{
				dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_SUCCESS, _userInfo));
			}
		}
		
		private function getCountryUserInfoCallback(data:Object):void
		{
			var countryInfo:Object = data[0];
			if (countryInfo && countryInfo.hasOwnProperty("name"))
			{
				var item:XML = <country/>;
				item.@id = String(countryInfo.cid);
				item.@name = String(countryInfo.name);
				_userInfo.location[0].appendChild(item);
			}
			
			if (_cityId)
			{
				_VK.api("places.getCityById", { cids: String(_cityId) },
				getCityUserInfoCallback, getUserInfoFailedCallback);
			}
			else
			{
				dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_SUCCESS, _userInfo));
			}
		}
		
		private function getCityUserInfoCallback(data:Object):void
		{
			var countryInfo:Object = data[0];
			if (countryInfo && countryInfo.hasOwnProperty("name"))
			{
				var item:XML = <city/>;
				item.@id = String(countryInfo.cid);
				item.@name = String(countryInfo.name);
				_userInfo.location[0].appendChild(item);
			}
			
			dispatchEvent(new GetUserDataEvent(GetUserDataEvent.GET_USER_DATA_SUCCESS, _userInfo));
		}
	}
}