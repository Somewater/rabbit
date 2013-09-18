package com.somewater.rabbit.application {
import com.somewater.control.IClear;
import com.somewater.rabbit.storage.Lib;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.storage.Lang;
import com.somewater.text.EmbededTextField;
import com.somewater.text.Hint;

import flash.display.DisplayObject;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.utils.Timer;

public class EnergyIndicator extends Sprite implements IClear{

	protected var user:UserProfile;
	private var refreshTimer:Timer;

	private var energyCounter:EmbededTextField;
	private var energyTimeCounter:EmbededTextField;

	public function EnergyIndicator(user:UserProfile = null) {
		if(!user) user = UserProfile.instance;
		this.user = user;
		user.addEventListener(UserProfile.CHANGE_USER_DATA, refreshUserData);
		createView();

		refreshTimer = new Timer(1000);
		refreshTimer.addEventListener(TimerEvent.TIMER, refreshUserData);

		refreshUserData();
		Hint.bind(this, hint)
	}

	private function hint():String {
		if(user.energyIsFull())
			return Lang.t('ENERGY_HINT_FULL');
		else
			return Lang.t('ENERGY_HINT_NO_FULL');
	}

	public function clear():void {
		if(user){
			user.removeEventListener(UserProfile.CHANGE_USER_DATA, refreshUserData);
			refreshTimer.removeEventListener(TimerEvent.TIMER, refreshUserData);
			if(refreshTimer.running) refreshTimer.stop();
			user = null;
			Hint.removeHint(this);
		}
	}

	private function createView():void {
		var core:DisplayObject = Lib.createMC('interface.EnergyIndicator');
		addChild(core);

		energyCounter = new EmbededTextField(null, 'w', 20, false, false, false, false, 'center');
		energyCounter.x = 8;
		energyCounter.y = 10;
		energyCounter.width = 35;
		energyCounter.height = 30;
		addChild(energyCounter);

		energyTimeCounter = new EmbededTextField(null, 'w', 16, false, false, false, false, 'center');
		energyTimeCounter.x = 47;
		energyTimeCounter.y = 13;
		energyTimeCounter.width = 68;
		energyTimeCounter.height = 30;
		addChild(energyTimeCounter);
	}

	private function refreshUserData(event:Event = null):void {
		setEnergy(user.getEnergy(false));
		if(user.energyIsFull()){
			setTime()
		} else {
			var timeLeft:int = user.gainEnergyTimeLeft();
			if(timeLeft > 0){
				if(!refreshTimer.running)
					refreshTimer.start();
				setTime(msToTimeFormat(timeLeft));
			} else {
				setTime();
			}
		}
	}

	private function setEnergy(value:int):void {
		energyCounter.text = value.toString();
	}

	private function setTime(value:String = ''):void {
		energyTimeCounter.text = value;
	}

	private static function msToTimeFormat(ms:int):String {
		var time:int = ms * 0.001;
		var seconds:int = time % 60;
		time = (time - seconds) / 60;
		var minutes:int = time % 60;
		var hours:int = (time - minutes) / 60;
		if(hours){
			return [hours, d(minutes), d(seconds)].join(':')
		}else if(minutes){
			return [d(minutes), d(seconds)].join(':')
		}else{
			return d(seconds);
		}
		function d(v:int):String {
			if(v > 9)
				return v.toString();
			else
				return '0' + v.toString();
		}
	}
}
}
