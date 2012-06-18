package com.somewater.display.blitting {

	import flash.display.MovieClip;
	import flash.events.Event;

	public class DeferredBlitProcessor extends BlitProcessorBase
	{
		/**
		 * Запоминаем запросы к процессору, которые еще не были обработаны и поставлены в очередь
		 */
		private var requests:Array = [];

		private var processedRequestFrame:int;
		protected var processedRequestCallback:Function;

		private var cacheByRef:Array;
		private var lengthByRef:Array;

		public function DeferredBlitProcessor(slug:String, movie:MovieClip, cacheBy:Array, lengthBy:Array)
		{
			super(slug, movie);
			cacheByRef = cacheBy;
			lengthByRef = lengthBy;
		}

		/**
		 * Асинхронно передает колбэку BlitData требуемого состояния анимации
		 */
		public function getBlitData(state:String, direction:int, frame:int, callback:Function):void
		{
			var shortHash:String = this.slug + ":" + state + ":" + direction;
			if(lengthByRef[shortHash])
				frame = frame % int(lengthByRef[shortHash]);

			var cache:BlitData = cacheByRef[this.slug + ":" + state + ':' + direction + ':' + frame];
			if(cache != null)
			{
				callback(cache);
				if(processedRequestCallback == null && requests.length)
					next();
				return;
			}

			if(processedRequestCallback == null /*|| processedRequestCallback == callback*/)
			{
				processedRequestCallback = callback;

				if(currentMovieState == state && currentMovieDirection == direction)
				{
					// только кадр
					if(currentMovieFrame == frame)
					{
						processCurrentMovie();
					}
					else
					{
						gotoFrame(frame);
					}
				}
				else
				{
					processedRequestFrame = frame;
					gotoStateDirection(state, direction);
				}
			}
			else
			{
				// сперва удаляем все вхождения с тем же колбэком
				var i:int = 0;
				while(i < requests.length)
				{
					var r:Array = requests[i];
					if(r[3] == callback)
						requests.splice(i, 1);
					else
						i++;
				}
				requests.push([state, direction, frame, callback]);
			}
		}

		override protected function onStateFrameConstructed(e:Event):void {
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			super.onStateFrameConstructed(e);

			// записать в менеджер инфорацию насчет общей продолжительности анимации
			var hash:String = slug + ":" + currentMovieState + ':' + currentMovieDirection;
			if(!lengthByRef[hash])
				lengthByRef[hash] = movieByStateDirection.totalFrames;

			if(processedRequestFrame == currentMovieFrame)
			{
				processCurrentMovie();
			}
			else
			{
				gotoFrame(processedRequestFrame);
			}
		}

		override protected function processCurrentMovie():BlitData {
			//trace('[RENDER] (' + movie.currentFrame + '/' + movieByStateDirection.currentFrame +') state=' + currentMovieState + ' dir=' + currentMovieDirection + ' frame=' + currentMovieFrame);
			var bd:BlitData = super.processCurrentMovie();

			// добавить в кэш
			cacheByRef[slug + ":" + currentMovieState + ':' + currentMovieDirection + ':' + currentMovieFrame] = bd;

			processedRequestCallback(bd);
			processedRequestCallback = null;

			if(requests.length)
				next();
			return bd;
		}

		private function next():void
		{
			getBlitData.apply(this, requests.shift());
		}

		override public function clear():void {
			super.clear();

			cacheByRef = null;
			lengthByRef = null;
			processedRequestCallback = null;
			requests = null;
		}
	}
}
