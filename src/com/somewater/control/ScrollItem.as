package com.somewater.control
{
	import com.somewater.control.IClear;
		
	import flash.display.Sprite;
	import flash.events.Event;
	
	
	
	[Event(name="resize", type="flash.events.Event")]
	
	/**
	 * Базовый класс для всех элементов интерфейса, используемых в различных скроллах
	 * и изменяющих свой размер (например ширину) при появлении/исчезновении полосы прокрутки
	 */
	public class ScrollItem extends Sprite implements IClear
	{
		protected var created:Boolean = false;
		protected var _width:int;
		protected var _height:int;
		protected var _data:*
		
		public function ScrollItem()
		{
			super();
		}
		
		public function setSize(w:Number, h:Number):void
		{
			if(_width != w || _height != h)
			{
				_width = w;
				_height = h;
				refresh();
			}			
		}
		
		
		protected function refresh():void
		{
			if(!created)
				createInterface();
			created = true;
			draw();
		}
		
		
		/**
		 * Создать элементы интерфейса и добавить их в список отображения, 
		 * но не позиционировать (или позиционировать координаты, которые более не изменятся)
		 */
		protected function createInterface():void
		{
			
		}
		
		/**
		 * Отпозиционировать все элементы на основе значений _width, _height
		 */
		public function draw():void
		{
			
		}
		
		
		/**
		 * Функция применяется, когда ресайз элемента извне породил ресайз элемента изнутри
		 * (например, при изменении ширины элемента, элемент требует изменение отведенной для него высоты)
		 */
		public function dispatchResize():void
		{
			dispatchEvent(new Event(Event.RESIZE));
		}
		
		
		public function clear():void
		{
			_data = null;
		}
		
		public function set data(_data:Object):void
		{
			this._data = _data;
			refresh();
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		override public function set width(value:Number):void
		{
			if(_width != value)
			{
				setSize(value, _height);
			}
		}
		
		override public function get height():Number
		{
			return _height;
		}
		
		override public function set height(value:Number):void
		{
			if(_height != value)
			{
				setSize(_width, value);
			}
		}
	}
}