package com.progrestar.common.polygonal
{
	import flash.geom.Point;
	
	import pl.bmnet.gpcas.geometry.Poly;

	public class PathRequest
	{
		public var start:Point;
		public var end:Point;
		public var map:Poly;
		
		
		public function PathRequest(start:Point, end:Point, map:Poly)
		{
			this.start = start;
			this.end = end;
			this.map = map;
		}
	}
}