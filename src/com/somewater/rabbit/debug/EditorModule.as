/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/24/11
 * Time: 1:01 AM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.rabbit.debug {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.IAnimatedObject;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.events.EditorEvent;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoRenderer;
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
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;

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
		private var _inited:Boolean = false;
		private var tool:EditorToolBase;

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
				tickVisualComponents(newEntity);

				// отпозиционировать ентити в нужный тайл
				IsoSpatial(newEntity.lookupComponentByName("Spatial")).tile = tile.clone();

				// вызвать внутренний колбэк на создание нового ентити
				onNewEntityCreated(newEntity);

				// убрать курсор и диспатчить конец процесса
				mode = 0;
				removeIcon();
				dispatchEvent(new EditorEvent(Event.CHANGE, newEntity));
			}
		}

		public function setTemplateTool(template:XML):IEventDispatcher
		{
			if(template == null)
			{
				// просто выключить курсор
				this.template = null;
				mode = 0;
				removeIcon();
				return null;
			}
			else
			{
				if(mode == 1) return null;

				this.template = template;
				setListeners();
				mode = 1;

				setIcon(template..slug);
				onMouseMove(null);

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
			if(_inited) return;
			_inited = true;

			// вешаем листенер и старательно тикаем IsoCameraController
			Config.application.addPropertyListener("game.pause", onGamePause);
			Config.application.addPropertyListener("game.start", onGameStart);

			// вешаем кое-какие хоткеи
			Config.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown)
		}

		private function onKeyDown(event:KeyboardEvent):void {
			if(event.charCode == String("p").charCodeAt())
			{
				if(Config.game.isTicking)
					Config.game.pause();
				else
					Config.game.start();
			}
		}

		/**
		 * Начать тикать всё, что нуждается в тиканье, даже если игра на паузе
		 */
		private function onGamePause():void
		{
			if(!Config.stage.hasEventListener(Event.ENTER_FRAME))
				Config.stage.addEventListener(Event.ENTER_FRAME, onTickDuringPause)
		}

		/**
		 * Закончить тикать то, что тикалось из-за функции onGameStart
		 */
		private function onGameStart():void
		{
			Config.stage.removeEventListener(Event.ENTER_FRAME, onTickDuringPause)
		}

		/**
		 * Вызывается во время паузы PBE.processManager
		 */
		private function onTickDuringPause(e:Event):void
		{
			var deltaTime:Number = 1/30;

			// тикаем рендеры персонажей
			var forDelete:Array = [];
			var entity:IEntity;
			for(var key:* in tickVisualQueue)
			{
				entity = key;
				if(tickVisualQueue[entity] > 0)
				{
					var components:Array = entity.lookupComponentsByType(DisplayObjectRenderer);
					for each(var renderer:DisplayObjectRenderer in components)
						renderer.onFrame(deltaTime);
				}
				else
					forDelete.push(entity);
			}

			for each(entity in forDelete)
				delete(tickVisualQueue[entity]);

			// тикаем сцену и камеру
			IsoCameraController(PBE.lookup("Camera")).onTick(deltaTime);
			(PBE.scene as IAnimatedObject).onFrame(deltaTime);
		}

		/**
		 * Протикать визуальные контроллеры объекта, чтобы он засиял
		 */
		private var tickVisualQueue:Dictionary = new Dictionary();
		private function tickVisualComponents(entity:IEntity):void
		{
			tickVisualQueue[entity] = 5;// тикнуть 5 раз
		}

		/**
		 * Колбэк на создания нового ентити
		 * @param newEntity
		 */
		private function onNewEntityCreated(newEntity:IEntity):void {
			var hero:IEntity = PBE.lookupEntity("Hero");
			if(hero)
				IsoCameraController.getInstance().trackObject = hero.getProperty(new PropertyReference("@Spatial"));
		}
	}
}
