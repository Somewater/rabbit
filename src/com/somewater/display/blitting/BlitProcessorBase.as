package com.somewater.display.blitting {

	import flash.display.BitmapData;

	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class BlitProcessorBase
	{
		public var slug:String;
		public var movie:MovieClip;
		public var statesByName:Array;// hash of MovieState
		public var states:Array;

		protected var movieByStateDirection:MovieClip;
		public var inProcessFlag:Boolean = true;
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
			bd.offsetX = -m.tx + Math.round(dor.x);
			bd.offsetY = -m.ty + Math.round(dor.y);
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
			currentMovieFrame = movieByStateDirection.currentFrame;

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
}
