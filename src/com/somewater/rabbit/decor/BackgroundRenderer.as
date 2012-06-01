package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.IAnimatedObject;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;

	import flash.display.Graphics;

	import flash.display.Shape;
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
		private var shiftPoint:Point = new Point();
		private var tempPoint:Point = new Point();

		public function BackgroundRenderer() {
			super();
			registerForUpdates = false;

			shape = new Shape();
			displayObject = shape;
		}

		override protected function onAdd():void {
			super.onAdd();

			IsoCameraController.getInstance().addCallback(onCameraMoved);

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
			onMouseInputChanged();
		}

		private function onMouseInputChanged():void {
			if(Config.application.mouseInput)
			{
				// показывать указатели на кролика
				PBE.inputManager.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				PBE.inputManager.addEventListener(MouseEvent.CLICK, onMouseClick);
			}
			else
			{
				// не показывать указатели, убить листенеры
				shape.graphics.clear();

				PBE.inputManager.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				PBE.inputManager.removeEventListener(MouseEvent.CLICK, onMouseClick);
			}
		}

		private function onMouseClick(event:MouseEvent):void {
			var tile:Point = IsoRenderer.screenToIso(new Point(PBE.mainStage.mouseX - PBE.scene.position.x,
															   PBE.mainStage.mouseY - PBE.scene.position.y));
			tile.x = int(tile.x);
			tile.y = int(tile.y);
			drawRect(tile, 0xFF0000);
		}

		private function onMouseMove(event:MouseEvent):void {
			var tile:Point = IsoRenderer.screenToIso(new Point(PBE.mainStage.mouseX - PBE.scene.position.x,
															   PBE.mainStage.mouseY - PBE.scene.position.y));
			tile.x = int(tile.x);
			tile.y = int(tile.y);
			shape.graphics.clear();
			drawRect(tile, 0x0000FF);
		}

		override protected function onRemove():void {
			super.onRemove();

			IsoCameraController.getInstance().removeCallback(onCameraMoved);

			heroSpatialRef = null;
		}

		private function drawRect(tile:Point, color:uint):void
		{
			if(heroSpatialRef == null)
				findHeroSpatialRef();

			if(heroSpatialRef == null)
				return;

			tempPoint.x = tile.x;
			tempPoint.y = tile.y;

			IsoRenderer.isoToScreen(tempPoint);

			var g:Graphics = shape.graphics;
			g.beginFill(color);
			g.drawRect(tempPoint.x, tempPoint.y,  Config.TILE_WIDTH, Config.TILE_HEIGHT);
		}

		private function onCameraMoved(shift:Point):void {
			shiftPoint.x = shift.x;
			shiftPoint.y = shift.y;
		}

		private function findHeroSpatialRef():void {
			var hero:IEntity = PBE.lookupEntity('Hero');
			if(hero)
				heroSpatialRef = hero.lookupComponentByName('Spatial') as IsoSpatial;
		}
	}
}
