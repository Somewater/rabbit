package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;
	import com.somewater.text.LinkLabel;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class AboutPage extends PageBase
	{
		private var leftButton:DisplayObject;
		private var items:Array = [];
		private var offerStat:OfferStatPanel;

		private var links:Array = [];
		private var testersScroller:RScroller;
		private var gdsScroller:RScroller;

		public function AboutPage()
		{
			super();

			var holder:Sprite = new Sprite();
			addChild(holder);

			var authorsTitle:EmbededTextField = new EmbededTextField(null, 0xDB661B, 21);
			authorsTitle.text = Lang.t('AUTHORS');
			authorsTitle.x = (Config.WIDTH - authorsTitle.textWidth) * 0.5;
			authorsTitle.y = 25;
			addChild(authorsTitle);

			var keys:Array = ['AUTHOR_ASFLASH','AUTHOR_SKINSIN','AUTHOR_NORDWULF'];
			var gds:Array = String(Lang.t('GAME_DESIGNERS') || '').split('|');
			var testers:Array = String(Config.loader.customHash['GAME_TESTERS'] || '').split(',');if(testers.length == 1 && testers[0] == '') testers = [];

			var nextY:int;
			var maxWidth:int;
			for (var i:int = 0; i < keys.length; i++)
			{
				var data:Array = Lang.t(keys[i]).split(';');
				var name:String = data[0];
				var jobs:String = data[1];
				var homepage:String = data[2];
				var item:AuthorItem = new AuthorItem(name,  jobs,  homepage, keys[i]);
				if(gds.length || tester.length)
				{
					item.x = 50;
					item.y = 95 + i * 120;
				}
				else
				{
					item.x = (Config.WIDTH - 300) * 0.5;
					item.y = 95 + i * 150;
				}
				holder.addChild(item);
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


			if(gds.length)
			{
				var gameDesignersTitle:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true);
				gameDesignersTitle.text = Lang.t('GAME_DESIGN_TITLE');
				gameDesignersTitle.x = DisplayObject(items[items.length - 1]).x;
				gameDesignersTitle.y = DisplayObject(items[items.length - 1]).y + DisplayObject(items[items.length - 1]).height;
				holder.addChild(gameDesignersTitle);

				var gdsHolder:Sprite = new Sprite();

				nextY = 0;
				maxWidth = 0;
				for each(var gd:String in gds)
				{
					var gdData:Array = gd.split(';');
					var gdName:String = gdData[0];
					var gdLink:String = gdData[1];
					var gdHint:String = gdData[2];
					var gameDesigner:LinkLabel = new LinkLabel(Config.FONT_SECONDARY, 0x31B1E8, 15, true);
					gameDesigner.y = nextY;
					nextY += gameDesigner.height;
					gdsHolder.addChild(gameDesigner);

					gameDesigner.text = gdName;
					gameDesigner.hint = gdHint;
					gameDesigner.data = gdLink;

					gameDesigner.addEventListener(LinkLabel.LINK_CLICK, onLinkClicked);
					links.push(gameDesigner);

					if(gameDesigner.width > maxWidth)
						maxWidth = gameDesigner.width;
				}

				gdsScroller = new RScroller();
				gdsScroller.content = gdsHolder;
				gdsScroller.x = gameDesignersTitle.x;
				gdsScroller.y = gameDesignersTitle.y + gameDesignersTitle.height + 5;
				gdsScroller.setSize(Math.max(220, maxWidth), Config.HEIGHT - gdsScroller.y - 20 - leftButton.height - 10);
				holder.addChild(gdsScroller);
			}


			if(testers.length)
			{
				var testersTitle:EmbededTextField = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true);
				testersTitle.text = Lang.t('GAME_TESTERS_TITLE');
				testersTitle.x = DisplayObject(items[0]).x + DisplayObject(items[items.length - 1]).width;
				testersTitle.y = DisplayObject(items[0]).y;
				addChild(testersTitle);

				var testersHolder:Sprite = new Sprite();

				nextY = 0;
				maxWidth = 0;
				for each(var ts:String in testers)
				{
					var testerData:Array = ts.split(';');
					var testerName:String = testerData[0];
					var testerLink:String = testerData[1];
					var testerHint:String = testerData[2];
					var tester:LinkLabel = new LinkLabel(Config.FONT_SECONDARY, 0x31B1E8, 11, true);
					tester.y = nextY;
					nextY += tester.height;
					testersHolder.addChild(tester);

					tester.text = testerName;
					tester.hint = testerHint;
					tester.data = testerLink;

					tester.addEventListener(LinkLabel.LINK_CLICK, onLinkClicked);
					links.push(tester);

					if(tester.width > maxWidth)
						maxWidth = tester.width;
				}

				testersScroller = new RScroller();
				testersScroller.content = testersHolder;
				testersScroller.x = testersTitle.x;
				testersScroller.y = testersTitle.y + testersTitle.height + 5;
				testersScroller.setSize(Math.max(170, maxWidth), Config.HEIGHT - testersScroller.y - 20);
				addChild(testersScroller);
			}
			else
				holder.x = (Config.WIDTH - AuthorItem.WIDTH - (logo.visible ? Config.WIDTH - logo.x : 0)) * 0.5;


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
			for each(var ll:LinkLabel in links)
			{
				ll.clear();
				ll.removeEventListener(LinkLabel.LINK_CLICK, onLinkClicked);
			}
			if(testersScroller)
				testersScroller.clear();
			if(gdsScroller)
				gdsScroller.clear();
		}

		private function onLinkClicked(event:Event):void {
			var data:String = LinkLabel(event.currentTarget).data as String;
			if(data && data.length)
			{
				if(data.indexOf('@') != -1)
				{
					if(data.substr(0,7) != 'mailto:')
						data = 'mailto:' + data;
				}
				else if(data.substr(0,7) != 'http://')
					data = 'http://' + data;
				navigateToURL(new URLRequest(data), '_blank')
			}
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
	public static const WIDTH:int = 300;

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
		var link:String = homepage;
		if(link.indexOf('@') != -1)
		{
			if(link.substr(0,7) != 'mailto:')
				link = 'mailto:' + link;
		}
		navigateToURL(new URLRequest(link), '_blank');
	}

	public function clear():void
	{
		homepageTF.removeEventListener(TextEvent.LINK, onLinkCLick)
		homepageTF.removeEventListener(MouseEvent.ROLL_OVER, onOver)
		homepageTF.removeEventListener(MouseEvent.ROLL_OUT, onOut)
	}

	override public function get width():Number {
		return WIDTH;
	}

	override public function get height():Number {
		return 100;
	}
}