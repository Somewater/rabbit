package com.somewater.rabbit.application.windows {
import com.somewater.rabbit.application.RewardManager;
import com.somewater.rabbit.application.commands.PostingFriendsInviteCommand;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.RewardDef;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.storage.Lang;

	import flash.display.DisplayObject;

	import flash.display.Shape;
	import flash.display.Sprite;

	public class OfferDescriptionWindow extends WindowWithImage{
	public function OfferDescriptionWindow() {

		super();

		setSize(WIDTH, HEIGHT);

		var image:DisplayObject = PostingFactory.getImage("images.OfferWindowImage");
		var imageHolder:Sprite = new Sprite();
		imageHolder.addChild(image)

		createTextAndImage(Lang.t('OFFERS_WINDOW_TITLE'), Lang.t('OFFERS_WINDOW_TEXT'), imageHolder);

		tf.x -= 15;// KLUDGE чтобы текст был так же как в дизайне, допуская перносы строк втех же местах
		tf.width += 15;

		open();

		if(Config.gameModuleActive)
		{
			Config.game.pause();
		}
	}


	override public function close():void {
		super.close();

		if(Config.gameModuleActive)
		{
			Config.game.start();
		}
	}
	}
}
