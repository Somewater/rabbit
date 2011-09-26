package com.somewater.rabbit.creature
{
	import com.greensock.TweenMax;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	
	final public class BeamRendererComponent extends IsoRenderer
	{
		private const TRANSITION_TIME:Number = 0.3;
		public static const ANGLE_AMP:Number = 20;
		
		public static const STATE_LEFT:String = "onLeft";
		public static const STATE_RIGHT:String = "onRight";
		public static const STATE_BALANCE:String = "onBalance";
		
		// стейт, в который осуществляется движение
		private var _requiredState:String;
		
		private var axis:DisplayObject;
		private var board:DisplayObject;
		private var core:*;
		
		public function BeamRendererComponent()
		{
			super();
			
			state = _currentState = STATE_BALANCE;
		}
		
		override public function onFrame(elapsed:Number):void
		{
			if(_displayObject == null)
				createDisplayObject();
			
			if(_currentState != state && _requiredState != state)
			{
				_currentState = States.TRANSITION;
				_requiredState = state;
				TweenMax.to(board, TRANSITION_TIME, {
					"rotation":(state == STATE_BALANCE?0:(state == STATE_LEFT?-ANGLE_AMP:ANGLE_AMP))
					,"onComplete":onTransitionComplete
				});
			}
			
			// super.super.onFrame :)
			updateProperties();			
			if (_transformDirty)
				updateTransform();
		}
		
		
		private function onTransitionComplete():void
		{
			_currentState = _requiredState;
		}
		
		
		protected function createDisplayObject():void
		{
			displayObject = core = Lib.createMC(slug);
			axis = core.axis;
			board = core.board;
		}
		
		override public function get rotation():Number
		{
			return board.rotation;
		}
	}
}