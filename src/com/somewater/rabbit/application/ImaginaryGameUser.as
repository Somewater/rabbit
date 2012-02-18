package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;

	import flash.display.Bitmap;

	import flash.display.BitmapData;

	public class ImaginaryGameUser extends GameUser{

		[Embed(source="imaginary_friend_avatar.png")]
		private static const IMAGINARY_FRIEND_AVATAR:Class;
		private static var _instance:ImaginaryGameUser;

		public function ImaginaryGameUser() {
			this._socialUser = new SocialUser();
			socialUser.female = UserProfile.instance.socialUser.female;
			socialUser.firstName = Lang.t('IMAGINARY_FRIEND_FIRST_NAME');
			socialUser.lastName = Lang.t('IMAGINARY_FRIEND_LAST_NAME');
			socialUser.isAppFriend = true;
			socialUser.isFriend = true;
			socialUser.photos = [''];

			this.score = UserProfile.instance.score * 0.7;
			this.data = {level: Math.max(1, UserProfile.instance.levelNumber - 2)};

			var datarow:Object = {"71":{"id":71,"x":6,"y":1,"n":1},"33":{"id":33,"x":0,"y":9,"n":1},"50":{"id":50,"x":2,"y":8,"n":0},"78":{"id":78,"x":8,"y":3,"n":2},"76":{"id":76,"x":5,"y":4,"n":5},"51":{"id":51,"x":6,"y":7,"n":0},"13":{"id":13,"x":1,"y":5,"n":3},"41":{"id":41,"x":8,"y":8,"n":0},"40":{"id":40,"x":7,"y":4,"n":0},"52":{"id":52,"x":7,"y":1,"n":0},"21":{"id":21,"x":5,"y":5,"n":9},"62":{"id":62,"x":2,"y":6,"n":0},"42":{"id":42,"x":2,"y":5,"n":0},"12":{"id":12,"x":4,"y":7,"n":24},"10":{"id":10,"x":8,"y":6,"n":14},"24":{"id":24,"x":4,"y":9,"n":14}}
			var counter:int = 0;
			for each(var data:Object in datarow)
			{
				if(counter > (this.levelNumber + 5))
					break;
				var r:RewardInstanceDef = new RewardInstanceDef(RewardManager.instance.getById(data['id']));
				r.x = data['x'];
				r.y = data['y'];
				addRewardInstance(r);
				counter++;
			}
		}

		public static function getAvatar():BitmapData
		{
			return Bitmap(new IMAGINARY_FRIEND_AVATAR()).bitmapData;
		}

		public static function get instance():ImaginaryGameUser {
			if(_instance == null)
				_instance = new ImaginaryGameUser();
			return _instance;
		}
	}
}
