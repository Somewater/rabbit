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
	import flash.geom.Rectangle;

	public class MoveTool extends EditorToolBase{

		private static var _redFilter:ColorMatrixFilter;
		private static var _greenFilter:ColorMatrixFilter;

		private var selectedEntity:IEntity;

		public function MoveTool(template:XML) {
			super(template);

			EditorModule.instance.setIcon(new MoveToolIcon(template ? template..slug : null));
		}


		override public function onMove(tile:Point):void {
			highlightObjects(tile);

			if(selectedEntity)
			{
				// перетаскиваемому ентити персонально убрать фильтр
				var render:IsoRenderer = IsoRenderer(selectedEntity.lookupComponentByName("Render"));
				render.displayObject.filters = [new GlowFilter(0x2222FF, 0.6, 10,10)];

				var spatial:IsoSpatial = selectedEntity.lookupComponentByName("Spatial") as IsoSpatial;
				spatial.tile = tile;

				render.onFrame(1/30);
			}
		}


		override public function onClick(tile:Point):void {
			highlightObjects(tile);

			if(selectedEntity)
			{
				// поставить на новое место
				dispatchMoving();
			}
			else
			{
				// начать перетаскивание
				var entities:Array = isoSpatialsToEntities(getObjectsUnderCursor(tile));
				for each(var entity:IEntity in entities)
				{
					selectedEntity = entity;
					break;
				}

				EditorModule.instance.setIcon(new MoveToolIcon(IsoRenderer(selectedEntity.lookupComponentByName("Render")).slug));
				onMove(tile);
			}
		}

		private function dispatchMoving():void
		{
			var selectedEntityRef:IEntity = selectedEntity;
			EditorModule.instance.onEntitieMoved(selectedEntityRef);
			clear();
			EditorModule.instance.dispatchEvent(new EditorEvent("move", selectedEntityRef));
		}


		override public function clear():void {
			super.clear();
			if(selectedEntity){
				dispatchMoving();
				selectedEntity = null;
			}
		}


		override protected function get getHighlightFilter():* {
			if(!_redFilter)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([1, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, 0.2, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, 0.2, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				_redFilter = new ColorMatrixFilter(matrix);
			}
			if(!_greenFilter)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([0.2, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, 1, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, 0.2, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				_greenFilter = new ColorMatrixFilter(matrix);
			}
			return selectedEntity ? _redFilter : _greenFilter;
		}


		override protected function getCursorRect(tile:Point):Rectangle {
			if(selectedEntity)
			{
				var spatial:IsoSpatial = selectedEntity.lookupComponentByName("Spatial") as IsoSpatial;
				return new Rectangle(tile.x,  tile.y, spatial.size.x,  spatial.size.y);
			}
			else
				return super.getCursorRect(tile);
		}
	}
}

import com.somewater.rabbit.debug.EditorToolBase;

import flash.display.Bitmap;

import flash.display.Graphics;
import flash.display.Sprite;

class MoveToolIcon extends Sprite
{
	private const SIZE:int = 25;

	public function MoveToolIcon(slug:String = null)
	{
		var icon:Bitmap
		if(slug)
		{
			icon = EditorToolBase.createIconFromSlug(slug, 0.3);
			addChild(icon);
		}


		var g:Graphics= this.graphics;
		g.lineStyle(3, 0x222288);

		g.moveTo(0,0);
		g.lineTo(SIZE,SIZE * 0.7);
		g.lineTo(SIZE * 0.7,SIZE);
		g.lineTo(0,0);
	}


	override public function get width():Number {
		return SIZE;
	}


	override public function get height():Number {
		return SIZE;
	}
}
