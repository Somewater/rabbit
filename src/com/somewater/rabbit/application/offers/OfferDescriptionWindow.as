package com.somewater.rabbit.application.offers {
	import com.somewater.display.Photo;
	import com.somewater.rabbit.application.windows.*;
	import com.somewater.rabbit.application.RewardManager;
import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
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

		private var imageSlug:String;

		public function OfferDescriptionWindow(titleArg:String = null, textArg:String = null, imageSlug:String = null) {

			super();

			setSize(WIDTH, HEIGHT);

			this.imageSlug = imageSlug || offerImage()
			var image:DisplayObject = PostingFactory.getImage(this.imageSlug);

			createTextAndImage(Lang.t(titleArg || offerTitle()), Lang.t(textArg || offerText()), image);

			tf.x -= 15;// KLUDGE чтобы текст был так же как в дизайне, допуская перносы строк втех же местах
			tf.width += 15;

			open();

			if(Config.gameModuleActive)
			{
				Config.game.pause();
			}

			titleTF.width = this.width * 0.9
			titleTF.x = (this.width - titleTF.textWidth) * 0.5;
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
			return "OFFERS_WINDOW_TEXT";
		}

		protected function offerImage():String {
			return "images.OfferWindowImage"
		}


		override protected function createTextAndImage(title:String, text:String = null, image:* = null):void {
			super.createTextAndImage(title, text, image);
			photo.visible = false;
			var img:DisplayObject = Lib.createMC(imageSlug);
			img.x = 0;
			img.y = 0;
			border.addChild(img);
			img.mask = border.getChildByName('photoMask');
		}
	}
}