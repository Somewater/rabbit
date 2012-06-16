package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.IAnimatedObject;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.PathBits;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;

	import flash.display.DisplayObject;

	import flash.display.Graphics;

	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	import flash.geom.Point;

	/**
	 * Управляет граундом игры
	 */
	public class BackgroundRenderer extends DisplayObjectRenderer{

		private const storyIndexToGrass:Array = ['grass', 'flowers'];

		private var shape:Shape;
		private var heroSpatialRef:IsoSpatial;
		private var heroMoverRef:IsoMover;
		private var shiftPoint:Point = new Point();
		private var tempPoint:Point = new Point();

		private var levelSize:Point = new Point(1,1);

		private var mouseTileVisible:Boolean = false;
		private var mouseTile:Point = new Point(int.MIN_VALUE, int.MIN_VALUE);
		private var destinationTileVisible:Boolean = false;
		private var destinationTile:Point = new Point(int.MIN_VALUE, int.MIN_VALUE);

		/**
		 * Смещение игрового модуля относительно стейджа
		 * (обычно [0,0], но для android это не так)
		 */
		private var gameOffset:Point;

		public function BackgroundRenderer() {
			super();
			registerForUpdates = false;

			shape = new Shape();
			displayObject = shape;
		}

		override protected function onAdd():void {
			super.onAdd();

			//IsoCameraController.getInstance().addCallback(onCameraMoved);

			var levelWidth:int = IsoSpatialManager.instance.width;
			var levelHeight:int = IsoSpatialManager.instance.height;
			var levelSquare:int = levelWidth * levelHeight;

			for (var i:int = 0; i < int(levelSquare * 0.05); i++) {
				var grass:IEntity = PBE.templateManager.instantiateEntity('GroundGrassTemplate');
				grass.owningGroup = this.owner.owningGroup;
				if(Config.game.level.story)
					(grass.lookupComponentByType(DisplayObjectRenderer) as GroundGrassRenderer).grassType = storyIndexToGrass[Config.game.level.story.number];
				grass.setProperty(new PropertyReference('@Spatial.position'),
						new Point(int(Math.random() * levelWidth * Config.TILE_WIDTH), Math.random() * levelHeight * Config.TILE_HEIGHT))
			}

			Config.application.addPropertyListener('mouseInput', onMouseInputChanged);
			InitializeManager.bindRestartLevel(onLevelRestart);
			onMouseInputChanged();
			registerForUpdates = true;

			gameOffset = new Point((Config.loader as DisplayObject).x, (Config.loader as DisplayObject).y);
		}

		private function onLevelRestart():void {
			levelSize.x = Config.game.level.width;
			levelSize.y = Config.game.level.height;
		}

		override public function onFrame(elapsed:Number):void {
			if(heroSpatialRef == null)
				findHeroSpatialRef();

			if(heroSpatialRef != null)
			{
				registerForUpdates = false;
			}
		}

		private function onMouseInputChanged():void {
			if(Config.application.mouseInput)
			{
				// показывать указатели на кролика
				PBE.inputManager.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				PBE.mainStage.addEventListener(Event.MOUSE_LEAVE, onMouseOut);
			}
			else
			{
				// не показывать указатели, убить листенеры
				clearGraphic();
				clearListeners();
			}
		}

		private function onMouseOut(event:Event):void {
			mouseTileVisible = false;
			update();
		}

		private function onMouseMove(event:MouseEvent):void {
			if(heroSpatialRef == null || PBE.processManager.continiousTickCounter < 2)
				return;

			var tempPoint:Point = this.tempPoint;
			tempPoint.x = PBE.mainStage.mouseX - gameOffset.x - PBE.scene.position.x;
			tempPoint.y = PBE.mainStage.mouseY - gameOffset.y - PBE.scene.position.y;
			IsoRenderer.screenToIso(tempPoint);
			tempPoint.x = int(tempPoint.x);
			tempPoint.y = int(tempPoint.y);

			// проверить, лежит ли позиция в пределах игрового поля
			var mustBeVisible:Boolean = tempPoint.x >= 0 && tempPoint.x < levelSize.x
									 && tempPoint.y >= 0 && tempPoint.y < levelSize.y
									 && PBE.processManager.isTicking;

			if(mouseTileVisible != mustBeVisible || tempPoint.x != mouseTile.x || tempPoint.y != mouseTile.y)
			{
				mouseTileVisible = mustBeVisible;
				mouseTile.x = tempPoint.x;
				mouseTile.y = tempPoint.y;
				update();
			}

		}

		private function onHeroDestinationChanged(event:Event):void {
			var destination:Point = heroMoverRef.destination;
			if(
				(destination == null && destinationTileVisible)
				||
				(destination != null && (!destinationTileVisible ||
						(int(destination.x) != int(destinationTile.x) || int(destination.y) != int(destinationTile.y))))
			)
			{
				if(destination == null || !PBE.processManager.isTicking)
				{
					destinationTileVisible = false;
				}
				else
				{
					destinationTileVisible = true;
					destinationTile.x = int(destination.x);
					destinationTile.y = int(destination.y);
				}
				update();
			}
		}

		override protected function onRemove():void {
			super.onRemove();

			//IsoCameraController.getInstance().removeCallback(onCameraMoved);
			clearListeners();
			heroSpatialRef = null;
			heroMoverRef = null;
			var hero:IEntity = PBE.lookupEntity('Hero');
			if(hero)
			{
				hero.eventDispatcher.addEventListener(IsoMover.DESTINATION_CHANGED, onHeroDestinationChanged)
			}
			clearGraphic();
			InitializeManager.unbindRestartLevel(onLevelRestart);
		}

		private function clearListeners():void
		{
			PBE.inputManager.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			PBE.mainStage.removeEventListener(Event.MOUSE_LEAVE, onMouseOut);
		}

		private function clearGraphic():void
		{
			shape.graphics.clear();
		}

		private function update():void
		{
			clearGraphic();

			if(mouseTileVisible)
			{
				// ориентировочно определяем, проходим ли тайл:
				var tileAvailable:Boolean = (IsoSpatialManager.instance.mapPath.getTileAt(mouseTile).mask & PathBits.GRASS) > 0
				drawRect(mouseTile, tileAvailable ? 0xeeFFee : 0xFF5555);
			}
			if(destinationTileVisible)
				drawRect(destinationTile, 0x5555FF);
		}

		private function drawRect(tile:Point, color:uint):void
		{
			tempPoint.x = tile.x;
			tempPoint.y = tile.y;

			IsoRenderer.isoToScreen(tempPoint);

			var g:Graphics = shape.graphics;
			g.lineStyle(1, color);
			g.beginFill(color, 0.3);
			g.drawRect(tempPoint.x, tempPoint.y,  Config.TILE_WIDTH, Config.TILE_HEIGHT);
		}

		private function onCameraMoved(shift:Point):void {
			shiftPoint.x = shift.x;
			shiftPoint.y = shift.y;
		}

		private function findHeroSpatialRef():void {
			var hero:IEntity = PBE.lookupEntity('Hero');
			if(hero)
			{
				heroSpatialRef = hero.lookupComponentByName('Spatial') as IsoSpatial;
				heroMoverRef = hero.lookupComponentByName('Mover') as IsoMover;
				hero.eventDispatcher.addEventListener(IsoMover.DESTINATION_CHANGED, onHeroDestinationChanged)
			}
		}
	}
}
