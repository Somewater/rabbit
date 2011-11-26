package com.somewater.rabbit.storage
{
	import com.somewater.social.SocialUser;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	[Event(name="changeUserData", type="com.somewater.rabbit.storage.UserProfile")]
	
	public class UserProfile extends GameUser implements IEventDispatcher
	{
		public static var instance:UserProfile;
		
		public var suspendBinding:Boolean = false;// изменения не диспатс\чатся при установленном флаге (полезно при замене большого кол-ва данных)
		public static const CHANGE_USER_DATA:String = "changeUserData";
		
		public var timeDelta:Number = 0;// разница между временем на сервере и клиенте, секунд: timeDelta = {клиент} - {сервер}, таким образом {клиент} = {сервер} + timeDelta
		
		private var listeners:Array = new Array();
		
		private var dispatcher:EventDispatcher;
		
		private var roll:uint;
		
		
		public function UserProfile(data:Object)
		{
			super(data);
			
			if(instance)
				throw new Error("Singletone class");
			
			dispatcher = new EventDispatcher();
			
			instance = this;
		}
		
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return dispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return dispatcher.willTrigger(type);
		}
		
		
		public function dispatchChange():void
		{
			if(suspendBinding) 
				return;
			dispatchEvent(new Event(UserProfile.CHANGE_USER_DATA));
			for(var i:int = 0;i<listeners.length;i++)
			{
				try{
					listeners[i]();
				}catch(e:Error){
					trace("[ERROR] Wrong listener " + listeners[i]);
				}
			}
		}
		
		public static function bind(listener:Function):void
		{
			if(instance.listeners.indexOf(listener) == -1)
				instance.listeners.push(listener);
			
			listener();
		}
		
		public static function unbind(listener:Function):void
		{
			var i:int = 0
			while(i < instance.listeners.length){
				if(instance.listeners[i] == listener){
					instance.listeners.splice(i, 1);
					break;
				}else
					i++;
			}
		}
		
		//////////////////////////////////////////////////////////////////
		//																//
		//							DATA								//
		//																//
		//////////////////////////////////////////////////////////////////
		
		private var _money:Number = 0;
		public function set money(value:Number):void
		{
			if(_money != value)
			{
				_money = value;
				dispatchChange();
			}
		}
		public function get money():Number
		{
			return _money;
		}
		
		
		override public function addLevelInstance(levelInst:LevelInstanceDef):void
		{
			if(levelInst.success)
			{
				super.addLevelInstance(levelInst);
				dispatchChange();
			}
		}


		
		override public function set score(value:int):void
		{
			if(_score != value)
			{
				_score = value;
				dispatchChange();
			}
		}
		
		private var _appFriends:Array;
		public function get appFriends():Array
		{
			if(_appFriends == null)
			{
				var social:Array = Config.loader.getAppFriends();
				_appFriends = [];
				social.forEach(function(user:SocialUser, ...args):void{
					_appFriends.push(new GameUser(user));
				});
			}
			return _appFriends;
		}
		
		public function canPlayWithLevel(level:LevelDef):Boolean
		{
			return level.number <= levelNumber;
		}


		override public function addRewardInstance(reward:RewardInstanceDef):void {
			super.addRewardInstance(reward);
			dispatchChange();
		}

		override public function getRoll():Number
		{
			var roll:uint = this.roll;
			if(roll == 0)
				roll = parseInt(this.uid) + 1024;
			roll = ((roll * 16147) % 2147483647)
			this.roll = roll;
			return roll / 2147483647;
		}


		override public function setRoll(roll:uint):void {
			this.roll = roll;
		}
	}
}