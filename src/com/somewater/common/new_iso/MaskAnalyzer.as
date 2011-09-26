package com.somewater.common.new_iso
{
	import com.astar.Analyzer;
	import com.astar.IMap;
	import com.astar.IPositionTile;
	
	import flash.geom.Point;
	
	/**
	 * 
	 * @author mister
	 * 
	 */
	public class MaskAnalyzer extends Analyzer
	{
		/**
		 *	Ссылка на мувера 
		 */		
		public var mover:IsoMover;
		
		/**
		 * размер объекта, для которого выискивается путь
		 * (если null значит тонкий мувер (0, 0))
		 */
		public var size:Point;
		
		/**
		 * Массив точек, которые также непроходимы, хотя по карте проходимости они могут быть проходимы
		 */
		public var exclude:Array;
			
		public function MaskAnalyzer()
		{
			super();
		}
		
		override public function getTileInterface():Class{
			return MapPathTile;
		}
		
		/**
		 *	Маска идентификации блока
		 * <code>
		 * 	  8  16 32
		 * 	1 +	 +  +
		 * 	2 +  +  +
		 * 	4 +  +  +
		 * 
		 * </code>
		 */		
		private var tilePositionMask:int = 0;
		
		/**
		 * Анализирует проходимость пути на основе масок
		 * @return тайл проходим
		 */
		override public function analyzeTile(mainTile:*):Boolean{
			
			if(exclude)
				for(var i:int = 0;i<exclude.length;i++)
					if(Point(exclude[i]).equals(IPositionTile(mainTile).getPosition()))
						return false;
			
			if(mainTile is MapPathTile)
			{
				var tile:MapPathTile = mainTile as MapPathTile;
				// если праверка без известного направления, то просто проверяем доходим ли тайл в принципе
				if(tilePositionMask == 0)
					return (tile.reachableType == 1); 
				else
					return MapObjectTiled.checkTileIsReachable(tile, mover, tilePositionMask);
			}
			else
				return true;
		}
		
		override protected function analyze(mainTile:*, allNeighbours:Array, neighboursLeft:Array, map:IMap):Array {
			
			var i:int = 0;
			
			var mainPos:Point = IPositionTile(mainTile).getPosition();
			
			var selfTile:MapPathTile = mainTile as MapPathTile;
			
			cycle:
			while(i < neighboursLeft.length) {
				
				var pos:Point = IPositionTile(neighboursLeft[i]).getPosition();
				
				// определение позиции блока 
				//(нумерации в массивах не приходиться доверять)
					
				tilePositionMask = MapObjectTiled.getDirectionMask(pos.x-mainPos.x, pos.y-mainPos.y);
				//MapObjectTiled.getTileDirectionMask(mainPos.x, mainPos.y, pos.x, pos.y);
				
				// если тайл в котором находиться персонаж содержит что либо, 
				// то по диагонали ходить нельзя
				if((selfTile.topLeft.x != 1 || selfTile.topLeft.y != 1))
				{
					// в собственном тайле что-то есть, 
					// то сразу отсекаем все диагональные направления
					if((tilePositionMask & MapObjectTiled.LEFT || tilePositionMask & MapObjectTiled.RIGHT) &&
						(tilePositionMask & MapObjectTiled.TOP || tilePositionMask & MapObjectTiled.BOTTOM))
					{
						neighboursLeft.splice(i, 1);
						continue cycle;
					}
				}
				
				if(selfTile.directionMask != 0)
				{
					if(
						(selfTile.directionMask & MapObjectTiled.LEFT && tilePositionMask == MapObjectTiled.BOTTOM + MapObjectTiled.RIGHT) ||
						(selfTile.directionMask & MapObjectTiled.BOTTOM && (tilePositionMask == MapObjectTiled.TOP + MapObjectTiled.RIGHT || tilePositionMask == MapObjectTiled.RIGHT) ) ||
						(selfTile.directionMask & MapObjectTiled.RIGHT && tilePositionMask & MapObjectTiled.BOTTOM)
					)
					{
						neighboursLeft.splice(i, 1);
						continue cycle;
					}
				}
				
				
				if(analyzeTile(neighboursLeft[i]))
				{
					// проверить размерных соседей
					if(size && size.length > 1){
						for(var dx:int = 0; dx<size.x; dx++)
							for(var dy:int = 0; dy<size.y; dy++)
								if (dx + dy != 0)
									if(!analyzeTile(map.getTileAt(new Point(pos.x + dx, pos.y + dy))))
									{
										neighboursLeft.splice(i, 1);
										continue cycle;// точка непроходима, потому что мувер толстый (хотя проходима для худого)
									}
						if(mover.searchDirection & IsoMover.DIAGONAL && mainPos.x != pos.x && mainPos.y != pos.y){
							// проверяем еще 2 точки во избежании поиска пути, у которого есть непроходимая диагональ
							var pp:Point = (mainPos.x > pos.x?pos:mainPos);
							var p1:Point = new Point(pp.x, pp.y + size.y);
							if(!analyzeTile(map.getTileAt(p1)))
							{ 
								neighboursLeft.splice(i, 1);
								continue cycle;
							}
							p1 = new Point(pp.x + size.x, pp.y);
							if(!analyzeTile(map.getTileAt(p1))){
								neighboursLeft.splice(i, 1);
								continue cycle;
							}
						}
						i++;// точка проходима даже для этого толстого мувера
					}else
						i++;
				}
				else
				{
					neighboursLeft.splice(i, 1);
					continue cycle;
				}
			}
			
			tilePositionMask = 0;
			return neighboursLeft;
		}
	}
}