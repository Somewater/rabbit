package com.somewater.control.table
{
	
	/**
	 * используется классом Table для визуального представления ячеек таблицы
	 */
	public interface ICellRenderer
	{		
		function set data(value:Object):void;
		function get data():Object;
		function setData(value:Object):void;// обычная ф-я, передающая свой парметр ф-ции data
		
		function set width(value:Number):void;
		function get width():Number;
		
		function set height(value:Number):void;
		function get height():Number;
		
		function set x(value:Number):void;
		function get x():Number;
		
		function set y(value:Number):void;
		function get y():Number;
		
		/* ************************
		 *
		 *	нижеследующие функции должны быть реализованы в классе, реализующем интерфейс
		 *
		 **************************
		
		private var _data:Object;
		public function set data(value:Object):void
		{
			_data = value;
		}
		public function get data ():Object
		{
			return _data;
		}
		
		private var _width:Number;
		override public function set width(value:Number):void{
			
		}
		override public function get width():Number{
			return _width
		}
		
		private var _height:Number;
		override public function set height(value:Number):void{
			
		}
		override public function get height():Number{
			return _height
		}
		
		private var _x:Number;
		override public function set x(value:Number):void{
			
		}
		override public function get x():Number{
			return _x;
		}
		
		private var _y:Number;
		override public function set y(value:Number):void{
			
		}
		override public function get y():Number{
			return _y;
		}
		
		
		*/
	}
}