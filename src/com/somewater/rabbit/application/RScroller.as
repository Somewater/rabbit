package com.somewater.rabbit.application {
	import com.somewater.control.IClear;
	import com.somewater.control.Scroller;

	import flash.display.Shape;

	import flash.display.Sprite;

	public class RScroller extends Scroller{
		public function RScroller() {
			startButton = new ScrollButton(true);
			endButton = new ScrollButton(false);
			thumb = new Thumb();

			var scrollLine:Sprite = new Sprite();
			scrollLine.graphics.beginFill(0xC9DA2E);
			scrollLine.graphics.drawRect(0,0,100,100);
			this.scrollLine = scrollLine;

			var back:Shape = new Shape();
			back.graphics.beginFill(0,0);
			back.graphics.drawRect(0,0,100,100);
			background = back;
		}

		override public function draw():void {
			super.draw();

			if(content)
			{
				scrollSpeed = Math.max(0.05, orientation == VERTICAL ? _height / content.height : _width / content.width);
			}
		}
	}
}

import com.somewater.control.IClear;
import com.somewater.rabbit.storage.Lib;

import flash.display.DisplayObject;

import flash.display.DisplayObject;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

class Thumb extends Sprite implements IClear
{
	private var up:DisplayObject;
	private var over:DisplayObject;
	private var down:DisplayObject;

	public function Thumb()
	{
		up = addChild(Lib.createMC('interface.GreenGround_up'));
		over = addChild(Lib.createMC('interface.GreenGround_over'));
		over.visible = false;
		down = addChild(Lib.createMC('interface.GreenGround_down'));
		down.visible = false;
		filters = [new DropShadowFilter(0, 0, 0xCCCCCC, 0.23,  13, 13)];

		addEventListener(MouseEvent.ROLL_OVER, setOver, false, 0, true);
		addEventListener(MouseEvent.ROLL_OUT, setUp, false, 0, true);
		addEventListener(MouseEvent.MOUSE_DOWN, setDown, false, 0, true);
		addEventListener(MouseEvent.MOUSE_UP, setOver, false, 0, true);
	}

	private function setDown(event:MouseEvent):void {
		down.visible = true;
		up.visible = over.visible = false;
	}

	private function setUp(event:MouseEvent):void {
		up.visible = true;
		down.visible = over.visible = false;
	}

	private function setOver(event:MouseEvent):void {
		over.visible = true;
		up.visible = down.visible = false;
	}

	public function clear():void
	{
		removeEventListener(MouseEvent.ROLL_OVER, setOver);
		removeEventListener(MouseEvent.ROLL_OUT, setUp);
		removeEventListener(MouseEvent.MOUSE_DOWN, setDown);
		removeEventListener(MouseEvent.MOUSE_UP, setOver);
	}
}

class ScrollButton extends Sprite
{
	public function ScrollButton(top:Boolean)
	{
		var btn:DisplayObject = addChild(Lib.createMC('interface.GreenButtonWithTopArrow'));
		if(!top)
		{
			btn.y = btn.height;
			btn.scaleY = -1;
		}
		filters = [new DropShadowFilter(0, 0, 0xCCCCCC, 0.23,  13, 13)];
	}
}
