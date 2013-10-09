package com.somewater.rabbit.application.map {
	import com.somewater.control.IClear;
	import com.somewater.display.CorrectSizeDefinerSprite;
	import com.somewater.rabbit.application.AudioControls;
	import com.somewater.rabbit.application.EnergyIndicator;
	import com.somewater.rabbit.application.FriendBar;
	import com.somewater.rabbit.application.ImaginaryGameUser;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.PageBase;
	import com.somewater.rabbit.application.RScroller;
	import com.somewater.rabbit.application.commands.OpenRewardLevelCommand;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.application.offers.OfferStatPanel;
	import com.somewater.rabbit.application.tutorial.HighlightArrow;
	import com.somewater.rabbit.application.windows.NeedMoreEnergyWindow;
	import com.somewater.rabbit.application.windows.OptionsWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	public class MapPage extends PageBase{

		private static const CORE_HEIGHT:int = 1500;
		private static var lastShopStart:Boolean = false;
		private static var lastHoleStart:Boolean = false;

		private static const friendPosExceptins:Object = {
			4: [-6, 70, -8, 8],
			6: [70, -6, 8, -8],
			8: [-6, 70, -4, 10],
			9: [-6, 70, -8, 8],
			14: [-10, 5, -11, -1],
			15: [70, 70, 4, 8],
			16: [70, 70, 4, 8],
			19: [-6, 70, -8, 8],
			20: [70, -6, 8, -8],
			21: [70, -6, 2, -8],
			23: [70, -6, 8, -2],
			24: [-6, 70, -8, 8]
		};

		protected var core:MovieClip;
		protected var scroller:MapRScroller;
		protected var levelIcons:Array;
		protected var highlightArrow:HighlightArrow;
		private var mouseMoveStartCoords:Point = new Point();
		protected var friendBar:FriendBar;

		private var shopButton:OrangeButton;
		private var holeButton:OrangeButton;
		private var energyIndicator:EnergyIndicator;
		private var offerButtons:Array = [];
		private var optionsButton:OrangeButton;
		private var friendIcons;

		public function MapPage() {
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onAddedToStage(event:Event):void {
			createCore();

			scroller = new MapRScroller();
			scroller.scrollSpeed = 0.05;
			scroller.scrollFullThumb = false;
			scroller.setSize(0, Config.HEIGHT);
			addChild(scroller);
			scroller.x = Config.WIDTH;
			scroller.y = 0;
			scroller.addEventListener(Event.CHANGE, onScroll);
			var scrollContent:Sprite = new CorrectSizeDefinerSprite(0, CORE_HEIGHT);
			scroller.content = scrollContent;
			scrollToUserCurrentPos();
			onScroll();

			friendBar = new FriendBar();
			friendBar.x = 10;
			friendBar.y = Config.HEIGHT -  friendBar.HEIGHT - 10;
			addChild(friendBar);
			friendBar.rollDown(true)

			shopButton = new BrightGreenButton();
			shopButton.label = Lang.t('SHOP_MENU_BTN');
			shopButton.icon = Lib.createMC('interface.IconShop')
			shopButton.setSize(180, 32);
			shopButton.x =  Config.WIDTH - shopButton.width - 30;
			shopButton.y = 10;
			shopButton.addEventListener(MouseEvent.CLICK, onShopClick)
			addChild(shopButton);

			holeButton = new OrangeButton();
			holeButton.label = Lang.t('MY_ACHIEVEMENTS');
			holeButton.icon = Lib.createMC('interface.IconRewards')
			holeButton.setSize(180, 32);
			holeButton.x = shopButton.x;
			holeButton.y = holeButton.y + 50;
			holeButton.addEventListener(MouseEvent.CLICK, onHoleClick)
			addChild(holeButton);

			if(UserProfile.instance.levelNumber > 1 || !UserProfile.instance.energyIsFull()){
				energyIndicator = new EnergyIndicator();
				energyIndicator.y = 10;
				energyIndicator.x = 10;
				energyIndicator.addEventListener(MouseEvent.CLICK, onEnergyIndicatorClick);
				addChild(energyIndicator);
			}

			optionsButton = new OrangeButton();
			optionsButton.setSize(48, 48);
			optionsButton.icon = Lib.createMC('interface.OptionsIcon');
			optionsButton.x = (energyIndicator ? energyIndicator.x + energyIndicator.width + 10: 10);
			optionsButton.y = 10;
			optionsButton.addEventListener(MouseEvent.CLICK, onOptionsClicked);
			Hint.bind(optionsButton, Lang.t('OPTIONS'));
			addChild(optionsButton);

			if(OfferManager.instance.active){
				for each(var offerType:int in OfferManager.instance.types) {
					var offerStat:OfferStatPanel = new OfferStatPanel(OfferStatPanel.INTERFACE_MODE, offerType);
					offerStat.x = optionsButton.x + optionsButton.width + 10 + offerType * 130;
					offerStat.y = 10 - 3;
					addChild(offerStat);
					offerButtons.push(offerStat);
				}
			}

			if(UserProfile.instance.levelNumber == 1){
				highlightArrow = new HighlightArrow();
				highlightArrow.rotation = 0;
				highlightArrow.x = 33;
				highlightArrow.y = 0;
				levelIcons[0].addChild(highlightArrow);
			}
		}

		override public function clear():void {
			super.clear();
			scroller.clear();
			scroller.removeEventListener(Event.CHANGE, onScroll);
			for each(var lIcon:MapLevelIcon in levelIcons){
				lIcon.clear();
				lIcon.removeEventListener(MouseEvent.CLICK, onLevelClick)
			}
			levelIcons = null;
			core.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownOnMap);
			core.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpOnMap);
			core.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUpOnMap);
			this.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			core.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveOnMap);
			if(stage) stage.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUpOnStage);
			clearButton(core.hole);
			clearButton(core.shop);
			shopButton.removeEventListener(MouseEvent.CLICK, onShopClick)
			holeButton.removeEventListener(MouseEvent.CLICK, onHoleClick)
			if(energyIndicator){
				energyIndicator.removeEventListener(MouseEvent.CLICK, onEnergyIndicatorClick);
				energyIndicator.clear();
			}
			for each(var offer:OfferStatPanel in offerButtons)
				offer.clear();
			if(highlightArrow)
				highlightArrow.clear();
			for each(var friendIcon:MapFriendIcon in friendIcons){
				friendIcon.clear();
				friendIcon.removeEventListener(MouseEvent.CLICK, onFriendIconClicked);
				friendIcon.removeEventListener(MouseEvent.ROLL_OVER, onFriendIconOver);
			}
			optionsButton.removeEventListener(MouseEvent.CLICK, onOptionsClicked);
			optionsButton.clear();
			Hint.removeHint(optionsButton);
		}

		private function onOptionsClicked(event:MouseEvent):void {
			new OptionsWindow();
		}

		private function onEnergyIndicatorClick(event:MouseEvent):void {
			if(!UserProfile.instance.energyIsFull())
				new NeedMoreEnergyWindow(null, null, Lang.t('BUY_ENERGY_WND_TITLE'));
		}

		override protected function createGround():void {
			this.graphics.beginFill(0x96C44A);
			this.graphics.drawRect(0, 0, Config.WIDTH, Config.HEIGHT);
			this.graphics.endFill();
		}

		private function createCore():void {
			core = Lib.createMC('interface.MapCore');
			addChild(core);
			levelIcons = [];
			var userLevel:int = UserProfile.instance.levelNumber;
			for(var i:int = 1; i < 100; i++){
				var levelHolder:DisplayObject = core['level_' + i];
				if(levelHolder){
					var icon:MapLevelIcon = new MapLevelIcon();
					icon.x = levelHolder.x;
					icon.y = levelHolder.y;
					levelHolder.parent.addChildAt(icon, levelHolder.parent.getChildIndex(levelHolder));
					levelHolder.visible = false;
					levelIcons.push(icon);
					icon.levelNum = i;
					icon.levelInstance = UserProfile.instance.getLevelInsanceByNumber(i);
					icon.refresh();
					icon.addEventListener(MouseEvent.CLICK, onLevelClick)
				} else
					break;
			}
			var rabbitPlace:DisplayObjectContainer = core['rabbit_place_' + userLevel];
			if(rabbitPlace){
				core.rabbit.x = core.rabbit.y = 0;
				rabbitPlace.addChild(core.rabbit);
			}
			core.wall2.visible = userLevel <= 12;
			core.wall3.visible = userLevel <= 24;
			createButton(core.hole);
			createButton(core.shop);
			core.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownOnMap);
			core.addEventListener(MouseEvent.MOUSE_UP, onMouseUpOnMap);
			core.addEventListener(MouseEvent.MOUSE_OUT, onMouseUpOnMap);
			if(stage) stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseUpOnStage);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			createFriendMapIcons();
		}

		private function createFriendMapIcons():void {
			friendIcons = [];
			/*var addition:Array = []
			for(var i:int = 1;i<26;i++)
				for(var k:int = 0;k<10;k++){
					var g:GameUser = new ImaginaryGameUser();
					g.socialUser.photos = ["http://localhost:3000/files/posting/friends_invite_posting.jpg"];
					g._levelNumber = i;
					addition.push(g);
				}*/
			var groupParentsByLevel:Object = {};
			for each(var friend:GameUser in UserProfile.instance.neighbours){
				var placeholder:DisplayObjectContainer = core['level_' + friend.levelNumber];
				if(placeholder){
					var icon:MapFriendIcon = new MapFriendIcon(friend);
					icon.addEventListener(MouseEvent.CLICK, onFriendIconClicked);
					icon.addEventListener(MouseEvent.ROLL_OVER, onFriendIconOver);
					friendIcons.push(icon);
					var groupParent = groupParentsByLevel[friend.levelNumber];
					var xOffset:int;
					var yOffset:int;
					var ex:Array = friendPosExceptins[friend.levelNumber];
					if(!groupParent){
						groupParentsByLevel[friend.levelNumber] = groupParent = new Sprite();

						if(ex){
							xOffset = ex[0];
							yOffset = ex[1];
						} else {
							xOffset = 70;
							yOffset = 70;
						}
						groupParent.x = placeholder.x + xOffset;
						groupParent.y = placeholder.y + yOffset;
						placeholder.parent.addChild(groupParent);
					}
					var groupParentNum:int = groupParent.numChildren;
					if(ex){
						xOffset = ex[2];
						yOffset = ex[3];
					} else {
						xOffset = 8;
						yOffset = 8;
					}
					icon.x = Math.pow(groupParentNum, 0.8) * xOffset;
					icon.y = Math.pow(groupParentNum, 0.8) * yOffset;
					groupParent.addChildAt(icon, 0);
				}
			}
		}

		private function onScroll(event:Event = null):void {
			core.y = (CORE_HEIGHT - Config.HEIGHT) * (1 - scroller.position) + Config.HEIGHT;
		}

		private function onLevelClick(event:MouseEvent):void {
			var icon:MapLevelIcon = event.currentTarget as MapLevelIcon;
			if(icon.active){
				var levelDef:LevelDef = Config.application.getLevelByNumber(icon.levelNum);
				if(UserProfile.instance.canPlayWithLevel(levelDef) || Config.memory['portfolioMode']){
					if(UserProfile.instance.canSpendEnergy()){
						Config.application.startGame(levelDef);
					}else{
						new NeedMoreEnergyWindow(function():void{
							Config.application.startGame(levelDef);
						})
					}
				}
			}
		}

		private function onMouseDownOnMap(event:MouseEvent):void {
			core.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveOnMap);
			mouseMoveStartCoords.x = this.stage.mouseX;
			mouseMoveStartCoords.y = this.stage.mouseY;
		}

		private function onMouseUpOnMap(event:MouseEvent):void {
			if(event.type == MouseEvent.MOUSE_OUT && core.contains(event.target as DisplayObject)) return;
			onMouseUpOnStage();
		}

		private function onMouseUpOnStage(event:Event = null):void {
			core.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveOnMap);
			Mouse.cursor = MouseCursor.AUTO;
		}

		private function onMouseMoveOnMap(event:MouseEvent):void {
			var delta:int = mouseMoveStartCoords.y - this.stage.mouseY;
			scroller.position += delta / (CORE_HEIGHT - Config.HEIGHT);
			onScroll();
			mouseMoveStartCoords.y = this.stage.mouseY;
			Mouse.cursor = MouseCursor.HAND
		}

		private function onMouseWheel(event:MouseEvent):void {
			scroller.scrollOnDelta(event.delta);
		}

		private function scrollToUserCurrentPos():void {
			var icon:DisplayObject;
			if(lastShopStart){
				icon = core.hole;
			} else if(lastHoleStart){
				icon = core.shop;
			} else {
				var searchLevel:int = (Config.application as RabbitApplication).lastStartedLevelNum ?
						(Config.application as RabbitApplication).lastStartedLevelNum : UserProfile.instance.levelNumber;
				for each(var ic:MapLevelIcon in levelIcons)
					if(ic.levelNum == searchLevel){
						icon = ic;
						break;
					}
			}
			if(icon){
				var pos:Point = core.globalToLocal(icon.localToGlobal(new Point()));
				scroller.position = (CORE_HEIGHT + pos.y - Config.HEIGHT * 0.5) / (CORE_HEIGHT - Config.HEIGHT);
			} else {
				scroller.position = 0;
			}
			lastShopStart = false;
			lastHoleStart = false;
		}

		private function createButton(button:MovieClip):void {
			button.addEventListener(MouseEvent.MOUSE_OVER, onCoreButtonOver);
			button.addEventListener(MouseEvent.MOUSE_OUT, onCoreButtonOut);
			button.addEventListener(MouseEvent.CLICK, onCoreButtonClick);
			button.buttonMode = button.useHandCursor = true;
		}

		private function clearButton(button:MovieClip):void {
			button.removeEventListener(MouseEvent.MOUSE_OVER, onCoreButtonOver);
			button.removeEventListener(MouseEvent.MOUSE_OUT, onCoreButtonOut);
			button.removeEventListener(MouseEvent.MOUSE_OVER, onCoreButtonClick);
		}

		private function onCoreButtonOver(event:MouseEvent):void {
			(event.currentTarget as DisplayObject).filters = [new GlowFilter(0xDB6E39, 1, 20, 20)]
		}

		private function onCoreButtonOut(event:MouseEvent):void {
			(event.currentTarget as DisplayObject).filters = [];
		}

		private function onCoreButtonClick(event:MouseEvent):void {
			lastShopStart = false;
			lastHoleStart = false;
			switch(event.currentTarget){
				case core.hole:
					lastHoleStart = true;
					new OpenRewardLevelCommand(UserProfile.instance).execute();
					break;
				case core.shop:
					lastShopStart = true;
					Config.application.startPage('shop');
					break;
			}
		}

		private function onShopClick(event:Event):void {
			Config.application.startPage('shop');
		}

		private function onHoleClick(event:Event):void {
			new OpenRewardLevelCommand(UserProfile.instance).execute();
		}

		private function onFriendIconOver(event:MouseEvent):void {
			var icon:MapFriendIcon = event.currentTarget as MapFriendIcon;
			icon.parent.setChildIndex(icon, icon.parent.numChildren - 1);
		}

		private function onFriendIconClicked(event:MouseEvent):void {
			var icon:MapFriendIcon = event.currentTarget as MapFriendIcon;
			new OpenRewardLevelCommand(icon.friend).execute();
		}
	}
}

import com.somewater.rabbit.application.RScroller;
import com.somewater.rabbit.application.buttons.GreenButton;
import com.somewater.rabbit.storage.Lib;

import flash.display.Sprite;

import flash.events.Event;

import flash.events.MouseEvent;

class MapRScroller extends RScroller{
	override protected function onWheel(event:MouseEvent):void {
		scrollOnDelta(event.delta);
	}

	public function scrollOnDelta(delta:int):void {
		this.position -= (delta > 0 ? 1 : (delta < 0 ? -1 : 0)) * scrollSpeed;
		dispatchEvent(new Event(Event.CHANGE));
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
