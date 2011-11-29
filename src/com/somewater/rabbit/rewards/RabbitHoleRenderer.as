package com.somewater.rabbit.rewards {
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;

	import flash.text.TextField;

	/**
	 * Отвечает за прорисовку наград на кроличьей полянке
	 */
	public class RabbitHoleRenderer extends IsoRenderer{

		public function RabbitHoleRenderer() {
		}

		override public function onFrame(elapsed:Number):void {
			if(_displayObject)
				super.onFrame(elapsed);
			else
			{
				super.onFrame(elapsed);
				if(_displayObject)
				    postprocessDisplayObject();
			}
		}

		/**
		 * Обработать мувик будки
		 */
		private function postprocessDisplayObject():void {
			var holeTitle:TextField = Config.application.createTextField(Config.FONT_SECONDARY, 0x6B450D, 12, true, false, false, false, 'center');
			holeTitle.width = 70;
			holeTitle.x = -25;
			holeTitle.y = -63;
			holeTitle.text = Config.loader.getUser().firstName && Config.loader.getUser().firstName.length ? Config.loader.getUser().firstName :
									(Config.loader.getUser().lastName ? Config.loader.getUser().lastName : '');
			clip.addChild(holeTitle);
		}
	}
}
