package com.somewater.rabbit.application.windows {
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.AudioControls;
	import com.somewater.storage.Lang;

	public class OptionsWindow extends Window{

		private var audioControls:AudioControls;

		public function OptionsWindow() {
			super(Lang.t('OPTIONS'), null, null, [])
			setSize(270, 300);

			audioControls = new AudioControls();
			audioControls.x = (this.width - audioControls.width) * 0.5;
			audioControls.y = 120;
			addChild(audioControls);

			open();
		}

		override public function clear():void {
			super.clear();
			audioControls.clear();
		}
	}
}
