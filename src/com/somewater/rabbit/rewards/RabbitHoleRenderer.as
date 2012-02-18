package com.somewater.rabbit.rewards {
	import com.somewater.rabbit.IUserLevel;
	import com.somewater.rabbit.events.CustomizeEvent;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;

	import flash.text.TextField;

	/**
	 * Отвечает за прорисовку наград на кроличьей полянке
	 */
	public class RabbitHoleRenderer extends IsoRenderer{

		private var holeCustomized:Boolean = false;

		public function RabbitHoleRenderer() {
		}

		override public function onFrame(elapsed:Number):void {
			super.onFrame(elapsed);

			if(!holeCustomized && _clip != null)
			{
				var event:CustomizeEvent = new CustomizeEvent(_clip, CustomizeEvent.TYPE_HOLE);
				Config.application.dispatchEvent(event);
				if(event.applyed)
					holeCustomized = true;
			}
		}
	}
}
