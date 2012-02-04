package com.somewater.rabbit.application.tutorial {
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.MainMenuPage;
	import com.somewater.rabbit.application.windows.LevelStartWindow;
	import com.somewater.rabbit.managers.IGameTutorialModule;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.UserProfile;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.clearInterval;

	/**
	 *
	 * Объяснить в тьюториале:
	 * 	1) как начать игру
	 * 		"Привет, я кроль" [Продолжить]
	 * 		"Щелкни на кнопку START_GAME/CONTINUE_GAME"
	 * 	2) как двигать кролика
	 * 		"Используй кнопки-стрелки _L чтобы управлять кроликом"  (триггер на то, что кролик сдвинулся с мертвой точки)
	 * 	3) научить собирать морковки
	 * 		"Подведи кролика к морковкам, чтобы их собрать" (триггер на сбор 3-х морковок)
	 * 	4) рассказать про иникатор морковок
	 * 		"Индикатор морковок показывает, сколько морковок еще не собрано" (подсказака на 2 секунды)
	 * 	5) ежей надо обходить
	 *		"Не наступай на ежей, они могут уколоть!"  (триггер на укол ежиком или на 2 секунды)
	 *  5.1) - после укола ежом
	 *  	"Это индикатор моей жизни" (выделить индикатор на 2 секунды)
	 *  6) индикатор времени
	 *  	"Это счетчик времени. если время закончится, я уже не смогу собрать все морковки" (на 2 секунды)
	 * 	7) как включить/выключить паузу
	 * 		"Нажми на паузу, если хочешь приостановить игру" (триггер на нажатие)
	 * 		"Нажми крестик на окне или кнопку 'Пробел' на клавиатуре, чтобы продолжить игру" (триггер на выход из режима паузы)
	 * 	8) как двигать кролика по диагонали
	 * 		"Нажимай по две кнопки одновременно, чтобы двигаться по диагонали"
	 *  9) после прохождения 1-го левела открыть главное меню, а не следующий левел, как посмотреть на свои награды  морковок
	 *  	"Поздравляю, мы прошли первый уровень и получили награду!"
	 * 		"Нажми на кнопку 'Награды', чтобы полюбоваться своими достижениями"
	 * 		"На полянке, около норы кролика, выставлены все награды, полученные в игре"
	 * 		"Нажми на стрелку, чтобы вернуться в главное меню"
	 * 10) как увидеть уровни
	 * 		"Нажми на кнопку LEVEL_SELECTION, чтобы увидеть уровни игры"
	 * 		"Все уровни разбиты на отдельные истории. Пройди уровни первой истории и получи доступ к уровням следующей" (2 секунды)
	 * 		"Нажми на стрелку, чтобы вернуться в главное меню"
	 * 11) если сеть поддерживает friendsApi: как зайти к другу (добавлять фейкового друга, пока не рпойден тьюториал и у человека нет собственных друзей)
	 * 		"Нажми на портрет друга, чтобы посмотреть на его полянку с наградами"
	 * 		"Каждый день заходя к другу, ты можешь собрать 1 морковку"
	 * 		"Нажми на стрелку, чтобы вернуться в главное меню"
	 * ////            ////12) посмотреть на топ
	 * ////	 ИСКЛЮЧЕН  ////	"нажми кнопку ТОП, чтобы посмотреть на самых успешных кроликов"
	 * ////	           ////	"нажми стрелку, чтобы вернуться в главное меню"
	 * 13) заключительное слово
	 * 		"Поздравляю, теперь ты умный кролик и самостоятельно можешь собирать морковку"
	 */
	public class TutorialManager implements IClear{

		public static const TIME_WAITING:int = 8000;

		public static const LEVEL_LAST_STEP:int = 7;// 7й шаг тьюториала (считая по массиву STEPS) все еще относится к 1му левелу

		private static var _instance:TutorialManager;

		private var age:int = 0;
		private var cleared:Boolean = false;
		private const YOUNG_AGE:int = 1;// первые 2 секнуды тьюториал не стартует, он "ждет"
		internal var STEPS:Array = [
										 TutorialStep1
										,TutorialStep2
										,TutorialStep3
										,TutorialStep4
										,TutorialStep5
										,TutorialStep6
										,TutorialStep7
										,TutorialStep8
										,TutorialStep9
										,TutorialStep10
										,TutorialStep11
										,TutorialStep12
										,TutorialStep13
									 ];

		private var tickTimer:Timer;
		private var arrowRepositTimer:Timer;

		private var currentStep:TutorialStepBase;
		private var highlightedObjects:Array = [];
		internal var messages:Array = [];
		private var highlightedToArrow:Dictionary = new Dictionary();

		internal var tickedClouds:Array = [];

		/**
		 * Ссылка на окно, которое было октрыто на момент старта последнего месседжа
		 */
		private var onMessageShowedActiveWindow:Class;
		private var onObjectHighlightedActiveWindow:Class;

		public function TutorialManager() {
			tickTimer = new Timer(300);
			tickTimer.addEventListener(TimerEvent.TIMER, onTick);
			tickTimer.start();

			arrowRepositTimer = new Timer(200);
			arrowRepositTimer.addEventListener(TimerEvent.TIMER, refrestarrowPosition);
			arrowRepositTimer.start();

			// при старте менеджера, проверить, как обстоят дела с friends api и удалить шаг посещения друга, если надо
			if(!Config.loader.hasFriendsApi)
			{
				if(STEPS.indexOf(TutorialStep11) != -1)
					STEPS.splice(STEPS.indexOf(TutorialStep11), 1);
			}
		}

		public static function get instance():TutorialManager
		{
			if(_instance == null)
				_instance = new TutorialManager();
			return _instance;
		}


		/**
		 * Стартовать указанные шаг
		 * @param step
		 */
		public function startStep(step:int):void {
			if(age < YOUNG_AGE || cleared) return;

			if(currentStep == null || step > currentStep.index)
			{
				if(currentStep)
					currentStep.clear();
				clearAllStuff();
				currentStep = null;
				var cl:Class = STEPS[step];
				if(cl)
				{
					currentStep = new cl();
					currentStep.execute();

					AppServerHandler.instance.incrementTutorial(currentStep.index);
				}
				else
				{
					// нет шага с таким номером, тьюториал выполнен
					clear();
				}
			}
			else if(step < currentStep.index)
				trace('Tutorial step is ' + currentStep.index + ', cannot assign ' + step);
		}

		/**
		 * Протикать текущий шаг тьюториала, если текущий не выбран, выстаивть его
		 * Проверить текущий шаг на завершение
		 * @param event
		 */
		private function onTick(event:TimerEvent):void {
			age++;
			if(age < YOUNG_AGE || cleared) return;

			if(currentStep == null && UserProfile.instance.tutorial >= 0)
				startStep(UserProfile.instance.tutorial);

			if(currentStep)
			{
				// HOOK: если юзер уже прошел 2-й уровень, то не показываем ему полянку наград и страницу левелов
				if(currentStep.index <= STEPS.indexOf(TutorialStep10) && UserProfile.instance.levelNumber > 2)
				{
					TutorialManager.instance.startStep(STEPS.indexOf(TutorialStep10) + 1);
					return;
				}

				// HOOK: если юзер прошел 1-й левел, автоматом отметить ему прохождение шагов тьюториала вплоть до 8-го
				if(currentStep.index <= STEPS.indexOf(TutorialStep8) && UserProfile.instance.levelNumber > 1)
				{
					TutorialManager.instance.startStep(STEPS.indexOf(TutorialStep8) + 1);
					return;
				}

				currentStep.tick();

				if(currentStep.completed())
				{
					UserProfile.instance.tutorial = currentStep.index + 1;
				}
			}
		}

		public function stepIndex():int
		{
			return currentStep ? currentStep.index : -1;
		}

		public function clear():void {
			cleared = true;
			tickTimer.removeEventListener(TimerEvent.TIMER, onTick);
			tickTimer.stop();
			tickTimer = null;

			arrowRepositTimer.removeEventListener(TimerEvent.TIMER, refrestarrowPosition);
			if(arrowRepositTimer.running)
				arrowRepositTimer.stop();
			arrowRepositTimer = null;
		}

		/**
		 * Показать кролика среди простого GUI (не в игре и не на поляне наград)
		 * @param msg
		 * @param x координата сидения кролика (совпадает с нижней точкой центра его живота, см. ассет)
		 * @param y
		 * @param onAccept если парамтер задан, около обачка есть кнопка "Далее", по нажатию на которую вызывается колбэк onAccept()
		 * @param toLeft развернуть кролика чтобы он смотрел направо и облачко было слева от него
		 */
		internal function guiMessage(msg:String, x:int,  y:int, onAccept:Function = null, image:* = null, toLeft:Boolean = false):void
		{
			clearMessages();

			msg = Config.application.translate(msg);
			var cloud:GuiCloud = new GuiCloud(msg, x, y, onAccept, image, toLeft);
			messages.push(cloud);

			onMessageShowedActiveWindow = this.activePageOrWindow();
		}

		/**
		 * Сообщение, идущее от кролика в игре
		 * @param msg
		 * @param onAccept если задано, появляется кнопка "Далее"
		 */
		internal function gameMessage(msg:String, onAccept:Function = null, image:* = null):void
		{
			clearMessages();

			msg = Config.application.translate(msg);
			var cloud:GameCloud = new GameCloud(msg, onAccept, image);
			messages.push(cloud);
			tickedClouds.push(cloud);
			cloud.tick();// отпозиционируем сразу

			onMessageShowedActiveWindow = this.activePageOrWindow();
		}

		internal function highlightGui(gui:DisplayObject, on:Boolean = true):void
		{
			var arrow:HighlightArrow

			if(on)
			{
				if(highlightedObjects.indexOf(gui) == -1)
				{
					clearHighlights();

					gui.filters = [new GlowFilter(0xF57800, 1, 5, 5, 10)];
					arrow = new HighlightArrow();
					if(gui.localToGlobal(new Point()).y < 60)
						arrow.rotation = 180;
					Config.loader.tutorial.addChild(arrow);
					highlightedToArrow[gui] = arrow;
					positionArrow(arrow, gui);
					highlightedObjects.push(gui);

					onObjectHighlightedActiveWindow = this.activePageOrWindow();
				}
			}
			else
			{
				if(highlightedObjects.indexOf(gui) != -1)
				{
					gui.filters = [];
					arrow = highlightedToArrow[gui];
					arrow.clear();
					delete(highlightedToArrow[gui]);
					highlightedObjects.splice(highlightedObjects.indexOf(gui), 1);
				}
			}
		}

		public function clearHighlights():void
		{
			while(highlightedObjects.length)
				highlightGui(highlightedObjects[0], false);
			onObjectHighlightedActiveWindow = null;
		}

		public function clearMessages():void
		{
			while(messages.length)
			{
				var msg:ITutorialMessage = messages[0];
				msg.clear();

				// если сообщение само себя не удалила из массива, делаем это сами
				if(messages.indexOf(msg) != -1)
					messages.splice(messages.indexOf(msg), 1);
			}
			onMessageShowedActiveWindow = null;
		}

		public function clearAllStuff():void
		{
			clearHighlights();
			clearMessages();
		}

		public function getGui(root:DisplayObjectContainer, path:String):*
		{
			var result:DisplayObject = root;
			var pathArr:Array = path.split('.');
			while(pathArr.length)
			{
				var name:String = pathArr.shift();
				if(root.getChildByName(name))
					result = root.getChildByName(name);
				else if(Object(root).hasOwnProperty(name))
					result = Object(root)[name];

				if(result is DisplayObjectContainer)
					root = result as DisplayObjectContainer;
			}
			return result;
		}

		private function refrestarrowPosition(event:TimerEvent = null):void {

			var activePageOrWindow:DisplayObject = this.activePageOrWindow(false);
			var messageMustVisible:Boolean = onMessageShowedActiveWindow == null || Boolean(activePageOrWindow is onMessageShowedActiveWindow);
			var highlightMustVisible:Boolean = onObjectHighlightedActiveWindow == null || Boolean(activePageOrWindow is onObjectHighlightedActiveWindow);

			for(var target:* in highlightedToArrow)
			{
				positionArrow(highlightedToArrow[target], target);
				DisplayObject(highlightedToArrow[target]).visible = highlightMustVisible;
			}

			for each(var gcloud:GameCloud in tickedClouds)
			{
				gcloud.tick();
			}

			for each(var msg:DisplayObject in messages)
			{
				msg.visible = messageMustVisible;
			}
		}

		private var tmpArrowPoint:Point = new Point();
		private function positionArrow(arrow:HighlightArrow, target:DisplayObject):void
		{
			tmpArrowPoint.x = target.width * 0.5;
			tmpArrowPoint.y = target.height * 0.5;
			tmpArrowPoint = target.localToGlobal(tmpArrowPoint);

			tmpArrowPoint = arrow.parent.globalToLocal(tmpArrowPoint);

			arrow.x = tmpArrowPoint.x;
			arrow.y = tmpArrowPoint.y;
		}

		//////////////////////////////
		//                          //
		//			utilitis		//
		//                          //
		//////////////////////////////
		private static var _modile:IGameTutorialModule;
		public static function get modile():IGameTutorialModule
		{
			if(_modile == null)
				_modile = Config.game.tutorialModule;
			return _modile;
		}

		public function get mainMenuPage():MainMenuPage
		{
			return (Config.application as RabbitApplication).currentPage as MainMenuPage
		}

		public function get levelsPage():LevelsPage
		{
			return (Config.application as RabbitApplication).currentPage as LevelsPage
		}

		/**
		 * LevelStartWindow был закрыт
		 */
		public function get levelStartWindowClosed():Boolean
		{
			return (Config.application as RabbitApplication).gameStartedCompletely &&
					(PopUpManager.activeWindow == null || !(PopUpManager.activeWindow is LevelStartWindow));
		}

		/**
		 * Для того чтобы удобно делать решения относительно видимости/невидимости стрелок и мессаджей
		 */
		private function activePageOrWindow(clazz:Boolean = true):*
		{
			var target:DisplayObject = PopUpManager.activeWindow;
			if(target == null)
				target = (Config.application as RabbitApplication).currentPage;
			if(clazz)
				return target ? Object(target).constructor : null;
			else
				return target
		}

		public function get active():Boolean {
			return currentStep != null || UserProfile.instance.tutorial <= STEPS.length;
		}
	}
}
