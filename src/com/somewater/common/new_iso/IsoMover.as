package com.somewater.common.new_iso
{
	import com.somewater.common.controllers.IsoMoverController;
	import com.somewater.common.factory.McFactory;
	import com.somewater.common.global.Env;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Обеспечивает правильное визуальное состояние объекта, при движении
	 * (напр. переключиться на анимацию "хотьба" и показать персонажа со спины, когда он перемещается вверх)
	 * 
	 * Направление
	 * <code>
	 * 	             				   top
	 *                                 y--
	 *                                 (2)
	 *                      (10) 1010   0010  0110 (6)               
	 *                                      
	 *                  x--,y--      \  |  /             x++, y--
	 *                                \ | /
	 *                                 \|/
	 *    left        --x 1000 (8) ---- o ----  0100 (4)     x++            right
	 *                                 /|\
	 *                                / | \
	 *                               /  |  \
	 *                      (9) 1001         0101 (5)
	 *                                 0001
	 *                  x--,y++        (1)               x++, y++
	 * 				     			   y++
	 *                               bottom
	 * </code>
	 * 
	 * Контроллером данного объекта должен быть IsoMoverController (или его потомок)
	 * 
	 * @author mister
	 */
	public class IsoMover extends MapObjectTiled
	{
		 
		/**
		 *	Возможные стейты 
		 */		
		public const ACTION_STATE_STAY:int = 0;
		public const ACTION_STATE_MOVE:int = 1;

		// только для тестирования
		public var TODO:Object = {};
		/**
		 * Т.е. направление вверх и вправо это (direction & TOP && direction & RIGHT)
		 */
		
		
		protected var _direction:uint;
		/**
		 * Установить анимацию (повренуть персонажа) согласно направлению его движения
		 * См. схему в описании класса 
		 * Пример реализации
		 * <listing>
		 *		if(direction & TOP){
		 * 			// идет вверх (в северном направлении)
		 * 			if(direction & LEFT) {}// на серверо-запад
		 * 			else if(direction & RIGHT){}// на северо-восток
		 * 			else{}// идет прямо на север
		 * 		}else if(direction & BOTTOM){
		 * 			// идет в южном направлении
		 *			if(direction & LEFT) {}// на юго-запад
		 * 			else if(direction & RIGHT){}// на юго-восток
		 * 			else{}// идет прямо на юг
		 * 		}else if(direction & LEFT){
		 * 			// идет прямо на запад
		 * 		}else if(direction & RIGHT){
		 * 			// идет прямо на восток
		 * 		}else{
		 * 			// стоит на месте
		 * 		}
		 *  // или для случая, когда кадры анимации ассета соответствующим образом подготовлены
		 *  // (1 - юго-запад, 2 - северо-восток, 4 - юго-восток, 6 - юг, 8 - северо-запад, 10 - север )
		 * 		var frame:int = direction * actionState * 10;
		 *      playAnimation(frame, dframe);
		 * 		actionState - 0 стоит, 1 идет
		 * 
		 * </listing>
		 * @param direction битовая маска направления
		 * @param moving персонаж идёт (а не стоит)
		 * @see com.progrestar.common.new_iso.IsoMover
		 */
		public function get direction():uint
		{
			return _direction;
		}
		public function set direction(value:uint)
		{
			_direction=value
		}
		
		protected var _searchDirection:uint = HORIZONTAL + VERTICAL;
		
		public static const HORIZONTAL:int = 1;
		public static const DIAGONAL:int = 2;
		public static const VERTICAL:int = 4;	
		
		/**
		 * Битовая маска направлений для поиска
		 * <listing>
		 *	public static const HORIZONTAL:int = 1;
		 *	public static const DIAGONAL:int = 2;
		 *	public static const VERTICAL:int = 4;	
		 * </listing>
		 */		
		public function get searchDirection():uint
		{
			return _searchDirection;
		}
		public function set searchDirection(value:uint)
		{
			_searchDirection = value
		}
		
		/**
		 * Определяет движение 
		 */		
		public var moving:Boolean;

		/**
		 * Ссылка на IsoMoverController, без которого существование IsoMover лишено всякого смысла
		 * @see com.progrestar.common.controllers.IsoMoverController
		 */
		public var moveController:IsoMoverController;
		
		/**
		 * Последние значения расположения персонажа 
		 */		
		protected var last_x:Number = 0, last_y:Number;
		
		
		public function IsoMover(mc:MovieClip = null){
			needTicking = true;
			super(mc);
			
			ghost = true;
		}
		
		
		override public function tick(arg1:int=0):void {
		
//			setMovingAnimation();

			if(moveController != null)
				moveController.tick(arg1);
			
			super.tick(arg1);
		}
		
		/**
		 * @param IsoPoint - новое значение.
		 */		
		override public function set position(value:IsoPoint):void{
			if(moveController && (!_position || !value.size.equals(_position.size)))
				moveController.setSize(value.size);
			
			if(value)
				refreshRegistratin(value.x, value.y, value.right, value.bottom);
			
			super.position = value;
		}
		
		override protected function refreshRegistratin(newX:Number, newY:Number, newRight:Number, newBottom:Number):void
		{
			if(!Env.unMoverGhosts)
				super.refreshRegistratin(newX, newY, newRight, newBottom);
			else
			{
				// мувер не должен обновлять карту
			}
		}

		/**
		 *	Метод для перемещения объекта из контроллеров.
		 * 	Устанавливает actionState в положение идет.
		 */		
		public function offset(_x:Number, _y:Number):void{
			
			var _direction:int = getDirectionMask(_x, _y);
			
			// проверить, не сменился ли тайл, не нужно ли вызвать refreshRegistratin()
			if(
				int(_position.x) != int(_position.x + _x) ||int(_position.y) != int(_position.y + _y) ||  // если сменил тайл левого верхнего угла
					(_position.size.length != 0 &&  (Math.ceil(_position.right) != Math.ceil(_position.right + _x) ||  Math.ceil(_position.bottom) !=  Math.ceil(_position.bottom + _y)))// если толстый мувер и правый нижний угол сменил тайл
					)
			{
				refreshRegistratin(_position.x + _x, _position.y + _y, _position.right + _x, _position.bottom  + _y);
			}			
	
			_position.offset(_x, _y);
			super.position = _position;
			
			// убиваем подергивание персонажа из-за невообразимо маленьких изменений
			//(резкая смена направления с 10 на 2 и с 4 на 5)
			if(_direction > 0 && 
				((Math.abs(_x) > 0.0000001 || _x == 0) && (Math.abs(_y) > 0.0000001 || _y == 0)))
				this.direction = _direction;
			
//			this.actionState = ACTION_STATE_MOVE;
		}
/*	
		/**
		 * Переключение анимации
		 */
/*
		protected function setMovingAnimation(arg1:int=0):void
		{
			var frame:int = this.direction + (this.actionState * 10);
			
			// паузы при движении (стейт не переключается - формально персонаж идет)
			// на случай, если персонаж столкнулся с другим персонажем
			if(actionState == ACTION_STATE_MOVE && _position.x == last_x && _position.y == last_y)
				frame -= actionState * 10;
			
			if(frame > 0 && frame != mc.currentFrame)
				playAnimation(frame, frame, true, true);
			
			last_x = _position.x;
			last_y = _position.y;
		}
		public function hit():Boolean
		{
			var check:Boolean=_position.x == last_x && _position.y == last_y;
			last_x = _position.x;
			last_y = _position.y;
			return check;
		}
		override public function set actionState(value:uint){
		_actionState = value;
		}
		
		override public function get actionState():uint{
		return _actionState;
		}

		
*/
		override public function unLoad():void{
		
			if(currentController)
				currentController.end();
			
			if (moveController) 
				moveController.end();
			
			moveController = null;
			super.unLoad();
		}
		
		override public function toString():String{
			return "[IsoMover type=" + TODO["type"] + "]";
		}
	}
}