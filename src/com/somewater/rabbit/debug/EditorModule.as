/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/24/11
 * Time: 1:01 AM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.rabbit.debug {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.events.EditorEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;

	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	[Event(name="change", type="flash.events.Event")]

	/**
	 * Управляет функциями editor-а
	 */
	public class EditorModule extends EventDispatcher{

		private static var _instance:EditorModule;

		/**
		 * Текущий режим
		 * 0 нормальный (стартовый)
		 * 1 перетаскивание иконки над сценой
		 */
		private var mode:int = 0;
		private var template:XML;
		private var mouseIcon:Bitmap;
		private var mouseListeners:Boolean = false;

		public function EditorModule() {
			if(_instance != null)
				throw new Error("Singletone");

			_instance = this;
		}

		public static function get instance():EditorModule
		{
			if(!_instance)
			{
				new EditorModule();
			}
			return _instance;
		}


		private function onMouseMove(event:MouseEvent):void {
			mouseIcon.x = stage.mouseX - mouseIcon.width * 0.5;
			mouseIcon.y = stage.mouseY - mouseIcon.height * 0.5;
		}

		private function onMouseClick(event:MouseEvent):void {
			if(mode == 1)
			{
				var tile:Point = IsoSpatialManager.globalToIso(new Point(PBE.cachedMainStage.mouseX, PBE.cachedMainStage.mouseY));
				tile.x = int(tile.x);
				tile.y = int(tile.y);

				// создать ентити
				var newEntity:IEntity = PBE.templateManager.instantiateEntity(template.@name);
				newEntity.owningGroup = PBE.lookup(Config.game.level.groupName) as PBGroup;
				
				// остановить процессор (который включается больно умным TemplateManager)
				Config.game.pause();

				// потикать контрллеры нового entity
				throw "TODO: tick new enity components"

				// отпозиционировать ентити в нужный тайл
				IsoSpatial(newEntity.lookupComponentByName("Spatial")).tile = tile.clone();

				// убрать курсор и диспатчить конец процесса
				mode = 0;
				removeIcon();
				dispatchEvent(new EditorEvent(Event.CHANGE, newEntity));
			}
		}

		public function setTemplateTool(template:XML):IEventDispatcher
		{
			if(mode == 1) return null;

			if(template == null)
			{
				// просто выключить курсор
				this.template = null;
				mode = 0;
				removeIcon();
			}
			else
			{
				this.template = template;
				setListeners();
				mode = 1;

				setIcon(template..slug);

				return this;
			}
		}

		private function setIcon(slug:String):void
		{
			removeIcon();
			mouseIcon = createIconFromSlug(slug, 0.7);
			stage.addChild(mouseIcon);
			setListeners();
		}

		private function removeIcon():void
		{
			if(mouseIcon && mouseIcon.parent)
				mouseIcon.parent.removeChild(mouseIcon);
			removeListeners();
		}

		private function get stage():Stage
		{
			return PBE.cachedMainStage;
		}

		private function createIconFromSlug(slug:String, size:Number = 1):Bitmap
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


		private function setListeners():void
		{
			if(mouseListeners) return;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.CLICK, onMouseClick, true);
			mouseListeners = true;
		}

		private function removeListeners():void
		{
			if(!mouseListeners) return;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.CLICK, onMouseClick, true);
			mouseListeners = false;
		}

		/**
		 * Вызывается один раз, при старте RabbitEditor
		 */
		public function init():void {

		}
	}
}
