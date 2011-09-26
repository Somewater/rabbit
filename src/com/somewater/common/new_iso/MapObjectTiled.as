package com.somewater.common.new_iso
{
	
	import com.somewater.utils.Profiler;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import com.somewater.rabbit.iso.IsoObject;
	
	/**
	 * Элементарный объект, который можно разместить на карте
	 * Обеспеивает обновление различных тайловых массивов контейнера, 
	 * а также хранит переменные, отвечающие за то, куда можно поставить объект (какие тайлы для него проходимы) 
	 * 
	 * Класс как таковой не может в чистом виде применяться на карте, т.к. его функция refreshRegistration() описана, 
	 * однако автоматически при смене позиции не вызывается
	 * @author mister
	 */
	public class MapObjectTiled extends IsoObject
	{
		public var flip:Boolean;
		
		/**
		 *	Маска направления. (основной комментарий пока в isoMover)
		 * 	Сейчас используется при движении isoMover (выбор анимационного состояния),
		 * 	при определении позиции тайла в maskAnalyzer и MapBase.TileIsFree,
		 * 	при движении в CameraDragController.
		 */		
		public static const BOTTOM:int = 1;
		public static const TOP:int = 2;		
		public static const RIGHT:int = 4;
		public static const LEFT:int = 8;
				
		/**
		 *	Маска проходимости 
		 */		
		public static const TYPE_GROUND:uint = 1;
		public static const TYPE_ROAD:uint = 2;
		public static const TYPE_OBJECT:uint = 4;
		public static const TYPE_WATER:uint = 8;
		
		/**
		 * Специальный тип - место куда программа может поставить, а человек нет.
		 */		
		public static const TYPE_MOUNTAIN:uint = 16;
		public static const TYPE_THRESHOLD:uint = 32;
		
		
		/**
		 *	На чем объект может стоять
		 * 	<li>1 - земля</li>
		 * 	<li>2 - дорога</li>
		 * 	<li>4 - объект на карте</li>
		 * 	<li>8 - вода</li>
		 * 	<li>16 - горы (пока не реализовано)</li>
		 */	
		public var pathMask:uint = 0;
		
		/**
		 *	Значения маски для данного объекта 
		 * 	из маски pathMask.  
		 */		
		public var maskType:uint = 0;
		
		/**
		 *	Имеет ли объект обрамление 
		 */		
		public var hasBorder:Boolean = false;
		
		/**
		 *	Нужно ли обновлять карту проходимости ? 
		 */		
		protected var updateReachableMap:Boolean = false;
		
		public function get isActive():Boolean
		{
			return _isActive;
		}

		public function set isActive(value:Boolean):void
		{
			_isActive = value;
		}

		/**
		 * Является ли объект проницаемым 
		 */		
		public function get ghost():Boolean
		{
			return _pWidth == 0 && _pHeight == 0;
		}
		
		public function set ghost(value:Boolean):void
		{
			if(value)
				_pWidth = _pHeight = 0;
			
			// must be overrided
		}
		
		protected var _isActive:Boolean;
				
		public function MapObjectTiled(mc:MovieClip=null)
		{
			super(mc);
		}
		
		/**
		 * Обновление карты по нынешней позиции объекта.
		 */		
		public function refreshMap():void{			
			if(position != null && !ghost)
				refreshRegistratin(position.x, position.y, position.right, position.bottom);
		}
		
		/**
		 * Обновляет записи об объекте в разнообразных массивах его контейнера (objectsOnTile и pathFindingMap)
		 * Старое значение позиции и размера объекта содержится в _position
		 */
		protected function refreshRegistratin(newX:Number, newY:Number, newRight:Number, newBottom:Number):void{
						
			Profiler.enter("MapObjectTiled.refreshRegistratin");
			
			var map:MapBase = parentGameObject as MapBase;

			if(map)
			{
				var w:int = map.position.width;
				var h:int = map.position.height;
				var one:int = int(hasBorder);
				
				var xPos:int;
				var yPos:int;
				var stopX:int = Math.ceil(_position.right) + (_position.x<w?one:0); // очистка от опустевшего бордюра
				var stopY:int = Math.ceil(_position.bottom) + (_position.y<h?one:0);
				// обновить старое место
				xPos = _position.x - (_position.x>0?one:0);	
				
				do{
					yPos = _position.y  - (_position.y>0?one:0);
					do{
						map.unregisteredTilesQueue[xPos + (yPos << 16)] = true;
						
						if(updateReachableMap)
							map.unregisteredReachableTilesQueue[xPos + (yPos << 16)] = true;
							
						var objects:Array = map.objectsOnTile[xPos][yPos];
						objects.splice(objects.indexOf(this),1);
						yPos++;
					}while(yPos < stopY)
					xPos++;
				}while(xPos < stopX)
				
				if(ghost)
				{
					Profiler.exit("MapObjectTiled.refreshRegistratin");
					return;
				}

				// обновить новое место
				stopX = Math.ceil(newRight);
				stopY = Math.ceil(newBottom);	
				xPos = newX;
				
				do{
					yPos = newY;
					do{
						if(map.objectsOnTile[xPos][yPos].indexOf(this) == -1)
						{
							map.unregisteredTilesQueue[xPos + (yPos << 16)] = true;
													
							if(updateReachableMap)
								map.unregisteredReachableTilesQueue[xPos + (yPos << 16)] = true;
							
							map.objectsOnTile[xPos][yPos].push(this);
						}
						yPos++;
					}while(yPos < stopY)
					xPos++;
				}while(xPos < stopX);
			}
			
			Profiler.exit("MapObjectTiled.refreshRegistratin");
		}
		
		/**
		 * Возвращает маску движения.
		 */		
		public static function getDirectionMask(_x:Number, _y:Number):int
		{
			return (_x>0?RIGHT:(_x<0?LEFT:0))+(_y>0?BOTTOM:(_y<0?TOP:0));
		}
		
		public static function isReachableDirection(moverSearchDirection:int, tilePositionMask:int):Boolean
		{
			return (moverSearchDirection & IsoMover.HORIZONTAL && 
				(tilePositionMask == LEFT || tilePositionMask == RIGHT)) ||
				(moverSearchDirection & IsoMover.VERTICAL && 
					(tilePositionMask == TOP || tilePositionMask == BOTTOM)) ||
				(moverSearchDirection & IsoMover.DIAGONAL && 
					(tilePositionMask == BOTTOM + RIGHT || tilePositionMask == TOP + LEFT));
			
		}
		
		/**
		 * Определяет доступность тайла по отношению к муверу по
		 * координате Z, по направлению движения к много тайловым объектам, 
		 * по направлению движения игрока и заполненности тайла.
		 */		
		public static function checkTileIsReachable(tile:MapPathTile, mover:IsoMover, tilePositionMask:int):Boolean
		{			
			if (tilePositionMask == 0 || isReachableDirection(mover.searchDirection, tilePositionMask))
			{				
				// первая проверка по типу тайла
				if(!checkTileIsAvailable(mover.pathMask, tile.pathMask))
					return false;
				
				// если высота больше, то просто перешагиваем
				// пример: человек через пенёк
				if(tile.objectZ < mover.objectZ)
					return true;
						
				// проверка по направлениям
				if(tile.directionMask != 0) {
					if(tilePositionMask == TOP + LEFT)
						return false;
					if(tilePositionMask == TOP && (tile.directionMask & MapObjectTiled.RIGHT))
						return false;
					if((tilePositionMask == LEFT + BOTTOM || tilePositionMask == LEFT) && 
						(tile.directionMask & MapObjectTiled.BOTTOM))
						return false;
				}
				
				if(tile.topLeft.x != 1 && tile.topLeft.y != 1)
				{
					// если в тайле что-то есть 
					// значит по диагонали пройти нельзя
					if((tilePositionMask & LEFT || tilePositionMask & RIGHT) &&
						(tilePositionMask & TOP || tilePositionMask & BOTTOM))
						return false;
					
					// вертикальное движение
					if((tilePositionMask == TOP || tilePositionMask == BOTTOM) && 
						mover.pBottomRight.x > tile.topLeft.x)
						return false;
					
					// горизонтальное движение
					if((tilePositionMask == LEFT || tilePositionMask == RIGHT) && 
						mover.pBottomRight.y > tile.topLeft.y)
						return false;
				}
				else
					return false;
				
				return true;
			}
			else
				return false;
		}
		
		/**
		 * Определяет доступность тайла по маске типа тайла и по вмещаемости тайла.
		 */		
		public static function checkTileIsAvailable(mask1:uint, mask2:uint, 
													object1BottomRight:Point=null, object2TopLeft:Point=null):Boolean
		{
			// если маска нулевая, то тайл свободен.
			// Для дорог есть отдельное значение в pathMask.
			if(mask2 == 0)
				return true;
			
			// проверка по маскам типов тайла
			if(!(mask1 & mask2))
				return false;
			
			
			// если предыдущие проверки пройдены, 
			// то смотрим может ли объект разместиться в выбранном тайле
			if(object2TopLeft && object1BottomRight && object1BottomRight > object2TopLeft)
				return false;

			return true;
		}
	}
}