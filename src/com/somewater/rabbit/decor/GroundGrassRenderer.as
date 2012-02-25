package com.somewater.rabbit.decor {
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;

	/**
	 * Рендерит траву (т.е. простой игровой объект, не меняющий положение, не анимированный)
	 */
	public class GroundGrassRenderer extends DisplayObjectRenderer{

		public var grassType:String;

		private var libraryMovie:MovieClip;

		public function GroundGrassRenderer() {
			super();
		}

		override public function onFrame(elapsed:Number):void {
			libraryMovie = Lib.createMC('rabbit.BackgroundGrass');
			libraryMovie.addEventListener('frameConstructed', onFrameConstructed);
			libraryMovie.scenes;

			var startFrame:int = 1;
			var endFrame:int = libraryMovie.totalFrames;

			var checkEndFrame:Boolean = false;
			if(grassType)
				for each(var fl:FrameLabel in libraryMovie.currentLabels)
				{
					if(checkEndFrame)
						endFrame = fl.frame - 1;
					else if(fl.name == grassType)
					{
						startFrame = fl.frame;
						checkEndFrame = true;
					}
				}

			libraryMovie.gotoAndStop(int((endFrame - startFrame + 1) * Math.random()) + startFrame);

			registerForUpdates = false;
		}

		override protected function onRemove():void {
			if(libraryMovie)
				libraryMovie.removeEventListener('frameConstructed', onFrameConstructed);
			super.onRemove();
		}

		private function onFrameConstructed(e:Event):void
		{
			libraryMovie.removeEventListener('frameConstructed', onFrameConstructed);

			var grass:DisplayObject;
			if(libraryMovie.numChildren == 1)
			{
				grass = libraryMovie.getChildAt(0);
			}
			else
			{
				grass = new Sprite();
				while (libraryMovie.numChildren)
					(grass as DisplayObjectContainer).addChild(libraryMovie.getChildAt(0))
			}

			libraryMovie = null;
			this.displayObject = grass;

			if(owner)
				this.position = owner.getProperty(positionProperty) as Point;
            updateTransform();
		}
	}
}