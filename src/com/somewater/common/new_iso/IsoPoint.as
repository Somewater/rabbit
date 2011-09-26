package com.somewater.common.new_iso
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Класс, хранящий пространственное положение IsoObject, в том числе его размер (!)
	 * Нативные переменные класса Rectangle хранят представление объекта при виде сверху (в системе отсчета tile, когда 1 - это величина 1го тайла)
	 * Возвращает координаты объекта в разных системах отсчета:
	 * <li>screen - привычная всем флешерам система экранных координат</li>
	 * <li>iso или тайловая - система координат при виде сверху (измеряется в тайлах!). Native свойства класса 
	 * Rectangle аналогичны iso - можно обращаться напрямую через них</li>
	 * @author mister
	 */
	public class IsoPoint extends Rectangle
	{
		public static function get Zero():IsoPoint
		{
			return new IsoPoint(new Rectangle(0,0,1,1));
		}
		
		/**
		 * Размер тайла в пикселях при виде сверху на тайл
		 */
		public static var TILE_SIZE:int = 50;
		
		/*
		 * Количество cell в пределах одного tile. Должно быть (натуральное число)^2
		 * Старшая часть номера ceil означает смещение по y внутри тайла, младшая означает смещение по x
		 * В пределах 1-го тайла больший cell означает первоочередный порядок прорисовки (перед другими)
		 *
		public static var CELL_QUANTITY:int = Math.pow(2, 2);// должно быть (натуральное число)^2 !!!
		*/
		
		// прочие константы
		public static const ISO_ANGLE:Number = Math.atan(0.5);// 26.565o угол при изометрии 2.5D, которая применяется в игре
		public static const ISO_ANGLE_TAN:Number = Math.tan(ISO_ANGLE);// 0.5
		public static const ISO_ANGLE_SIN:Number = Math.sin(ISO_ANGLE);// 0.447
		public static const DIV_ISO_ANGLE_SIN:Number = 1/ISO_ANGLE_SIN;
		public static const ISO_ANGLE_COS:Number = Math.cos(ISO_ANGLE);// 0.894
		public static const DIV_ISO_ANGLE_COS:Number = 1/ISO_ANGLE_COS;

		/**
		 * @param rectangle прямоугольник в системе отсчета iso, по которому назначаются свойства IsoPoint
		 */
		public function IsoPoint(rectangle:Rectangle = null)
		{			
			super();
			if(rectangle){
				x = rectangle.x;
				y = rectangle.y;
				width = rectangle.width;
				height = rectangle.height;
			}
		}
		
		/**
		 * Создать объект с теми же свойствами, что и текущий 
		 */
		override public function clone():Rectangle{
			return new IsoPoint(this);
		}
		
		/**
		 * Возвращает позицию объекта в iso системе отсчета
		 * (аналогично прямому вызову свойства topLeft)
		 */
		public function get position():Point{
			return topLeft;
		}
		public function set position(value:Point):void{
			topLeft = value;
		}
		
		/**
		 * Возвращает позицию объекта в тайловой системе отсчета (округляя до тайла, в котором располагается точка) 
		 */
		public function get tile():Point{
			return new Point(int(x), int(y));
		}		
		public function set tile(value:Point):void{
			topLeft = new Point(int(value.x),int(value.y));	
		}
		
		
		/**
		 * Положение в "экранных" координатах
		 */
		public function get screenPos():Point{
			return isoToScreen(topLeft.clone());
		}
		public function set screenPos(value:Point):void{			
			size = screenToIso(value.clone());
		}
		
		
		/**
		 * Прямоульник в координатах экрана (хранит в себе положение и размер одновременно)
		 */
		public function get screenRect():Rectangle{
			var _screenPos:Point = isoToScreen(topLeft.clone());
			return new Rectangle(_screenPos.x, _screenPos.y, width * TILE_SIZE, height * TILE_SIZE);
		}
		
		/**
		 * Прямоугольник объекта в тайловых координатах (хранит в себе положение и размер одновременно)
		 * Когда возможно, следует вызывать методы класса IsoPoint напрямую (intersection вместо tileRect.intersection)
		 */
		public function get tileRect():Rectangle{
			return new Rectangle(x, y, width, height);
		}
		
		/**
		 * Нативная функция возвращает false для пустого прямоугольника на границе текущего прямоугольника,
		 * в то же время аналогичная точка дает containsPoint(...) == true
		 * Переопределение решает указанную проблему
		 */
		override public function containsRect(rect:Rectangle):Boolean{
			if(rect.isEmpty())
				return containsPoint(rect.topLeft);
			else
				return super.containsRect(rect);
		}
		
		
		/**
		 * Из координат объекта с вида сверху (в тайловых координатах) возвращает его координаты на экране
		 */		
		public static function isoToScreen(point:Point):Point{
			var sourceX:Number = point.x;			
			point.x = (point.x - point.y) * ISO_ANGLE_COS * TILE_SIZE;
			point.y = (sourceX + point.y) * ISO_ANGLE_SIN * TILE_SIZE;
			return point;
		}
		
		/**
		 * Из экранных координат объекта в координаты вида сверху (в тайловых координатах)
		 */		
		public static function screenToIso(point:Point):Point{
			var sourceX:Number = point.x; 
			point.x = (point.y * DIV_ISO_ANGLE_SIN + point.x * DIV_ISO_ANGLE_COS) * 0.5 / TILE_SIZE;
			point.y = (point.y * DIV_ISO_ANGLE_SIN - sourceX * DIV_ISO_ANGLE_COS) * 0.5 / TILE_SIZE;
			return point;
		}
	}	
}