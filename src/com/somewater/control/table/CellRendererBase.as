package com.somewater.control.table
{
	import flash.display.Sprite;

	public class CellRendererBase extends Sprite implements ICellRenderer
	{
		public function CellRendererBase()
		{
			super();
		}
		
		// создать всё, чот нужно, после изменения размера
		protected function resize():void{
			if (_data != null)// если контент уже был установлен
				draw();
		}
		
		// чтобы создать всё. что нужно. после изменения данных
		protected function draw():void{
			throw new Error("Method draw():void in base class will be overridden");		
		}
		
		protected var _data:Object;
		public function set data(value:Object):void
		{
			_data = value;
			draw();
			
		}
		public function get data ():Object
		{
			return _data;
		}
		
		public function setData(value:Object):void{
			data = value;
		}
		
		protected var _width:Number;
		override public function set width(value:Number):void{
			_width = value;
			resize();
		}
		override public function get width():Number{
			return _width
		}
		
		protected var _height:Number;
		override public function set height(value:Number):void{
			_height = value;
			resize();
		}
		override public function get height():Number{
			return _height
		}
		
		/*protected var _x:Number;
		override public function set x(value:Number):void{
			_height = value;
			resize();
		}
		override public function get x():Number{
			return _x;
		}
		
		protected var _y:Number;
		override public function set y(value:Number):void{
			_y = value;
		}
		override public function get y():Number{
			return _y;
		}*/
		
	}
}