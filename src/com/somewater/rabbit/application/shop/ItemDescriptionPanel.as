package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.Sprite;

	public class ItemDescriptionPanel extends Sprite implements IClear{

		public static const WIDTH:int = 200;

		private var title:EmbededTextField;
		private var text:EmbededTextField;
		private var border:Sprite;
		private var photo:Photo;

		public function ItemDescriptionPanel() {
			title = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 22, true, true, false, false, 'center');
			title.width = WIDTH;
			addChild(title);

			text = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true, true);
			text.width = WIDTH;
			addChild(text);

			border = Lib.createMC("interface.VerticalImage");
			border.x = 0;
			border.y = 155;
			addChild(border);

			photo = new Photo(null, Photo.ORIENTED_CENTER, 140, 200, 140/2, 200/2);
			photo.photoMask = border.getChildByName('photoMask');
		}

		public function show(powerup:PowerupDef):void
		{
			title.text = powerup.getTitle();
			text.text = powerup.getDescription();
			text.y = title.textHeight + 15;

			if(powerup.name == 'powerup_speed' && powerup.shop_photo && powerup.shop_photo.length > 2)
			{
				border.visible = true;
				photo.source = Lib.createMC(powerup.shop_photo);
			}
			else
			{
				border.visible = false;
			}
		}

		public function clear():void {
			photo.clear();
		}
	}
}
