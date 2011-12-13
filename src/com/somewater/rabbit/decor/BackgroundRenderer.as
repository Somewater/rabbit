package com.somewater.rabbit.decor {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.IAnimatedObject;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.storage.Config;

	import flash.geom.Point;

	/**
	 * Управляет граундом игры
	 */
	public class BackgroundRenderer extends DisplayObjectRenderer{
		public function BackgroundRenderer() {
			super();
			registerForUpdates = false;
		}

		override protected function onAdd():void {
			super.onAdd();

			var levelWidth:int = IsoSpatialManager.instance.width;
			var levelHeight:int = IsoSpatialManager.instance.height;
			var levelSquare:int = levelWidth * levelHeight;

			for (var i:int = 0; i < int(levelSquare * 0.05); i++) {
				var grass:IEntity = PBE.templateManager.instantiateEntity('GroundGrassTemplate');
				grass.owningGroup = this.owner.owningGroup;
				grass.setProperty(new PropertyReference('@Spatial.position'),
						new Point(int(Math.random() * levelWidth * Config.TILE_WIDTH), Math.random() * levelHeight * Config.TILE_HEIGHT))
			}
		}
	}
}
