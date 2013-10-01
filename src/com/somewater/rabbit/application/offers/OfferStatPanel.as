package com.somewater.rabbit.application.offers {
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.offers.OfferDescriptionWindow;
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
		private var type:int;

		public function OfferStatPanel(visualMode:int, type:int) {
			if(OfferManager.instance.active)
			{
				core = Lib.createMC('interface.OfferStatPanel');
				addChild(core);
				textField = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 17, true);
				textField.width = 65;
				textField.x = 56;
				textField.y = 14.5;
				addChild(textField);

				this.type = type;

				UserProfile.bind(refresh);

				Hint.bind(this, hint);

				addEventListener(MouseEvent.CLICK, onClick);
				buttonMode = useHandCursor = true;

				switch(visualMode)
				{
					case GAME_MODE:
						(core.getChildByName('icon') as MovieClip).gotoAndStop(1 + type * 2);
						break
					case INTERFACE_MODE:
						(core.getChildByName('icon') as MovieClip).gotoAndStop(2 + type * 2);
						//core.getChildByName('background').visible = false;
						for(var i:int = 0; i < core.getChildIndex(core.getChildByName('icon')); i++)
							core.getChildAt(i).visible = false;
						var buttonGround:OrangeButton = new OrangeButton();
						buttonGround.setSize(core.width, core.height);
						buttonGround.y = 3;
						core.addChildAt(buttonGround, core.getChildIndex(core.getChildByName('icon')));
						(core.getChildByName('icon') as Sprite).mouseEnabled = false;
						break
				}
			}
		}

		private function onClick(event:MouseEvent):void {
			var titleArg:String = 'OFFERS_WND_TITLE_0' + type;
			var textArg:String = 'OFFERS_WND_TEXT_' + type;
			if(UserProfile.instance.offersByType(type) >= OfferManager.instance.prizeQuantityByType(type)){
				textArg = 'OFFERS_WND_ALREADY_TEXT_' + type;
				Config.application.message(textArg);
				return;
			}
			new OfferDescriptionWindow(titleArg,
					textArg,
					"images.OfferWindowImage_" + type);
		}

		private function refresh():void
		{
			textField.text = UserProfile.instance.offersByType(type) + ' / ' + OfferManager.instance.prizeQuantityByType(type);
		}

		public function clear():void {
			UserProfile.unbind(refresh);
			Hint.removeHint(this)
			removeEventListener(MouseEvent.CLICK, onClick)
		}

		private function hint():String
		{
			if(type == 0)
				return Lang.t("{harvested:Собрана|Собрано|Собрано} {harvested} {harvested:рыбья косточка|рыбьи косточки|рыбьих косточек} из {need}",
						{harvested: UserProfile.instance.offersByType(type), need: OfferManager.instance.prizeQuantityByType(type)});
			else if(type == 1)
				return Lang.t("{harvested:Собран|Собрано|Собрано} {harvested} {harvested:штурвал|штурвала|штурвалов} из {need}",
						{harvested: UserProfile.instance.offersByType(type), need: OfferManager.instance.prizeQuantityByType(type)});
			else if(type == 2)
				return Lang.t("{harvested:Собран|Собрано|Собрано} {harvested} {harvested:сундучек|сундучка|сундучков} из {need}",
						{harvested: UserProfile.instance.offersByType(type), need: OfferManager.instance.prizeQuantityByType(type)});
			return ''
		}
	}
}
