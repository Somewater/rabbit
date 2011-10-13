package com.somewater.rabbit.debug {
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.events.EditorEvent;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;

	import flash.display.DisplayObject;

	import flash.filters.ColorMatrixFilter;

	import flash.filters.GlowFilter;

	import flash.geom.Point;

	public class DeleteTool extends EditorToolBase{

		private static var _filter:ColorMatrixFilter;
		private static function get red_filter():ColorMatrixFilter{
			if(!_filter)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([1, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, 0, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, 0, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				_filter = new ColorMatrixFilter(matrix);
			}
			return _filter;
    }

		/**
		 * Ранее подсвеченные объекты
		 */
		private var lastDIsplayObjects:Array = []

		public function DeleteTool(template:XML) {
			super(template);

			EditorModule.instance.setIcon(new DeleteToolIcon());
		}


		override public function onMove(tile:Point):void {
			highlightObjects(tile);
		}


		override public function onClick(tile:Point):void {
			highlightObjects(tile);

			var entities:Array =isoSpatialsToEntities(getObjectsUnderCursor(tile));
			for each(var entity:IEntity in entities)
			{
				entity.destroy();
			}

			EditorModule.instance.onEntitiesDeleted(entities);

			clear();
			EditorModule.instance.dispatchEvent(new EditorEvent("delete", entities));
		}


		override public function clear():void {
			super.clear();
			clearLastDisplayObjects();
		}


		private function highlightObjects(tile:Point):void
		{
			clearLastDisplayObjects();
			lastDIsplayObjects = isoSpatialsToDIsplayObjects(getObjectsUnderCursor(tile));
			for each(var dor:DisplayObject in lastDIsplayObjects)
				dor.filters = [red_filter];
		}

		private function getObjectsUnderCursor(tile:Point):Array
		{
			var result:Array = [];
			IsoSpatialManager.instance.getObjectsUnderPoint(tile, result);
			return result;
		}


		private function isoSpatialsToDIsplayObjects(spatials:Array):Array
		{
			var displayObjects:Array = [];
			for each(var spatial:IsoSpatial in spatials)
			{
				var isoRender:IsoRenderer = IsoRenderer(spatial.owner.lookupComponentByName("Render"))
				if(isoRender.displayObject && displayObjects.indexOf(isoRender.displayObject) == -1)
					displayObjects.push(isoRender.displayObject);
			}
			return displayObjects;
		}

		private function isoSpatialsToEntities(spatials:Array):Array
		{
			var entities:Array = [];
			for each(var spatial:IsoSpatial in spatials)
			{
				var entity:IEntity = spatial.owner;
				if(entity && entities.indexOf(entity) == -1)
					entities.push(entity);
			}
			return entities;
		}

		private function clearLastDisplayObjects():void
		{
		 	for each(var dor:DisplayObject in lastDIsplayObjects)
			{
				dor.filters = [];
			}
			lastDIsplayObjects = [];
		}
	}
}

import flash.display.Graphics;
import flash.display.Sprite;

class DeleteToolIcon extends Sprite
{
	private const SIZE:int = 40;

	public function DeleteToolIcon()
	{
		var g:Graphics= this.graphics;
		g.lineStyle(3, 0x882222);

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
