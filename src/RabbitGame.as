package
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.core.TemplateManager;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.SceneAlignment;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.display.blitting.BlitManager;
	import com.somewater.display.blitting.PreparativeBlitManager;
	import com.somewater.rabbit.IRabbitGame;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.commands.RestartLevelCommand;
	import com.somewater.rabbit.components.GenocideComponent;
	import com.somewater.rabbit.components.InputComponent;
	import com.somewater.rabbit.components.PowerupControllerComponent;
	import com.somewater.rabbit.components.RandomActComponent;
	import com.somewater.rabbit.debug.ConsoleUtils;
	import com.somewater.rabbit.debug.CreateTool;
	import com.somewater.rabbit.debug.EditorModule;
	import com.somewater.rabbit.events.ExceptionEvent;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.iso.scene.SceneView;
	import com.somewater.rabbit.managers.GameTutorialModule;
	import com.somewater.rabbit.managers.IGameTutorialModule;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.util.RandomizeUtil;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.storage.Lang;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.utils.Timer;

	import nl.demonsters.debugger.MonsterDebugger;
	
	[SWF(width="810", height="550", backgroundColor="#FFFFFF", frameRate="30")]
	public class RabbitGame extends Sprite implements IRabbitGame
	{

		private var PROGRESS_RATIO:Number;
		
		public static var instance:RabbitGame;
		
		public static var worldScene:SceneView;		
		private var hero:IEntity;
		private var heroSpatial:SimpleSpatialComponent;
		
		
		public var uiLayer:Sprite;
		public var popupLayer:Sprite;
		public var hintLayer:Sprite;
		
		private var _level:LevelDef;
		public function get level():LevelDef{ return _level; }

		/**
		 * Таймер обеспечивает апдейт прогрессбара каждую секунду во время блиттинга
		 * (бывают ситуации, когда сам блит менеджер диспатчит апдейт
		 * реже чем раз в секунду - длинная анимация персонажа)
		 */
		private var blitProgressUpdater:Timer;
		
		public function RabbitGame()
		{
			if(Config.game)
				throw new Error("Must be only one. And his name a Rabbit!");
			
			Config.game = instance = this;

			PROGRESS_RATIO = Config.blitting ? 0.2 : 0.5;
			
			graphics.beginFill(0x85B53D);
			graphics.drawRect(0,0,Config.WIDTH,Config.HEIGHT);

			try{
			Security.allowDomain("*");
			}catch(err:Error){
				trace(err)
			}
			
			if(stage)// если запущена непоследстенно игра, минуя прелоадер
				run();
		}
		
		
		private var onInitCallback:Function;
		public function run(callback:Function = null):void
		{
			onInitCallback = callback;
			PBE.IS_SHIPPING_BUILD = !(CONFIG::debug);
			
			if(stage)
				onAddedToStage(null);
			else
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		
		private var onLevelStartedCallback:Function;
		public function startLevel(level:LevelDef, callback:Function = null):void
		{
			if(stage)
				stage.frameRate = Config.FRAME_RATE;
			
			Config.gameModuleActive = true;			
			_level = level;
			onLevelStartedCallback = callback;
			
			loadAssets();
		}
		
		/**
		 * @param event
		 * @param supressBack не открывать страницу "Уровни". Предполагается, что вызывающая
		 * 					  функция сама распорядится поведением, после конца уровня 
		 */
		public function finishLevel(event:LevelInstanceDef):void
		{
			Config.gameModuleActive = false;
			PBE.processManager.stop();
			PBE.processManager.clear();
			InitializeManager.clearLevel()
		}
		
		
		protected function onAddedToStage(e:Event):void
		{
			if(e)
				removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

			InitializeManager.init(this);
			
			onInitCallback && onInitCallback();
		}
		
		
		private function loadAssets():void
		{
			//Config.application.showSlash(0);

			var swfs:Array = [];
			swfs = swfs.concat(_level.additionSwfs);

			Config.loader.loadSwfs(swfs, function():void{
				// complete
				loadXML();
			}, function():void{
				// error
				Config.application.fatalError(Lang.t("ERROR_LOADING_ASSETS"));
			}, function(value:Number):void{
				// progress
				//Config.application.showSlash(value * PROGRESS_RATIO);
			});
		}
		
		private var addedXmlNames:Array = [];
		private function loadXML():void
		{
			var paths:Object = {
					"Description":Config.loader.getFilePath("Description")// вообщето обязано (!) быть загружено ранее
					,"Rewards":Config.loader.getFilePath('Rewards')
					,"Managers":Config.loader.getFilePath("Managers")
			};
			var pathsToLoad:Array = [];
			for(var name:String in paths)
			{
				var xml:XML = Config.loader.getXML(name);
				if(xml)
					add(xml, name);
				else
					pathsToLoad[name] = paths[name];
			}
			
			Config.loader.load(pathsToLoad, function(xmls:Object):void{
				// on complete
				for(var name:String in xmls)
					add(xmls[name], name);
				blitSlugs();
			}, function():void{
				// on error
				Config.application.fatalError(Lang.t("ERROR_LOADING_XMLS"));
			},function(value:Number):void{
				// on progress
				Config.application.showSlash(PROGRESS_RATIO + value * PROGRESS_RATIO);
			});
			
			function add(xml:*, name:String):void
			{
				if(addedXmlNames[name]) return;
				if(!(xml is XML))
					xml = new XML(xml);
				addedXmlNames[name] = true;
				for each (var child:XML in xml.*)
					PBE.templateManager.addXML(child, Config.loader.getFilePath(name), 0);
			}
		}
		
		private function blitSlugs():void
		{
			if(Config.blitting)
			{
				var movieBySlug:Object = XmlController.instance.getLevelSlugs(_level);
				var slugs:Array = [];
				var slug:String;
				for(slug in movieBySlug)
					slugs.push(slug);

				var uniqMovieBySlug:Object = {};// не создаем одно и то же дважды
				for each(slug in slugs)
					if(!BlitManager.instance.slugRegistered(slug))
					{
						var mc:MovieClip = Lib.createMC(slug);
						CONFIG::air
						{
							// добавляем мувик на сцену, куда нить подальше в угол. ПОтому что иначе AIR косячит жутко
							mc.x = -500;
							mc.y = -500;
							mc.visible = false;
							Config.stage.addChildAt(mc, 0);
						}
						uniqMovieBySlug[slug] = mc;
					}

				BlitManager.instance.addEventListener(Event.COMPLETE, recreateLevel);
				//BlitManager.instance.addEventListener(Event.CHANGE, onBlittingProgress);
				clearBlitUpdater();
				blitProgressUpdater = new Timer(2000);
				blitProgressUpdater.addEventListener(TimerEvent.TIMER, onBlittingProgress);
				blitProgressUpdater.start();

				BlitManager.instance.prepare(uniqMovieBySlug, true)
			}

			recreateLevel();
		}

		private function clearBlitUpdater():void
		{
			if(blitProgressUpdater)
			{
				blitProgressUpdater.removeEventListener(TimerEvent.TIMER, onBlittingProgress);
				blitProgressUpdater.stop();
				blitProgressUpdater = null;
			}
		}

		private function onBlittingProgress(event:Event):void {
			var lastProgress:Number = PROGRESS_RATIO * 2;
			Config.application.showSlash(lastProgress + BlitManager.instance.progress * (1 - lastProgress));
		}
		
		private function recreateLevel(event:Event = null):void
		{
			if(Config.blitting)
			{
				clearBlitUpdater();
				BlitManager.instance.removeEventListener(Event.CHANGE, onBlittingProgress);
				BlitManager.instance.removeEventListener(Event.COMPLETE, recreateLevel);
			}

			include 'com/somewater/rabbit/include/Sitelock.as';
			InitializeManager.restartLevel();
			
			onLevelStartedCallback && onLevelStartedCallback();
			Config.application.dispatchPropertyChange("levelChanged");
		}
		
		
		
		public function start():void
		{
			include 'com/somewater/rabbit/include/Sitelock.as';
			if(!PBE.processManager.isTicking)
				PBE.processManager.start();
			Config.application.dispatchPropertyChange("game.start");
			Config.application.dispatchPropertyChange("game.switch");
		}
		
		public function pause():void
		{
			if(PBE.processManager.isTicking)
				PBE.processManager.stop();
			Config.application.dispatchPropertyChange("game.pause");
			Config.application.dispatchPropertyChange("game.switch");

			// "отжать" нажатые кнопки
			try
			{
				(PBE.lookupEntity('Hero').lookupComponentByType(InputComponent) as InputComponent).clearKeys();
			}catch(err:Error){}
		}
		
		
		public function get isTicking():Boolean
		{
			return PBE.processManager.isTicking;
		}
		
		public function logError(reporter:*, method:String, message:String):void
		{
			Logger.error(reporter, method, message);
		}

		public function initializeEditorModule():void
		{
			CONFIG::debug
			{
				EditorModule.instance.init();
			}
		}

		public function setTemplateTool(toolname:String, template:XML = null, objectReference:XML = null):IEventDispatcher
		{
			CONFIG::debug
			{
				pause();
				return EditorModule.instance.setTemplateTool(toolname, template, objectReference);
			}
			return null;
		}
		
		/**
		 * Обработка ошибки, произошедшей во время тиканья процесс-менеджера
		 */
		public function onSomeException(event:ExceptionEvent):void
		{
			var text:String = Config.application.translate('ERROR_CLIENT_EXCEPTION',
				{
					'error': (event.error.getStackTrace().length ? event.error.getStackTrace() : event.error.message)
				});
			var w:Sprite = Config.application.message(text, function(...args):Boolean{
					// рестарт уровня
					new RestartLevelCommand().execute();
					return true;
				}, [Config.application.translate('BUTTON_RESTART_LEVEL')]);
			w.width = Config.WIDTH * 0.95;
			if(w && w.getChildByName('closeButton'))
				w.getChildByName('closeButton').visible = false;
			if(w && w.getChildByName('ground'))
				w.getChildByName('ground').alpha = 0.5;
			if(w && w.getChildByName('textField')
					&& w.getChildByName('textField') is TextField
					&& w.getChildByName('textField').hasOwnProperty('size'))
			{
				text = text + text + text + text;
				TextField(w.getChildByName('textField')).y = 10;
				TextField(w.getChildByName('textField')).text = text;
				TextField(w.getChildByName('textField')).selectable = true;
				TextField(w.getChildByName('textField')).mouseEnabled = true;
				w.getChildByName('textField').height = Math.min(w.height * 0.75, Config.HEIGHT * 0.95);
				Object(w.getChildByName('textField')).size = 12;
			}
			pause();

			Config.stat(Stat.EXCEPTION_CATCHED);
		}
		
		override public function get width():Number{return Config.WIDTH;}
		override public function get height():Number{return Config.HEIGHT;}

		public function get tutorialModule():IGameTutorialModule
		{
			return GameTutorialModule.instance;
		}

		public function createOffer(x:int, y:int):void {
			//var entity:IEntity =
			createEntity('OfferTemplate', x, y);
		}

		public function usePowerup(templateName:String):void {
			// найдем ссылку на Hero
			var hero:IEntity = PBE.lookupEntity('Hero');
			if(hero)
			{
				var heroPos:Point = (hero.lookupComponentByType(IsoSpatial) as IsoSpatial).tile;
				(hero.lookupComponentByType(PowerupControllerComponent) as PowerupControllerComponent).applyPowerup(createEntity(templateName, heroPos.x, heroPos.y), templateName);
			}
			else if(CONFIG::debug)
				throw new Error('Hero not founded')
		}

		public function createFriendVisitReward():void
		{
			// выбрать пустое место, доступное кролику для перемещения, и создать там монетку
			var position:Point = new Point(0, 2);

			createEntity('MoneyRewardTemplate', position.x, position.y);
		}

		private function createEntity(template:String, x:int, y:int):IEntity
		{
			var entity:IEntity = PBE.templateManager.instantiateEntity(template);
			entity.owningGroup = PBE.lookup(InitializeManager.lastLevelGroup) as PBGroup;
			entity.setProperty(new PropertyReference('@Spatial.position'), new Point(x,  y))
			return entity;
		}

		public function startPrepareBlitting():void
		{
			var movies:Array = [];
			var mainCharacters:Array = ['Hero', 'Hedgehog', 'Dog', 'Bush', 'Carrot', 'Crow'];
			var slug:String;
			for each(var character:String in mainCharacters)
			{
				slug = XmlController.instance.getSlugByTemplateName(character);
				movies.push({slug: slug, movie:Lib.createMC(slug)});
			}
			if(BlitManager.instance == null)
				BlitManager.instance = new PreparativeBlitManager();
			(BlitManager.instance as PreparativeBlitManager).startPrepare(movies);
		}

		public function stopPrepareBlitting():void
		{
			(BlitManager.instance as PreparativeBlitManager).onStop();
		}

		public function entityToTile(entity:*):Point {
			var e:IEntity = entity as IEntity;
			return (e.lookupComponentByName("Spatial") as IsoSpatial).tile;
		}
	}
}