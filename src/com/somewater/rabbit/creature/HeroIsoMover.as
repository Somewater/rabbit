package com.somewater.rabbit.creature {
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.PathItem;

	import flash.geom.Point;

	/**
	 * IsoMover для героя, который управляется кнопками курсора
	 * Данная реализация всегда выбрасывает из найденного пути первую точку
	 * (что позволяет не ценрироваться персонажу в текущем тайле, а сразу идти в следующий)
	 */
	public class HeroIsoMover extends IsoMover{

		private var savedSpeed:Number

		public function HeroIsoMover() {
		}

		override protected function checkFirstPathPoint():void {
//			if(_destinationPath.length > 1)
//			{
//				var p:Point = _spatial.tile;
//				var fp:Point = PathItem(_destinationPath[0]).position;
//				if(p.x == int(fp.x) && p.y == int(fp.y))// если p и fp лежат в одном тайле
//					_destinationPath.shift();
//			}
			if(_destinationPath.length > 1)
				_destinationPath.shift();
		}

		public function pinHero():void {
			if(_speed){
				savedSpeed = _speed;
				_speed = 0;
			}
		}

		public function unpinHero():void {
			if(_speed == 0 && savedSpeed > 0){
				_speed = savedSpeed;
				savedSpeed = 0;
			}
		}
	}
}
