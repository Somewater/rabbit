package com.somewater.rabbit.application.tutorial {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.MovieClip;

	import flash.display.Sprite;

	public class HighlightArrow extends Sprite implements IClear{

		private var arrow:MovieClip;

		public function HighlightArrow() {
			arrow = Lib.createMC('tutorial.TutorialArrow')
			addChild(arrow);
		}

		public function clear():void {
			arrow.stop();
			if(parent)
				parent.removeChild(this);
		}
	}
}
