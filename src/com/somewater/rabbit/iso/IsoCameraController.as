package com.somewater.rabbit.iso
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.debug.Logger;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.storage.Config;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * Содержит общедоступные из всех точек программы методы для управления камерой
	 */
	public class IsoCameraController extends PBObject implements ITickedObject
	{
		
		private static var instance:IsoCameraController;
		
		/**
		 * Какова sensivity при перетаскивании мышкой 
		 */
		public var MOVE_MULTI:int = 3;
		
		/**
		 * Сколько тайлов должно остаться объекту слежки до края,
		 * чтобы сцена начала передвигаться
		 */
		public var PADDING:int = 3;
		
		/**
		 * На сколько тайлов "сверху" передвинется камера, при необходимости передвинуться
		 * (для того, чтобы экран "не скакал", когда trackObject постоянно идет в его край)
		 */
		public var RESERVE:int = 2;
		
		private var USE_RESERVE:int = 1;
		
		
		/**
		 * Объекь, за которым передвигается экран
		 */
		public var trackObject:IsoSpatial;

		/**
		 * Отцентровать относительно trackObject мгновенно, а не плавно
		 */
		public var centreTrackObjectImmediately:Boolean = false;
		
		
		
		/**
		 * Флаг означает, что сцена анимируется в данный момен, 
		 * поэтому пересчет координат производить нельзя
		 */
		private var tweeningFlag:Boolean = false;
		private var tween:Point;
		
		/**
		 * Листенеры на изменение позиции сцены (движение камеры)
		 */
		private var cameraMoveListeners:Array = [];
		
		public function IsoCameraController()
		{
			// пересчитываем константы в зависимости от размера сцены
			var T_SIZE:int = Math.min(Config.T_WIDTH, Config.T_HEIGHT);
			if(PADDING * 2 + RESERVE >= T_SIZE)
			{
				RESERVE = Math.max(0, T_SIZE - PADDING * 2 - 1)
				if(RESERVE == 0)
				{
					RESERVE = 1;
					PADDING = (T_SIZE - RESERVE - 1) / 2
				}
			}

			initialize("Camera");
			
			PBE.processManager.addTickedObject(this, 1);
			
			PBE.inputManager.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			PBE.inputManager.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			PBE.mainStage.addEventListener(MouseEvent.ROLL_OUT, onMouseUp);
		}
		
		
		// значение PBE.scene.position на момент начала перетаскивания
		private var mouseScenePos:Point;
		
		// координата мышки на момент начала перетаскивания
		private var mouseStartPos:Point = new Point();
		
		private function onMouseDown(e:MouseEvent):void
		{
			if(Config.gameModuleActive && (!Config.application.mouseInput || (Config.editorActive && !Config.editorOver)))
			{
				PBE.inputManager.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				PBE.inputManager.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				tweeningFlag = true;
				mouseScenePos = PBE.scene.position;
				mouseStartPos.x = PBE.mainStage.mouseX;
				mouseStartPos.y = PBE.mainStage.mouseY;
				
				if(tween)
					tween = null;
			}
		}
		
		
		private function onMouseUp(e:MouseEvent):void
		{
			if(Config.gameModuleActive)
			{
				PBE.inputManager.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				// привязать экран к тайлам
				var p:Point = position;
				p.x = Math.round(p.x);
				p.y = Math.round(p.y);
				setPositionAnimated(p);
				
				tweeningFlag = false;
				mouseScenePos = null;
			}
		}
		
		private var mouseMoveTempPos:Point = new Point();
		private function onMouseMove(e:MouseEvent):void
		{
			var gameIsTicking:Boolean = Config.game.isTicking;
			CONFIG::debug
			{
				if(Config.editor)
					gameIsTicking = gameIsTicking || PBE.mainStage != null;
			}
			if(gameIsTicking && mouseStartPos)
			{
				var dx:Number = PBE.mainStage.mouseX - mouseStartPos.x;
				var dy:Number = PBE.mainStage.mouseY - mouseStartPos.y;
				
				mouseMoveTempPos.x = mouseScenePos.x + dx * MOVE_MULTI;
				mouseMoveTempPos.y = mouseScenePos.y + dy * MOVE_MULTI;
				
				if(mouseMoveTempPos.x > 0)
					mouseMoveTempPos.x = 0;
				else if(mouseMoveTempPos.x < -IsoSpatialManager.instance.width * Config.TILE_WIDTH + Config.WIDTH)
					mouseMoveTempPos.x = -IsoSpatialManager.instance.width * Config.TILE_WIDTH + Config.WIDTH;
				
				if(mouseMoveTempPos.y > Config.HORIZONT_HEIGHT * Config.TILE_HEIGHT)
					mouseMoveTempPos.y = Config.HORIZONT_HEIGHT * Config.TILE_HEIGHT;
				if(mouseMoveTempPos.y < - IsoSpatialManager.instance.height * Config.TILE_HEIGHT +  Config.HEIGHT)
					mouseMoveTempPos.y = - IsoSpatialManager.instance.height * Config.TILE_HEIGHT + Config.HEIGHT;
				
				if(Point.distance(PBE.scene.position, mouseMoveTempPos) < 100)
				{
					PBE.scene.position = mouseMoveTempPos;
					dispatchCameraMoving(mouseMoveTempPos);
				}
				
				USE_RESERVE = 0;
			}
		}
		
		public function onTick(deltaTime:Number):void
		{
			if(tweeningFlag)
			{
				if(tween)
					onTween();
				return;
			}
			
			if(trackObject)
			{
				if(trackObject.isRegistered == false)
				{
					trackObject = null;
					return;
				}
				
				var objPos:Point = trackObject.tile;
				var movePos:Point = position;
				var scenePos:Point = movePos.clone();
				
				if(objPos.x - scenePos.x < PADDING)
					movePos.x = objPos.x - PADDING - USE_RESERVE * RESERVE;
				else if((scenePos.x + Config.T_WIDTH) - objPos.x < PADDING + 1)
					movePos.x = objPos.x - Config.T_WIDTH + PADDING + 1 + USE_RESERVE * RESERVE;
				
				if(objPos.y - scenePos.y < PADDING)
					movePos.y = objPos.y - PADDING - USE_RESERVE * RESERVE;
				else if((scenePos.y + Config.T_HEIGHT) - objPos.y < PADDING + 1)
					movePos.y = objPos.y - Config.T_HEIGHT + PADDING + 1 + USE_RESERVE * RESERVE;
				
				
				// обеспечить, чтобы экран не сдвинулся за пределы границ карты
				if(movePos.x < 0)
					movePos.x = 0;
				else if(movePos.x > IsoSpatialManager.instance.width - Config.T_WIDTH)
					movePos.x = IsoSpatialManager.instance.width - Config.T_WIDTH;				
				if(movePos.y < -Config.HORIZONT_HEIGHT)
					movePos.y = -Config.HORIZONT_HEIGHT;
				else if(movePos.y > IsoSpatialManager.instance.height - Config.T_HEIGHT)
					movePos.y = IsoSpatialManager.instance.height - Config.T_HEIGHT;
				
				if(movePos.equals(scenePos))
					return;
				
				USE_RESERVE = 1;

				if(centreTrackObjectImmediately)
				{
					centreTrackObjectImmediately = false;
					position = movePos;
				}
				else
					setPositionAnimated(movePos);
			}
		}
		
		
		
		private function setPositionAnimated(newPosition:Point):void
		{			
			var scenePos:Point = position;
			
			if(scenePos.equals(newPosition))
				return;
			
			tweeningFlag = true;
			var dist:Number = Math.sqrt(Math.pow(scenePos.x - newPosition.x, 2) + Math.pow(scenePos.y - newPosition.y, 2)); 
			
			tween = newPosition;
			//TweenLite.to(this, 0.1 + Math.max(0.2,Math.min(0,Math.log(dist)/10)),
			//	{"x":newPosition.x, "y":newPosition.y, "onComplete": tweenOff, "ease": com.greensock.easing.Linear.easeIn});
		}
		
		

		private var tmpPositionPoint:Point = new Point()
		private function onTween():void
		{
			var position:Point = this.position;
			tmpPositionPoint.x = tween.x * 0.3 + position.x * 0.7;
			tmpPositionPoint.y = tween.y * 0.3 + position.y * 0.7;

			if(Math.abs(tmpPositionPoint.x - position.x) < 0.05 && Math.abs(tmpPositionPoint.y - position.y) < 0.05)
			{
				this.position = tween;
				tweeningFlag = false;
				tween = null;
			}
			else
				this.position = tmpPositionPoint;
		}
		
		
		private var tempPos:Point = new Point();
		public function get x():Number
		{
			tempPos.x = -PBE.scene.position.x / Config.TILE_WIDTH;
			return tempPos.x;
		}
		public function set x(value:Number):void
		{
			tempPos.x = -value * Config.TILE_WIDTH;
			PBE.scene.position = tempPos;
			
			dispatchCameraMoving(tempPos)
		}
		public function get y():Number
		{
			tempPos.y = -PBE.scene.position.y / Config.TILE_HEIGHT;
			return tempPos.y;
		}
		public function set y(value:Number):void
		{
			tempPos.y = -value * Config.TILE_HEIGHT;
			PBE.scene.position = tempPos;
			dispatchCameraMoving(tempPos);
		}
		
		
		
		/**
		 * Позиция (смещение) сцены, только не в пикселах, а в тайлах
		 */
		public function set position(value:Point):void
		{
			value.x = -value.x * Config.TILE_WIDTH;
			value.y = -value.y * Config.TILE_HEIGHT;
			PBE.scene.position = value;
			dispatchCameraMoving(value);
		}
		
		public function get position():Point
		{
			var value:Point = PBE.scene.position;
			value.x = -value.x / Config.TILE_WIDTH;
			value.y = -value.y / Config.TILE_HEIGHT;
			return value;
		}
		
		
		public static function getInstance():IsoCameraController
		{
			if(instance == null)
				instance = new IsoCameraController();
			
			return instance;
		}
		
		/**
		 * Добавить слушателя на изменение позиции сцены
		 * callback(point:Point)  где point - смещение сцены в пикселях
		 */
		public function addCallback(callback:Function):void
		{
			if(cameraMoveListeners.indexOf(callback) == -1)
				cameraMoveListeners.push(callback);
		}
		
		/**
		 * Удалить слушателя на изменение позиции сцены
		 */
		public function removeCallback(callback:Function):void
		{
			var idx:int = cameraMoveListeners.indexOf(callback);
			if(idx != -1)
				cameraMoveListeners.splice(idx, 1);
		}
		
		private function dispatchCameraMoving(shift:Point):void
		{
			for(var i:int = 0;i<cameraMoveListeners.length;i++)
				cameraMoveListeners[i](shift);	
		}

		public function isoSpatialInViewArea(isoSpatial:IsoSpatial):Boolean
		{
			var pos:Point = isoSpatial._position;
			var x:int = this.x;
			var y:int = this.y;
			return pos.x >= x && pos.x <= x + Config.T_WIDTH && pos.y >= y && pos.y <= y + Config.T_HEIGHT;
		}
	}
}