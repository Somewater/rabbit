package com.somewater.rabbit.decor {
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;

	/**
	 * Рендерит траву (т.е. простой игровой объект, не меняющий положение, не анимированный)
	 */
	public class GroundGrassRenderer extends DisplayObjectRenderer{

		private var libraryMovie:MovieClip;

		public function GroundGrassRenderer() {
			super();
			registerForUpdates = false;
		}

		override protected function onAdd():void {

			libraryMovie = Lib.createMC('rabbit.BackgroundGrass');
			libraryMovie.addEventListener('frameConstructed', onFrameConstructed);
			libraryMovie.gotoAndStop(int(libraryMovie.totalFrames * Math.random()) + 1);
			super.onAdd();
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

			 updateProperties();
             updateTransform();
		}
	}
}

import flash.display.Sprite;

class Sp extends Sprite
{

	override public function set x(value:Number):void {
		super.x = value;
	}
}
