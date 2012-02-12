package com.somewater.rabbit.events {
	import flash.events.Event;

	public class OfferEvent extends Event{

		public static const OFFER_EVENT:String = 'offerEvent';

		public var x:int;
		public var y:int;

		public function OfferEvent(x:int, y:int) {
			this.x = x;
			this.y = y;
			super(OFFER_EVENT);
		}
	}
}
