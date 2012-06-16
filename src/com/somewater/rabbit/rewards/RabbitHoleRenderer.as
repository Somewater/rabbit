package com.somewater.rabbit.rewards {
	import com.somewater.rabbit.IUserLevel;
	import com.somewater.rabbit.events.CustomizeEvent;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;

	import flash.display.MovieClip;

	import flash.events.MouseEvent;

	import flash.text.TextField;

	/**
	 * Отвечает за прорисовку наград на кроличьей полянке
	 */
	public class RabbitHoleRenderer extends IsoRenderer{

		private var holeCustomized:Boolean = false;

		public function RabbitHoleRenderer() {
			this.useMovieClip = true;
		}

		override public function onFrame(elapsed:Number):void {
			super.onFrame(elapsed);

			var _clip:MovieClip = this.displayObject as MovieClip;
			if(!holeCustomized && _clip != null)
			{
				var event:CustomizeEvent = new CustomizeEvent(_clip, CustomizeEvent.TYPE_HOLE);
				Config.application.dispatchEvent(event);
				if(event.applyed)
					holeCustomized = true;
				_clip.addEventListener(MouseEvent.CLICK, onHoleClicked)
				_clip.buttonMode = _clip.useHandCursor = true;
			}
		}

		private function onHoleClicked(e:MouseEvent):void {
			var _clip:MovieClip = this.displayObject as MovieClip;
			var event:CustomizeEvent = new CustomizeEvent(_clip, CustomizeEvent.TYPE_HOLE_CLICK);
			Config.application.dispatchEvent(event);
		}

		override protected function onRemove():void {
			var _clip:MovieClip = this.displayObject as MovieClip;
			if(_clip)
				_clip.removeEventListener(MouseEvent.CLICK, onHoleClicked)
			super.onRemove();
		}
	}
}
