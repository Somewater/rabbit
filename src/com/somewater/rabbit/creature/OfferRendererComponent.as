package com.somewater.rabbit.creature {
	import com.somewater.display.blitting.BlitManager;
	import com.somewater.display.blitting.MovieState;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;

	import flash.display.FrameLabel;

	import flash.display.MovieClip;

	public class OfferRendererComponent extends IsoRenderer{
		public function OfferRendererComponent() {
		}


		override protected function onClipInited():void {
			if(Config.blitting)
			{
				var states:Array = BlitManager.instance.getStates(this.slug);
				var state:MovieState = states[int(Math.random() * states.length)];
				this.state = state.name;
			}
			else
			{
				// переставляем анимацию на один из стейтов
				var selectedState:FrameLabel = (this.displayObject as MovieClip).currentLabels[int(Math.random() *
															(this.displayObject as MovieClip).currentLabels.length)];
 				this.state = selectedState.name;
			}
		}
	}
}
