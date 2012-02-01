package com.somewater.rabbit.managers {
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public interface IGameTutorialModule {

		function get rabbitEntity():*

		function get heroPoint():Point

		function get heroTile():Point

		function getDisplayObject(entity:*):DisplayObject

		function get heroDisplayObject():DisplayObject

		function get carrotHarvested():int

		function get health():Number
	}
}
