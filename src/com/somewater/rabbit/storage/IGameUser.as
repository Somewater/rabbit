package com.somewater.rabbit.storage {
	import com.somewater.social.SocialUser;

	public interface IGameUser {
		function itsMe():Boolean;

		function get uid():String;

		function get socialUser():SocialUser
	}
}
