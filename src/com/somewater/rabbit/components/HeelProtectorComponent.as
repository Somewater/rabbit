package com.somewater.rabbit.components {
	import com.pblabs.engine.components.ThinkingComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.util.RandomizeUtil;

	import flash.events.Event;
	import flash.geom.Point;

	/**
	 * "Защищает пятки"
	 * Т.е. препятствует тому, что несколько персонажей, движимые одним алгоритмом, гонятся за жертвой синхронно и
	 * визуально сливаются в одно пятно (наступая друг другу на пятки)
	 */
	public class HeelProtectorComponent extends ThinkingComponent{

		private var spatialRef:IsoSpatial;
		private var objectMaskRef:PropertyReference = new PropertyReference('@Spatial._objectMask');
		private var pauseRef:PropertyReference = new PropertyReference('@Mover.paused');

		/**
		 * На сколько ms застыть, чтобы не допустить наступание на пятки
		 */
		public var minCoolDown:int = 50;
		public var maxCoolDown:int = 100;

		public function HeelProtectorComponent() {
		}

		override protected function onAdd():void {
			super.onAdd();

			owner.eventDispatcher.addEventListener(IsoMover.TILE_CHANGED, onTileChanged);
		}

		override protected function onRemove():void {
			super.onRemove();

			spatialRef = null;
			owner.eventDispatcher.removeEventListener(IsoMover.TILE_CHANGED, onTileChanged);
		}

		protected function onTileChanged(event:Event):void {
			if(spatialRef == null)
				spatialRef = owner.lookupComponentByName('Spatial') as IsoSpatial;

			// проверить, нет ли в достигнутом тайле других персонажей такого же темплейта и, если есть, замереть
			var brothers:Array = [];
			if(IsoSpatialManager.instance.getObjectsUnderPoint(spatialRef.tile, brothers, spatialRef.objectMask))
			{
				if(brothers.length == 1 && brothers[0] == spatialRef)
					return;// нашел только самого себя в тайле

				// надо как то сместиться, чтобы не наступать на "пятки" собратьев
				owner.setProperty(pauseRef, true);
				think(onDecoolDown, minCoolDown + (maxCoolDown - minCoolDown) * RandomizeUtil.rnd);
			}
		}

		private function onDecoolDown():void
		{
			if(owner)
			{
				owner.setProperty(pauseRef, false);
			}
		}
	}
}
