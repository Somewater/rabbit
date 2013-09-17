package com.somewater.rabbit.application.offers {
	import com.somewater.rabbit.application.windows.*;
	import com.somewater.rabbit.application.RewardManager;
import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.RewardDef;
import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.storage.Lang;
	import com.somewater.storage.Lang;

	import flash.display.DisplayObject;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class OfferDescriptionWindow extends WindowWithImage{
		public function OfferDescriptionWindow(titleArg:String = null, textArg:String = null, imageSlug:String = null) {

			super();

			setSize(WIDTH, HEIGHT);

			var image:DisplayObject = PostingFactory.getImage(imageSlug || offerImage());
			var imageHolder:Sprite = new Sprite();
			imageHolder.addChild(image)

			createTextAndImage(Lang.t(titleArg || offerTitle()), Lang.t(textArg || offerText()), imageHolder);

			tf.x -= 15;// KLUDGE чтобы текст был так же как в дизайне, допуская перносы строк втех же местах
			tf.width += 15;

			open();

			if(Config.gameModuleActive)
			{
				Config.game.pause();
			}
		}

		override protected function onButtonClick_handler(e:MouseEvent):void {
			close();
			if(!Config.gameModuleActive){
				Config.application.startPage("levels");
			}
		}

		override public function close():void {
			super.close();

			if(Config.gameModuleActive)
			{
				Config.game.start();
			}
		}

		protected function offerTitle():String {
			return 'OFFERS_WINDOW_TITLE';
		}

		protected function offerText():String {
			return 'OFFERS_WINDOW_TEXT';
		}

		protected function offerImage():String {
			return "images.OfferWindowImage"
		}
}
}
