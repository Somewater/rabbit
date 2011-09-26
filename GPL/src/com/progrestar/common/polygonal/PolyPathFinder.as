package com.progrestar.common.polygonal{
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import pl.bmnet.gpcas.geometry.Poly;
	import pl.bmnet.gpcas.geometry.PolyDefault;
	
	
	[Event(name="pathFound", type="com.astar.AstarEvent")]
	
	[Event(name="pathNotFound", type="com.astar.AstarEvent")]
	
	public class PolyPathFinder extends EventDispatcher 
	{
		
		private var _map:PolyDefault; 
		
		public function PolyPathFinder()
		{
			
		}
		
		public function clear():void
		{
			_map.clear();
			_map = null;
		}
		
		public function setMap(map:PolyDefault):void
		{
			_map = map;
		}
		
		
		public function getPath(item : PathRequest):void
		{
			var t:uint = getTimer();
			var path:Array;
			
			trace("Is point inside = " + item.map.isPointInside(item.start));
			
			path = solveMainPath(item.start, item.end, item.map);

			path.unshift(item.start);
			path.push(item.end);
			
			var event:PolyPathFinderEvent = new PolyPathFinderEvent(PolyPathFinderEvent.PATH_FOUND, path, item);
			
			trace("*****************\n" + ("path calc time = " + (getTimer() - t)) + "\n*****************");
			
			dispatchEvent(event);
		}
		
		/**
		 * Найти пересечение 2-х отрезков V1[S1, F1] и V2[S2, F2]
		 * 
		 */
		public function cross(S1:Point,F1:Point,S2:Point,F2:Point):Point
		{
			var Z:Number  = (F1.y-S1.y)*(S2.x-F2.x)-(S2.y-F2.y)*(F1.x-S1.x);
			var Ca:Number = (F1.y-S1.y)*(S2.x-S1.x)-(S2.y-S1.y)*(F1.x-S1.x);
			var Cb:Number = (S2.y-S1.y)*(S2.x-F2.x)-(S2.y-F2.y)*(S2.x-S1.x);
			if( (Z == 0)&&(Ca == 0)&&(Cb == 0) )
			{
				return null;//Same line
			}
			if( Z == 0 )
			{
				return null;//Paralel
			}
			var Ua:Number = Ca/Z;
			var Ub:Number = Cb/Z;
			if( (0 <= Ua)&&(Ua <= 1)&&(0 <= Ub)&&(Ub <= 1) )
			{
				return new Point(S1.x+(F1.x-S1.x)*Ub,S1.y+(F1.y-S1.y)*Ub);
				//				if((Ua==0)||(Ua==1)||(Ub==0)||(Ub==1)) return null//On tail
			}
			else
			{
				return null;//Cross outside
			}
			
			return null;
		}
		
		
		public function solveMainPath(S:Point, F:Point, poly:Poly):Array
		{
			var result:Array = [];
			var penetrations:Array = solvePath(S, F, poly); 
			var i:int;
				
			// сортитовать, чтобы отрезки пути шли по порядку
			penetrations.sort(function(a:Penetration, b:Penetration):Number {
				var ap:Point = a.S;
				var bp:Point = b.S;
				var dist:Number = Math.abs(S.x - ap.x) - Math.abs(S.x - bp.x);
				if(dist < 0) 
					return -1;
				else if(dist == 0)
					return Math.abs(S.y - ap.y) - Math.abs(S.y - bp.y);
				else return 1;
			});
			var innerPolyCount:uint = penetrations.length;
			var lastPoint_dx:Number;
			var lastPoint_dy:Number;
			var lastPenetration:Penetration;
			
			var temp:Array = [];
			
			for(i = 0;i<innerPolyCount;i++)
			{
				var penetration:Penetration = penetrations[i];
				var p:Point;
				if(i == 0){
					p = penetration.F;
					lastPoint_dx = Math.abs(S.x - p.x);
					lastPoint_dy = Math.abs(S.y - p.y);
				}else{
					p = penetration.S;
					if(	lastPenetration && 
								lastPenetration.poly == penetration.poly ){						
						lastPenetration.F = penetration.F;
						lastPoint_dx = Math.abs(S.x - lastPenetration.F.x);
						lastPoint_dy = Math.abs(S.y - lastPenetration.F.y);
						continue;
					}else if(Math.abs(S.x - p.x) < lastPoint_dx || 
						Math.abs(S.y - p.y) < lastPoint_dy ){
						// fatal error
						continue;
					}else{
						p = penetration.F;
						lastPoint_dx = Math.abs(S.x - p.x);
						lastPoint_dy = Math.abs(S.y - p.y);
					}
				}
				
				temp.push(penetration);
					//result.concat(findLocalPath(penetration.S, penetration.F, penetration.poly, penetration.indexDictionary));
				lastPenetration = penetration;
			}
			
			for(i = 0; i<temp.length;i++)
			{
				lastPenetration = temp[i];
				result = result.concat(findLocalPath(lastPenetration.S, lastPenetration.F, lastPenetration.poly, lastPenetration.indexDictionary));
				lastPenetration.clear();
			}
			
			return result;
		}
		
		
		
		/**
		 * Найти точки пересечения прямой и многоугольника
		 */
		public function solvePath(S:Point, F:Point, poly:Poly):Array
		{
			var innerPolyCount : int = poly.getNumInnerPoly();
			if (innerPolyCount>1){
				var innerPoly : Poly;
				var innerResults:Array = [];
				for (var i:int = 0; i<innerPolyCount; i++){
					innerPoly = poly.getInnerPoly(i);
					
					innerResults = innerResults.concat(solvePath(S,F,innerPoly));
				}
				return innerResults;
			}
			else{
				return solvePathInSimplePoly(S, F, poly);
			}
		}
		
		
		
		public function solvePathInSimplePoly(S:Point, F:Point, poly:Poly):Array{
			var result:Array = [];
			
			var pointsCount : int = poly.getNumPoints();
			var intersectPointIndex:Dictionary = new Dictionary();// хранить порядковые номера точек многогранника, отрезок которых пересек отрезок S-F
			var lastPoint:Boolean;
			var i:int;
			var p1:Point;
			var p2:Point;
			for (i = 0; i<pointsCount;i++){
				p1 = poly.getPoint(i);
				lastPoint = i == pointsCount-1;// явлияется ли рассматриваемая точка многоугольника последней
				p2 = poly.getPoint(lastPoint?0:i + 1);
				var intersect:Point = cross(S, F, p1, p2);
				if(intersect)
				{
					result.push(intersect);
					intersectPointIndex[intersect] = i | (lastPoint?0x80000000:0);// выставить старший бит в 1, если теущая точка многоугольника последняя (т.е. если вторая точка нулевая, а не i+1)
				}
			}
			
			if(result.length == 0) return result;
			if(result.length & 1) throw new Error("Path not found", 1);
			// видимо есть пересчения, придется их разбирать
			

			result.sort(function(a:Point, b:Point):Number {
				var dist:Number = Math.abs(S.x - a.x) - Math.abs(S.x - b.x);
				if(dist < 0) 
					return -1;
				else if(dist == 0)
					return Math.abs(S.y - a.y) - Math.abs(S.y - b.y);
				else return 1;
			});
			
			var temp:Array = [];
			for(i = 0;i<result.length;i += 2)
			{
				temp.push(new Penetration(result[i], result[i + 1], poly, intersectPointIndex));
			}
			
			return temp;
		}
		
		
		/**
		 * Получив отрезок S-F и простой многоугольник poly, просчитать оптимальный путь обхода многоугольника
		 * S, F лежать на гранях многоугольника
		 */
		public function findLocalPath(S_near:Point, F_near:Point, poly:Poly, intersectPointIndex:Dictionary):Array
		{
			var result:Array = [];
			
			var pointsCount:int = poly.getNumPoints();
			
			var S_near_p1:uint = intersectPointIndex[S_near];
			var lastPoint:Boolean = (S_near_p1 & 0x80000000);
			var S_near_p2:uint = lastPoint?0:S_near_p1 + 1;if(lastPoint) S_near_p1 &=  0x7FFFFFFF;
			
			var F_near_p1:uint = intersectPointIndex[F_near];
			lastPoint = (F_near_p1 & 0x80000000); if(lastPoint) F_near_p1 &=  0x7FFFFFFF;
			var F_near_p2:uint = lastPoint?0:F_near_p1 + 1;
			
			var CW:Number = dist2(F_near, poly.getPoint(F_near_p1));
			var p1:Point = S_near;
			var p2:Point;
			var CW_path:Array = [S_near];
			
			var i:int = S_near_p2;
			while(i != F_near_p2)
			{
				p2 = poly.getPoint(i);
				CW +=dist2(p1, p2);
				i++;
				if(i == pointsCount) i = 0;
				p1 = p2;
				CW_path.push(p1);
			}
			
			
			var CCW:Number = dist2(F_near, poly.getPoint(F_near_p2));
			p1 = S_near;
			var CCW_path:Array = [S_near];
			
			i = S_near_p1;
			while(i != F_near_p1)
			{
				p2 = poly.getPoint(i);
				CCW +=dist2(p1, p2);
				i--;
				if(i < 0) i = pointsCount - 1;
				p1 = p2;
				CCW_path.push(p1);
			}
			
			if(CW < CCW)
				result = CW_path;
			else
				result = CCW_path;
			
			result.push(F_near);
			
			return result;
			
			function dist2(p1:Point, p2:Point):Number
			{
				var dx:Number = Math.abs(p1.x - p2.x);
				dx *= dx;
				var dy:Number = Math.abs(p1.y - p2.y);
				dy *= dy;
				return dx + dy;
			}
		}
		
		
		/**
		 * Из набора точек найти две: ближайшую к начальнуй и ближайшую к конечной
		 */
		private var S_near:Point;// хранит значения работы функции getNearestPoints
		private var F_near:Point;
		public function getNearestPoints(S:Point, F:Point, points:Array):void
		{
			var p:Point;
			if(points.length == 2){
				// простой алгоритм поиска
				F_near = points[0];
				S_near = points[1];
				var dx:Number = Math.abs(F_near.x - F.x) - Math.abs(S_near.x - F.x);
				if(dx < 0)
					return;
				else if (dx > 0)
				{
					p = S_near;
					S_near = F_near;
					F_near = p;
				}
				else if(Math.abs(F_near.y - F.y) < Math.abs(S_near.y - F.y))
					return;
				else
				{
					p = S_near;
					S_near = F_near;
					F_near = p;
				}
			}else{
				var F_near_dx:Number;
				var F_near_dy:Number;
				var S_near_dx:Number;
				var S_near_dy:Number;
				var counter:int = points.length;
				
				for(var i:int = 0;i<counter;i++)
				{
					p = points[i];
					if(i == 0){
						F_near_dx = Math.abs(F.x - p.x);
						F_near_dy = Math.abs(F.y - p.y);
						S_near_dx = Math.abs(S.x - p.x);
						S_near_dy = Math.abs(S.y - p.y);
						F_near = p;
						S_near = p;
					}else{
						var dist:Number = Math.abs(F.x - p.x);
						if(dist < F_near_dx)
						{
							F_near = p;
							F_near_dx = dist;
							F_near_dy = Math.abs(F.y - p.x);
							continue;
						}else if(dist == F_near_dx){
							// проверить по y
							dist = Math.abs(F.y - p.y);
							if(dist < F_near_dy){
								F_near = p;
								F_near_dy = dist;
								continue;
							}
						}
						dist = 	Math.abs(S.x - p.x);
						if(dist < S_near_dx)
						{
							S_near = p;
							S_near_dx = dist;
							S_near_dy = Math.abs(S.y - p.x);
							continue;
						}else if(dist == S_near_dx){
							// проверить по y
							dist = Math.abs(S.y - p.y);
							if(dist < S_near_dy){
								S_near = p;
								S_near_dy = dist;
								continue;
							}
						}
					}
				}// end cycle
			}			
		}// end getNearestPoints
		
		
		/**
		 * Найти траекторию "обхода" многоугольника. Многоугольник должен быть без вложенных многоугольников!
		 */
		public function findRoundPath(S:Point, F:Point, poly:Poly):Array
		{
			var result:Array = [];
			
			if(poly.getNumInnerPoly() > 1) throw new Error("Fatal error");
			
			// TODO
			
			return result;
		}
	}	
}
import flash.geom.Point;
import flash.utils.Dictionary;

import pl.bmnet.gpcas.geometry.Poly;


class Penetration{
	
	public var S:Point;
	public var F:Point;
	public var poly:Poly;
	public var indexDictionary:Dictionary;
	
	public function Penetration(S:Point, F:Point, poly:Poly, indexDictionary:Dictionary):void
	{
		this.S = S;
		this.F = F;
		this.poly = poly;
		this.indexDictionary = indexDictionary;
	}
	
	public function clear():void
	{
		S = null;
		F = null;
		poly = null;
		indexDictionary = null;
	}
	
	public function calculate():Array
	{
		return null;
	}
}