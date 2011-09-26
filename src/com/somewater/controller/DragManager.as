package com.somewater.controller
{
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.display.Dragable;
	import com.somewater.display.IDragable;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class DragManager implements IController
	{
		// ссылка на перетаскиваемый визуальный элемент
		public static var currentDraggable:IDragable;
		// ссылка на визуалльный элемент. породивший перетаскиваемый
		public static var currentDraggableParent:IDragable;
		// массив зарегистрированных контейнеров, которые получают события, когда над ними проводится перетаскивание
		private static var dragContainers:Array;
		
		public function DragManager()
		{
		}
		
		
		private static var stopMoveX:Number;// помнят координаты перетаскиваемого объекта в момент его отпускания
		private static var stopMoveY:Number;// (используются для эффекта "исчезновение в середину", а не в край)
		public static function onStopDrag(e:MouseEvent):void{
			e.currentTarget.stopDrag();
			e.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, onStopDrag);
			
			e.currentTarget.dispatchEvent(new Event(Dragable.STOP_DRAG))
			
			stopMoveX = e.currentTarget.x;
			stopMoveY = e.currentTarget.y;
			
			TweenMax.to(e.currentTarget, 0.4, 
				{scaleX:0, scaleY:0, onUpdate:onStopDrag_update, onUpdateParams:[e.currentTarget],
				onComplete: onStopDrag_complete, onCompleteParams:[e.currentTarget]});
		}
		
		// происходит анимация исчезновения перетягиваемого элемента
		protected static function onStopDrag_update(e:DisplayObject):void{
			e.x = stopMoveX + 0.5 * e.width * (1 - e.scaleX);
			e.y = stopMoveY + 0.5 * e.height * (1 - e.scaleY);
		}
		
		// закончена анимация исчезновения перетягиваемого элмента. нужно удалить его на самом деле
		protected static function onStopDrag_complete(e:DisplayObject):void{
			e.dispatchEvent(new Event(Dragable.DRAG_COMPLETE));
			if (e is IClear) IClear(e).clear();
			PopUpManager.removePopUp(e);
			
			currentDraggable = null
			currentDraggableParent = null;
		}
		
				
		/**
		 * Зарегистрировать объект, который заинтересован в получении события "перетягивание над ним"
		 * @return объект был зарегистрирован (впервые)
		 */
		public static function registerContainer(container:DisplayObjectContainer):Boolean{
			if (dragContainers == null) dragContainers = [];
			if (dragContainers.indexOf(container) == -1){
				dragContainers.push(container);
				return true;
			}
			else
				return false;
		}

	}
}