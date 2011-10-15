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

		public function DeleteTool(template:XML, objectReference:XML = null) {
			super(template, objectReference);

			if(objectReference)
			{
				// просто удалить указанного и самоудалиться
				var entity:IEntity = findEntityByHash(objectReference.@hash);
				entity.destroy();
				EditorModule.instance.onEntitiesDeleted([entity]);
				clear();
			}
			else
				EditorModule.instance.setIcon(new DeleteToolIcon());
		}


		override public function onMove(tile:Point):void {
			highlightObjects(tile);
		}


		override public function onClick(tile:Point):void {
			highlightObjects(tile);

			var entities:Array = isoSpatialsToEntities(getObjectsUnderCursor(tile));
			for each(var entity:IEntity in entities)
			{
				entity.destroy();
			}

			if(entities.length)
				EditorModule.instance.onEntitiesDeleted(entities);

			clear();
			if(entities.length)
				EditorModule.instance.dispatchEvent(new EditorEvent("delete", entities));
		}


		override public function clear():void {
			super.clear();
		}


		override protected function get getHighlightFilter():* {
			if(!_filter)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([1, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, 0.2, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, 0.2, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				_filter = new ColorMatrixFilter(matrix);
			}
			return _filter;
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
