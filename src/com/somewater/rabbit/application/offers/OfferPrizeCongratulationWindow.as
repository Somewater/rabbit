package com.somewater.rabbit.application.offers {
	import com.somewater.rabbit.storage.Config;

	public class OfferPrizeCongratulationWindow extends OfferDescriptionWindow{

		private var offersQueue:Array;
		private var type:int;

		public function OfferPrizeCongratulationWindow(offersQueue:Array) {
			this.offersQueue = offersQueue.slice();
			this.type = this.offersQueue.pop();
			super(null, null, "images.OfferWindowImage_" + type);
		}

		override public function close():void {
			super.close();
			if(offersQueue.length){
				new OfferPrizeCongratulationWindow(offersQueue.slice());
			}
		}
	}
}
