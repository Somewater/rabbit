package com.somewater.rabbit.application {
import com.somewater.control.IClear;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.text.EmbededTextField;

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
	}

	public function clear():void {
		user.removeEventListener(UserProfile.CHANGE_USER_DATA, refreshUserData);
		refreshTimer.removeEventListener(TimerEvent.TIMER, refreshUserData);
		if(refreshTimer.running) refreshTimer.stop();
		user = null;
	}

	private function createView():void {
		energyCounter = new EmbededTextField();
		addChild(energyCounter);

		energyTimeCounter = new EmbededTextField(null, 'b');
		energyTimeCounter.x = energyCounter.width + 5;
		addChild(energyTimeCounter);

		graphics.beginFill(0xCCDD00, 0.4);
		graphics.drawRect(0, 0, energyTimeCounter.x + energyTimeCounter.width, energyTimeCounter.height);
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
		var seconds = time % 60;
		time = (time - seconds) / 60;
		var minutes = time % 60;
		var hours = (time - minutes) / 60;
		if(hours){
			return [hours, minutes, seconds].join(':')
		}else if(minutes){
			return [minutes, seconds].join(':')
		}else{
			return seconds.toString();
		}
	}
}
}
