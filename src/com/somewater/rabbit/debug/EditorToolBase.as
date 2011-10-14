package com.somewater.rabbit.debug {
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.control.IClear;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.Bitmap;
	import flash.display.BitmapData;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;

	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class EditorToolBase implements IClear{

		public var cleared:Boolean = false;
		protected var template:XML;

		/**
		 * Ранее подсвеченные объекты
		 */
		private var lastDIsplayObjects:Array = []

		public function EditorToolBase(template:XML = null) {
			this.template = template;
		}

		public function onMove(tile:Point):void
		{

		}

		public function onClick(tile:Point):void
		{

		}

		public function clear():void
		{
			cleared = true;

			template = null;
			EditorModule.instance.setTemplateTool(null);

			clearLastDisplayObjects();
		}

		protected function highlightObjects(tile:Point):void
		{
			clearLastDisplayObjects();
			lastDIsplayObjects = isoSpatialsToDIsplayObjects(getObjectsUnderCursor(tile));
			for each(var dor:DisplayObject in lastDIsplayObjects)
				dor.filters = [getHighlightFilter];
		}

		protected function getObjectsUnderCursor(tile:Point):Array
		{
			var result:Array = [];
			var rectangle:Rectangle = getCursorRect(tile);
			if(rectangle.width == 0 && rectangle.height == 0)
				IsoSpatialManager.instance.getObjectsUnderPoint(tile, result);
			else
				IsoSpatialManager.instance.queryRectangle(rectangle, null, result);
			return result;
		}


		protected function isoSpatialsToDIsplayObjects(spatials:Array):Array
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

		protected function isoSpatialsToEntities(spatials:Array):Array
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

		protected function clearLastDisplayObjects():void
		{
		 	for each(var dor:DisplayObject in lastDIsplayObjects)
			{
				dor.filters = [];
			}
			lastDIsplayObjects = [];
		}

		/**
		 * возвратить размер курсора (по умолчанию - точечный)
		 */
		protected function getCursorRect(tile:Point):Rectangle
		{
			return new Rectangle(tile.x,  tile.y, 0, 0);
		}

		/**
		 * Возвратить фильтр выделения
		 */
		protected function get getHighlightFilter():*
		{
			return new GlowFilter();
		}


		public static function createIconFromSlug(slug:String, size:Number = 1):Bitmap
		{
			var mc:MovieClip = Lib.createMC(slug);
			MovieClipHelper.stopAll(mc);
		    var bounds:Rectangle = mc.getBounds(mc);
			var bmp:BitmapData = new BitmapData(bounds.width, bounds.height, true, 0);
			var m:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
            bmp.draw(mc, m);

			var bitmap:Bitmap = new Bitmap(bmp);
			bitmap.scaleX = bitmap.scaleY = size;
			return bitmap;
		}
	}
}
