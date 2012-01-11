package com.somewater.rabbit.iso {
	import com.astar.BasicTile;

	import flash.geom.Point;

	public class PathItem {
		public function PathItem(_tile:BasicTile, _position:Point)
		{
			tile = _tile;
			position = _position
		}

		public function clear():void
		{
			tile = null;
			position = null;
		}

		public function toString():String
		{
			var tileS:String = tile?tile.toString():null;
			return tileS?
				(tileS.substr(0, tileS.length - 1) + (position?(", np:" + position.x.toFixed(2) + "," + position.y.toFixed(2)):"") + "]")
				:"[PathItem (empty)]";
		}

		public var marked:Boolean = false;// тайл уже был помечен объектом как занимаемый. Т.е. нельзя тестировать тайл на проходимость, потому что он занят - но занят текущим объектом
		public var tile:BasicTile;
		public var position:Point;// точка, в общем случае равная tile.position, но учитывающая размер объекта (центрование тонких муверов)
	}
}
