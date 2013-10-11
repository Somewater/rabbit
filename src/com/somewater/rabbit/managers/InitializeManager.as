package com.somewater.rabbit.managers
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.debug.Logger;
	import com.pblabs.engine.debug.Profiler;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.SceneAlignment;
	import com.somewater.display.blitting.BlitManager;
	import com.somewater.display.blitting.PreparativeBlitManager;
	import com.somewater.rabbit.components.CowardComponent;
	import com.somewater.rabbit.components.HeelProtectorComponent;
	import com.somewater.rabbit.components.HeroHarvesterComponent;
	import com.somewater.rabbit.components.ObviousHarvesterComponent;
	import com.somewater.rabbit.components.ObviousHunterComponent;
	import com.somewater.rabbit.components.PowerupControllerComponent;
	import com.somewater.rabbit.components.PowerupDataComponent;
	import com.somewater.rabbit.components.PowerupPanelRendererComponent;
	import com.somewater.rabbit.components.ProxyIsoRenderer;
	import com.somewater.rabbit.creature.CrowHarvesterComponent;
	import com.somewater.rabbit.creature.HeroIsoMover;
	import com.somewater.rabbit.creature.MoneyRewardControllerComponent;
	import com.somewater.rabbit.creature.OfferControllerComponent;
  import com.somewater.rabbit.creature.OfferRendererComponent;
  import com.somewater.rabbit.creature.ShapeSpatialComponent;
	import com.somewater.rabbit.decor.BackgroundRenderer;
	import com.somewater.rabbit.decor.EffectRenderer;
	import com.somewater.rabbit.decor.GroundGrassRenderer;
	import com.somewater.rabbit.decor.PopupEffectRenderer;
	import com.somewater.rabbit.events.ExceptionEvent;
	import com.somewater.rabbit.iso.scene.IsoLayer;
	import com.somewater.rabbit.rewards.RabbitHoleRenderer;
	import com.somewater.rabbit.components.AttackComponent;
	import com.somewater.rabbit.components.ConcealComponent;
	import com.somewater.rabbit.components.DataComponent;
	import com.somewater.rabbit.components.GenocideComponent;
	import com.somewater.rabbit.components.HarvestableComponent;
	import com.somewater.rabbit.components.HarvesterComponent;
	import com.somewater.rabbit.components.HelixComponent;
	import com.somewater.rabbit.components.HeroDataComponent;
	import com.somewater.rabbit.components.HunterComponent;
	import com.somewater.rabbit.components.InputComponent;
	import com.somewater.rabbit.components.LeadRendererComponent;
	import com.somewater.rabbit.components.RandomActComponent;
	import com.somewater.rabbit.components.RandomMovingComponent;
	import com.somewater.rabbit.components.RandomThinkingMovingComponent;
	import com.somewater.rabbit.components.SwitchableAttackComponent;
	import com.somewater.rabbit.components.WalkComponent;
	import com.somewater.rabbit.creature.BeamRendererComponent;
	import com.somewater.rabbit.creature.BeamSpatialComponent;
	import com.somewater.rabbit.creature.CarrotAngryComponent;
	import com.somewater.rabbit.creature.CarrotAttackComponent;
	import com.somewater.rabbit.debug.ConsoleUtils;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.iso.scene.SceneView;
	import com.somewater.rabbit.logic.LogicComponent;
	import com.somewater.rabbit.logic.SentientComponent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.ui.HorizontRender;
	import com.somewater.rabbit.ui.LevelHorizontRender;
	import com.somewater.rabbit.ui.RewardHorizontRender;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import nl.demonsters.debugger.MonsterDebugger;

	/**
	 * Менеджер, содержащий единственную функцию и запускаемый при старте приложения 
	 * (дабы вынести код из Rabbit.as)
	 */
	public class InitializeManager
	{
		
		private static var app:RabbitGame;
		
		private static var restartLevelCallbacks:Array;
		
		public static var lastLevelGroup:String;// название группы, которая была инициализирована при прошлом запуске
		private static var lastLevelManagers:String;// название группы менеджеров, которые были инициированы при запуске прошлого уровня
		
		
		/**
		 * Были ли инициализированы менеджеры и прочие классы, 
		 * которые надо проинитить 1 раз (при первом запуске игры)
		 */
		private static var levelManagersInited:Boolean = false;
		
		public function InitializeManager()
		{
			throw new Error("Static methods only");
		}
		
		
		public static function init(_app:RabbitGame):void
		{
			app = _app;
			
			restartLevelCallbacks = [];

			if(!BlitManager.instance)
				BlitManager.instance = _app.createBlitManager();
			
			Config.init();

			PBE.startup(app);
			
			RabbitGame.worldScene = new SceneView();
			RabbitGame.worldScene.width = Config.WIDTH;
			RabbitGame.worldScene.height = Config.HEIGHT;
			
			PBE.initializeScene(RabbitGame.worldScene, "SceneDB", null, IsoSpatialManager);
			PBE.scene.sceneAlignment = SceneAlignment.TOP_LEFT;

			app.uiLayer = new Sprite();
			app.addChild(app.uiLayer);
			
			app.popupLayer = new Sprite();
			app.addChild(app.popupLayer);
			
			app.hintLayer = new Sprite();
			app.addChild(app.hintLayer);
			
			initiateComponents();
			
			// отключаем видимость сцены до лучших времен
			switchPBE(false);

			PBE.levelManager.addEventListener(ExceptionEvent.TICK_EXCEPTION, app.onSomeException);
			
			app.dispatchEvent(new Event("applicationComplete"));
			
			CONFIG::debug
			{
				ConsoleUtils.initCommands();
			}
		}
		
		
		
		private static function initiateComponents():void
		{
			PBE.registerType(IsoRenderer);
			PBE.registerType(IsoSpatial);
			PBE.registerType(InputComponent);
			PBE.registerType(IsoMover);
			PBE.registerType(LogicComponent);
			PBE.registerType(SentientComponent);
			PBE.registerType(DataComponent);
			PBE.registerType(HeroDataComponent);
			PBE.registerType(HarvesterComponent);
			PBE.registerType(GenocideComponent);
			PBE.registerType(HelixComponent);
			PBE.registerType(AttackComponent);
			PBE.registerType(HunterComponent);
			PBE.registerType(LeadRendererComponent);
			PBE.registerType(RandomActComponent);
			PBE.registerType(BeamSpatialComponent);
			PBE.registerType(BeamRendererComponent);
			PBE.registerType(WalkComponent);
			PBE.registerType(HorizontRender);
			PBE.registerType(ConcealComponent);
			PBE.registerType(RandomThinkingMovingComponent);
			PBE.registerType(RandomMovingComponent);
			PBE.registerType(CarrotAngryComponent);
			PBE.registerType(SwitchableAttackComponent);
			PBE.registerType(HarvestableComponent);
			PBE.registerType(CarrotAttackComponent);
			PBE.registerType(RewardHorizontRender);
			PBE.registerType(RabbitHoleRenderer);
			PBE.registerType(GroundGrassRenderer);
			PBE.registerType(BackgroundRenderer);
			PBE.registerType(PopupEffectRenderer);
			PBE.registerType(HeroHarvesterComponent);
			PBE.registerType(ShapeSpatialComponent);
			PBE.registerType(ObviousHunterComponent);
			PBE.registerType(ObviousHarvesterComponent);
			PBE.registerType(HeelProtectorComponent);
			PBE.registerType(CowardComponent);
			PBE.registerType(CrowHarvesterComponent);
			PBE.registerType(HeroIsoMover);
			PBE.registerType(PowerupControllerComponent);
			PBE.registerType(PowerupDataComponent);
			PBE.registerType(OfferControllerComponent);
			PBE.registerType(PowerupPanelRendererComponent);
			PBE.registerType(ProxyIsoRenderer);
			PBE.registerType(LevelHorizontRender);
			PBE.registerType(MoneyRewardControllerComponent);
            PBE.registerType(OfferRendererComponent);
			PBE.registerType(EffectRenderer);

			RandomizeUtil.initialize();				
		}
		
		/**
		 * Инициализировать все, что нужно для запуска уровня, и требует инициализации 1 раз
		 */
		private static function initLevel():void
		{
			PBE.templateManager.instantiateGroup("Managers");
			IsoCameraController.getInstance();

			new LevelConditionsManager();
		}
		
		/**
		 * Переустановить уровень
		 */
		public static function restartLevel():void
		{
			var level:LevelDef = app.level;
			
			clearLevel();
			
			IsoSpatialManager.instance.setSize(level.width, level.height);
			
			if(levelManagersInited == false)
				initLevel();
			
			switchPBE(true);
			RandomizeUtil.initializeSeed();
			
			Profiler.clear();

			PBE.processManager.optimizeModeCounter = 0;// прорисовать все кустики, инициализировать все цветочки

			instantiateLevel(app.level);
			
			var hero:IEntity = PBE.lookupEntity("Hero");
			if(hero)
			{
				var heroSpatial:IsoSpatial = hero.getProperty(new PropertyReference("@Spatial"));
				IsoCameraController.getInstance().trackObject = heroSpatial;
				if(heroSpatial){
					var heroCameraPos:Point = heroSpatial.tile.clone();
					heroCameraPos.x = Math.min(level.width - Config.T_WIDTH, Math.max(0, heroCameraPos.x - Config.T_WIDTH * 0.5));
					heroCameraPos.y = Math.min(level.height - Config.T_HEIGHT, Math.max(0, heroCameraPos.y - Config.T_HEIGHT * 0.5));
					IsoCameraController.getInstance().position = heroCameraPos;
				}
			}
			else
			{
				IsoCameraController.getInstance().position = new Point(int((level.width - Config.T_WIDTH)*0.5),
						int((level.height - Config.T_HEIGHT)*0.5));// создаем камеру и центрируем (если надо) игровое поле
				Logger.error(InitializeManager, "restartLevel", "Hero looking failed");
			}
			
			fireLevelRestart();
			
			
			if(levelManagersInited == false)
			{
				
			}
			
			levelManagersInited = true;

			PBE.processManager.optimizeModeCounter = 0;// прорисовать все кустики, инициализировать все цветочки
			IsoLayer.instance.tickForGlobalSorting = 1;
		}
		
		
		/**
		 * Вкл/выкл игровое поле (в т.ч. его видимость)
		 */
		private static function switchPBE(on:Boolean):void
		{
			RabbitGame.worldScene.visible = on;
			
			if(on)
				PBE.processManager.start();
			else
				PBE.processManager.stop();
		}
		
		
		/**
		 * Добавить слушателя на старт уровня
		 */
		public static function bindRestartLevel(callback:Function):void
		{
			if(restartLevelCallbacks.indexOf(callback) == -1)
				restartLevelCallbacks.push(callback);
		}
		
		
		/**
		 * Убрать слушателя на старт уровня
		 */
		public static function unbindRestartLevel(callback:Function):void
		{
			var idx:int = restartLevelCallbacks.indexOf(callback);
			if(idx != -1)
				restartLevelCallbacks.splice(idx, 1);
		}
		
		/**
		 * Диспатчить рестарт уровня всем заинтересованным слушателям
		 */
		private static function fireLevelRestart():void
		{
			var callbacks:Array = restartLevelCallbacks.slice();
			
			for(var i:int = 0;i<callbacks.length;i++)
			{
				callbacks[i]();
			}
		}
		
		
		/**
		 * 
		 */
		private static function instantiateLevel(level:LevelDef):void
		{
			lastLevelManagers = level.type+ "Managers";
			PBE.templateManager.instantiateGroup(lastLevelManagers);

			if(level.group is XML)
			{
				lastLevelGroup = level.groupName;
				var group:XML = XML(level.group).copy();
				
				if(PBE.templateManager.getXML(lastLevelGroup) == null)
					PBE.templateManager.addXML(group, lastLevelGroup, 0);
				
				PBE.templateManager.instantiateGroup(lastLevelGroup);
			}
			else
				throw new Error("Level #" + level.id + " instantiation error. Wrong type of group field");
		}

		public static function clearLevel():void {
			if(lastLevelGroup && PBE.nameManager.lookup(lastLevelGroup))
				PBGroup(PBE.nameManager.lookup(lastLevelGroup)).destroy();

			if(lastLevelManagers && PBE.nameManager.lookup(lastLevelManagers))
				PBGroup(PBE.nameManager.lookup(lastLevelManagers)).destroy();
		}
	}
}