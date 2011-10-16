package
{
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Window;
	import com.somewater.net.ServerHandler;
	import com.somewater.rabbit.IRabbitApplication;
	import com.somewater.rabbit.application.AboutPage;
	import com.somewater.rabbit.application.GameGUI;
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.OrangeGround;
	import com.somewater.rabbit.application.PageBase;
	import com.somewater.rabbit.application.WindowBackground;
	import com.somewater.rabbit.application.windows.LevelFinishFailWindow;
	import com.somewater.rabbit.application.windows.LevelFinishSuccessWindow;
	import com.somewater.rabbit.application.windows.LevelStartWindow;
	import com.somewater.rabbit.application.windows.PauseMenuWindow;
	import com.somewater.rabbit.net.AppServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.social.SocialAdapter;
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
	import flash.text.Font;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;


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
										"about":AboutPage
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
			
			runInitalizeResponses();
		}
		
		private function createRefs():void
		{
			_content = Config.loader.content;
		}
		
		
		private function initializeManagers():void
		{
			Lib.Initialize(Config.loader.swfADs);
			
			EmbededTextField.DEFAULT_FONT = Config.FONT_PRIMARY;
			Font.registerFont(Lib.createMC("font.FuturaRound_font", null, false));
			Font.registerFont(Lib.createMC("font.Arial_font", null, false));
			trace("FONTS: " + Font.enumerateFonts().map(function(font:Font, ...args):String{return font.fontName}));
			var blurScreen:Sprite = new Sprite();
			blurScreen.graphics.beginFill(0, 0.09);
			blurScreen.graphics.drawRect(0, 0, Config.WIDTH, Config.HEIGHT);
			
			var preloader:* = Config.loader.allocatePreloader();
			PageBase.Initialize(preloader);
			var splashIcon:DisplayObject = preloader.logo;
			var splashBar:MovieClip = preloader.bar;
			for(var i:int = 0;i<10;i++) splashBar.removeChild(splashBar["carrot" + i]);
			var splashHolder:Sprite = new Sprite();
			splashHolder.graphics.beginFill(0, 0.3);
			splashHolder.graphics.drawRect(0, 0, Config.WIDTH, Config.HEIGHT);
			splashHolder.addChild(splashIcon);
			splashHolder.addChild(splashBar);
			var splashBar_x_diff:Number = (Config.WIDTH - splashBar.width) * 0.5 - splashBar.x;
			splashBar.x += splashBar_x_diff;
			splashIcon.x += splashBar_x_diff;
			splashIcon.y = (Config.HEIGHT - splashIcon.height) * 0.5 - 50;
			splashBar.y = splashIcon.y + splashIcon.height + 40;
			Config.loader.addChild(splashHolder);
			splashHolder.visible = false;
			
			PopUpManager.Initialize(Config.loader.popups, _content, Config.WIDTH, Config.HEIGHT, blurScreen, splashHolder);
			if(Config.loader.popups.stage)
				addGlobalListeners(Config.loader.popups.stage);
			Window.BTN_CLASS = OrangeButton;
			Window.CLOSE_BTN_CLASS = Lib.createMC("interface.CloseButton", null, false);
			Window.GROUND_CLASS = WindowBackground;
			
			Hint.init(Config.loader.tooltips);
		}
		
		
		
		public function runInitalizeResponses():void
		{
			//TODO: запустить инициализационную загрузку с сервера
			// 1. статику:
			//		- Levels
			//		- Managers
			//		- Description
			//		- LevelPack
			// 2. профайл пользователя с сервера
			//
			
			Config.loader.setProgress(2, 0);
			Config.loader.load({
				"Levels":Config.loader.getFilePath("Levels")
				,"Managers":Config.loader.getFilePath("Managers")
				,"Description":Config.loader.getFilePath("Description")
				,"LevelPack":Config.loader.getFilePath("LevelPack")
			}, function(data:Object):void{
				// статика загружена
				Config.loader.setProgress(2, 1);
				Config.loader.setProgress(3, 0);
				
				// обработать xml
				processLevelsXML();
				
				// инициализировать ServerHandler и выполнить запрос к серверу
				AppServerHandler.initRequest(onInitResponseComplete, function(error:Object):void{
					// на запрос профайла сервер вернул ошибку
					fatalError(Lang.t("ERROR_INIT_LOADING_PROFILE"));
				});
			}, function():void{
				// ошибка загрузки статики
				fatalError(Lang.t("ERROR_INIT_LOADING_STATIC"));
			}, function(value:Number):void{
				// прогресс загрузки статики 0..1
				Config.loader.setProgress(2, value);
			});
		}
		
		private function processLevelsXML():void
		{
			var levels:XML = Config.loader.getXML("Levels");
			_levels = [];
			_levelsByNumber = [];
			for each (var level:XML in levels.*)
			{
				addLevel(new LevelDef(level));
			}

			if(_levels.length == 0)// вносим один пустой уровень
				addLevel(XmlController.instance.getNewLevel());
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
			if(levelInstance.success)
			{
				new LevelFinishSuccessWindow(levelInstance);
			}
			else
			{
				new LevelFinishFailWindow(levelInstance);
			}
		}

		public function addFinishedLevel(levelInstance:LevelInstanceDef):void
		{
			UserProfile.instance.addLevelInstance(levelInstance);
		}

		
		private function onInitResponseComplete(response:Object):void
		{
			Config.loader.setProgress(3, 1);
			clearLoader();
			
			var userData:Object = response;
			
			new UserProfile(userData);
			
			startPage("main_menu");

			dispatchEvent(new Event("applicationInited"))
		}
		
		private function onInitResponseError(error:Object):void
		{
			trace("[ERROR] Init server response error");
		}
		
		
		private function clearLoader():void
		{
			Config.loader.clear();
		}
		
		
		public function message(msg:String):Sprite
		{
			return PopUpManager.message(msg);
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
			Config.application.hideSplash();
			message(msg);
		}
		
		
		public function startPage(name:String):void
		{
			var pageClass:Class = PAGES[name];
			if(pageClass == null)
				throw new Error("Undefined page identifier \"" + name + "\"");
			currentPage = new pageClass();
			clearContent();			
			_content.addChild(currentPage);
			Config.gameModuleActive = false;
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
				level = getLevelByNumber(levelNumber + 1);
				if(level == null)
					level = getLevelByNumber(levelNumber);
				if(level == null)
					level = Config.application.levels[0];
			}

			clearContent();
			showSlash(-1);
			
			var game:DisplayObject = Config.game as DisplayObject;
			_content.addChild(game);
			Config.gameModuleActive = true;
			
			if(!__gameAlreadyRun)
			{
				Config.game.run(onGameInited);
				__gameAlreadyRun = true;
			}
			else
				onGameInited();
			
			function onGameInited():void
			{
				Config.game.startLevel(level, onGameStarted);
				
			}
			function onGameStarted():void
			{
				_content.addChild(new GameGUI());
				hideSplash();
				levelStartMessage(level);
			}
		}
		private var __gameAlreadyRun:Boolean = false;

		
		
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
		
		private var _sound:Number = 1;
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
		
		private var _music:Number = 1;
		public function set music(value:Number):void
		{
			if(_music != value)
			{
				_music = value;
				dispatchPropertyChange("music");
			}
		}
		public function get music():Number
		{
			return _music;	
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
					if(activeWindow 
					   && activeWindow.buttons
					   && activeWindow.buttons.length == 1
					   && activeWindow.buttons[0] is DisplayObject)
						activeWindow.simulateButtonPress(DisplayObject(activeWindow.buttons[0]));
				}
			}
		}
	}
}