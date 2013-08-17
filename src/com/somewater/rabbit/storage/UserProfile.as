package com.somewater.rabbit.storage
{
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.social.SocialUser;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Timer;

[Event(name="changeUserData", type="com.somewater.rabbit.storage.UserProfile")]
	
	public class UserProfile extends GameUser implements IEventDispatcher
	{
		public static var instance:UserProfile;
		
		public var suspendBinding:Boolean = false;// изменения не диспатс\чатся при установленном флаге (полезно при замене большого кол-ва данных)
		public static const CHANGE_USER_DATA:String = "changeUserData";
		
		private var listeners:Array = new Array();
		
		private var dispatcher:EventDispatcher;
		
		private var roll:uint;

		private var _tutorial:int = -1;

		private var _items:Array = [];

		private var _energy:int = 0;
		private var _energyLastGain:Date;
		private var energyGainTimer:Timer;

		/**
		 * Разница между временем на клиенте и сервере, в миллисекундах
		 * Показывает, на сколько клиент отстает от сервера, т.е.
		 * clienTime + msDelta = serverTime
		 */
		public var msDelta:Number;
		
		
		public function UserProfile(data:Object)
		{
			super(data);
			
			if(instance)
				throw new Error("Singletone class");
			
			dispatcher = new EventDispatcher();
			
			instance = this;

			energyGainTimer = new Timer(1000, 1);
			energyGainTimer.addEventListener(TimerEvent.TIMER, onEnergyGainTimer);
		}

		override public function itsMe():Boolean {
			return true;
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
				_appFriends = [];
			return _appFriends;
		}

		override public function addAppFriend(gameUserFriend:GameUser):void
		{
			if(_appFriends == null)
				_appFriends = [];
			_appFriends.push(gameUserFriend);
			dispatchChange();
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
			if(roll < 1024)
				roll = Math.abs(parseInt(this.uid.length > 9 ? this.uid.slice(this.uid.length - 9) : this.uid)) + 1024;
			roll = ((roll * 16147) % 2147483647)
			//Config.game.logError(this, 'getRoll', 'ROLL ' + this.roll + ' => ' + roll + ' (' + (roll / 2147483647) + ')')
			CONFIG::debug
			{
				trace("GET ROLL: " + this.roll + ' => ' + roll + ' (' + (roll / 2147483647) + ')');
			}
			this.roll = roll;
			return roll / 2147483647;
		}


		override public function setRoll(roll:uint):void {
			CONFIG::debug
			{
				if(this.roll > 0 && this.roll != roll)
					throw new Error('Roll collision: client_roll=' + this.roll + '\tserver_roll=' + roll);
			}
			this.roll = roll;
		}


		override public function set postings(postings:int):void {
			super.postings = postings;
			dispatchChange();
		}

		override public function get levelNumber():int
		{
			var max:int = 0;
			for each(var inst:LevelInstanceDef in _levelInstances)
				if(inst.levelDef.number > max)
					max = inst.levelDef.number;
			max++;// т.к. уровень человека - это пройденный вроень + 1
			return Math.max(max, super.levelNumber);
		}

		public function get tutorial():int
		{
			return _tutorial;
		}

		public function set tutorial(value:int):void
		{
			if(value != _tutorial)
			{
				_tutorial = value;
				//TutorialManager.instance.startStep(_tutorial);
			}
		}


		override public function addOfferInstance(offer:OfferDef):void {
			super.addOfferInstance(offer);
			dispatchChange();
		}

		public function get offers():int
		{
			var i:int = 0;
			for each(var of:OfferDef in _offerInstances)
				i++;
			return i;
		}

		override public function get stars():int {
			var value:int = 0;

			for each(var li:LevelInstanceDef in _levelInstances)
				value += li.stars;

			return Math.max(value, _stars);
		}

		override public function set stars(value:int):void
		{
			if(_stars != value)
			{
				_stars = value;
				dispatchChange();
			}
		}

		public function get items():Array
		{
			return _items
		}

		public function clearItems():void
		{
			_items = [];
		}

		public function hasItem(id:int):Boolean
		{
			return int(_items[id]) > 0;
		}

		public function addItem(id:int, quantity:uint = 1):void
		{
			_items[id] = int(_items[id]) + quantity;
			dispatchChange();
		}

		public function deleteItem(id:int, quantity:uint = 1):void
		{
			if(int(_items[id]) < quantity)
				throw new Error('Cant allocate ' + quantity + ' items id=' + id);
			_items[id] = int(_items[id]) - quantity;
			if(_items[id] == 0)
				delete(_items[id]);
			dispatchChange();
		}

		/**
		 * Возвращает время на сервере (МИЛЛИСЕКУНДЫ), принимая в учет msDelta
		 * Если во время работы приложения пользователь перевео системное время, настройка собьется
		 */
		public function serverUnixTime():Number
		{
			return new Date().time + msDelta;
		}

		override public function setCustomize(customize:CustomizeDef):void
		{
			super.setCustomize(customize);
			dispatchChange();
		}

		public function getEnergy(recalc:Boolean = true):int {
			if(recalc && _energy <= 0 && canGainEnergy()){
				return ConfManager.instance.getNumber('ENERGY_MAX');
			}else
				return _energy;
		}

		public function canSpendEnergy(value:int = 1):Boolean {
			return _energy - value >= 0 || canGainEnergy();
		}

		private function canGainEnergy():Boolean {
			return !_energyLastGain || _energyLastGain.time == 0 ||
				(_energyLastGain.time + ConfManager.instance.getNumber('ENERGY_GAIN_INTERVAL') * 1000) < serverUnixTime();
		}

		// ms
		public function gainEnergyTimeLeft():int {
			if(!_energyLastGain || _energyLastGain.time == 0)
				return 0;
			var gainTime:int = (_energyLastGain.time + ConfManager.instance.getNumber('ENERGY_GAIN_INTERVAL') * 1000);
			var now:int = serverUnixTime();
			if(gainTime > now)
				return gainTime - now;
			else
				return 0;
		}

		public function energyIsFull():Boolean {
			return _energy == ConfManager.instance.getNumber('ENERGY_MAX');
		}

		public function spendEnergy(value:int = 1):void {
			if(!canSpendEnergy(value))
				throw new Error("Not enough energy");
			if(_energy - value < 0 && canGainEnergy()){
				gainEnergy();
			}
			_energy -= value;
			dispatchChange();
		}

		public function gainEnergy():void{
			if(!canGainEnergy())
				throw new Error("Can't gain energy");
			_energy = ConfManager.instance.getNumber('ENERGY_MAX')
			_energyLastGain = new Date(serverUnixTime());
			refreshEnergyGainTimer();
			dispatchChange();
		}

		public function setEnergyData(energy:int, lastGain:Date):void {
			_energy = energy;
			_energyLastGain = lastGain;
			refreshEnergyGainTimer()
			dispatchChange();
		}

		private function refreshEnergyGainTimer():void {
			if(_energyLastGain && _energyLastGain.time > 0){
				var newEnergyLastGain:Number = _energyLastGain.time;
				var now:Number = serverUnixTime();
				var newEnergyValue:int = _energy;
				while(newEnergyLastGain < now && newEnergyValue < ConfManager.instance.getNumber('ENERGY_MAX')){
					newEnergyValue += 1;
					if(newEnergyValue >= ConfManager.instance.getNumber('ENERGY_MAX'))
						newEnergyLastGain = now;
					else
						newEnergyLastGain += ConfManager.instance.getNumber('ENERGY_GAIN_INTERVAL') * 1000;
				}
				_energy = newEnergyValue;
				_energyLastGain = new Date(newEnergyLastGain);

				if(!energyIsFull()){
					energyGainTimer.delay = gainEnergyTimeLeft();
					energyGainTimer.repeatCount = 1;
					energyGainTimer.reset();
					energyGainTimer.start();
				}
			} else if(_energy < ConfManager.instance.getNumber('ENERGY_MAX')){
				gainEnergy();
			}
		}

		private function onEnergyGainTimer(event:Event):void {
			energyGainTimer.stop();
			if(canGainEnergy()){
				gainEnergy();
			}
		}
	}
}