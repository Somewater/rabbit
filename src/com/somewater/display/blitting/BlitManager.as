package com.somewater.display.blitting {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name='change', type='flash.events.Event')]
	[Event(name='complete', type='flash.events.Event')]
	public class BlitManager extends EventDispatcher{

		public static var instance:BlitManager;

		/**
		 * Кэш BitmapData по hash = slug + ":" + state + ":" + direction + ":" + frame
		 */
		protected var cacheBy:Array = [];

		/**
		 * Кэш длины анимации по hash = slug + ":" + state + ":" + direction
		 */
		protected var lengthBy:Array = [];

		/**
		 * Для определения slug, по которым уже был создан процессор
		 */
		protected var processedIndexBySlug:Array = [];

		private var prepareSlugsQueue:Array = [];
		private var prepareSlugsQueueOriginalLength:int;
		private var processors:Array = [];

		protected var deferredProcessorsBySlug:Array = [];

		public function BlitManager() {
		}

		/**
		 * подготовить блит данные
		 */
		public function prepare(movieBySlug:Object, defer:Boolean = true):void
		{
			var slug:String
			if(defer)
			{
				for(slug in movieBySlug)
					if(!processedIndexBySlug[slug])
					{
						var dc:DeferredBlitProcessor = createProcessor(slug, movieBySlug[slug]) as DeferredBlitProcessor;
						processedIndexBySlug[slug] = 'deferred';
						deferredProcessorsBySlug[slug] = dc;
					}
			}
			else
			{
				if(prepareSlugsQueue.length)
					throw new Error('Other prepare in progreess');

				for(slug in movieBySlug)
					if(!processedIndexBySlug[slug])
					{
						prepareSlugsQueue.push({'slug':slug, 'movie':movieBySlug[slug]});
						processedIndexBySlug[slug] = 'processed';
					}
				prepareSlugsQueueOriginalLength = prepareSlugsQueue.length;

				for (var i:int = 0; i < prepareSlugsQueueOriginalLength; i++)
					processNextMovieBySlug();
			}
		}

		protected function createProcessor(slug:String, movie:MovieClip):BlitProcessorBase
		{
			return new DeferredBlitProcessor(slug, movie, cacheBy, lengthBy);
		}

		public function get progress():Number
		{
			var completed:Number = Math.min(1,
					Math.max(0, prepareSlugsQueueOriginalLength - prepareSlugsQueue.length - processors.length)
					/ Math.max(1, prepareSlugsQueueOriginalLength));
			if(processors.length)
			{
				var coef:Number = (1 - completed) / (processors.length + prepareSlugsQueue.length);
				for each(var p:BlitProcessor in processors)
					completed += p.progress * coef;
			}
			return completed;
		}

		public function slugRegistered(slug:String):Boolean{
			return processedIndexBySlug[slug] != null;
		}

		private function processNextMovieBySlug(processor:BlitProcessor = null):void {
			if(processor != null)
			{
				processors.splice(processors.indexOf(processor), 1);
				processor.clear();
				dispatchEvent(new Event(Event.CHANGE));
			}
			var next:Object = prepareSlugsQueue.pop();
			if(next == null && processors.length == 0)
			{
				onPrepareComplete();
			}
			else if(next)
			{
				processor = new BlitProcessor(next.slug, next.movie, processNextMovieBySlug, onPrepareError);
				processors.push(processor);
				processor.process();
			}

		}

		private function onPrepareError():void {
			trace('PREPARE ERROR')
			throw new Error('Prepare blitting movie Error');
		}

		private function onPrepareComplete():void
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}

		/**
		 * @param callback function(data:BlitData):void
		 */
		public function getBlitData(slug:String, state:String, direction:int, frame:int, callback:Function):void
		{
			var data:BlitData = cacheBy[slug + ':' + state + ':' + direction + ':' + frame];
			if(data != null)
				callback(data);
			else{
				var d:DeferredBlitProcessor = deferredProcessorsBySlug[slug];
				if(d){
					d.getBlitData(state, direction, frame, callback);
				}else{
					onSlugNotFound(slug, state, direction, frame, callback);
				}
			}
		}

		protected function onSlugNotFound(slug:String, state:String, direction:int, frame:int, callback:Function):void {
			throw new Error("Override me");
		}

		public function getLength(slug:String, state:String, direction:int):int
		{
			return lengthBy[slug + ":" + state + ':' + direction];
		}

		public function getStates(slug:String):Array {
			return DeferredBlitProcessor(deferredProcessorsBySlug[slug]).states;
		}
	}
}

import com.somewater.display.blitting.BlitProcessorBase;
import com.somewater.display.blitting.MovieState;

import flash.display.MovieClip;
import flash.events.Event;

class BlitProcessor extends BlitProcessorBase
{
	private var prepareMovieStates:Array;
	private var prepareMovieStatesLength:int;
	private var prepareMovieState:MovieState;
	private var prepareMovieDirection:int;
	private var prepareMovieFrame:int;
	private var prepareMovieFramesTotal:int;

	private var onComplete:Function;// function(processor:BlitProcessor):void
	private var onError:Function;// function():void

	public function BlitProcessor(slug:String, movie:MovieClip, onComplete:Function, onError:Function)
	{
		super(slug, movie)
		this.onComplete = onComplete;
		this.onError = onError;
	}

	public function process():void
	{

		prepareMovieStates = states.slice();
		prepareMovieStatesLength = prepareMovieStates.length;
		processNextMovieState();
	}

	public function get progress():Number
	{
		var prepareMovieStatesLength:int = (this.prepareMovieStatesLength > 0 ? this.prepareMovieStatesLength : 1);
		var value:Number = 1 - (prepareMovieStates.length / prepareMovieStatesLength);
		// учесть готовность текуще обрабатываемого стейта
		value += 1 / prepareMovieStatesLength * (prepareMovieDirection / (prepareMovieState.directionLength.length > 0 ? prepareMovieState.directionLength.length : 1));
		return value;
	}

	private function processNextMovieState():void {
		prepareMovieState = prepareMovieStates.shift();
		if(prepareMovieState != null)
		{
			prepareMovieDirection = -1;
			processNextMovieDirection();
		}
		else
			onComplete(this);
	}

	private function processNextMovieDirection():void {
		prepareMovieDirection++;
		if(prepareMovieDirection < prepareMovieState.directionLength.length)
			gotoStateDirection(prepareMovieState.name, prepareMovieDirection);
		else
			processNextMovieState();
	}

	override protected function onStateFrameConstructed(e:Event):void {
		e.currentTarget.removeEventListener(e.type, arguments.callee);
		super.onStateFrameConstructed(e);
		prepareMovieFrame = -1;
		prepareMovieFramesTotal = movieByStateDirection.totalFrames;

		processNextFrame();
	}

	private function processNextFrame():void
	{
		prepareMovieFrame++;
		if(prepareMovieFrame < prepareMovieFramesTotal)
		{
			gotoFrame(prepareMovieFrame + 1)
		}
		else
			processNextMovieDirection();
	}

	override protected function onFrameConstructed(e:Event):void {
		e.currentTarget.removeEventListener(e.type, arguments.callee);
		super.onFrameConstructed(e);
		processNextFrame()
	}

	override public function clear():void {
		super.clear();
		prepareMovieStates = null;
		prepareMovieState = null;
		onComplete = null;
		onError = null;
	}
}