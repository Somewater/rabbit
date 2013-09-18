package com.somewater.rabbit.application.offers {
	import com.somewater.rabbit.storage.Config;

	public class OfferPrizeCongratulationWindow extends OfferDescriptionWindow{

		private var offersQueue:Array;
		private var type:int;

		public function OfferPrizeCongratulationWindow(offersQueue:Array) {
			this.offersQueue = offersQueue.slice();
			this.type = this.offersQueue.pop();
			var textArg:String = '';
			if(type == 0)
				textArg = "Йохохо, братец-кролик! Ты храбро сражался и получаешь награду - набор супер-энергетиков: ускорение и защиту от всех врагов!";
			else if(type == 1)
				textArg = "Ахой! Разрази меня гром! Тебе удалось сделать это! Пиратский комплект для жилища Кроля - твой, заметано!";
			else if(type == 2)
				textArg = "Аррр! Карамба! Ты выиграл 50 кругликов и теперь богат, как губернатор Ямайки!";
			super("Ура, победа!!!", textArg, "images.OfferWindowImage_" + type);
		}

		override public function close():void {
			super.close();
			if(offersQueue.length){
				new OfferPrizeCongratulationWindow(offersQueue.slice());
			}
		}
	}
}
