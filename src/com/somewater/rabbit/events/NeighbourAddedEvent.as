package com.somewater.rabbit.events {
	import flash.events.Event;

	public class NeighbourAddedEvent extends Event{

		public static const NEIGHBOUR_ADDED_EVENT:String = 'neighbourAddedEvent';
		public var uid:String;

		public function NeighbourAddedEvent(uid:String) {
			this.uid = uid;
			super(NEIGHBOUR_ADDED_EVENT);
		}
	}
}
