package com.somewater.rabbit.creature {
	import com.somewater.rabbit.iso.IsoRenderer;

	import flash.display.FrameLabel;

	import flash.display.MovieClip;

	public class OfferRendererComponent extends IsoRenderer{
		public function OfferRendererComponent() {
		}


		override protected function onClipInited(mc:MovieClip):void {
			// переставляем анимацию на один из стейтов
			var selectedState:FrameLabel = mc.currentLabels[int(Math.random() * mc.currentLabels.length)];
 			this.state = selectedState.name;
		}
	}
}
