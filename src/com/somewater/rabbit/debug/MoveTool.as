package com.somewater.rabbit.debug {
	import flash.geom.Point;

	public class MoveTool extends EditorToolBase{
		public function MoveTool(template:XML) {
			super(template);

			EditorModule.instance.setIcon(new MoveToolIcon());
		}

		override public function onMove(tile:Point):void {

		}


		override public function onClick(tile:Point):void {

		}
	}
}

import flash.display.Graphics;
import flash.display.Sprite;

class MoveToolIcon extends Sprite
{
	private const SIZE:int = 40;

	public function MoveToolIcon()
	{
		var g:Graphics= this.graphics;
		g.lineStyle(3, 0x00FF00);

		g.moveTo(0,0);
		g.lineTo(SIZE,SIZE);

		g.moveTo(SIZE,0);
		g.lineTo(0,SIZE);
	}


	override public function get width():Number {
		return SIZE;
	}


	override public function get height():Number {
		return SIZE;
	}
}
