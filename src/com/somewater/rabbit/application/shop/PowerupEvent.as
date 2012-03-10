package com.somewater.rabbit.application.shop {
	import com.somewater.rabbit.storage.PowerupDef;

	import flash.events.Event;

	public class PowerupEvent extends Event{

		public static const POWERUP_EVENT:String = 'powerupEvent';

		public var powerup:PowerupDef;

		public function PowerupEvent(powerup:PowerupDef) {
			this.powerup = powerup;
			super(POWERUP_EVENT);
		}
	}
}
