package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.application.buttons.GreenButton;
	import com.somewater.rabbit.application.commands.OpenRewardLevelCommand;
	import com.somewater.rabbit.application.commands.StartNextLevelCommand;
	import com.somewater.rabbit.application.tutorial.TutorialLevelDef;
	import com.somewater.rabbit.application.tutorial.TutorialManager;
import com.somewater.rabbit.application.windows.NeedMoreEnergyWindow;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
import com.somewater.text.Hint;

import flash.display.DisplayObject;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MainMenuPage extends PageBase
	{
		private const labelToIcon:Object =
		{
			 'START_GAME':'interface.IconPlay'
			,'CONTINUE_GAME':'interface.IconPlay'
			,'LEVEL_SELECTION':'interface.IconLevels'
			,'MY_ACHIEVEMENTS':'interface.IconRewards'
			,'ABOUT_GAME':'interface.IconCopyright'
			,'TUTORIAL_BTN':'interface.IconTutorial'
			,'SHOP_MENU_BTN':'interface.IconShop'

		};

		private var buttons:Array;
		private var audioControls:AudioControls
		private var friendBar:FriendBar;
		private var offerStat:OfferStatPanel;

		private var topLink:EmbededTextField;
		private var sponsorLogo:DisplayObject;
		private var copyrightBtn:OrangeButton;
		private var energyIndicator:EnergyIndicator;
		
		public function MainMenuPage()
		{
			var beginner:Boolean = UserProfile.instance.levelNumber == 1;// если не пройдено не олдного уровня
			buttons = [(beginner?"START_GAME":"CONTINUE_GAME"),
						"LEVEL_SELECTION",
						"MY_ACHIEVEMENTS"
					  ];

			buttons.splice((beginner ? 0 : 1), 0, 'TUTORIAL_BTN');

			if(!Config.memory['hideShop'])
				buttons.splice(buttons.indexOf('MY_ACHIEVEMENTS'), 0, "SHOP_MENU_BTN");// ставим пеерд "Ми нарады"

			if(Config.loader.hasFriendsApi)
			{
				friendBar = new FriendBar();
				friendBar.x = 35;
				friendBar.y = Config.HEIGHT -  FriendBar.HEIGHT - 40;

				if(!Config.memory['hideTop'])
				{
					createTopLink();
				}

				addChild(friendBar);
			} else if(Config.memory['showTopButton']){
				createTopLink();
			}

			// +2 к количеству кнопок, т.к. учитываются контролы аудио (примерно как 2 кнопки по высоте)
			var buttonsY:int = ((friendBar ? friendBar.y : Config.HEIGHT) - ((buttons.length + 2) * 55)) * 0.5;
			var nextButtonsY:int = 0;

			var b:OrangeButton;
			for(var i:int = 0;i<buttons.length;i++)
			{
				b = labelToButton((buttons[i]));
				b.label = Lang.t(buttons[i]);
				buttons[i] = b;
				b.addEventListener(MouseEvent.CLICK, onSomeButtonClick);
				if(i == 0)
				{
					b.setSize(180, 48);
					b.textField.size = 17;
					b.textField.y -= 2;
					b.icon.scaleX = b.icon.scaleY = 1.45;
				}
				else
				{
					b.setSize(180, 32);
				}
				b.x = (Config.WIDTH - b.width) * 0.5;
				b.y = buttonsY + nextButtonsY;
				nextButtonsY += b.height + 23;
				addChild(b);
			}
			audioControls = new AudioControls();
			audioControls.x = b.x;
			audioControls.y = b.y + 55;
			addChild(audioControls);
			
			if(logo.visible)
				logo.visible = (friendBar == null || friendBar.x + FriendBar.WIDTH + 10 < logo.x) && logo.x + logo.width < Config.WIDTH;

			offerStat = new OfferStatPanel(OfferStatPanel.INTERFACE_MODE);
			offerStat.x = Config.WIDTH - offerStat.width - 15;
			offerStat.y = 15;
			addChild(offerStat);

			var sponsorLogoClass:Class = Config.loader.getClassByName('interface.SponsorLogo');
			if(sponsorLogoClass != null)
			{
				var sponsorLogoHolder:Sprite = new Sprite();
				sponsorLogo = new sponsorLogoClass();
				sponsorLogoHolder.addChild(sponsorLogo);
				addChild(sponsorLogoHolder)
				sponsorLogoHolder.x = 40;
				sponsorLogoHolder.y = DisplayObject(buttons[0]).y;
				sponsorLogoHolder.buttonMode = sponsorLogoHolder.useHandCursor = true;
			}

			copyrightBtn = new CopyrightButton()
			copyrightBtn.y = DisplayObject(buttons[0]).y;
			copyrightBtn.x = Config.WIDTH - copyrightBtn.width - copyrightBtn.y;
			copyrightBtn.addEventListener(MouseEvent.CLICK, onCopyrightClicked);
			addChild(copyrightBtn)

			if(UserProfile.instance.levelNumber > 1 || !UserProfile.instance.energyIsFull()){
				energyIndicator = new EnergyIndicator();
				energyIndicator.y = DisplayObject(buttons[0]).y;
				energyIndicator.x = 40;
				energyIndicator.addEventListener(MouseEvent.CLICK, onEnergyIndicatorClick);
				addChild(energyIndicator);
			}
		}
		
		private function createTopLink():void {
			topLink = new EmbededTextField(Config.FONT_SECONDARY, 0x31B1E8, 16, true);
			addChild(topLink);
			topLink.addEventListener(MouseEvent.CLICK, onTopLinkClick);
			topLink.addEventListener(MouseEvent.ROLL_OVER, onLinkOver)
			topLink.addEventListener(MouseEvent.ROLL_OUT, onLinkOut)
			topLink.htmlText = "<a href='event:'>"+Lang.t('USERS_TOP')+"</a>";
			topLink.mouseEnabled = true;
			topLink.underline = true;
			
			if(friendBar){
				topLink.x = friendBar.x;
				topLink.y = friendBar.y - 35;
			} else {
				topLink.x = 30;
				topLink.y = Config.HEIGHT - topLink.textHeight - 30;
			}
		}

		override public function clear():void
		{
			for(var i:int = 0;i<buttons.length;i++)
				buttons[i].removeEventListener(MouseEvent.CLICK, onSomeButtonClick);
			if(friendBar)
				friendBar.clear();
			audioControls.clear();
			offerStat.clear();
			if(topLink)
			{
				topLink.removeEventListener(MouseEvent.CLICK, onTopLinkClick);
				topLink.removeEventListener(MouseEvent.ROLL_OVER, onLinkOver)
				topLink.removeEventListener(MouseEvent.ROLL_OUT, onLinkOut)
			}
			if(copyrightBtn)
				copyrightBtn.removeEventListener(MouseEvent.CLICK, onCopyrightClicked);
			if(energyIndicator){
				energyIndicator.clear();
				energyIndicator.removeEventListener(MouseEvent.CLICK, onEnergyIndicatorClick);
			}
		}
		
		override protected function createGround():void
		{
			super.createGround();
			var subGround:DisplayObject = Lib.createMC("interface.MainPageGround");
			subGround.x = (Config.WIDTH - 810) * 0.5;
			subGround.y = (Config.HEIGHT - 655) * 0.5;
			addChild(subGround);
		}
		
		private function onSomeButtonClick(e:MouseEvent):void
		{
			if(!OrangeButton(e.currentTarget).enabled)
				return;

			switch(OrangeButton(e.currentTarget).label)
			{
				case 	Lang.t("START_GAME"):
				case 	Lang.t("CONTINUE_GAME"):
					 	new StartNextLevelCommand().execute();
						break;
				case Lang.t("LEVEL_SELECTION"):
						Config.application.startPage("levels");
						break;
				case Lang.t("SHOP_MENU_BTN"):
						Config.application.startPage('shop');
						break;
				case Lang.t("MY_ACHIEVEMENTS"):
						new OpenRewardLevelCommand(UserProfile.instance).execute();
						break;
				case Lang.t("USERS_TOP"):
						onTopLinkClick();
						break;
				case Lang.t("ABOUT_GAME"):
						onCopyrightClicked();
						break;
				case Lang.t('TUTORIAL_BTN'):
						Config.application.startGame(new TutorialLevelDef())
						break;
			}
		}

		private function onTopLinkClick(event:MouseEvent = null):void {
			if(Config.memory['customTop'])
				Config.memory['customTop'](UserProfile.instance);
			else
				Config.application.startPage("top");
		}

		private function onCopyrightClicked(event:MouseEvent = null):void {
			Config.application.startPage("about");
		}

		// для тьюториала
		public function get startGameButton():OrangeButton
		{
			return buttons[0];
		}

		// для тьюториала
		public function get rewardButton():OrangeButton
		{
			for each(var b:OrangeButton in buttons)
				if(b.label == Lang.t('MY_ACHIEVEMENTS'))
					return b;
			disableButtons(false);
			return null;
		}

		// для тьюториала
		public function get levelsButton():OrangeButton
		{
			for each(var b:OrangeButton in buttons)
				if(b.label == Lang.t('LEVEL_SELECTION'))
					return b;
			disableButtons(false);
			return null;
		}

		// для тьюториала
		public function disableButtons(disable:Boolean = true):void
		{
			for each(var b:OrangeButton in buttons)
				b.enabled = !disable;
		}

		// для тьюториала
		public function getFriendBar():FriendBar
		{
			return friendBar;
		}

		private function labelToButton(label:String):OrangeButton
		{
			var b:OrangeButton = label == 'SHOP_MENU_BTN' ? new BrightGreenButton() : new OrangeButton();
			b.icon = labelToIcon[label] ? Lib.createMC(labelToIcon[label]) : null;
			return b
		}

		private function onLinkOut(event:MouseEvent):void {
			EmbededTextField(event.currentTarget).underline = true;
		}

		private function onLinkOver(event:MouseEvent):void {
			EmbededTextField(event.currentTarget).underline = false;
		}

		private function onEnergyIndicatorClick(event:MouseEvent):void {
			if(!UserProfile.instance.energyIsFull())
				new NeedMoreEnergyWindow(null, null, Lang.t('BUY_ENERGY_WND_TITLE'));
		}
	}
}

import com.somewater.rabbit.application.OrangeButton;
import com.somewater.rabbit.application.buttons.GreenButton;
import com.somewater.rabbit.storage.Lib;

import flash.display.Sprite;

class CopyrightButton extends OrangeButton
{
	public function CopyrightButton()
	{
		super();

		setSize(32,32);
		icon = Lib.createMC('interface.IconCopyright');
	}


	override protected function resize():void {
		super.resize();

		if(_icon)
		{
			_icon.x = _width * 0.5;
		}
	}
}

class BrightGreenButton extends GreenButton {

	public function BrightGreenButton(){
		super();
		this.color = 0x226822;
	}

	override protected function createGround(type:String):Sprite {
		return Lib.createMC(this.enabled ? "interface.BrightGreenButton_" + type : 'interface.ShadowOrangeButton_up');
	}
}