package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.InputKey;
	import com.pblabs.engine.entity.EntityComponent;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectScene;
	import com.pblabs.rendering2D.IScene2D;
	import com.pblabs.rendering2D.ui.IUITarget;
	import com.pblabs.rendering2D.ui.SceneView;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	/**
	 * Меняет destination персонажа в соответствии с вводимыми потзователем данными
	 */
	public class InputComponent extends EntityComponent implements ITickedObject
	{		
		private static const LEFT:int 	= 0x11;//  10010b
		private static const RIGHT:int 	= 0x12;//  10001b
		private static const UP:int 	= 0x24;// 100100b
		private static const DOWN:int 	= 0x28;// 101000b
		

		
		private var tileRef:PropertyReference;
		private var destinationRef:PropertyReference;
		private var rendererDirectionRef:PropertyReference;
		
		/**
		 * Клик мышью в пределах времени реакции (первый из множества)
		 */
		private var clickResult:Point;
		
		/**
		 * Нажатые кнопки в пределах времени реакции (не более 2-х)
		 */
		private var keyResult:uint;
		
		
		/**
		 * Добавлен запрос на shedule запуск ф-ции onTick
		 * (для осуществления диагональных перемещений "с ходу")
		 */
		private var scheduleStarted:Boolean = false;
		
		
		/**
		 * Флаг, который отменяет прослушивание события
		 * IsoMover.DESTINATION_ERROR и IsoMover.DESTINATION_SUCCESS
		 * (во избежании рекурсии)
		 */
		private var listenSuspended:Boolean = false;
		
		
		/**
		 * Сохраненное значение @Render.direction, которое должно было быть установлено
		 * согласно последним нажатым кнопкам
		 * (необходимо для того, чтобы повернуть персонаж в сторону желаемого движения, в том случае, 
		 * если движение невозможно)
		 */
		private var lastInputDirection:int;

		
		public function InputComponent()
		{
			super();
			
			tileRef = new PropertyReference("@Spatial.tile");
			destinationRef = new PropertyReference("@Mover.destination");
			rendererDirectionRef = new PropertyReference("@Render.direction");
		}
		
		override protected function onAdd():void
		{
			super.onAdd();			
			PBE.inputManager.addEventListener(MouseEvent.MOUSE_DOWN, onSceneClick);
			PBE.inputManager.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			PBE.inputManager.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			clickResult = null;
			keyResult = 0;
			
			owner.eventDispatcher.addEventListener(IsoMover.DESTINATION_SUCCESS, onIsoMoverChanged);
			owner.eventDispatcher.addEventListener(IsoMover.DESTINATION_ERROR, onIsoMoverChanged);
		}

		override protected function onRemove():void
		{
			super.onRemove();			
			PBE.inputManager.removeEventListener(MouseEvent.MOUSE_DOWN, onSceneClick);
			PBE.inputManager.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			PBE.inputManager.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_SUCCESS, onIsoMoverChanged);
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_ERROR, onIsoMoverChanged);
		}
		
		protected function onSceneClick(e:MouseEvent):void
		{		
			return;
			
			if(clickResult == null)
			{
				clickResult = IsoRenderer.screenToIso(new Point(PBE.mainStage.mouseX, PBE.mainStage.mouseY));
				clickResult.x = int(clickResult.x);
				clickResult.y = int(clickResult.y);
				
				onTick(0);
			}
		}
		
		protected function onKeyDown(e:KeyboardEvent):void
		{
			if(!PBE.processManager.isTicking) return;// не обрабатываем действия, если игра на паузе
			
			var buf:uint = keyResult;
			
			if(e.keyCode == Keyboard.UP && !(keyResult & DOWN))
				keyResult |= UP;
			else if(e.keyCode == Keyboard.DOWN && !(keyResult & UP))
				keyResult |= DOWN;
			else if(e.keyCode == Keyboard.LEFT && !(keyResult & RIGHT))
				keyResult |= LEFT;
			else if(e.keyCode == Keyboard.RIGHT && !(keyResult & LEFT))
				keyResult |= RIGHT;
			
			
			if(keyResult != buf)
			{
				// вызываем лишь в следующем тике, чтобы дать возм-ть нажать еще одну кнопку
				// и осуществить диагональное перемещение
				if(owner.getProperty(destinationRef) == null)
				{
					if(scheduleStarted == false)
					{
						PBE.processManager.schedule(50, this, onTick, 1);
						scheduleStarted = true;
					}
				}
				else
					onTick(0);
			}
			
		}
		
		
		protected function onKeyUp(e:KeyboardEvent):void
		{
			if(!PBE.processManager.isTicking) return;// не обрабатываем действия, если игра на паузе
			
			var buf:uint = keyResult;
			
			if(e.keyCode == Keyboard.UP)
				keyResult = keyResult & (~UP);
			else if(e.keyCode == Keyboard.DOWN)
				keyResult = keyResult & (~DOWN);
			else if(e.keyCode == Keyboard.LEFT)
				keyResult = keyResult & (~LEFT);
			else if(e.keyCode == Keyboard.RIGHT)
				keyResult = keyResult & (~RIGHT);
			
			
			if(keyResult != buf)
				onTick(0);
		}
		
		
		protected function onIsoMoverChanged(e:Event):void
		{
			if(listenSuspended)
			{
				// hook для поворачивания персонажа в сторону желаемого движения, если движение невозможно
				if(lastInputDirection)
					// установить видимость в нужную сторону (даже если искомый тайл недосягаем, напр занят,
					// кроль по крайней мере повернется в его сторону
					owner.setProperty(rendererDirectionRef, lastInputDirection);
			}else{
				// обычная обработка
				onTick(0);
			}
		}
		
		
		public function onTick(deltaTime:Number):void
		{
			if(scheduleStarted == false && deltaTime == 1)
				return;// пришло время schedule, но разрешение на него уже отменено
			
			// можно запускать новые schedule
			scheduleStarted = false;
			
			// очистить расчет старого @Render.direction
			lastInputDirection = 0;
			
			if((keyResult || clickResult) && _owner && _owner.getProperty(destinationRef) == null)
			{	
				
				var tile:Point;
				
				if(keyResult)
				{
					tile = owner.getProperty(tileRef).clone();
					keyResult = keyResult & 0xF;// 1111b					
					
					if(true)
					{
						if(keyResult & UP)
						{
							tile.y -= 1;
							lastInputDirection |= IsoRenderer.TOP;
						}
						else if(keyResult & DOWN)
						{
							tile.y += 1;
							lastInputDirection |= IsoRenderer.BOTTOM;
						}
						
						if(keyResult & LEFT)
						{
							tile.x -= 1;
							lastInputDirection |= IsoRenderer.LEFT;
						}
						else if(keyResult & RIGHT)
						{
							tile.x += 1;
							lastInputDirection |= IsoRenderer.RIGHT;
						}
					}else{					
						if(PBE.isKeyDown(InputKey.UP))
						{
							tile.y -= 1;
							lastInputDirection |= IsoRenderer.TOP;
						}
						else if(PBE.isKeyDown(InputKey.DOWN))
						{	
							tile.y += 1;
							lastInputDirection |= IsoRenderer.BOTTOM;
						}
						
						if(PBE.isKeyDown(InputKey.LEFT))
						{
							tile.x -= 1;
							lastInputDirection |= IsoRenderer.LEFT;
						}
						else if(PBE.isKeyDown(InputKey.RIGHT))
						{
							tile.x += 1;
							lastInputDirection |= IsoRenderer.RIGHT;
						}
					}
					
					if(!IsoSpatialManager.contain(tile))
					{
						// получившаяся координата лежит за пределами поля
						tile = null;
					}
				}
				
				if(tile == null && clickResult)
				{
					tile = clickResult;
				}
				
				if(tile)
				{
					//trace("input tile=" + tile + "	(dest=" + owner.getProperty(destinationRef) + ")");
					listenSuspended = true;
					owner.setProperty(destinationRef, tile);
					listenSuspended = false;
				}
				
				clickResult = null;
				//keyResult = 0;
			}
		}
	}
}