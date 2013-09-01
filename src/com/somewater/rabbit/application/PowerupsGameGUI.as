package com.somewater.rabbit.application {
	import com.greensock.TweenLite;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.buttons.InteractiveOpaqueBack;
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
		private var btnHolder:InteractiveOpaqueBack;
		private var btnHolderPadding:int;
		private var closeButton:InteractiveOpaqueBack;

		private var opened:Boolean = false;

		private var wishPowerupId:int// id паверапа, который надо купить и применить

		private var pauseSplashRef:DisplayObject;

		public function PowerupsGameGUI(pauseSplashRef:DisplayObject) {

			this.pauseSplashRef = pauseSplashRef;
			pauseSplashRef.addEventListener(MouseEvent.CLICK, close);

			btnHolder = new InteractiveOpaqueBack(Lib.createMC('interface.PowerupGUIPanelBtn'));
			btnHolder.iconShiftY = -1;
			btnHolderPadding = (WIDTH - btnHolder.width) * 0.5;
			btnHolder.x = 0;
			btnHolder.y = 0;
			btnHolder.setSize(48, 48);
			addChild(btnHolder);

			btnHolder.addEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);

			myPowerups = new MyPowerupsBag(10, true);
			myPowerups.x = 5;
			myPowerups.y = 3;
			myPowerups.addEventListener(PowerupEvent.POWERUP_EVENT, onPowerupCliced);
			addChild(myPowerups);
			myPowerups.visible = false;

			closeButton = new InteractiveOpaqueBack(Lib.createMC('interface.PowerupCloseBtn'));
			closeButton.setSize(30, 48);
			closeButton.visible = false;
			closeButton.x = calculateOpenedWidth() - closeButton.width - 5;
			closeButton.addEventListener(MouseEvent.CLICK, close)
			addChild(closeButton);

			UserProfile.bind(onUserDataChanged);

			Hint.bind(this, Lang.t('POWERUP_GAME_GUI_BTN_HINT'))
		}

		private function onBtnClicked(event:MouseEvent):void {
			setStateAnimated(!opened);
			event.stopPropagation();
		}

		private function setStateAnimated(opened:Boolean):void
		{
			if(this.opened == opened) return;
			pauseSplashRef.visible = this.opened = opened;
			if(opened)
			{
				Config.game.pause();
				TweenLite.to(btnHolder.icon, 0.2, {alpha: 0});
				TweenLite.to(btnHolder, 0.2, {alpha:0.4, width:calculateOpenedWidth(), onComplete: onPanelOpenComplete});
			}
			else
			{
				if(PopUpManager.activeWindow == null)
					Config.game.start();
				myPowerups.visible = true;
				TweenLite.to(myPowerups, 0.2, {alpha: 0, onComplete: onPowerupsAnimComplete});
				TweenLite.to(closeButton, 0.2, {alpha: 0});
			}
		}

		private function calculateOpenedWidth():int {
			return WIDTH + myPowerups.width + 5;
		}

		private function onPanelOpenComplete():void {
			myPowerups.visible = true;
			myPowerups.alpha = 0;
			closeButton.visible = true;
			closeButton.alpha = 0;
			TweenLite.to(myPowerups, 0.2, {alpha: 1});
			TweenLite.to(closeButton, 0.2, {alpha: 1})
			btnHolder.mouseEnabled = false;
		}

		private function onPanelCloseComplete():void {
			btnHolder.mouseEnabled = true;
		}

		private function onPowerupsAnimComplete():void {
			myPowerups.visible = false;
			closeButton.visible = false;
			//btnHolder.scaleX = -1;
			TweenLite.to(btnHolder.icon, 0.2, {alpha: 1});
			TweenLite.to(btnHolder, 0.2, {alpha:1, width:WIDTH, onComplete: onPanelCloseComplete});
		}

		public function clear():void {
			btnHolder.removeEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);
			btnHolder.clear();
			TweenLite.killTweensOf(btnHolder);
			TweenLite.killTweensOf(myPowerups);
			myPowerups.removeEventListener(PowerupEvent.POWERUP_EVENT, onPowerupCliced);
			myPowerups.clear();
			UserProfile.unbind(onUserDataChanged);
			Hint.removeHint(this);
			pauseSplashRef.removeEventListener(MouseEvent.CLICK, close)
			pauseSplashRef = null;
			closeButton.clear();
			closeButton.removeEventListener(MouseEvent.CLICK, close)
		}


		private function onPowerupCliced(event:PowerupEvent):void {
			wishPowerupId = 0;
			if(UserProfile.instance.hasItem(event.powerup.id) || Config.game.level.number == 1)
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
			if(Config.game.level.number > 1)
			{
				UserProfile.instance.deleteItem(powerup.id);
				AppServerHandler.instance.useItem(powerup.id);// todo: обрабатывать оибку применения паверапа
			}
		}

		private function onShopEventClosed(event:Event):void {
			if(wishPowerupId && UserProfile.instance.hasItem(wishPowerupId))
			{
				userPowerup(ItemDef.byId(wishPowerupId) as PowerupDef);
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

		public function close(event:Event = null):void {
			setStateAnimated(false);
		}
	}
}
