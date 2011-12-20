package com.somewater.rabbit.components {
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.util.RandomizeUtil;

	import flash.geom.Point;

	/**
	 * При приближении объекта страха в поле видимости, заставляет персонаж бежать в рандомную точку
	 */
	public class CowardComponent extends FinderComponentBase{

		/**
		 * Для минимизации проверок врага поблизости
		 */
		private var age:uint = 0;

		public function CowardComponent() {
			registerForTicks = true;
		}


		override public function onTick(deltaTime:Number):void {
			if(age++ % 15 == 0)// каждый 15-й тик, т.е. 2 раза в секунду
				analyze();
		}

		override public function analyze():void {
			if(this._driving)
				return;// если уж бежим, то не отвлекаемся на другие ужосы

			var result:Array = this.searchVictims();
			if(result.length)
			{
				_port(getSense({"terrible":result[0]}, 'terrible'));
			}
		}

		override public function startAction(sense:SenseEvent):void
		{
			if(sense.data.hasOwnProperty("terrible"))
			{
				var tile:Point = IsoSpatial(owner.lookupComponentByName('Spatial')).tile
				var flightPoint:Point = RandomizeUtil.RandomTilePoint_near(tile) //IsoSpatial(sense.data.terrible).tile.clone();
				IsoMover(owner.lookupComponentByName("Mover")).setDestination(
									flightPoint, onFlightCompleted, onFlightCompleted);
			}
			else
			{
				_port(null);
			}
		}


		override public function breakAction():void
		{
			// остановить движение
			IsoMover(owner.lookupComponentByName("Mover")).destination = null;
		}

		// мы достигли или не достигли точки, куда убегаем, но процесс перемещения завершен по каккой-то причине
		private function onFlightCompleted():void
		{
			if(_port)
				_port(null);
		}
	}
}
