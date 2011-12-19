package com.somewater.rabbit.components {
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoSpatial;

	/**
	 * Ищет жертву только в видимой игроку области карты
	 */
	public class ObviousHunterComponent extends HunterComponent{
		public function ObviousHunterComponent() {
		}


		override protected function searchVictims(radius:Number = NaN):Array {
			var victims:Array = super.searchVictims(radius);
			// исключаем из поиска персонажей, лежащих за пределами видимости
			var victimsInScene:Array = [];
			for (var i:int = 0; i < victims.length; i++) {
				var isoSpatial:IsoSpatial = victims[i];
				if(IsoCameraController.getInstance().isoSpatialInViewArea(isoSpatial))
					victimsInScene.push(isoSpatial)
			}
			return victimsInScene;
		}
	}
}
