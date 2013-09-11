package
{
	import com.google.analytics.GATracker;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.AboutPage;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.CustomizeManager;
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.OfferManager;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.OrangeGround;
	import com.somewater.rabbit.application.PageBase;
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.application.RewardManager;
	import com.somewater.rabbit.application.ServerLogic;
	import com.somewater.rabbit.application.TopPage;
	import com.somewater.rabbit.application.commands.RestartLevelCommand;
	import com.somewater.rabbit.application.tutorial.TutorialLevelDef;
	import com.somewater.rabbit.application.WindowBackground;
	import com.somewater.rabbit.application.shop.ShopPage;
	import com.somewater.rabbit.application.tutorial.TutorialManager;
	import com.somewater.rabbit.application.windows.InviteFriendsWindow;
	import com.somewater.rabbit.application.windows.LevelFinishFailWindow;
	import com.somewater.rabbit.application.windows.LevelFinishSuccessWindow;
	import com.somewater.rabbit.application.windows.LevelStartWindow;
	import com.somewater.rabbit.application.windows.LevelSwitchWindow;
	import com.somewater.rabbit.application.windows.OfferDescriptionWindow;
	import com.somewater.rabbit.application.windows.PauseMenuWindow;
	import com.somewater.rabbit.application.windows.PendingRewardsWindow;
	import com.somewater.rabbit.application.windows.TesterInvitationWindow;
	import com.somewater.rabbit.events.GameModuleEvent;
	import com.somewater.rabbit.storage.ConfManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.rabbit.storage.RewardInstanceDef;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.rabbit.storage.StoryDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.social.SocialUser;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	import ru.etcs.ui.MouseWheel;


	[Event(name="applicationInited", type="flash.events.Event")]

	/**
	 * Интерфейс игры, исключая собственно игровой модуль
	 * (САМ КЛАСС В ВИЗУАЛЬНОМ ОФОРМЛЕНИИ РОЛИ НЕ ИГРАЕТ, ВЫСТУПАЯ В КАЧЕСТВЕ МЕНЕДЖЕРА)
	 */
	public class RabbitApplication extends Sprite implements IRabbitApplication
	{
		private const PAGES:Object = {
										"main_menu":MainMenuPage
										,
										"levels":LevelsPage
										,
										"top":TopPage
										,
										"about":AboutPage
										,
										"shop":ShopPage
									}
		private const LEVELS_GUI:Object = {
												'Level':GameGUI,
												'TutorialLevel':GameGUI,
												'RewardLevel':RewardLevelGUI
											}
			
		public var currentPage:DisplayObject;
		
		private var _content:Sprite;
		
		private var _levels:Array;// массив всех уровней игры
		private var _levelsByNumber:Array;
		public function get levels():Array{ return _levels; }//array of LevelDef (sort by number)
		public function getLevelByNumber(number:int):LevelDef{ return _levelsByNumber[number]; }
		
		/**
		 * Колбэки на смену свойств вида propertyCallbacks["propertyName"] === Array
		 */
		private var propertyCallbacks:Array = [];

		/**
		 * Пул звуковых "треков" игры
		 */
		private var soundTracks:Array = [];
		private var _soundSoundTransform:SoundTransform = new SoundTransform();
		private var _musicSoundTransform:SoundTransform = new SoundTransform();
		private var soundLibraryLoadingStarted:Boolean = false;
		private var soundLibraryLoaded:Boolean = false;
		private const musicNameToFile:Object = {'sound.MusicMenu':'MusicMenu',
												'sound.MusicGame':'MusicGame'};

		private var friendInviteTimer:Timer;

		private var gameUsersByUid:Array = [];

		/**
		 * Игра стартовала, загрузила все необходимые ей ассеты и уже было открыто окно SwitchWindow (если это не награды)
		 */
		public var gameStartedCompletely:Boolean = false;

		protected var gaTracker:GATracker;

		public function RabbitApplication()
		{
			super();
			
			if(Config.application)
				throw new Error("Two Application confusion");
			
			Config.application = this;
		}
		
		
		public function run():void
		{
			createRefs();
			
			initializeManagers();

			include 'com/somewater/rabbit/include/Sitelock.as';
			
			runInitalizeResponses();
		}
		
		private function createRefs():void
		{
			_content = Config.loader.content;
		}
		
		
		private function initializeManagers():void
		{
			Lib.Initialize(Config.loader.swfADs);

			var splashHolder:Sprite = new Sprite();
			splashHolder.graphics.beginFill(0, 0.3);
			splashHolder.graphics.drawRect(0, 0, Config.WIDTH, Config.HEIGHT);
			var splashIconCl:Class = Config.loader.getClassByName('preloader.LogoRabbit');
			var splashIcon:DisplayObject = new splashIconCl();
			splashIcon.name = 'logo';
			var splashBar:MovieClip = Lib.createMC('interface.PreloaderBar');
			splashBar.name = 'bar';
			for(var i:int = 0;i<10;i++)
				splashBar.removeChild(splashBar["carrot" + i]);
			splashHolder.addChild(splashIcon);
			splashHolder.addChild(splashBar);
			var splashBar_x_diff:Number = (Config.WIDTH - splashBar.width) * 0.5 - splashBar.x;
			splashBar.x += splashBar_x_diff;
			splashIcon.x += splashBar_x_diff + 60;
			splashIcon.y = (Config.HEIGHT - splashIcon.height) * 0.5 - 40;
			splashBar.y = splashIcon.y + splashIcon.height + 40;
			var blurScreen:Sprite = new Sprite();
			blurScreen.graphics.beginFill(0, 0.09);
			blurScreen.graphics.drawRect(0, 0, Config.WIDTH, Config.HEIGHT);
			Config.loader.popups.addChild(splashHolder);
			splashHolder.visible = false;
			PopUpManager.Initialize(Config.loader.popups, _content, Config.WIDTH, Config.HEIGHT, blurScreen, splashHolder);

			EmbededTextField.DEFAULT_FONT = Config.FONT_PRIMARY;
			Font.registerFont(Lib.createMC("font.FuturaRound_font", null, false));
			Font.registerFont(Lib.createMC("font.Arial_font", null, false));
			trace("FONTS: " + Font.enumerateFonts().map(function(font:Font, ...args):String{return font.fontName}));
			
			if(Config.loader.popups.stage)
				addGlobalListeners(Config.loader.popups.stage);

			Window.BTN_CLASS = OrangeButton;
			Window.CLOSE_BTN_CLASS = Lib.createMC("interface.CloseButton", null, false);
			Window.GROUND_CLASS = WindowBackground;
			
			Hint.init(Config.loader.tooltips);
			MouseWheel.capture();

			CONFIG::debug
			{
				if(Config.memory['showLoaderTitle']){
					var loaderHint:TextField = new TextField();
					loaderHint.autoSize = TextFieldAutoSize.LEFT;
					loaderHint.text = Config.loader.toString() + ' uid=' + Config.loader.getUser().id;
					loaderHint.x = 0;
					loaderHint.y = Config.stage.stageHeight - loaderHint.height;
					Config.stage.addChild(loaderHint);
				}
			}
			
			Lang.options['male'] = Config.loader.getUser().male;

			Config.loader.serverHandler.addGlobalHandler(false, serverErrorHandler)
			addPropertyListener('musicEnabled', onMusicVolumeChanged);
			addPropertyListener('music', onMusicVolumeChanged);
			addPropertyListener('soundEnabled', onSoundVolumeChanged);
			addPropertyListener('sound', onSoundVolumeChanged);
			addPropertyListener('mouseInput', onMouseInputChanged);

			addEventListener(GameModuleEvent.FRIEND_VISIT_REWARD_HARVESTED, onFriendVisitRewardHarvested);

			loadSettings();

			gaTracker = new GATracker(Config.loader as DisplayObject, 'UA-29834261-1', 'AS3', false);
			while(Config.pendingStats.length)
				stat(Config.pendingStats.shift());

			CONFIG::air{
				initializeManagersAIR();
			}

		}

		CONFIG::air{
			include 'com/somewater/rabbit/include/AIRManagers.as';
		}
		
		public function runInitalizeResponses():void
		{
			// 1. статику:
			//		- Levels
			//		- Managers
			//		- Description
			//		- Rewards
			//		- Config
			// 2. профайл пользователя с сервера
			//

			Config.loader.setProgress(2, 0);
			Config.loader.load({
				"Levels":Config.loader.getFilePath("Levels")
				,"Managers":Config.loader.getFilePath("Managers")
				,"Description":Config.loader.getFilePath("Description")
				,"Rewards":Config.loader.getFilePath("Rewards")
				,"Config":Config.loader.getFilePath("Config")
			}, function(data:Object):void{
				// статика загружена
				Config.loader.setProgress(2, 0.5);
				Config.loader.setProgress(2, 1);
				Config.loader.setProgress(3, 0);
				
				// обработать xml
				processConfigXML();
				
				// инициализировать ServerHandler и выполнить запрос к серверу
				AppServerHandler.instance.initRequest(new UserProfile(Config.loader.getUser()),
					onInitResponseComplete, function(error:Object):void{
						clearLoader();
						// на запрос профайла сервер вернул ошибку
						fatalError(Lang.t("ERROR_INIT_LOADING_PROFILE"));
					});
			}, function():void{
				clearLoader();
				// ошибка загрузки статики
				fatalError(Lang.t("ERROR_INIT_LOADING_STATIC"));
			}, function(value:Number):void{
				// прогресс загрузки статики 0..1
				Config.loader.setProgress(2, value);
			});
		}
		
		private function processConfigXML():void
		{
			var data:XML = Config.loader.getXML("Levels");
			var levels:XMLList = data.levels;
			_levels = [];
			_levelsByNumber = [];
			for each (var level:XML in levels.*)
			{
				var l:LevelDef = new LevelDef(level);
				if(l.number < 100 || CONFIG::debug)
					addLevel(l);
			}

			if(_levels.length == 0)// вносим один пустой уровень
				addLevel(XmlController.instance.getNewLevel());

			var stories:XMLList = data.stories;
			for each (var story:XML in stories.*)
				new StoryDef(story);

			var offers:XMLList = data.offers;
			for each(var offer:XML in offers.*)
				OfferManager.instance.createOffer(offer);

			RewardManager.instance.initialize(Config.loader.getXML('Rewards'))

			var itemClassesHash:Object = {'CustomizeDef':CustomizeDef, 'ItemDef':ItemDef, 'PowerupDef':PowerupDef}
			for each(var customizeData:Object in ConfManager.instance.getArray(ConfManager.ITEMS_KEY))
			{
				var cl:Class = itemClassesHash[customizeData['class']]
				var item:ItemDef = new cl(customizeData);
			}

			Config.blitting
				Config.callLater(Config.game.startPrepareBlitting, null, 2);
		}

		public function addLevel(level:LevelDef):void
		{
			var replacement:Boolean = false;
			for (var i:int = 0; i < _levels.length; i++)
				if(LevelDef(_levels[i]).number == level.number)
				{
					_levels.splice(i, 1, level);
					replacement = true;
					break;
				}
			if(!replacement)
				_levels.push(level);
			_levelsByNumber[level.number] = level;
		}

		public function levelStartMessage(level:LevelDef):void
		{
			new LevelStartWindow(level);
		}

		public function levelFinishMessage(levelInstance:LevelInstanceDef):void
		{
			include 'com/somewater/rabbit/include/Sitelock.as';
			if(levelInstance.success)
			{
				new LevelFinishSuccessWindow(levelInstance);
			}
			else
			{
				new LevelFinishFailWindow(levelInstance);
			}
		}

		public function preFinishedLevel(levelInstance:LevelInstanceDef):void{
			if(levelInstance.success)
				playMusicFadeIn(Sounds.MUSIC_WIN, true);
			else
				playMusicFadeIn(Sounds.MUSIC_LOSE, true);
		}

		public function addFinishedLevel(levelInstance:LevelInstanceDef):void
		{
			if(levelInstance.levelDef.type == LevelDef.TYPE || levelInstance.levelDef.type == TutorialLevelDef.TYPE)
			{
				ServerLogic.addRewardsToLevelInstance(UserProfile.instance, levelInstance);
				if(levelInstance.success){
					AppServerHandler.instance.onLevelPassed(UserProfile.instance, levelInstance);
				}
			}

			TutorialManager.instance.restart(null);

			levelFinishMessage(levelInstance);
			AppServerHandler.instance.statLevelPassed(levelInstance);
		}

		
		private function onInitResponseComplete(response:Object):void
		{
			Config.loader.setProgress(3, 1);
			clearLoader();

			if(response['rewards'] && response['rewards'].length)
			{
				var rewards:Array = [];
				for each(var rewardObject:Object in response['rewards'])
					rewards.push(RewardManager.instance.getById(rewardObject['id']));
				new PendingRewardsWindow(rewards);
			}

			startPage("main_menu");

			Config.stat(Stat.APP_STARTED);

			dispatchEvent(new Event("applicationInited"))

			if(Config.loader.hasFriendsApi)
			{
				friendInviteTimer = new Timer(3*60*1000);
				friendInviteTimer.addEventListener(TimerEvent.TIMER, onFriendInviteTimer);
				friendInviteTimer.start();

				var interv:uint = setInterval(function():void{
					if(canShowOfferWindow)
					{
						clearInterval(interv);
						if(OfferManager.instance.quantity > 0 && UserProfile.instance.offers < OfferManager.instance.prizeQuantity)
							new OfferDescriptionWindow();
					}
				}, 10*1000)
			}
		}
		
		private function onInitResponseError(error:Object):void
		{
			trace("[ERROR] Init server response error");
		}
		
		
		private function clearLoader():void
		{
			var preloader:* = Config.loader.allocatePreloader();
			PageBase.Initialize(preloader);
			Config.loader.clear();
		}
		
		
		public function message(msg:String, closeFunc:Function = null, buttons:Array = null):Sprite
		{
			return PopUpManager.message(translate(msg), null, closeFunc, buttons);
		}
		
		public function showSlash(process:Number):void
		{
			PopUpManager.showSlash(process);
		}
		
		public function hideSplash():void
		{
			PopUpManager.hideSplash();
		}
		
		public function fatalError(msg:String):void
		{
			var openWndErr:Error;
			try
			{
				var wnd:Window = message(msg) as Window;
				wnd.closeButton.visible = false;
				wnd.buttons = [];
			}catch(err:Error){
				openWndErr = err;
			}
			Config.application.hideSplash();
			Config.application = null;
			Config.game = null;
			Config.loader = null;
			if(openWndErr)
				throw openWndErr;
		}
		
		
		public function startPage(name:String):void
		{
			var pageClass:Class = PAGES[name];
			if(pageClass == null)
				throw new Error("Undefined page identifier \"" + name + "\"");
			clearContent();
			currentPage = new pageClass();
			_content.addChild(currentPage);
			Config.gameModuleActive = false;
			_gameGUI = null;
			playMusicFadeIn(Sounds.MUSIC_MENU);
		}
		
		/**
		 * Запускает игру, если та еще не была запущена
		 * в т.ч., добавляет игру на сцену
		 * если аргумент не задан, вычисляется и запускается следующий непройденный (и доступный) уровень
		 */
		public function startGame(level:LevelDef = null):void
		{
			if(level == null)
			{
				var levelNumber:int = UserProfile.instance.levelNumber;
				level = getLevelByNumber(levelNumber);
				if(level == null)
					level = getLevelByNumber(levelNumber - 1);
				if(level == null)
					level = Config.application.levels[0];
			}

			if(level.type == LevelDef.TYPE && level.number == 1){
				level = new TutorialLevelDef();
			}

			clearContent();
			showSlash(-1);
			playMusicFadeIn(level.type == RewardLevelDef.TYPE ? Sounds.MUSIC_MENU : Sounds.MUSIC_GAME);
			
			currentPage = Config.game as DisplayObject;
			_content.addChild(currentPage);
			Config.gameModuleActive = true;
			if(Config.blitting)
				Config.game.stopPrepareBlitting();
			gameStartedCompletely = false;

			Config.callLater(function():void{
				if(!__gameAlreadyRun)
				{
					Config.game.run(onGameInited);
					__gameAlreadyRun = true;
				}
				else
					onGameInited();
			}, null, __gameAlreadyRun || !Config.blitting ? 1 : 3);// больше времени, чтобы подготовка блиттига успела отработать

			
			function onGameInited():void
			{
				include 'com/somewater/rabbit/include/Sitelock.as';
				Config.game.startLevel(level, function():void{
					var guiClass:Class = LEVELS_GUI[level.type];
					if(guiClass)
					{
						_gameGUI = new guiClass()
						_content.addChild(_gameGUI);
					}
					Config.callLater(onGameStarted, null, 2);
				});
				
			}
			function onGameStarted():void
			{
				hideSplash();

				if(level.type == LevelDef.TYPE || level.type == TutorialLevelDef.TYPE)
				{
					levelStartMessage(level);
					Config.stat(Stat.LEVEL_STARTED);
					AppServerHandler.instance.onLevelStarted(UserProfile.instance, level);
					OfferManager.instance.onLevelStarted(level);
				}
				else if(level.type == RewardLevelDef.TYPE)
				{
					if(RewardLevelDef(level).gameUser.itsMe())
						Config.stat(Stat.MY_REWARDS_OPENED)
					else
						Config.stat(Stat.FRIEND_REWARDS_OPENED);

					CustomizeManager.instance.customize();
				}

				TutorialManager.instance.restart(level);

				gameStartedCompletely = true;
				dispatchEvent(new GameModuleEvent(GameModuleEvent.GAME_MODULE_STARTED_EVENT, level));
			}
		}
		private var __gameAlreadyRun:Boolean = false;

		public function restartCurrentGame():void{
			new RestartLevelCommand().execute();
		}
		
		
		/**
		 * Очистить зону контента
		 */
		private function clearContent():void
		{
			while(_content.numChildren)
			{
				var child:DisplayObject = _content.removeChildAt(0);
				if(child is IClear)
					IClear(child).clear();
			}
			currentPage = null;
			TutorialManager.instance.restart(null);
		}
		
		
		/**
		 * @param callback callback():void
		 */
		public function addPropertyListener(propertyName:String, callback:Function):void
		{
			if(!propertyCallbacks[propertyName])
				propertyCallbacks[propertyName] = [];
			if(propertyCallbacks[propertyName].indexOf(callback) == -1)
				propertyCallbacks[propertyName].push(callback);
		}
		
		public function removePropertyListener(propertyName:String, callback:Function):void
		{
			if(propertyCallbacks[propertyName])
				propertyCallbacks[propertyName].splice(propertyCallbacks[propertyName].indexOf(callback),1)
		}

		/**
		 * Возможные события:
		 * "music" 			изменение громкости музыки
		 * "musicEnabled"   вкл/выкл музыки
		 * "sound" 			изменение громкости звука
		 * "soundEnabled"   вкл/выкл звука
		 * "levelChanged"	стартовал очередной уровень
		 * "game.start"     игра стартовала (в смысле - старт после паузы, рестарт левела не вызывает данный эвент)
		 * "game.pause"     игра переведена на паузу
		 * "game.switch"    игра стартовала (после паузы) или поставлена на паузу
		 */
		public function dispatchPropertyChange(propertyName:String):void
		{
			if(propertyCallbacks[propertyName])
			{
				for(var i:int = 0; i<propertyCallbacks[propertyName].length; i++)
					propertyCallbacks[propertyName][i]();
			}
		}
		
		private var _sound:Number = 0.7;
		public function set sound(value:Number):void
		{
			if(_sound != value)
			{
				_sound = value;
				dispatchPropertyChange("sound");
			}
		}
		public function get sound():Number
		{
			return _sound;
		}
		
		private var _music:Number = 0.7;
		public var musicFader:Number = 1;
		public function set music(value:Number):void
		{
			if(_music != value)
			{
				_music = value;
				dispatchMusicChange();
			}
		}
		public function get music():Number
		{
			return _music * musicFader;
		}
		private function dispatchMusicChange():void
		{
			dispatchPropertyChange("music");
		}
		
		private var _musicEnabled:Boolean = true;
		public function set musicEnabled(value:Boolean):void
		{
			if(_musicEnabled != value)
			{
				_musicEnabled = value;
				dispatchPropertyChange("musicEnabled");
			}
		}
		public function get musicEnabled():Boolean
		{
			return _musicEnabled;	
		}
		
		private var _soundEnabled:Boolean = true;
		public function set soundEnabled(value:Boolean):void
		{
			if(_soundEnabled != value)
			{
				_soundEnabled = value;
				dispatchPropertyChange("soundEnabled");
			}
		}
		public function get soundEnabled():Boolean
		{
			return _soundEnabled;	
		}

		private var _mouseInput:Boolean = true;
		public function set mouseInput(value:Boolean):void {
			if(_mouseInput != value)
			{
				_mouseInput = value;
				dispatchPropertyChange("mouseInput");
			}
		}

		public function get mouseInput():Boolean {
			return _mouseInput;
		}

		public function get allowKeyboard():Boolean
		{
			return true;
		}
		
		private function addGlobalListeners(stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onGlobalKeyDown);
		}
		
		private function onGlobalKeyDown(e:KeyboardEvent):void
		{
			if(Config.gameModuleActive)
			{
				if(e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.SPACE)
				{
					if(PopUpManager.activeWindow is PauseMenuWindow)
						PauseMenuWindow(PopUpManager.activeWindow).simulateCloseButtonClick();
					else if(PopUpManager.activeWindow is LevelStartWindow)
						LevelSwitchWindow(PopUpManager.activeWindow).defaultButtonPress();
					else if(!PopUpManager.activeWindow && Config.game.isTicking)
						new PauseMenuWindow();
				}
			}
			else
			{
				if(e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.SPACE)
				{
					// "нажать" кнопку в окне
					var activeWindow:Window = PopUpManager.activeWindow;
					if(activeWindow)
						activeWindow.defaultButtonPress();
				}
			}
		}

		public function createTextField(font:String = null,color:* = null,
										size:int = 12,bold:Boolean = false,
										multiline:Boolean = false, selectable:Boolean = false,
										input:Boolean = false,align:String = "left",bitmapText:Boolean = false):TextField
		{
			return new EmbededTextField(font, color,size, bold, multiline, selectable, input,align, bitmapText);
		}

		public function translate(key:String, args:Object = null):String
		{
			return Lang.t(key, args)
		}



		/**
		 * Обработка любых серверных ошибок
		 */
		private function serverErrorHandler(response:Object):void {
			if(response.hasOwnProperty('no_callback') && response['no_callback'])
				this.fatalError(response['error'] ? response['error'] : translate('UNDEFINED_SERVER_ERROR'))
		}

		public function play(soundName:String, track:String, force:Boolean = false):void
		{
			if(track != SoundTrack.MUSIC && soundName != Sounds.HARVEST && soundName != Sounds.DAMAGE)
				return;// Пока музыка (звуки вернее) идиотская, не проигрываем ее вовсе

			if(force == false && soundTracks[track] && SoundData(soundTracks[track]).soundName == soundName)
				return; // игнорируем попытку прогирать один и тот же звук, когда не доиграл такой же

			var soundObject:Sound = Lib.createMC(soundName);
			if(soundObject == null)
			{
				// if music, load and start playing async
				if(track == SoundTrack.MUSIC)
				{
					Config.loader.loadSwf(musicNameToFile[soundName] || 'Sound', playActualMusic);
				}
				else
				{
					if(!soundLibraryLoadingStarted)
					{
						Config.loader.loadSwf('Sound', onSoundLibraryLoaded);
						soundLibraryLoadingStarted = true;
					}else if(soundLibraryLoaded)
						Config.game.logError(this, 'play', 'Sound ' + soundName + ' not found in library');
				}
				return;
			}

			if(soundTracks[track])
			{
				SoundData(soundTracks[track]).channel.stop();
				SoundData(soundTracks[track]).channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete)
				if(track == SoundTrack.MUSIC)
					Config.callLater(playNewSound, null, 1)
				else
					playNewSound();
			}
			else
				playNewSound();

			function playNewSound():void
			{
				var ortadoxMusic:Boolean = track == SoundTrack.MUSIC && (soundName == Sounds.MUSIC_MENU || soundName == Sounds.MUSIC_GAME)
				var soundTransform:SoundTransform = track == SoundTrack.MUSIC ? _musicSoundTransform : _soundSoundTransform;
				if(pseudoMusic(soundName))
					soundTransform = _soundSoundTransform;
				soundTracks[track] = new SoundData(soundName, soundObject.play(0,
						ortadoxMusic ? 0xFFFF : 0, soundTransform));
				SoundData(soundTracks[track]).channel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			}
		}

		private function pseudoMusic(soundName:String):Boolean {
			return soundName == Sounds.MUSIC_WIN || soundName == Sounds.MUSIC_LOSE;
		}

		private function onSoundVolumeChanged():void {
			_soundSoundTransform.volume = _soundEnabled ? _sound : 0;
			for(var name:* in soundTracks)
				if(name != SoundTrack.MUSIC && soundTracks[name])
					SoundData(soundTracks[name]).channel.soundTransform = _soundSoundTransform;
			saveAudioSettings();
		}

		private function onMusicVolumeChanged():void {
			updateMusicVolume();
			saveAudioSettings();
		}

		private function onMouseInputChanged():void {
			if(!settingsLoadingFlag)
			{
				Config.loader.set('inputSettings', {'mouseInput': this.mouseInput});
			}
		}

		private function onSoundComplete(event:Event):void
		{
			var sd:SoundData;
			var track:String;
			for(track in soundTracks)
			{
				sd = soundTracks[track];
				if(sd.channel == event.currentTarget as SoundChannel)
				{
					sd.channel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
					delete(soundTracks[track]);
					break;
				}
			}

			if(sd) {
				if(track == SoundTrack.MUSIC) {
					playActualMusic(true);
				}
			}
		}

		private var settingsLoadingFlag:Boolean = false;
		private var _gameGUI:DisplayObject;

		private function saveAudioSettings():void
		{
			if(!settingsLoadingFlag)
			{
				Config.loader.set('audioSettings', {'music': this.music, 'musicEnabled': this.musicEnabled,
													'sound': this.sound, 'soundEnabled': this.soundEnabled});
			}
		}

		private function loadSettings():void
		{
			settingsLoadingFlag = true;
			var settings:Object = Config.loader.get('audioSettings');
			if(settings)
			{
				this.music = settings['music'];
				this.musicEnabled = settings['musicEnabled'];
				this.sound = settings['sound'];
				this.soundEnabled = settings['soundEnabled'];
			}
			settings = Config.loader.get('inputSettings');
			if(settings)
			{
				this.mouseInput = settings['mouseInput'];
			}
			settingsLoadingFlag = false;
		}
		
		/**
		 * Loaded lib file with some music theme
		 */
		private function playActualMusic(fade:Boolean = false):void
		{
			if(currentPage == Config.game)
			{
				if(fade)
					playMusicFadeIn(Sounds.MUSIC_GAME, !fade)
			    else
					play(Sounds.MUSIC_GAME, SoundTrack.MUSIC);
			}
			else
			{
				if(fade)
					playMusicFadeIn(Sounds.MUSIC_MENU)
				else
					play(Sounds.MUSIC_MENU, SoundTrack.MUSIC);
			}
		}

		private function onSoundLibraryLoaded():void
		{
			soundLibraryLoaded = true;
		}

		/**
		 * Пришло время проверить возможность показать окно-приглашалку друзей и показать её
		 */
		private function onFriendInviteTimer(event:TimerEvent):void {
			if(canShowOfferWindow)
			{
				/*
				if(UserProfile.instance.levelNumber > 8)
				{
					new TesterInvitationWindow();
				}
				else
				*/
				// если включен какой-то интерфейс приложения, а не сама игра (уровень, полянка и т.д.) и нет окон
				new InviteFriendsWindow();
			}
		}


		public function get gameGUI():DisplayObject
		{
			return _gameGUI;
		}

		/**
		 * Все условия для того чтобы показать офферное окно
		 */
		public function get canShowOfferWindow():Boolean
		{
			return Config.gameModuleActive == false
					&& PopUpManager.numWindows == 0
					&& !TutorialManager.active
					&& !(currentPage is ShopPage)// в магазине никого не беспокоим, пусть тратят деньги
		}

		/**
		 * Обеспечивает уникальность кажого объеата GameUser (не создается дважды)
		 */
		public function createGameUser(data:SocialUser):GameUser
		{
			var user:GameUser = gameUsersByUid[data.id];
			if(user == null)
			{
				user = new GameUser();
				user.data = data;
				gameUsersByUid[data.id] = user;
			}
			return user;
		}

		public function stat(name:String):void {
			if(gaTracker)
			{
				gaTracker.trackEvent('ClientStat_' + Config.loader.net, name);
				gaTracker.trackPageview(name);
			}
			else
				Config.pendingStats.push(name);
		}

		private function onFriendVisitRewardHarvested(event:GameModuleEvent):void
		{
			// послать на сервер запрос насчет реварда и выдать ревард юзеру (выдается в AppServerHandler)
			AppServerHandler.instance.friendVisitReward((event.level as RewardLevelDef).gameUser as GameUser, null, function(response:Object):void{
				// error
				message(Lang.t('ERROR_FRIEND_VISIT_REWARD'));
			})
		}

		private function playMusicFadeIn(musicName:String, fastFade:Boolean = false):void
		{
			if(soundTracks[SoundTrack.MUSIC])
			{
				if(SoundData(soundTracks[SoundTrack.MUSIC]).soundName == musicName)
					return;// не нужно плавного перехода, если и так играет что надо

				TweenLite.killTweensOf(this, true);
				TweenLite.to(this, fastFade ? 0.3 : 0.8, {musicFader: 0,
					onComplete:startMusicFadeInImmediately,
					onCompleteParams: [musicName, fastFade],
					onUpdate: updateMusicVolume
				});
			}
			else
			{
				this.musicFader = 0;
				startMusicFadeInImmediately(musicName, fastFade);
			}
		}

		private function startMusicFadeInImmediately(musicName:String, fastFade:Boolean):void
		{
			TweenLite.to(this, fastFade ? 0.3 : 0.8, {musicFader: 1, onUpdate: updateMusicVolume});
			play(musicName, SoundTrack.MUSIC);
		}

		public function canCompleteLevel():Boolean{
			return !TutorialManager.instance.running;
		}

		private function updateMusicVolume():void{
			_musicSoundTransform.volume = _musicEnabled ? _music : 0;
			var sd:SoundData = soundTracks[SoundTrack.MUSIC];
			if(sd && !pseudoMusic(sd.soundName))
				sd.channel.soundTransform = _musicSoundTransform;
		}
	}
}

import flash.media.SoundChannel;

class SoundData
{
	public var soundName:String;
	public var channel:SoundChannel;

	public function SoundData(soundName:String, channel:SoundChannel)
	{
		this.soundName = soundName;
		this.channel = channel;
	}
}