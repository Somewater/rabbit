package com.somewater.rabbit.managers
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.LevelEvent;
	import com.pblabs.engine.core.LevelManager;
	import com.pblabs.engine.core.NameManager;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.core.PBSet;
	import com.somewater.rabbit.application.tutorial.TutorialLevelDef;
	import com.somewater.rabbit.components.HeroDataComponent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
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
		public static var instance:LevelConditionsManager;
		
		private var startLevelTime:uint;
		private var currentTime:uint;
		
		private var conditionsRef:Array;
		private var completeConditions:Array;// с ним снавнивается локальная переменная conditions
		
		private var rabbitInited:Boolean;// кролик этого уровня хоть раз существовал
		
		private var horizontRef:HorizontRender;

		private var gameGuiRef:Object;

		/**
		 * Запоминает использованные в процессе прохождения уровня покупные паверапы
		 */
		public var powerupTemplateNameToQuantity:Array = [];
		
		
		public function LevelConditionsManager()
		{
			instance = this;
			
			initialize("LevelConditionsManager");
			
			PBE.processManager.addTickedObject(this);
			
			InitializeManager.bindRestartLevel(onLevelRestart);
		}
		
		
		
		private function onLevelRestart():void
		{
			gameGuiRef = null;
			horizontRef = null;

			startLevelTime = PBE.processManager.virtualTime;
			conditionsRef = [];
			var levelRef:LevelDef = Config.game.level;

			var normalLevelMode:Boolean = levelRef.type == LevelDef.TYPE || levelRef.type == TutorialLevelDef.TYPE

			_levelFinished = !normalLevelMode;// для всех "необычных" уровней, блочим логику менеджера

			if(!normalLevelMode)
				return;

			for (var key:String in levelRef.conditions)
				conditionsRef[key] = levelRef.conditions[key];
			if(conditionsRef["time"] == null)
				conditionsRef["time"] = 60;

			conditionsRef["carrotMax"] = XmlController.instance.calculateMaxCarrots(levelRef);
			conditionsRef['carrotMiddle'] = XmlController.instance.calculateMiddleCarrots(levelRef);
			conditionsRef['carrotMin'] = XmlController.instance.calculateMinCarrots(levelRef);

			rabbitInited = false;
			
			conditionsRef["time"] *= 1000;// расчеты в мс
			if(conditionsRef['fastTime'])
				conditionsRef["fastTime"] *= 1000;// расчеты в мс

			// что может являться причиной успешного завершения уровня
			completeConditions = [];
			completeConditions["time"] = true; // в том смысле, что НЕ(время закончилось)
			completeConditions["carrotMax"] = true;

			powerupTemplateNameToQuantity = [];
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
						var harvestSet:PBSet = PBE.nameManager.lookup("harvest");
						if(harvestSet)
						{
							// на уровне болше нет морковок
							if(harvestSet.length == 0)
							{
								finishForTimeOrCarrot();
							}
							// игрок уже не в состоянии собрать сколько нужно
							else if(conditionsRef["carrotMin"] - heroDataRef.carrot > harvestSet.length)
							{
								finishLevel(false, LevelInstanceDef.LEVEL_FATAL_CARROT);
							}
						}
					}
				}
			}

			//////////////////////////
			//		T I M E			//
			//////////////////////////
			if(time > conditionsRef["time"])
			{
				finishForTimeOrCarrot();
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
					if(Config.application.canCompleteLevel()){
						finishLevel(true, LevelInstanceDef.LEVEL_SUCCESS_FINISH);
					}
				}
			}
			
			
			//////////////////////////////////////////
			//										//
			//		U P D A T E    G U I			//
			//										//
			//////////////////////////////////////////
			if(gameGuiRef == null)
			{
				gameGuiRef = Config.application.gameGUI;// ссылка на gui из application
				if(gameGuiRef.hasOwnProperty('rightGameGUI'))
				{
					gameGuiRef.timeEnd = conditionsRef["time"] * 0.001;
					gameGuiRef.carrotMax = conditionsRef["carrotMax"];
					gameGuiRef.carrotMiddle = conditionsRef["carrotMiddle"];
					gameGuiRef.carrotMin = conditionsRef["carrotMin"];
					gameGuiRef.carrot = heroDataRef?heroDataRef.carrot:0;
					gameGuiRef.init();
				}
				else
					gameGuiRef = null;
			}
			else
			{
				gameGuiRef.life = heroDataRef?heroDataRef.health:0;
				gameGuiRef.time = time * 0.001;
				gameGuiRef.carrot = heroDataRef?heroDataRef.carrot:0;
				gameGuiRef.update(heroDataRef == null, heroDataRef ? heroDataRef.protectedFlag > 0 : false);
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
		 * Закончить уровень по вышедшему времени или морковкам (причем игрок может как выиграть так и проиграть
		 * в зависимости от того сколько он собрал морковок)
		 */
		private function finishForTimeOrCarrot():void
		{
			if(HeroDataComponent.instance && HeroDataComponent.instance.carrot >= conditionsRef['carrotMin'])
				finishLevel(true, LevelInstanceDef.LEVEL_SUCCESS_FINISH);
			else
				finishLevel(false, LevelInstanceDef.LEVEL_FATAL_TIME);
			if(gameGuiRef)
				gameGuiRef.update(true, false);
		}

		public function clear():void
		{
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
			event.currentCarrotHarvested = event.carrotHarvested = HeroDataComponent.instance ? HeroDataComponent.instance.carrot : HeroDataComponent.lastCarrotValue;
			event.currentTimeSpended = event.timeSpended = Math.max(time, 1000);
			event.currentStars = event.stars = (event.carrotHarvested >= conditionsRef['carrotMax'] ? 3
								: (event.carrotHarvested >= conditionsRef['carrotMiddle'] ? 2
								: (event.carrotHarvested >= conditionsRef['carrotMin'] ? 1 : 0) ))

			if(event.success && HeroDataComponent.instance)
				HeroDataComponent.instance.protectedFlag = 10;

			Config.application.preFinishedLevel(event);
			PBE.processManager.schedule(flag == LevelInstanceDef.LEVEL_FATAL_TIME ? 0 : 1000, this, function():void{

				event.spendedPowerups = powerupTemplateNameToQuantity;

				// специально для случаев, когда во время delay игрок еще подсобрал морковок более, чем carrotMax (причем время еще не кончилось)
				if(time <= conditionsRef["time"] && event.stars == 3 && HeroDataComponent.instance)
					event.currentCarrotHarvested = event.carrotHarvested =  HeroDataComponent.instance.carrot;

				clear();

				Config.application.addFinishedLevel(event);
				Config.game.finishLevel(event);
			});
		}

		/**
		 * Уменишить время, прошедшее с момента старта уровня, на заданную величину
		 * @param seconds
		 */
		public function decrementSpendedTime(milliseconds:Number):void
		{
			startLevelTime = Math.min(currentTime, startLevelTime + milliseconds);
		}
	}
}