/**
 * Когда кролика атакуют
 */
package com.somewater.rabbit.events {
	import flash.events.Event;

	public class HeroHealthEvent extends Event{
		public static const HERO_DAMAGE_EVENT:String = 'heroHealthEvent';

		public var oldHealth:Number;
		public var newHealth:Number;

		public function HeroHealthEvent(oldHealth:Number, newHealth:Number) {
			super(HERO_DAMAGE_EVENT);
			this.oldHealth = oldHealth;
			this.newHealth = newHealth;
		}

		public function get isDamage():Boolean {
			return newHealth < oldHealth;
		}

		public function get isMedication():Boolean {
			return newHealth > oldHealth;
		}

		public function isKilled():Boolean{
			return newHealth <= 0;
		}
	}
}
