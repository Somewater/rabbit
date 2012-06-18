package com.somewater.display.blitting {
	import com.somewater.rabbit.storage.Config;

	import flash.display.MovieClip;
	import flash.utils.getTimer;

	/**
	 * Умеет подготавливать отбличенные кадры, пока игровой модуль не активен
	 * подготавливает 1-е кадры каждого стейта
	 */
	public class PreparativeBlitManager extends BlitManager{

		private var preparationActive:Boolean = false;
		private var prepareSlugs:Array;
		private var t:uint;

		public function PreparativeBlitManager() {
		}


		/**
		 * @param queue Очередь вида [{slug, movie}, ....]
		 * @param defer
		 */
		public function startPrepare(queue:Array):void {
			preparationActive = true;
			prepareSlugs = [];
			var movieBySlug:Object = {};
			for each(var data:Object in queue)
			{
				prepareSlugs.push(data.slug);
				movieBySlug[data.slug] = data.movie;
			}
			prepare(movieBySlug, true);

			prepareNextSlug();

			t = getTimer();
		}

		override protected function createProcessor(slug:String, movie:MovieClip):BlitProcessorBase {
			return new PrepareDeferredBlitProcessor(slug, movie, cacheBy, lengthBy);
		}

		public function onStop():void {
			if(preparationActive)
			{
				for each(var dp:PrepareDeferredBlitProcessor in deferredProcessorsBySlug)
					if(dp != null)
						dp.stopPrepare();
				preparationActive = false;
				prepareSlugs = null;
			}
		}

		private function prepareNextSlug(processor:PrepareDeferredBlitProcessor = null):void
		{
			if(prepareSlugs != null && prepareSlugs.length)
			{
				if(processor != null)
					prepareSlugs.splice(prepareSlugs.indexOf(processor.slug),1);
				var slug:String = prepareSlugs.shift();
				if(slug && deferredProcessorsBySlug[slug] is PrepareDeferredBlitProcessor)
					PrepareDeferredBlitProcessor(deferredProcessorsBySlug[slug]).startPrepare(prepareNextSlug);
				else
				{
					// мы всё распарсили!!!
				}
			}
		}
	}
}

import com.somewater.display.blitting.BlitData;
import com.somewater.display.blitting.DeferredBlitProcessor;
import com.somewater.display.blitting.MovieState;

import flash.display.MovieClip;


class PrepareDeferredBlitProcessor extends DeferredBlitProcessor
{
	private var prepare:Boolean = false;
	private var onPrepareCompleteCallback:Function;
	private var statesPrepareQueue:Array;
	private var currentPrepareState:MovieState;
	private var currentPrepareDirection:int;

	public function PrepareDeferredBlitProcessor(slug:String, movie:MovieClip, cacheBy:Array, lengthBy:Array)
	{
		super(slug, movie, cacheBy, lengthBy);
	}

	override protected function processCurrentMovie():BlitData {
		super.processCurrentMovie();

		if(prepare)
		{
			// перейти к следующему шагу
			nextPrepareStep();
		}

		return null;
	}

	public function startPrepare(onPrepareCompleteCallback:Function):void {
		this.onPrepareCompleteCallback = onPrepareCompleteCallback;
		prepare = true;
		statesPrepareQueue = states.slice();
		currentPrepareDirection = -1;
		nextPrepareStep();
	}

	public function stopPrepare():void {
		prepare = false;
		onPrepareCompleteCallback = null;
	}

	public function prepareComplete():Boolean
	{
		return statesPrepareQueue.length == 0 && currentPrepareState == null;
	}

	private function nextPrepareStep():void {
		currentPrepareDirection++;
		if(currentPrepareState != null)
		{
			if(currentPrepareDirection <= (currentPrepareState.endFrame - currentPrepareState.startFrame))
			{
				processedRequestCallback = dummy;
				gotoStateDirection(currentPrepareState.name, currentPrepareDirection);
				return;
			}
			else
			{
				// нам нужен новый стейт
			}
		}

		currentPrepareState = statesPrepareQueue.pop();
		currentPrepareDirection = 0;

		if(currentPrepareState != null)
		{
			processedRequestCallback = dummy;
			gotoStateDirection(currentPrepareState.name, currentPrepareDirection);
		}
		else
		{
			// мы всё отрендерели
			prepare = false;
			if(onPrepareCompleteCallback != null)
				onPrepareCompleteCallback(this);
		}
	}

	private function dummy(data:BlitData):void{

	}
}