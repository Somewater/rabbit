package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.events.MouseEvent;

	public class AboutPage extends PageBase
	{
		private var leftButton:DisplayObject;
		private var items:Array = [];
		private var offerStat:OfferStatPanel;

		public function AboutPage()
		{
			super();

			var authorsTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B, 21);
			authorsTitle.text = Lang.t('AUTHORS');
			authorsTitle.x = (Config.WIDTH - authorsTitle.textWidth) * 0.5;
			authorsTitle.y = 25;
			addChild(authorsTitle);

			var keys:Array = ['AUTHOR_ASFLASH','AUTHOR_SKINSIN','AUTHOR_NORDWULF'];
			for (var i:int = 0; i < keys.length; i++)
			{
				var data:Array = Lang.t(keys[i]).split(';');
				var name:String = data[0];
				var jobs:String = data[1];
				var homepage:String = data[2];
				var item:AuthorItem = new AuthorItem(name,  jobs,  homepage, keys[i]);
				item.x = (Config.WIDTH - 300) * 0.5;
				item.y = 95 + i * 200;
				addChild(item);
				items.push(item);
			}
			
			leftButton = Lib.createMC("interface.LeftButton");
			leftButton.x = 20;
			leftButton.y = Config.HEIGHT - leftButton.height - 20;
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);


			logo.visible = logo.visible ? logo.x + logo.width < Config.WIDTH : false;

			offerStat = new OfferStatPanel(OfferStatPanel.INTERFACE_MODE);
			offerStat.x = Config.WIDTH - offerStat.width - 15;
			offerStat.y = 15;
			addChild(offerStat);

			Config.stat(Stat.ABOUT_PAGE_OPENED);
		}

		private function onLeftButtonClick(event:MouseEvent):void {
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.application.startPage("main_menu");
		}


		override public function clear():void {
			super.clear();
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.removeHint(leftButton);
			if(items)
				for (var i:int = 0; i < items.length; i++)
					IClear(items[i]).clear();
			items = null;
			offerStat.clear();
		}
	}
}

import com.somewater.control.IClear;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.text.EmbededTextField;

import flash.display.DisplayObject;
import flash.display.MovieClip;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;

class AuthorItem extends Sprite implements IClear
{
	private var titleTF:EmbededTextField;
	private var jobTF:EmbededTextField;
	private var homepageTF:EmbededTextField;
	private var icon:MovieClip;
	private var homepage:String;

	public function AuthorItem(name:String, job:String, homepage:String, key:String)
	{
		this.homepage = homepage;

		icon = Lib.createMC('interface.AuthorItem');
		icon.gotoAndStop(key);
		addChild(icon);

		titleTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 18, true);
		titleTF.mouseEnabled = false;
		titleTF.x = 80;
		titleTF.y = -5;
		addChild(titleTF);

		jobTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true); ;
		jobTF.mouseEnabled = false;
		jobTF.x = 80;
		jobTF.y = 20;
		addChild(jobTF);

		homepageTF = new EmbededTextField(Config.FONT_SECONDARY, 0x31B1E8, 12, true);
		homepageTF.x = 80;
		homepageTF.y = 55;
		addChild(homepageTF);
		homepageTF.addEventListener(MouseEvent.CLICK, onLinkCLick);
		homepageTF.addEventListener(MouseEvent.ROLL_OVER, onOver)
		homepageTF.addEventListener(MouseEvent.ROLL_OUT, onOut)

		titleTF.text = name;
		jobTF.text = job;
		homepageTF.htmlText = "<a href='event:'>"+homepage.replace(/^http\:\/\//,'').replace(/\/$/,'')+"</a>";
		homepageTF.mouseEnabled = true;
		onOut(null);
	}

	private function onOut(event:MouseEvent):void {
		homepageTF.underline = true;
	}

	private function onOver(event:MouseEvent):void {
		homepageTF.underline = false;
	}

	private function onLinkCLick(event:Event):void {
		navigateToURL(new URLRequest(homepage), '_blank');
	}

	public function clear():void
	{
		homepageTF.removeEventListener(TextEvent.LINK, onLinkCLick)
		homepageTF.removeEventListener(MouseEvent.ROLL_OVER, onOver)
		homepageTF.removeEventListener(MouseEvent.ROLL_OUT, onOut)
	}
}