package com.somewater.rabbit.application.buttons
{
	import com.gskinner.geom.ColorMatrix;
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Rectangle;
	
	[Event(name="change", type="flash.events.Event")]
	
	public class SlideBar extends Sprite implements IClear
	{
		private var core:Sprite;
		private var thumb:Sprite;
		private var line:DisplayObject;
		
		private var _value:Number = 0.2;
		
		private var _enabled:Boolean = true;
		
		
		public function SlideBar()
		{
			super();
			
			core = Lib.createMC("interface.SlideBar");
			addChild(core);
			
			thumb = core["thumb"];
			line = core["line"];
			
			thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
			
			buttonMode = useHandCursor = _enabled;
			addEventListener(MouseEvent.CLICK, onClick);
			
			graphics.beginFill(0, 0);
			graphics.drawRect(0, -5, 130, 10);
		}
		
		public function clear():void
		{
			thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
			removeEventListener(MouseEvent.CLICK, onClick);
			
			if(stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
				stage.removeEventListener(MouseEvent.ROLL_OUT, onThumbUp);
			}
		}
		
		
		public function set enabled(val:Boolean):void
		{
			if(_enabled != val)
			{
				_enabled = val;
				if(_enabled)
				{
					filters = [];
				}
				else
				{
					var cm:ColorMatrix = new ColorMatrix([]);
					cm.adjustSaturation(-80);
					filters = [new ColorMatrixFilter(cm.toArray())]
					if(stage)
					{
						stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
						stage.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
						stage.addEventListener(MouseEvent.ROLL_OUT, onThumbUp);
					}
					thumb.stopDrag();
				}
			}
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		override public function get width():Number
		{
			return 132;
		}
		
		private function onThumbDown(e:Event):void
		{
			if(_enabled)
			{
				thumb.startDrag(false, new Rectangle(2, 0, 128, 0));
				if(stage)
				{
					stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
					stage.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
					stage.addEventListener(MouseEvent.ROLL_OUT, onThumbUp);
				}
			}
		}
		
		private function onThumbUp(e:Event):void
		{
			thumb.stopDrag();
			if(stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
				stage.removeEventListener(MouseEvent.ROLL_OUT, onThumbUp);
			}
		}
		
		private function onMouseMove(e:Event):void
		{
			if(_enabled)
				setValueByCoord(thumb.x);
		}
		
		private function onClick(e:Event):void
		{
			if(_enabled)
				setValueByCoord(this.mouseX);
		}
		
		private function setValueByCoord(coord:int):void
		{
			coord = Math.max(2, Math.min(128, coord));
			thumb.x = coord;
			line.width = coord - 2;
			
			_value = (coord - 2) / 126;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function set value(v:Number):void
		{
			_value = v;
			setValueByCoord(v * 126 + 2);
		}
		
		public function get value():Number
		{
			return _value;
		}
	}
}