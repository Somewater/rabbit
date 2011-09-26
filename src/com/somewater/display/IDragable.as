package com.somewater.display
{
	public interface IDragable 
	{
		// возвращает свою копию для перетаскивания
		function clone():IDragable;
		
		// включают и выключают режим слежения за кликом мышки
		function set enableDrag(value:Boolean):void;
		function get enableDrag():Boolean;
	}
}