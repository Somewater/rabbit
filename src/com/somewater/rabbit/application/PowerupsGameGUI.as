package com.somewater.rabbit.application {
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.buttons.InteractiveOpaqueBack;
	import com.somewater.rabbit.application.shop.ItemIcon;
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
	import flash.display.MovieClip;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class PowerupsGameGUI extends Sprite implements IClear{

		public static const WIDTH:int = 48;
		public static const HEIGHT:int = 48;

		public var myPowerups:MyPowerupsBag;
		private var buttonHolder:Sprite;
		private var button:InteractiveOpaqueBack;
		private var buttonIcon:MovieClip;
		private var btnHolderPadding:int;
		private var closeButton:InteractiveOpaqueBack;

		private var buttonAnimated:Boolean = false;
		private var buttonAnimatedCounter:int = 0;
		private var healthProblem:Boolean;
		private var timeProblem:Boolean;

		private var opened:Boolean = false;

		private var wishPowerupId:int// id паверапа, который надо купить и применить

		private var pauseSplashRef:DisplayObject;

		public function PowerupsGameGUI(pauseSplashRef:DisplayObject) {

			this.pauseSplashRef = pauseSplashRef;
			pauseSplashRef.addEventListener(MouseEvent.CLICK, close);

			button = new InteractiveOpaqueBack();
			button.iconShiftY = -1;
			btnHolderPadding = (WIDTH - button.width) * 0.5;
			button.setSize(48, 48);
			button.x = -button.width * 0.5;
			button.y = -button.height * 0.5;
			buttonHolder = new Sprite()
			buttonHolder.addChild(button);
			buttonHolder.x = button.width * 0.5;
			buttonHolder.y = button.height * 0.5;
			addChild(buttonHolder);

			buttonIcon = Lib.createMC('interface.PowerupGUIPanelBtn');
			buttonIcon.gotoAndStop(1);
			buttonIcon.x = (button.width - buttonIcon.width) * 0.5;
			buttonIcon.y = (button.height - buttonIcon.height) * 0.5;
			buttonIcon.mouseEnabled = false;
			addChild(buttonIcon);

			buttonHolder.addEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);
			buttonIcon.addEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);

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

		public function startButtonAnim(healthProblem:Boolean, timeProblem:Boolean):void {
			this.healthProblem = healthProblem;
			this.timeProblem = timeProblem;
			if(!buttonAnimated && !opened){
				buttonAnimated = true;
				buttonAnimatedCounter = 0;
				TweenMax.to(buttonHolder, 0.3, {scaleX: 1.1, scaleY: 1.1, onUpdate: updateIcon, yoyo: true, repeat: -1, startAt:{scaleX: 1.0, scaleY: 1.0}});
			}
		}

		private function updateIcon():void {
			var frame1:int = ((buttonAnimatedCounter * 0.1) % 2)
			buttonAnimatedCounter++;
			var frame2:int = ((buttonAnimatedCounter * 0.1) % 2)
			if(frame1 != frame2)
				buttonIcon.gotoAndStop(frame2 + 1)
		}

		public function stopButtonAnim(clearFlags:Boolean):void {
			if(buttonAnimated){
				TweenMax.killTweensOf(buttonHolder, true);
				buttonIcon.gotoAndStop(1);
				TweenMax.to(buttonHolder, 0.2, {scaleX: 1.0, scaleY: 1.0});
				buttonAnimated = false;
			}
			if(clearFlags){
				healthProblem = false;
				timeProblem = false;
			}
		}

		private function setStateAnimated(opened:Boolean):void
		{
			if(this.opened == opened) return;
			pauseSplashRef.visible = this.opened = opened;
			if(opened)
			{
				Config.game.pause();
				TweenLite.to(buttonIcon, 0.2, {alpha: 0});
				stopButtonAnim(false);
				TweenLite.to(button, 0.2, {alpha:0.4, width:calculateOpenedWidth(), onComplete: onPanelOpenComplete});
			}
			else
			{
				if(PopUpManager.activeWindow == null)
					Config.game.start();
				myPowerups.visible = true;
				TweenLite.to(myPowerups, 0.2, {alpha: 0, onComplete: onPowerupsAnimComplete});
				TweenLite.to(closeButton, 0.2, {alpha: 0});
				stopPowerupIconAnim(myPowerups.getPowerupIcon(0));
				stopPowerupIconAnim(myPowerups.getPowerupIcon(2));
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
			button.mouseEnabled = false;

			if(healthProblem)
				startPowerupIconAnim(myPowerups.getPowerupIcon(0));
			if(timeProblem)
				startPowerupIconAnim(myPowerups.getPowerupIcon(2));

			Config.stat(Stat.ON_PAUSE_POWERUP);
		}

		private function startPowerupIconAnim(icon:ItemIcon):void {
			TweenMax.to(icon.imageHolder, 0.2, {scaleX: 1.2, scaleY: 1.2, yoyo: true, repeat: -1, startAt:{scaleX: 1.0, scaleY: 1.0}});
		}

		private function stopPowerupIconAnim(icon:ItemIcon):void {
			TweenLite.killTweensOf(icon.imageHolder);
			icon.scaleX = icon.scaleY = 1;
		}

		private function onPanelCloseComplete():void {
			button.mouseEnabled = true;
		}

		private function onPowerupsAnimComplete():void {
			myPowerups.visible = false;
			closeButton.visible = false;
			//btnHolder.scaleX = -1;
			TweenLite.to(buttonIcon, 0.2, {alpha: 1});
			TweenLite.to(button, 0.2, {alpha:1, width:WIDTH, onComplete: onPanelCloseComplete});


		}

		public function clear():void {
			buttonHolder.removeEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);
			buttonIcon.removeEventListener(MouseEvent.MOUSE_DOWN, onBtnClicked);
			button.clear();
			TweenLite.killTweensOf(buttonHolder);
			TweenLite.killTweensOf(button);
			TweenLite.killTweensOf(buttonIcon);
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
				Config.stat(Stat.ON_POWERUP_USE);
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
				Config.stat(Stat.ON_POWERUP_BUY);
			}
		}

		public function getOpenBtn():DisplayObject
		{
			return button;
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
