package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.Sprite;

	public class ItemDescriptionPanel extends Sprite implements IClear{

		public static const WIDTH:int = 200;

		private var title:EmbededTextField;
		private var text:EmbededTextField;

		public function ItemDescriptionPanel() {
			title = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 22, true, true, false, false, 'center');
			title.width = WIDTH;
			addChild(title);

			text = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true, true);
			text.width = WIDTH;
			addChild(text);
		}

		public function show(powerup:PowerupDef):void
		{
			title.text = powerup.getTitle();
			text.text = powerup.getDescription();
			text.y = title.textHeight + 15;
		}

		public function clear():void {
		}
	}
}
