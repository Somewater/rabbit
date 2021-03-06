package com.somewater.rabbit.application
{
	import com.greensock.TweenLite;
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.application.buttons.InteractiveOpaqueBack;
	import com.somewater.rabbit.application.offers.OfferManager;
	import com.somewater.rabbit.application.offers.OfferStatPanel;
	import com.somewater.rabbit.application.windows.PauseMenuWindow;
import com.somewater.rabbit.events.CameraMoveEvent;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;

	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class GameGUI extends Sprite implements IClear
	{
		public var rightGameGUI:Boolean = true;// флаг для отличия от других GameGUI при нетипизированном использовании

		private var playPauseButton:InteractiveOpaqueBack;
		private var statPanel:Sprite;
		private var timeTF:EmbededTextField;
		private var carrotTF:EmbededTextField;
		private var minutesArrowShelf:Shape;
		private var offerStat:OfferStatPanel;
		public var powerupPanel:PowerupsGameGUI;
		private var pauseSplash:Sprite;

		private var healthHintArea:Sprite;
		private var timeHintArea:Sprite;
		private var scoreHintArea:Sprite;

		public var carrotMax:int;
		public var carrotMiddle:int;
		public var carrotMin:int;
		public var carrotOnLevel:int;

		private var carrotGUISwitched:int = 0;

		private var cameraArrowLeft:Sprite;
		private var cameraArrowRight:Sprite;
		private var cameraArrowUp:Sprite;
		private var cameraArrowDown:Sprite;
		
		public function GameGUI()
		{
			super();
			
			playPauseButton = new InteractiveOpaqueBack(Lib.createMC("interface.PauseButton"));
			playPauseButton.setSize(48, 48)
			Hint.bind(playPauseButton, Lang.t('PAUSE'))
			playPauseButton.x = 15;
			playPauseButton.y = 15;
			addChild(playPauseButton);
			playPauseButton.addEventListener(MouseEvent.MOUSE_DOWN, onPlayPauseClick);
			
			statPanel = Lib.createMC("interface.GameStatPanel");
			statPanel.x = Config.WIDTH - statPanel.width - 15;
			statPanel.y = 15;
			addChild(statPanel);
			var minutesArrowCircle:Shape = new Shape();
			minutesArrowShelf = new Shape();
			statPanel.addChildAt(minutesArrowCircle, statPanel.getChildIndex(statPanel.getChildByName("minutesArrow")));
			statPanel.addChildAt(minutesArrowShelf, statPanel.getChildIndex(statPanel.getChildByName("minutesArrow")));
			minutesArrowShelf.x = minutesArrowCircle.x = statPanel.getChildByName("minutesArrow").x;
			minutesArrowShelf.y = minutesArrowCircle.y = statPanel.getChildByName("minutesArrow").y;
			minutesArrowCircle.mask = minutesArrowShelf;
			minutesArrowCircle.graphics.beginFill(0xFFFFFF, 0.47);
			minutesArrowCircle.graphics.drawCircle(0, 0, 15);

			(statPanel.getChildByName('carrot0') as MovieClip).gotoAndStop(1);
			(statPanel.getChildByName('carrot1') as MovieClip).gotoAndStop(1);
			(statPanel.getChildByName('carrot2') as MovieClip).gotoAndStop(1);

			timeTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true);
			timeTF.width = 55;
			timeTF.x = 139;
			timeTF.y = 15;
			statPanel.addChild(timeTF);
			
			carrotTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true);
			carrotTF.width = 35;
			carrotTF.x = 260;
			carrotTF.y = 15;
			statPanel.addChild(carrotTF);

			life = 0;
			time = 0;
			carrot = 0;

			Hint.bind(statPanel.getChildByName('scoreHintArea'), scoreHint);
			statPanel.getChildByName('scoreHintArea').alpha = 0;
			Hint.bind(statPanel.getChildByName('timeHintArea'), timeHint);
			statPanel.getChildByName('timeHintArea').alpha = 0;
			Hint.bind(statPanel.getChildByName('healthHintArea'), healthHint);
			statPanel.getChildByName('healthHintArea').alpha = 0;
			Hint.bind(statPanel.getChildByName('scoreRatingHintArea'), scoreRatingHint);
			statPanel.getChildByName('scoreRatingHintArea').alpha = 0;

			if(OfferManager.instance.active && OfferManager.instance.levelOffers(Config.game.level.number, true).length > 0)
			{
				offerStat = new OfferStatPanel(OfferStatPanel.GAME_MODE,
						OfferManager.instance.offerTypeByLevel(Config.game.level.number));
				offerStat.x = statPanel.x - 10 - offerStat.width;
				offerStat.y = statPanel.y;
				addChild(offerStat);
				offerStat.disableClick();
			}

			pauseSplash = Lib.createMC('interface.PauseSplash');
			pauseSplash.useHandCursor = pauseSplash.buttonMode = true;
			pauseSplash.x = (Config.WIDTH - pauseSplash.width) * 0.5;
			pauseSplash.y = (Config.HEIGHT - pauseSplash.height) * 0.5;
			pauseSplash.visible = false;
			addChild(pauseSplash);

			powerupPanel = new PowerupsGameGUI(pauseSplash);
			powerupPanel.x = playPauseButton.x + playPauseButton.width + 10;
			powerupPanel.y = statPanel.y;
			addChild(powerupPanel);

			const CAMERA_ARROW_PADDING:int = 15;
			cameraArrowLeft = Lib.createMC('interface.CameraArrowLeft');
			cameraArrowLeft.mouseChildren = cameraArrowLeft.mouseEnabled = false;
			cameraArrowLeft.x = CAMERA_ARROW_PADDING;
			cameraArrowLeft.y = (Config.HEIGHT - cameraArrowLeft.height) * 0.5;
			addChild(cameraArrowLeft);
			cameraArrowRight = Lib.createMC('interface.CameraArrowRight');
			cameraArrowRight.mouseChildren = cameraArrowRight.mouseEnabled = false;
			cameraArrowRight.x = Config.WIDTH - cameraArrowRight.width - CAMERA_ARROW_PADDING;
			cameraArrowRight.y = (Config.HEIGHT - cameraArrowRight.height) * 0.5;
			addChild(cameraArrowRight);
			cameraArrowUp = Lib.createMC('interface.CameraArrowUp');
			cameraArrowUp.mouseChildren = cameraArrowUp.mouseEnabled = false;
			cameraArrowUp.x = (Config.WIDTH - cameraArrowUp.width) * 0.5;
			cameraArrowUp.y = powerupPanel.y;
			addChild(cameraArrowUp);
			cameraArrowDown = Lib.createMC('interface.CameraArrowDown');
			cameraArrowDown.mouseChildren = cameraArrowDown.mouseEnabled = false;
			cameraArrowDown.x = (Config.WIDTH - cameraArrowDown.width) * 0.5;
			cameraArrowDown.y = Config.HEIGHT - cameraArrowDown.height - CAMERA_ARROW_PADDING;
			addChild(cameraArrowDown);

			cameraArrowLeft.visible = cameraArrowRight.visible = cameraArrowDown.visible = cameraArrowUp.visible = false;
			Config.game.addEventListener(CameraMoveEvent.CAMERA_MOVE_EVENT, onCameraMove, false, 0, true);

			Config.application.addPropertyListener('game.switch', onGameSwitched);

			if(Config.memory['cleanGameScreen'])
				this.visible = false
		}

		public function init():void
		{
			carrotGUISwitched = 0;
			(statPanel.getChildByName('carrot0') as MovieClip).gotoAndStop(1);
			(statPanel.getChildByName('carrot1') as MovieClip).gotoAndStop(1);
			(statPanel.getChildByName('carrot2') as MovieClip).gotoAndStop(1);

			var tmpCarrot:int = _carrot;
			_carrot = -1;
			carrot = tmpCarrot;
		}


		//	GAME_INTERFACE_HEALTH_BAR=Здоровье кролика {persent}%
		//	GAME_INTERFACE_SCORES=На уровне осталось {number} морковок
		//	GAME_INTERFACE_TIME=Осталось {seconds} секунд до конца уровня
		private function healthHint():String
		{
			return Lang.t('GAME_INTERFACE_HEALTH_BAR', {persent: Math.round(_life * 100)});
		}

		private function timeHint():String
		{
			return Lang.t('GAME_INTERFACE_TIME', {seconds: (_timeEnd - _time)});
		}

		private function scoreHint():String
		{
			return Lang.t('GAME_INTERFACE_SCORES', {number: (carrotMax - _carrot), harvested: _carrot, all: carrotMax});
		}

		private function scoreRatingHint():String
		{
			if(carrotGUISwitched > 0)
				return Lang.t('GAME_INTERFACE_SCORES_RATING', {carrot: carrotGUISwitched});
			else
				return Lang.t('GAME_INTERFACE_SCORES_RATING_UNCOMPL', {need: (carrotMin - _carrot)});
		}
		
		public function clear():void
		{
			playPauseButton.removeEventListener(MouseEvent.MOUSE_DOWN, onPlayPauseClick);
			Hint.removeHint(playPauseButton);
			if(offerStat)
				offerStat.clear();
			if(powerupPanel)
			{
				powerupPanel.clear();
			}

			Hint.removeHint(statPanel.getChildByName('scoreHintArea'));
			Hint.removeHint(statPanel.getChildByName('timeHintArea'));
			Hint.removeHint(statPanel.getChildByName('healthHintArea'));
			Hint.removeHint(statPanel.getChildByName('scoreRatingHintArea'));

			Config.game.removeEventListener(CameraMoveEvent.CAMERA_MOVE_EVENT, onCameraMove);

			Config.application.removePropertyListener('game.switch', onGameSwitched);
		}

		private function onGameSwitched():void {
			var vis:Boolean = Config.game.isTicking;
			TweenLite.to(pauseButton, 0.3, {'autoAlpha': (vis ? 1 : 0)})
		}
		
		private function onPlayPauseClick(e:Event):void
		{
			// закрыть панель паверапов, если она была открыта
			powerupPanel.close();

			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			new PauseMenuWindow();
			e.stopPropagation();
		}
		
		// 0..1
		public function set life(value:Number):void
		{
			if(_life != value)
			{
				statPanel.getChildByName("progressBar").scaleX = Math.max(0,Math.min(1, value));
				_life = value;
			}
		}
		private var _life:Number = 1;
		
		/**
		 * Сколько максимально длится раунд, секунды
		 */
		public function set timeEnd(value:int):void
		{
			_timeEnd = value;
			_time = -1;
			time = _time;	
		}
		public var _timeEnd:int = 60;

		/**
		 * Сколько длится текущий раунд
		 */
		public function set time(value:int):void
		{
			if(_time != value)
			{
				if(value > _timeEnd)
					_timeEnd = value;
				_time = value;

				timeTF.text = secondsToFormattedTime(_timeEnd - _time);
				
				var part:Number = value / _timeEnd;
				var t_part:Number = Math.PI * 2 * part;
				statPanel.getChildByName("minutesArrow").rotation = part * 360;
				
				var g:Graphics = minutesArrowShelf.graphics;
				g.clear();
				g.beginFill(0xFFFFFF, 0.47);
				if(part < 0.25)
				{
					g.moveTo(0,0);
					g.lineTo(0, -100);
				}
				else if(part < 0.50)
				{
					g.drawRect(0, -20,20,20);
					
					g.moveTo(0,0);
					g.lineTo(100, 0);
				}
				else if(part < 0.75)
				{
					g.drawRect(0, -20,20,40);
					
					g.moveTo(0,0);
					g.lineTo(0, 100);
				}
				else
				{
					g.drawRect(0, -20,20,40);
					g.drawRect(-20, 0,20,20);
					
					g.moveTo(0,0);
					g.lineTo(-100, 0);
				}
				
				g.lineTo(100 * Math.sin(t_part), -100 * Math.cos(t_part));
				g.endFill();
			}
		}
		private var _time:int;
		
		public function set carrot(value:int):void
		{
			if(value != _carrot)
			{
				carrotTF.text = value + (carrotMax < 100 ? " / " : "/") + carrotMax;
				_carrot = value;

				if(value >= carrotMin && carrotGUISwitched == 0)
					switchNextGUICarrot();
				if(value >= carrotMiddle && carrotGUISwitched == 1)
					switchNextGUICarrot();
				if(value >= carrotMax && carrotGUISwitched == 2)
					switchNextGUICarrot();
			}
		}
		private var _carrot:int;

		private function switchNextGUICarrot():void
		{
			(statPanel.getChildByName('carrot' + carrotGUISwitched) as MovieClip).gotoAndStop(2);
			carrotGUISwitched++;
		}

		public static function secondsToFormattedTime(seconds:int):String
		{
			var minutes:int = seconds / 60;
			seconds = seconds - (minutes * 60);
			return (minutes > 9?minutes:"0" + minutes)
				+ ":" + (seconds > 9?seconds:"0" + seconds);
		}

		// для тьюториала
		public function get carrotIndicator():DisplayObject
		{
			return carrotTF;
		}

		// для тьюториала
		public function get healthIndicator():DisplayObject
		{
			return statPanel.getChildByName("progressBar");
		}

		// для тьюториала
		public function get timeIndicator():DisplayObject
		{
			return timeTF;
		}

		// для тьюториала
		public function get pauseButton():DisplayObject
		{
			return playPauseButton;
		}

		// для тьюториала
		public function get powerupIndicator():DisplayObject
		{
			return powerupPanel.getOpenBtn();
		}

		private function onCameraMove(event:CameraMoveEvent):void {
			var dir:int = event.direction;
			cameraArrowLeft.visible = dir & CameraMoveEvent.LEFT;
			cameraArrowRight.visible = dir & CameraMoveEvent.RIGHT;
			cameraArrowDown.visible = dir & CameraMoveEvent.DOWN;
			cameraArrowUp.visible = dir & CameraMoveEvent.UP;
		}

		public function update(heroNotFound:Boolean, protectedFlag:Boolean):void {
			if(heroNotFound){
				powerupPanel.stopButtonAnim(true);
				return
			}

			if((_timeEnd - _time) > 0 && _life > 0 ){
				var healthProblem:Boolean = !protectedFlag && _life < 0.37;
				var timeProblem:Boolean = (_timeEnd - _time) < 10 && carrotOnLevel > 0;
				if(healthProblem || timeProblem){
					powerupPanel.startButtonAnim(healthProblem, timeProblem);
					return;
				}
			}
			powerupPanel.stopButtonAnim(true);
		}
	}
}