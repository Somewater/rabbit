package
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.core.TemplateManager;
	import com.pblabs.engine.debug.Console;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.SceneAlignment;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.rabbit.IRabbitGame;
	import com.somewater.rabbit.components.GenocideComponent;
	import com.somewater.rabbit.components.RandomActComponent;
	import com.somewater.rabbit.debug.ConsoleUtils;
	import com.somewater.rabbit.debug.EditorModule;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.iso.scene.SceneView;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.ui.GameUIComponent;
	import com.somewater.rabbit.util.RandomizeUtil;
	import com.somewater.storage.Lang;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import nl.demonsters.debugger.MonsterDebugger;
	
	[SWF(width="810", height="550", backgroundColor="#FFFFFF", frameRate="30")]
	public class RabbitGame extends Sprite implements IRabbitGame
	{
		
		public static var instance:RabbitGame;
		
		public static var worldScene:SceneView;		
		private var hero:IEntity;
		private var heroSpatial:SimpleSpatialComponent;
		
		
		public var uiLayer:Sprite;
		public var popupLayer:Sprite;
		public var hintLayer:Sprite;
		
		private var _level:LevelDef;
		public function get level():LevelDef{ return _level; }
		
		public function RabbitGame()
		{
			if(Config.game)
				throw new Error("Must be only one. And his name a Rabbit!");
			
			Config.game = instance = this;
			
			graphics.beginFill(0x85B53D);
			graphics.drawRect(0,0,810,650);
			
			Security.allowDomain("*");
			
			if(stage)// если запущена непоследстенно игра, минуя прелоадер
				run();
		}
		
		
		private var onInitCallback:Function;
		public function run(callback:Function = null):void
		{
			onInitCallback = callback;
			
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
		public function finishLevel(event:LevelInstanceDef, supressLevelsPageTransition:Boolean = false):void
		{
			Config.gameModuleActive = false;
			PBE.processManager.stop();
			PBE.processManager.clear();
			
			// асинхронный вызов функци, т.к. иначе не дотикают неокторые контроллеры в processManager
			// (он остановится не мгновенно, а доведет до конца текущий тик)
			if(!supressLevelsPageTransition)
				addEventListener(Event.ENTER_FRAME, function(e:Event):void{
					e.currentTarget.removeEventListener(e.type, arguments.callee);
					Config.application.startPage("levels");
				});
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
			Config.application.showSlash(0);
			
			Config.loader.loadSwfs([{name:"Assets"}, {name:"Interface"}], function():void{
				// complete
				loadXML();
			}, function():void{
				// error
				Config.application.fatalError(Lang.t("ERROR_LOADING_ASSETS"));
			}, function(value:Number):void{
				// progress
				Config.application.showSlash(value * 0.5);
			});
		}
		
		private var addedXmlNames:Array = [];
		private function loadXML():void
		{
			var paths:Object = {
					"LevelPack":Config.loader.getFilePath("LevelPack")
					,"Description":Config.loader.getFilePath("Description")
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
				recreateLevel();
			}, function():void{
				// on error
				Config.application.fatalError(Lang.t("ERROR_LOADING_XMLS"));
			},function(value:Number):void{
				// on progress
				Config.application.showSlash(0.5 + value * 0.5);
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
		
		
		
		private function recreateLevel():void
		{
			InitializeManager.restartLevel();
			
			onLevelStartedCallback && onLevelStartedCallback();
			Config.application.dispatchPropertyChange("levelChanged");
		}
		
		
		
		public function start():void
		{
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

		public function setTemplateTool(template:XML):IEventDispatcher
		{
			CONFIG::debug
			{
				pause();
				return EditorModule.instance.setTemplateTool(template);
			}
			return null;
		}
		
		override public function get width():Number{return Config.WIDTH;}
		override public function get height():Number{return Config.HEIGHT;}
	}
}