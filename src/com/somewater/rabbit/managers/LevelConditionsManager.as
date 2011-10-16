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
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.ui.HorizontRender;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.storage.Lang;
	
	import flash.utils.getTimer;

	/**
	 * В каждом тике проверяет, не были ли выполнены условия прохождения уровня (либо, условия провала уровня)
	 * Если да, менеджер завершает уровень и выдает сообщение
	 *
	 * Известные conditions:
	 * <conditions>
	 *     <!-- ВРЕМЯ -->
	 *     <time>2</time> # макс. время на раунд
	 *     <fastTime>0.5</fastTime> # [OPTIONALLY] это время считать быстрым
	 *
	 *     <!-- МОРКОВКА -->
	 *     <carrotMin>15</carrotMin> # минимальное число морковок  (alias <carrot>)
	 *     <carrotMiddle>15</carrotMiddle> # число морковок на 2 звезды
	 *     <carrotMax>15</carrotMax> # [OPTIONALLY, calculated]число морковок на 3 звезды (если не задано - макс. число морковок на уровне)
	 * </conditions>
	 */
	public class LevelConditionsManager extends PBObject implements ITickedObject
	{
		public var instance:LevelConditionsManager;
		
		private var startLevelTime:uint;
		private var currentTime:uint;
		
		private var conditionsRef:Array;
		private var completeConditions:Array;// с ним снавнивается локальная переменная conditions
		
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

			if(conditionsRef["carrotMax"] == null)
				conditionsRef["carrotMax"] = XmlController.instance.calculateCarrots(Config.game.level);
			if(conditionsRef['carrotMiddle'] == null)
				conditionsRef['carrotMiddle'] = conditionsRef['carrotMax'] - 1;
			if(conditionsRef['carrotMin'] == null)
				conditionsRef['carrotMin'] = conditionsRef['carrot'] ? conditionsRef['carrot'] : conditionsRef['carrotMiddle'] - 1;
			
			conditionsRef["time"] *= 1000;// расчеты в мс
			if(conditionsRef['fastTime'])
				conditionsRef["fastTime"] *= 1000;// расчеты в мс

			_levelFinished = false;
			rabbitInited = false;

			// что может являться причиной успешного завершения уровня
			completeConditions = [];
			completeConditions["time"] = true; // в том смысле, что НЕ(время закончилось)
			completeConditions["carrotMax"] = true;
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
					finishLevel(false, LevelInstanceDef.LEVEL_FATAL_LIFE);
				}
					
				//////////////////////////
				//		C A R R O T		//
				//////////////////////////
				if(heroDataRef && conditionsRef["carrotMax"])
				{
					// игрок собрал сколько нужно
					if(heroDataRef.carrot >= conditionsRef["carrotMax"])
					{
						completed["carrotMax"] = true;// по морковкам уровень пройден
					}
					else
					{
						// игрок уже не в состоянии собрать сколько нужно
						var harvestSet:PBSet = PBE.nameManager.lookup("harvest");
						if(harvestSet && conditionsRef["carrotMax"] - heroDataRef.carrot > harvestSet.length)
						{
							finishLevel(false, LevelInstanceDef.LEVEL_FATAL_CARROT);
						}
					}
				}
			}

			//////////////////////////
			//		T I M E			//
			//////////////////////////
			if(time > conditionsRef["time"])
			{
				finishLevel(false, LevelInstanceDef.LEVEL_FATAL_TIME);
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
				for(var conditionName:String in completeConditions)
					if(completed[conditionName] == null || completed[conditionName] == false)
					{
						levelCompletedSuccesfully = false;
						break;
					}
				
				if(levelCompletedSuccesfully)
				{
					finishLevel(true, LevelInstanceDef.LEVEL_SUCCESS_FINISH);
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

			if(timeLeft <= 10000)
			{
				if(!horizontRef)
				{
					horizontRef = PBE.lookupComponentByName("Horizont", "Render") as HorizontRender;
				}

				if(horizontRef)
					horizontRef.darkness = (10000 - timeLeft) / 10000;
			}
		}
		
		
		/**
		 * Число миллисекунд с момента старта игры
		 */
		public function get time():int
		{
			return currentTime - startLevelTime;
		}
		
		private var _levelFinished:Boolean;// флаг, означающий, что формально уровень закончен (и вызовы ф-ции finishLevel излишни и игнорятся)
		private function finishLevel(success:Boolean, flag:String):void
		{
			if(_levelFinished) return;
			_levelFinished = true;

			var event:LevelInstanceDef = new LevelInstanceDef(Config.game.level)
			event.finalFlag = flag;
			event.success = success;
			event.aliensPassed = (success ? XmlController.instance.calculateAliens(event.levelDef) : 0);
			event.carrotHarvested = HeroDataComponent.instance ? HeroDataComponent.instance.carrot : 0;
			event.timeSpended = time;
			event.stars = (event.carrotHarvested >= conditionsRef['carrotMax'] ? 3
								: (event.carrotHarvested >= conditionsRef['carrotMiddle'] ? 2
								: (event.carrotHarvested >= conditionsRef['carrotMin'] ? 1 : 0) ))

			// вычисляем и выдаем бонусы
			if(conditionsRef['fastTime'] && conditionsRef['fastTime'] <= event.timeSpended)
				event.bonuses.push(LevelInstanceDef.BONUS_FAST_TIME);
			if(event.aliensPassed)
				event.bonuses.push(LevelInstanceDef.BONUS_ALIENS_PASSED);

			PBE.processManager.schedule(2000, this, function():void{
				Config.application.levelFinishMessage(event);
				Config.application.addFinishedLevel(event);
				if(event.success)
				{
					// если левел пройден успешно, открываем следующий, а не страницу левелов
					Config.game.finishLevel(event, true);
					Config.application.startGame();
				}
				else
				{
					Config.game.finishLevel(event);
				}
			});
		}
	}
}