/**
 * Базовый класс для создания перетаскиваемых объектов
 * Если объект невозможно наследовать от Draggable напряиую следует применить интерфейс IDraggable
 * Диспатчит события старт, стоп и комплит (завершена анимация "стоп драг" и объект анимационно исчез с экрана полностью)
 * 
 * В единицу времени не может перетягиваться более 1-го объекта
 * От времени срабатывания "старт" и сразу после "комплит" ссылка на перетаскиваемый объект находится
 * в статик свойствах класса DragManager
 */
package com.somewater.display
{
	import com.somewater.control.IClear;
	import com.somewater.controller.DragManager;
	import com.somewater.controller.PopUpManager;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	[Event(name="startDrag", type="com.somewater.display.Dragable")]
	[Event(name="stopDrag", type="com.somewater.display.Dragable")]
	[Event(name="dragComplete", type="com.somewater.display.Dragable")]
	
	public class Dragable extends Sprite implements IClear, IDragable
	{
		public static var START_DRAG:String = "startDrag";
		public static var STOP_DRAG:String = "stopDrag";
		public static var DRAG_COMPLETE:String = "dragComplete";
		
		private var _enableDrag:Boolean;// включение/отключение возможности перетаскивания
		protected var DRAG_ALPHA:Number = 0.5;// прозрачность перетягиваемого экземпляра
		protected var DRAG_DELAY_DIST:int = 10*10;// (в квадрате, чотбы минимизировать расчет дистанции) на сколько пикселе надо отодвинуть мышку при щелчке чтобы активировать перетаскивание
		
		private var startMoveX:Number;// помнят значание координат при начальном нажатии
		private var startMoveY:Number;// (используем чтобы создать "задержку" перетягивания)
		
		public function Dragable()
		{
			super();
			_enableDrag = false;
		}
		
		
		public function clear():void{
			removeAllListeners();
			if (DragManager.currentDraggable == this) DragManager.currentDraggable = null;
			if (DragManager.currentDraggableParent == this) DragManager.currentDraggableParent = null;
		}
		
		/**
		 * Возвратить визуальный объект, который будет перетаскиваться за мышью
		 */
		public function clone():IDragable{
			var dragable:Dragable = new Dragable();
			return dragable;
		}
		
		private function removeAllListeners():void{			
			removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
		}
		

		public function set enableDrag(value:Boolean):void
		{
			if (_enableDrag != value){
				_enableDrag = value;
				if (value){
					buttonMode = true;	useHandCursor = true;
					addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
				}else{
					buttonMode = false;	useHandCursor = false;
					removeAllListeners();
				}
			}
		}
		public function get enableDrag ():Boolean
		{
			return _enableDrag;
		}
		
		/**
		 * обеспечивает "перетягиваемость"
		 */
		private function onMouseDown(e:MouseEvent):void{
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			startMoveX = mouseX;
			startMoveY = mouseY;
		}	
		
		/**
		 * Следим за "дистанцией" мыши от точки начального клика
		 * Если мышь удалилась достаточно далеко(на DRAG_DELAY_DUST) активируем перетаскивание
		 */
		private function onMouseMove(e:MouseEvent):void{
			var distance:Number = Math.pow((mouseX-startMoveX),2) + Math.pow((mouseY-startMoveY),2);
			if (distance > DRAG_DELAY_DIST)
				onStartDrag();
		}	
		
		/**
		 * Кнопка была отжата без активации перетаскивания 
		 * (или с ней - вызов данной функции только для очистки от листенеров)
		 */
		private function onMouseUp(e:MouseEvent = null):void{
			removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		/*******************
		 * 
		 * 		Активировать перетаскиваение
		 * 			- создать копию объекта, включить его startDrag(), снабдить листенером на MOUSE_UP
		 * 			- записать перетаскиваемую копию и инициализатор в глобальные переменные DragManager
		 * 			- отдиспатчить событие: старт перетаскивания
		 * 
		 *******************/
		protected function onStartDrag():void{
			onMouseUp();
			
			var dragable:Dragable = clone() as Dragable;
			dragable.alpha = DRAG_ALPHA;
			var point:Point = localToGlobal(new Point(x,y));
			dragable.x = point.x - x*scaleX;
			dragable.y = point.y - y*scaleY;
			PopUpManager.addPopUp(dragable);
			dragable.startDrag();
			dragable.addEventListener(MouseEvent.MOUSE_UP, DragManager.onStopDrag);
			
			DragManager.currentDraggable = dragable;
			DragManager.currentDraggableParent = this;
			
			dispatchEvent(new Event(START_DRAG));
		}
	}
}