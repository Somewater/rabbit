package com.somewater.rabbit.util {
	import com.somewater.rabbit.storage.Config;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.setTimeout;

	public class AnimationHelper {

		private static var _instance:AnimationHelper;

		private const TICK_RATE_SEC:Number = 0.3;

		private var blinkQueue:Array = [];
		private var blinkObjectToStopAt:Dictionary = new Dictionary(true);

		public static function get instance():AnimationHelper
		{
			if(_instance == null)
			 	_instance = new AnimationHelper();
			return _instance;
		}

		private var tickTimer:Timer;


		/**
		 * Заставить объект мигать
		 * @param delay отсрочка мигания, сек
		 */
		public function blink(targer:DisplayObject, delay:Number = 0, stopAt:Number = 1000):void
		{
			if(delay > 0)
			{
				setTimeout(blink, delay * 1000, targer, 0, stopAt);
			}
			else if(targer.parent != null && blinkQueue.indexOf(targer) == -1)
			{
				blinkQueue.push(targer);
				blinkObjectToStopAt[targer] = stopAt;
				start();
			}
		}

		private function start():void
		{
			if(tickTimer == null)
			{
				tickTimer = new Timer(TICK_RATE_SEC * 1000);
				tickTimer.addEventListener(TimerEvent.TIMER, onTimer);
				tickTimer.start();
			}
		}

		private function stop():void
		{
			if(tickTimer)
			{
				tickTimer.removeEventListener(TimerEvent.TIMER, onTimer);
				tickTimer.stop();
				tickTimer = null
			}
		}

		private function onTimer(event:TimerEvent):void {
			var i:int;
			while(i < blinkQueue.length)
			{
				var targer:DisplayObject = blinkQueue[i];
				blinkObjectToStopAt[targer] -= TICK_RATE_SEC;
				if(targer.parent == null || blinkObjectToStopAt[targer] < 0)
				{
					blinkQueue.splice(i, 1);
					delete blinkObjectToStopAt[targer];
					targer.alpha = 1;
				}
				else
				{
					targer.alpha = targer.alpha == 1 ? 0.2 : 1;
					i++;
				}
			}

			if(blinkQueue.length == 0)
				stop();
		}
	}
}
