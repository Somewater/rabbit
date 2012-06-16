package com.somewater.display.blitting {
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;

	public class MovieClipAnimator implements IBlitted{

		protected var movie:MovieClip;
		protected var movieByStateDirection:MovieClip;

		private var state:String = null;
		private var direction:int = -1;
		private var frame:int = -1;
		private var currentStateDirectionLength:int;

		public var statesByName:Array;// hash of MovieState
		public var states:Array;
		private var inProcessFlag:Boolean;

		public function MovieClipAnimator() {
		}

		public function initialize(slug:String):void {
			// обработать заранее установленный clip
			if(movie == null)
				throw new Error('Override "initialize" method and create movie clip');

			states = [];
			statesByName = [];
			inProcessFlag = true;
			currentStateDirectionLength = 0;

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

		public function goto(state:String, direction:int):void {
			if(inProcessFlag || this.state != state || this.direction != direction)
			{
				this.state = state;
				this.direction = direction;
				this.frame = -1;
				this.currentStateDirectionLength = 0;
				movie.removeEventListener("frameConstructed", onStateFrameConstructed);
				movie.addEventListener("frameConstructed", onStateFrameConstructed);

				inProcessFlag = true;
				movie.gotoAndStop(MovieState(statesByName[state]).startFrame + direction);
			}
		}

		protected function onStateFrameConstructed(e:Event):void {
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			movieByStateDirection = usePseudoMc(e.currentTarget.getChildAt(0));
			movieByStateDirection.stop();
			this.frame = -1;// нельзя быть уверенным, на какой кадр мы перешли
			inProcessFlag = false;

			var s:MovieState = statesByName[this.state];
			if(!s.directionLength[this.direction])
				s.directionLength[this.direction] = currentStateDirectionLength = movieByStateDirection.totalFrames;
			else
				currentStateDirectionLength = s.directionLength[this.direction];
		}

		public function next(frames:int = 1):void {
			var f:int;
			if(!inProcessFlag && this.frame != -1)
				f = this.frame + frames;
			else
				f = frames;

			if(currentStateDirectionLength)
				f = f % currentStateDirectionLength;

			if(inProcessFlag || this.frame != f)
			{
				this.frame = f;
				movieByStateDirection.removeEventListener("frameConstructed", onFrameConstructed);
				movieByStateDirection.addEventListener("frameConstructed", onFrameConstructed);
				movieByStateDirection.gotoAndStop(frame + 1);
			}
		}

		protected function onFrameConstructed(event:Event):void {
			event.currentTarget.removeEventListener(event.type, arguments.callee);
			inProcessFlag = false;
		}

		public function get displayObject():DisplayObject {
			return movie;
		}

		/**
		 * Обеспечивает возможность не делать кадры direction для персонажей, которые их не имеют
		 * а вместо них помещать само изображение персонажа в нужном стейте
		 */
		private function usePseudoMc(child:DisplayObject):MovieClip
		{
			var mc:MovieClip =  child as MovieClip;
			if(mc)
				return mc;
			mc = new MovieClip();
			child.parent.addChildAt(mc, child.parent.getChildIndex(child));
			mc.addChild(child);
			return mc;
		}
	}
}
