package com.somewater.rabbit.managers
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.LevelEvent;
	import com.pblabs.engine.core.LevelManager;
	import com.pblabs.engine.core.NameManager;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.core.PBSet;
	import com.somewater.rabbit.components.HeroDataComponent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.ui.HorizontRender;
	import com.somewater.storage.Lang;
	
	import flash.utils.getTimer;

	/**
	 * В каждом тике проверяет, не были ли выполнены условия прохождения уровня (либо, условия провала уровня)
	 * Если да, менеджер завершает уровень и выдает сообщение
	 */
	public class LevelConditionsManager extends PBObject implements ITickedObject
	{
		public var instance:LevelConditionsManager;
		
		private var startLevelTime:uint;
		private var currentTime:uint;
		
		private var conditionsRef:Array;
		
		private var rabbitInited:Boolean;// кролик этого уровня хоть раз существовал
		
		private var horizontRef:HorizontRender;
		
		
		public function LevelConditionsManager()
		{
			if(instance)
				throw new Error("Singletone");
			
			instance = this;
			
			initialize("LevelConditionsManager");
			
			PBE.processManager.addTickedObject(this);
			
			InitializeManager.bindRestartLevel(onLevelRestart);
		}
		
		
		
		private function onLevelRestart():void
		{
			startLevelTime = PBE.processManager.virtualTime;
			conditionsRef = [];
			for (var key:String in Config.game.level.conditions)
				conditionsRef[key] = Config.game.level.conditions[key];
			if(conditionsRef["time"] == null)
				conditionsRef["time"] = 60;
			
			conditionsRef["time"] *= 1000;// расчеты в мс
			_levelFinished = false;
			rabbitInited = false;
		}
			
		
		
		public function onTick(deltaTime:Number):void
		{
			var time:int = this.time;
			var timeLeft:int = conditionsRef["time"] - time;
			
			currentTime = PBE.processManager.virtualTime;
			if(_levelFinished) return;
			
			// проверять условия на выполнения уровня
			// Если условия были выполнены, либо обнаружено, что условие уже никогда не будет выполнено
			// проставить в Config.game.level нужную "рецензию" и завершить игру (вызвать) game.finishLevel
			
			var heroDataRef:HeroDataComponent = HeroDataComponent.instance;
			var completed:Array = [];// записываем идентификаторы выполненных условий
			
			if(heroDataRef || rabbitInited)
			{
				rabbitInited = true;
				//////////////////////////
				//		L  I  F  E		//
				//////////////////////////
				if(heroDataRef == null || heroDataRef.health <= 0)
				{
					finishLevel(false, Lang.t("LEVEL_FATAL_LIFE"));
				}
					
				//////////////////////////
				//		C A R R O T		//
				//////////////////////////
				if(heroDataRef && conditionsRef["carrot"])
				{
					// игрок собрал сколько нужно
					if(heroDataRef.carrot >= conditionsRef["carrot"])
					{
						completed["carrot"] = true;
					}
					
					// игрок уже не в состоянии собрать сколько нужно
					var harvestSet:PBSet = PBE.nameManager.lookup("harvest");
					if(harvestSet && conditionsRef["carrot"] - heroDataRef.carrot > harvestSet.length)
					{
						finishLevel(false, Lang.t("LEVEL_FATAL_CARROT"));
					}
					
					
				}
			}
			
			if(time > conditionsRef["time"])
			{
				finishLevel(false, Lang.t("LEVEL_FAIL_TIME"));
			}
			else
				completed["time"] = true;// по времени уровень заврешен (от противного - НЕ(уравень проигран из-за окончания времени) )
			
			
			///////////////////////////////////////////
			//										 //
			//		C H E C K		S U C C E S S	 //
			//										 //
			///////////////////////////////////////////
			if(!_levelFinished)
			{
				var levelCompletedSuccesfully:Boolean = true;
				for(var conditionName:String in conditionsRef)
					if(completed[conditionName] == null)
					{
						levelCompletedSuccesfully = false;
						break;
					}
				
				if(levelCompletedSuccesfully)
				{
					finishLevel(true, Lang.t("LEVEL_SUCCESS_FINISH"));
				}
			}
			
			
			//////////////////////////////////////////
			//										//
			//		U P D A T E    G U I			//
			//										//
			//////////////////////////////////////////
			var gameGUI:Object = Config.memory["GameGUI"];// ссылка на gui из application
			if(gameGUI)
			{
				gameGUI._timeEnd = conditionsRef["time"] * 0.001;
				gameGUI.life = heroDataRef?heroDataRef.health:0;
				gameGUI.time = time * 0.001;
				gameGUI.carrot = heroDataRef?heroDataRef.carrot:0;
			}
			
			if(!horizontRef)
			{
				horizontRef = PBE.lookupComponentByName("Horizont", "Render") as HorizontRender;
			}
			
			if(horizontRef)
				horizontRef.darkness = timeLeft > 10000 ? 0 : (10000 - timeLeft) / 10000;
		}
		
		
		/**
		 * Число миллисекунд с момента старта игры
		 */
		public function get time():int
		{
			return currentTime - startLevelTime;
		}
		
		private var _levelFinished:Boolean;// флаг, означающий, что формально уровень закончен (и вызовы ф-ции finishLevel излишни и игнорятся)
		private function finishLevel(success:Boolean, message:String):void
		{
			if(_levelFinished) return;
			_levelFinished = true;
			
			PBE.processManager.schedule(2000, this, function():void{
				Config.application.message(message);
				Config.game.finishLevel(success);
			});
		}
	}
}