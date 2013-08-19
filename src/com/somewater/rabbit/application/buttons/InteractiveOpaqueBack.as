package com.somewater.rabbit.application.buttons {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class InteractiveOpaqueBack extends Sprite implements IClear{

		public var iconShiftX:int = 0;
		public var iconShiftY:int = 0;
		public var icon:DisplayObject;
		protected var back:DisplayObject;

		protected var _width:int;
		protected var _height:int;

		private var state:int = 0;
		private var createdState:int = 0;

		public function InteractiveOpaqueBack(icon:DisplayObject = null) {
			this.icon = icon;
			if(icon){
				addChild(icon);
				if(icon is Sprite){
					Sprite(icon).mouseEnabled = false;
				}
			}
			buttonMode = useHandCursor = true;

			addEventListener(MouseEvent.ROLL_OVER, onOver);
			addEventListener(MouseEvent.ROLL_OUT, onUp);
			addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			addEventListener(MouseEvent.MOUSE_UP, onOver);

			state = 1;
			refresh();
		}

		private function onDown(event:MouseEvent):void {
			state = 3;
			refresh();
		}

		private function onUp(event:MouseEvent):void {
			state = 1;
			refresh();
		}

		private function onOver(event:MouseEvent):void {
			state = 2;
			refresh();
		}

		public function clear():void {
			removeEventListener(MouseEvent.ROLL_OVER, onOver);
			removeEventListener(MouseEvent.ROLL_OUT, onUp);
			removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
			removeEventListener(MouseEvent.MOUSE_UP, onOver);
		}

		public function setSize(w:int, h:int):void {
			_width = w;
			_height = h;
			refresh();
		}

		override public function set width(value:Number):void {
			_width = value;
			refresh();
		}

		override public function set height(value:Number):void {
			_height = value;
			refresh();
		}

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		private function refresh():void {
			if(state != createdState || createdState == 0){
				if(createdState && back){
					back.parent.removeChild(back);
					back = null;
				}
				back = Lib.createMC('interface.InteractiveOpaqueBack_' + (state == 1 ? 'up' : (state == 2 ? 'over' : 'down')));
				back.x = back.y = (state == 3 ? 3 : 1);
				addChildAt(back, 0);
				createdState = state;
			}
			back.width = _width + (state == 3 ? 0 : 2);
			back.height = _height + (state == 3 ? 0 : 2);
			if(icon){
				icon.x = (_width - icon.width) * 0.5 + (state == 3 ? 2 : 0) + iconShiftX;
				icon.y = (_height - icon.height) * 0.5 + (state == 3 ? 2 : 0) + iconShiftY;
			}
		}
	}
}
