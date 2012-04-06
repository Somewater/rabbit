		import com.somewater.social.SocialUser;

		//////////////////////////////////////////////////////////////////
		//																//
		//		S O C I A L     A P I    I M P L E M E N T A T I O N 	//
		//					(all data in local storage)					//
		//																//
		//////////////////////////////////////////////////////////////////

		override protected function initializeServerHandler():void
		{
			if(_serverHandler == null)
				_serverHandler = new LocalServerHandler(getConfigForServerHandler());
			_serverHandler.init(getUser().id, 'embed', net);
		}

		override public function get hasFriendsApi():Boolean {
			return Config.memory['portfolioMode'];
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

		private var user:SocialUser;

		private function loadUserData():void
		{
			var userParams:Object = this.get('user');
			if(userParams == null)
				userParams = {};
			user = new SocialUser();
			user.male = true;
			user.id = userParams['id'] ? userParams['id'] : '0';
			user.itsMe = true;
			user.balance = 0;
			user.bdate = new Date(1980, 0, 0).time;
			user.firstName = userParams['firstName'] ? userParams['firstName'] : "Hopper";
			user.lastName = userParams['lastName'] ? userParams['lastName'] : "";
		}

		private function saveUserData(user:SocialUser):void {
			var userParams:Object = {"id": user.id};
			this.set('user', userParams);
		}