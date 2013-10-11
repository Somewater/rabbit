package com.somewater.rabbit.application.effects {
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;

	public class OfferFountainEffect extends GameFountainEffect{
		public function OfferFountainEffect(icon:DisplayObject, params:Object) {
			super([icon]);
			lifetime = 1000;
		}
	}
}
