package com.somewater.rabbit.util
{
	import flash.geom.Point;

	public class GeomUtil
	{
		public function GeomUtil()
		{
		}
		
		/**
		 * Найти точки пересечения откружности и отрезка, заданного 2-мя точками
		 * @return array of Point | null
		 */
		public static function circlePartInrersections(center:Point, radius:Number,
				partS:Point, partF:Point):Array
		{
			const EPS:Number = 0.01;
			
			var cX:Number = center.x;
			var cY:Number = center.y;
			
			var sX:Number = partS.x - cX;
			var sY:Number = partS.y - cY;
			var fX:Number = partF.x - cX;
			var fY:Number = partF.y - cY;
			
			var dx:Number = fX - sX;
			var dy:Number = fY - sY;
			
			// wolfram
			var D:Number = sX * fY - fX * sY;
			var dr2:Number = dx * dx + dy * dy;
			var descriminant:Number = radius * radius * dr2 - D * D;
			if(descriminant < 0)
				return null;// no intersections
			else if((descriminant<0?-descriminant:descriminant) < 1)// eps=0.01
			{
				// tangent
				return [new Point(D * dy / dr2 + cX, -D * dx / dr2 + cY)];
			}else{
				var desc_sqrt:Number = Math.sqrt(descriminant);
				
				var x1:Number = D * dy + ((dy<0?-1:1) * dx * desc_sqrt);
				var x2:Number = D * dy - ((dy<0?-1:1) * dx * desc_sqrt);
				var y1:Number = - D * dx + ((dy<0?-dy:dy) * desc_sqrt);
				var y2:Number = - D * dx - ((dy<0?-dy:dy) * desc_sqrt);
				
				var result:Array = [];
				
				// в сущности простая, но очень некрасивая проверка на нахождение точки пересечения внутри 
				// заданного отрезка (а не просто на прямой, образуемой отрезком)
				var p:Point = new Point(x1/dr2, y1/dr2);
				if(!((dx<0?-dx:dx) > EPS && (p.x < (sX < fX?sX:fX) || p.x > (sX > fX?sX:fX)))
					&& !((dy<0?-dy:dy) > EPS && (p.y < (sY < fY?sY:fY) || p.y > (sY > fY?sY:fY))))
				{
					p.x += cX;
					p.y += cY;
					result.push(p);
				}
				
				p = new Point(x2/dr2, y2/dr2);
				if(!((dx<0?-dx:dx) > EPS && (p.x < (sX < fX?sX:fX) || p.x > (sX > fX?sX:fX)))
					&& !((dy<0?-dy:dy) > EPS && (p.y < (sY < fY?sY:fY) || p.y > (sY > fY?sY:fY))))
				{
					p.x += cX;
					p.y += cY;
					result.push(p);
				}
				
				return result;
			}
		}
	}
}