package com.somewater.display.blitting {
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

		private var deferredProcessorsBySlug:Array = [];

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
						var dc:DeferredBlitProcessor = new DeferredBlitProcessor(slug, movieBySlug[slug], cacheBy, lengthBy);
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
			else
				DeferredBlitProcessor(deferredProcessorsBySlug[slug]).getBlitData(state, direction, frame, callback);
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

import com.somewater.display.blitting.BlitData;
import com.somewater.display.blitting.MovieState;

import flash.display.BitmapData;

import flash.display.DisplayObject;
import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;

class BlitProcessorBase
{
	public var slug:String;
	public var movie:MovieClip;
	public var statesByName:Array;// hash of MovieState
	public var states:Array;

	protected var movieByStateDirection:MovieClip;
	protected var inProcessFlag:Boolean = true;
	protected var currentMovieState:String = null;
	protected var currentMovieDirection:int = -1;
	protected var currentMovieFrame:int = -1;

	public function BlitProcessorBase(slug:String, movie:MovieClip)
	{
		this.slug = slug;
		this.movie = movie;
		movie.play();

		// вычисляем и запоминаем структуру мувика
		statesByName = [];
		states = [];
		var s:MovieState;
		for each(var l:FrameLabel in movie.currentLabels)
		{
			s = new MovieState();
			s.name = l.name;
			s.startFrame = l.frame;
			states.push(s);
			statesByName[s.name] = s;
		}

		states.sortOn('startFrame', Array.NUMERIC);

		for (var i:int = 0; i < states.length; i++) {
			s = states[i];
			if(i != states.length - 1)
				s.endFrame = MovieState(states[i + 1]).startFrame - 1;
			else
				s.endFrame = movie.totalFrames;

			var directions:int = s.startFrame - s.endFrame + 1;
			s.directionLength = []
			for (var j:int = 0; j < directions; j++)
				s.directionLength[j] = 0;
		}
	}

	protected function processCurrentMovie():BlitData
	{
		var bd:BlitData = new BlitData();
		var dor:DisplayObject = movieByStateDirection;
		var rotated:Boolean = dor.transform.matrix.a == -1;
		var bounds:Rectangle = dor.getBounds(dor);
		var bmp:BitmapData = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0);
		//var m:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
		var m:Matrix = new Matrix(rotated?-1:1, 0, 0, 1, (rotated?bounds.x + bounds.width:-bounds.x), -bounds.y);
		bmp.draw(dor, m);
		bd.bmp = bmp;
		bd.offsetX = -m.tx + dor.x;
		bd.offsetY = -m.ty + dor.y;
		bd.hash = currentMovieState + ':' + currentMovieDirection + ':' + currentMovieFrame;
		return bd;
	}

	/**
	 * Обеспечивает возможность не делать кадры direction для персонажей, которые их не имеют
	 * а вместо них помещать само изображение персонажа в нужном стейте
	 */
	protected function usePseudoMc(child:DisplayObject):MovieClip
	{
		var mc:MovieClip =  child as MovieClip;
		if(mc)
			return mc;
		mc = new MovieClip();
		child.parent.addChildAt(mc, child.parent.getChildIndex(child));
		mc.addChild(child);
		return mc;
	}

	public function clear():void
	{
		stopMovie(movie)
		movie = null;
		stopMovie(movieByStateDirection);
		movieByStateDirection = null;
	}

	private function stopMovie(mc:MovieClip):void
	{
		mc.stop();
		var l:int = mc.numChildren;
		for (var i:int = 0; i < l; i++) {
			var ch:MovieClip = mc.getChildAt(i) as MovieClip;
			if(ch != null)
				stopMovie(ch);
		}
	}

	protected function stateDirectionToFrame(state:String, direction:int):int
	{
		return MovieState(statesByName[state]).startFrame + direction;
	}

	protected function gotoStateDirection(state:String, direction:int):void {
		currentMovieState = state;
		currentMovieDirection = direction;
		movie.removeEventListener("frameConstructed", onStateFrameConstructed);
		movie.addEventListener("frameConstructed", onStateFrameConstructed);

		inProcessFlag = true;
		movie.gotoAndStop(stateDirectionToFrame(state, direction));
	}

	protected function onStateFrameConstructed(e:Event):void {
		e.currentTarget.removeEventListener(e.type, arguments.callee);
		//stopMovie(movie);
		movieByStateDirection = usePseudoMc(e.currentTarget.getChildAt(0));
		movieByStateDirection.stop();
		currentMovieFrame = -1;// нельзя быть уверенным, на какой кадр мы перешли

		var s:MovieState = statesByName[currentMovieState];
		if(!s.directionLength[currentMovieDirection])
			s.directionLength[currentMovieDirection] = movieByStateDirection.totalFrames;

		inProcessFlag = false;
	}

	protected function gotoFrame(frame:int):void
	{
		currentMovieFrame = frame;
		movieByStateDirection.removeEventListener("frameConstructed", onFrameConstructed);
		movieByStateDirection.addEventListener("frameConstructed", onFrameConstructed);
		inProcessFlag = true;
		movieByStateDirection.gotoAndStop(frame);
	}

	protected function onFrameConstructed(event:Event):void {
		event.currentTarget.removeEventListener(event.type, arguments.callee);
		//stopMovie(movie);
		inProcessFlag = false;
		processCurrentMovie();
	}
}

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

class DeferredBlitProcessor extends BlitProcessorBase
{
	/**
	 * Запоминаем запросы к процессору, которые еще не были обработаны и поставлены в очередь
	 */
	private var requests:Array = [];

	private var processedRequestFrame:int;
	private var processedRequestCallback:Function;

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