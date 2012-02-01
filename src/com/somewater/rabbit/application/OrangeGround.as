package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;

	public class OrangeGround extends Sprite implements IClear
	{
		protected var _width:int;
		protected var _height:int;
		
		protected var up:Sprite;
		protected var over:Sprite;
		protected var down:Sprite;
		
		private var listenersCreated:Boolean;
		
		/**
		 * 0 up
		 * 1 over
		 * 2 down
		 */
		protected var _mouseMode:int = 0;
		
		public function OrangeGround()
		{
			recreateGrounds();

			listenersCreated = false;
			
			filters = [new DropShadowFilter(2, 45, 0, 0.24, 10, 10)];
		}

		protected function recreateGrounds():void
		{
			if(down && down.parent)
				down.parent.removeChild(down);
			if(over && over.parent)
				over.parent.removeChild(over);
			if(up && up.parent)
				up.parent.removeChild(up);

			up = createGround("up");
			up.mouseEnabled = up.mouseChildren = false;
			addChildAt(up, 0);

			over = createGround("over");
			over.visible = false;
			over.mouseEnabled = over.mouseChildren = false;
			addChildAt(over, 0);

			down = createGround("down");
			addChildAt(down, 0);
		}
		
		public function clear():void
		{
			deleteListeners();
		}
		
		private function createListeners():void
		{
			if(listenersCreated) return;
			listenersCreated = true;
			
			addEventListener(MouseEvent.ROLL_OVER, onOver);
			addEventListener(MouseEvent.ROLL_OUT, onOut);
			addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			addEventListener(MouseEvent.MOUSE_UP, onOver);
		}
		
		private function deleteListeners():void
		{
			listenersCreated = false;
			
			removeEventListener(MouseEvent.ROLL_OVER, onOver);
			removeEventListener(MouseEvent.ROLL_OUT, onOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
			removeEventListener(MouseEvent.MOUSE_UP, onOver);
		}
		
		override public function set buttonMode(value:Boolean):void
		{
			super.buttonMode = value;
			useHandCursor = value;
			
			if(value)
				createListeners();
			else
				deleteListeners();
		}
		
		public function setSize(w:int, h:int):void
		{
			_width = w;
			_height = h;
			
			resize();
		}
		
		protected function resize():void
		{
			up.width = _width;
			up.height = _height;
			
			over.width = _width;
			over.height = _height;
			
			down.width = _width;
			down.height = _height;
		}
		
		protected function onMouse(event:MouseEvent):void
		{
			
		}
		
		override public function set width(value:Number):void
		{
			if(_width != value)
			{
				_width = value;
				resize();
			}
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		override public function set height(value:Number):void
		{
			if(value != _height)
			{
				_height = value;
				resize();
			}
		}
		
		override public function get height():Number
		{
			return _height;
		}
		
		
		protected function onOver(e:MouseEvent):void
		{
			_mouseMode = 1;
			onMouse(e);
			up.visible = false;
			over.visible = true;
		}
		
		protected function onOut(e:MouseEvent):void
		{
			_mouseMode = 0;
			onMouse(e);
			up.visible = true;
			over.visible = false;
		}
		
		protected function onDown(e:MouseEvent):void
		{
			_mouseMode = 2;
			onMouse(e);
			up.visible = false;
			over.visible = false;
		}

		protected function createGround(type:String):Sprite
		{
			return Lib.createMC("interface.OrangeButton_" + type);
		}
	}
}