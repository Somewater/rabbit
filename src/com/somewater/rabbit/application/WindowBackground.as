package com.somewater.rabbit.application
{
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	
	public class WindowBackground extends Sprite
	{
		protected var _width:int;
		protected var _height:int;
		
		private var front:Sprite;
		private var back:Sprite;
		private var carrotHolder:Sprite;
		private var carrotHolderMask:Shape;
		
		public function WindowBackground()
		{
			super();
			
			back = Lib.createMC("interface.WindowGround_back");
			back.filters = [new DropShadowFilter(0, 45, 0, 1, 10, 10, 0.5)];
			addChild(back);
			
			front = Lib.createMC("interface.WindowGround_front");
			addChild(front);
			front.x = 3.65;
			front.y = 3.65;
			
			carrotHolder = new Sprite();
			addChild(carrotHolder);
				
			carrotHolderMask = new Shape();
			addChild(carrotHolderMask);
			carrotHolder.mask = carrotHolderMask;
			carrotHolderMask.x = carrotHolder.x = 3.65
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
		
		protected function resize():void
		{
			back.width = _width;
			back.height = _height;
			var contentWidth:int = _width - 7.3
			front.width = contentWidth;
			front.height = _height - 7.3;
			
			
			
			carrotHolderMask.y = carrotHolder.y = _height - 47.5 - 3.65;
			carrotHolderMask.graphics.clear();
			carrotHolderMask.graphics.beginFill(0);
			carrotHolderMask.graphics.drawRoundRectComplex(0, 0, contentWidth, 47.5, 0, 0, 10, 10);
			
			while(carrotHolder.numChildren)
				carrotHolder.removeChildAt(0);
			
			var needCarrotNum:int = Math.ceil(contentWidth/38.25);
			var padding:int = (needCarrotNum * 38.25 - contentWidth) * 0.5;
			
			for(var i:int = 0;i<needCarrotNum;i++)
			{
				var carrot:DisplayObject = Lib.createMC("interface.WindowGround_carrot");
				carrot.x = -padding + i * 38.25;
				carrotHolder.addChild(carrot);
			}
		}
	}
}