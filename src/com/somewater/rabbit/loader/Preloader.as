package com.somewater.rabbit.loader {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;

	public class Preloader extends MovieClip{

		public var rabbitLoaderName:String = CONFIG::loadername;
		private var preloader:*;
		private var preloaderCarrotIndex:int = -1;// индекс последней запущенной морковки

		public function Preloader() {
			if(stage)
				onStage();
			else
				addEventListener(Event.ADDED_TO_STAGE, onStage);
		}


		private function onStage(event:Event = null):void
		{
			if(event)
				removeEventListener(event.type, onStage);

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;

			var pcl:Class = PreloaderAssetClass;
			preloader = new pcl();
			for(var i:int = 0; i < 10; i++)
				preloader.bar["carrot" + i].stop();
			addChild(preloader);

			preloader.x = (stage.stageWidth- preloader.width) * 0.5;
			preloader.y = (stage.stageHeight - preloader.height) * 0.5 - 20;

			updateProgress();
			addEventListener(Event.ENTER_FRAME, updateProgress);
		}

		private function updateProgress(... rest):void
		{
			if(framesLoaded == totalFrames)
				onComplete()
			else
			{
				var value:Number = (loaderInfo.bytesLoaded / loaderInfo.bytesTotal) * 0.7;
				preloader.bar.textField.text = Math.round(value * 100) + "%";
				preloader.bar.progressBar.scaleX = 1 - value;
				for(var nextCarrotIndex:int = Math.min(9,Math.round(value * 10));preloaderCarrotIndex < nextCarrotIndex;preloaderCarrotIndex++)
				{
					var carrot:MovieClip = preloader.bar["carrot" + (preloaderCarrotIndex + 1)];
					carrot.play();
					carrot.addFrameScript(carrot.totalFrames-1, carrot.stop);
				}
			}
		}

		private function onComplete(event:Event = null):void
		{
			removeEventListener(Event.ENTER_FRAME, updateProgress);
			this.stop();
			start();
		}

		protected function start():void
		{
			var s:Stage = this.stage;

			if(this.parent)
				this.parent.removeChild(this)

			var app:Class = getDefinitionByName(rabbitLoaderName) as Class;
			s.addChild(new app(preloader));
		}

		protected function get PreloaderAssetClass():Class
		{
			throw new Error('TODO')
		}
	}
}
