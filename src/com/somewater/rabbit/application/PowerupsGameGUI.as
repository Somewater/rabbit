package com.somewater.rabbit.application {
	import com.greensock.TweenLite;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.shop.MyPowerupsBag;
	import com.somewater.rabbit.application.shop.PowerupEvent;
	import com.somewater.rabbit.application.shop.ShopWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class PowerupsGameGUI extends Sprite implements IClear{

		public static const WIDTH:int = 48;
		public static const HEIGHT:int = 48;

		public var myPowerups:MyPowerupsBag;
		private var ground:DisplayObject;
		private var btnHolder:DisplayObject;

		private var opened:Boolean = false;

		private var wishPowerupId:int// id паверапа, который надо купить и применить

		private var autoCloseTimer:Timer;
		private var pauseSplashRef:DisplayObject;

		public function PowerupsGameGUI(pauseSplashRef:DisplayObject) {

			this.pauseSplashRef = pauseSplashRef;

			ground = Lib.createMC('interface.OpaqueBackground');
			ground.width = WIDTH;
			ground.height = HEIGHT;
			addChild(ground);

			myPowerups = new MyPowerupsBag(10, true);
			myPowerups.x = -myPowerups.width + WIDTH - 5;
			myPowerups.y = 3;
			myPowerups.addEventListener(PowerupEvent.POWERUP_EVENT, onPowerupCliced);
			addChild(myPowerups);
			myPowerups.visible = false;


			btnHolder = Lib.createMC('interface.PowerupGUIPanelBtn');
			btnHolder.scaleX = -1;
			btnHolder.x = (WIDTH + btnHolder.width) * 0.5 - 4;
			btnHolder.y = (HEIGHT - btnHolder.height) * 0.5;
			addChild(btnHolder);

			btnHolder.addEventListener(MouseEvent.CLICK, onBtnClicked);

			UserProfile.bind(onUserDataChanged);

			autoCloseTimer = new Timer(15000);
			autoCloseTimer.addEventListener(TimerEvent.TIMER, onAutoClose);

			Hint.bind(this, Lang.t('POWERUP_GAME_GUI_BTN_HINT'))
		}

		private function onBtnClicked(event:MouseEvent):void {
			setStateAnimated(!opened);
		}

		private function setStateAnimated(opened:Boolean):void
		{
			if(this.opened == opened) return;
			pauseSplashRef.visible = this.opened = opened;
			if(opened)
			{
				Config.game.pause();
				btnHolder.scaleX = 1;
				var myPowerupsWidth:int = myPowerups.width + 5;
				TweenLite.to(btnHolder, 0.2, {alpha:0.4, x: (WIDTH - btnHolder.width) * 0.5 - myPowerupsWidth})
				TweenLite.to(ground, 0.2, {width:WIDTH + myPowerupsWidth, x: -myPowerups.width, onComplete: onPanelOpenComplete});
				autoCloseTimer.start();
			}
			else
			{
				if(PopUpManager.activeWindow == null)
					Config.game.start();
				myPowerups.visible = true;
				TweenLite.to(myPowerups, 0.2, {alpha: 0, onComplete: onPowerupsAnimComplete});
				if(autoCloseTimer.running)
					autoCloseTimer.stop();
			}
		}

		private function onPanelOpenComplete():void {
			myPowerups.visible = true;
			myPowerups.alpha = 0;
			TweenLite.to(myPowerups, 0.2, {alpha: 1});
		}

		private function onPowerupsAnimComplete():void {
			myPowerups.visible = false;
			btnHolder.scaleX = -1;
			TweenLite.to(btnHolder, 0.2, {alpha:1, x: (WIDTH + btnHolder.width) * 0.5 - 4})
			TweenLite.to(ground, 0.2, {width:WIDTH, x: 0});
		}

		public function clear():void {
			btnHolder.removeEventListener(MouseEvent.CLICK, onBtnClicked);
			TweenLite.killTweensOf(btnHolder);
			TweenLite.killTweensOf(ground);
			TweenLite.killTweensOf(myPowerups);
			myPowerups.removeEventListener(PowerupEvent.POWERUP_EVENT, onPowerupCliced);
			myPowerups.clear();
			UserProfile.unbind(onUserDataChanged);
			autoCloseTimer.removeEventListener(TimerEvent.TIMER, onAutoClose);
			if(autoCloseTimer.running)
				autoCloseTimer.stop();
			Hint.removeHint(this);
		}


		private function onPowerupCliced(event:PowerupEvent):void {
			wishPowerupId = 0;
			if(UserProfile.instance.hasItem(event.powerup.id))
			{
				// просто используем что есть
				userPowerup(event.powerup);
				setStateAnimated(false);
			}
			else
			{
				// открываем окно магазина паверапов
				wishPowerupId = event.powerup.id;
				new ShopWindow().addEventListener(Window.EVENT_CLOSE, onShopEventClosed);
			}
		}

		private function onUserDataChanged():void {
			if(wishPowerupId)
			{

			}
		}

		private function userPowerup(powerup:PowerupDef):void
		{
			Config.game.usePowerup(powerup.template);
			UserProfile.instance.deleteItem(powerup.id);
			AppServerHandler.instance.useItem(powerup.id);// todo: обрабатывать оибку применения паверапа
		}

		private function onShopEventClosed(event:Event):void {
			if(wishPowerupId && UserProfile.instance.hasItem(wishPowerupId))
			{
				userPowerup(ItemDef.byId(wishPowerupId) as PowerupDef);
				setStateAnimated(false);
			}
			else
			{
				if(!autoCloseTimer.running)
					autoCloseTimer.start();
			}
		}

		private function onAutoClose(event:TimerEvent):void {
			autoCloseTimer.stop();
			if(opened && PopUpManager.activeWindow == null)
			{
				setStateAnimated(false);
			}
		}

		public function getOpenBtn():DisplayObject
		{
			return btnHolder;
		}

		public function isOpened():Boolean
		{
			return opened;
		}
	}
}
