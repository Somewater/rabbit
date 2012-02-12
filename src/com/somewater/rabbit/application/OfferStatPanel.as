package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.application.windows.OfferDescriptionWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.MovieClip;

	import flash.display.Sprite;
	import flash.events.MouseEvent;

	/**
	 * Отображает собранные офферы. Если на данный момент нет офферов
	 * (нет никаких акций, у панели нет визуального представления)
	 */
	public class OfferStatPanel extends Sprite implements IClear{

		public static const GAME_MODE:int = 1;
		public static const INTERFACE_MODE:int = 2;

		private var core:Sprite;
		private var textField:EmbededTextField;

		public function OfferStatPanel(visualMode:int) {
			if(OfferManager.instance.quantity)
			{
				core = Lib.createMC('interface.OfferStatPanel');
				addChild(core);
				textField = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 17, true);
				textField.width = 65;
				textField.x = 56;
				textField.y = 14.5;
				addChild(textField);

				UserProfile.bind(refresh);

				Hint.bind(this, hint);

				addEventListener(MouseEvent.CLICK, onClick);
				buttonMode = useHandCursor = true;

				switch(visualMode)
				{
					case GAME_MODE:
						(core.getChildByName('icon') as MovieClip).gotoAndStop(1);
						break
					case INTERFACE_MODE:
						(core.getChildByName('icon') as MovieClip).gotoAndStop(2);
						core.getChildByName('background').alpha = 0;
						break
				}
			}
		}

		private function onClick(event:MouseEvent):void {
			new OfferDescriptionWindow();
		}

		private function refresh():void
		{
			textField.text = UserProfile.instance.offers + ' / ' + OfferManager.instance.prizeQuantity;
		}

		public function clear():void {
			UserProfile.unbind(refresh);
			Hint.removeHint(this)
			removeEventListener(MouseEvent.CLICK, onClick)
		}

		private function hint():String
		{
			return Lang.t('OFFERS_HINT', {harvested: UserProfile.instance.offers, need: OfferManager.instance.prizeQuantity});
		}
	}
}
