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
	import com.somewater.rabbit.storage.Config;

	import flash.display.DisplayObject;

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
//		private static const LEFT:int 	= 0x11;//  10010b
//		private static const RIGHT:int 	= 0x12;//  10001b
//		private static const UP:int 	= 0x24;// 100100b
//		private static const DOWN:int 	= 0x28;// 101000b
		private static const LEFT:int 	= 0x2;// 0010b
		private static const RIGHT:int 	= 0x1;// 0001b
		private static const UP:int 	= 0x4;// 0100b
		private static const DOWN:int 	= 0x8;// 1000b
		

		
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
		 * Последний примененный keyResult
		 */
		private var lastKeyResult:uint;
		
		
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

		/**
		 * Смещение игрового модуля относительно стейджа
		 * (обычно [0,0], но для android это не так)
		 */
		private var gameOffset:Point;

		
		public function InputComponent()
		{
			super();
			
			tileRef = new PropertyReference("@Spatial.tile");
			destinationRef = new PropertyReference("@Mover.destination");
			rendererDirectionRef = new PropertyReference("@Render.direction");
			gameOffset = new Point((Config.loader as DisplayObject).x, (Config.loader as DisplayObject).y);
		}
		
		override protected function onAdd():void
		{
			super.onAdd();			
			PBE.mainStage.addEventListener(MouseEvent.CLICK, onSceneClick);
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
			PBE.mainStage.removeEventListener(MouseEvent.CLICK, onSceneClick);
			PBE.inputManager.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			PBE.inputManager.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_SUCCESS, onIsoMoverChanged);
			owner.eventDispatcher.removeEventListener(IsoMover.DESTINATION_ERROR, onIsoMoverChanged);
		}
		
		protected function onSceneClick(e:MouseEvent):void
		{		
			if(Config.gameModuleActive && this.owner != null && PBE.processManager.continiousTickCounter > 2)
			{
				var tile:Point = IsoRenderer.screenToIso(new Point(PBE.mainStage.mouseX - gameOffset.x - PBE.scene.position.x,
																   PBE.mainStage.mouseY - gameOffset.y - PBE.scene.position.y));
				tile.x = int(tile.x);
				tile.y = int(tile.y);
				
				listenSuspended = true;
				owner.setProperty(destinationRef, tile);
				listenSuspended = false;
			}
		}
		
		protected function onKeyDown(e:KeyboardEvent):void
		{
			if(!PBE.processManager.isTicking) return;// не обрабатываем действия, если игра на паузе
			
			var buf:uint = keyResult;

			var keyCode:int = e.keyCode;
			
			if((keyCode == Keyboard.UP || keyCode == Keyboard.NUMPAD_8) && !(keyResult & DOWN))
				keyResult |= UP;
			else if((keyCode == Keyboard.DOWN || keyCode == Keyboard.NUMPAD_2) && !(keyResult & UP))
				keyResult |= DOWN;
			else if((keyCode == Keyboard.LEFT || keyCode == Keyboard.NUMPAD_4) && !(keyResult & RIGHT))
				keyResult |= LEFT;
			else if((keyCode == Keyboard.RIGHT || keyCode == Keyboard.NUMPAD_6) && !(keyResult & LEFT))
				keyResult |= RIGHT;

			// диагональные клавиши
			if(keyCode == Keyboard.HOME || keyCode == Keyboard.NUMPAD_7)
				keyResult = UP | LEFT;
			else if(keyCode == Keyboard.PAGE_UP || keyCode == Keyboard.NUMPAD_9)
				keyResult = UP | RIGHT;
			else if(keyCode == Keyboard.END || keyCode == Keyboard.NUMPAD_1)
				keyResult = DOWN | LEFT;
			else if(keyCode == Keyboard.PAGE_DOWN || keyCode == Keyboard.NUMPAD_3)
				keyResult = DOWN | RIGHT;
			
			
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

			var keyCode:int = e.keyCode;

			if(keyCode == Keyboard.UP || keyCode == Keyboard.NUMPAD_8)
				keyResult = keyResult & (~UP);
			else if(keyCode == Keyboard.DOWN || keyCode == Keyboard.NUMPAD_2)
				keyResult = keyResult & (~DOWN);
			else if(keyCode == Keyboard.LEFT || keyCode == Keyboard.NUMPAD_4)
				keyResult = keyResult & (~LEFT);
			else if(keyCode == Keyboard.RIGHT || keyCode == Keyboard.NUMPAD_6)
				keyResult = keyResult & (~RIGHT);

			// диагональные клавиши
			if(keyCode == Keyboard.HOME || keyCode == Keyboard.NUMPAD_7)
				keyResult = keyResult & (~(UP | LEFT));
			else if(keyCode == Keyboard.PAGE_UP || keyCode == Keyboard.NUMPAD_9)
				keyResult = keyResult & (~(UP | RIGHT));
			else if(keyCode == Keyboard.END || keyCode == Keyboard.NUMPAD_1)
				keyResult = keyResult & (~(DOWN | LEFT));
			else if(keyCode == Keyboard.PAGE_DOWN || keyCode == Keyboard.NUMPAD_3)
				keyResult = keyResult & (~(DOWN | RIGHT));
			
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
			if(_owner == null)
				return;// пока кролик двигался, его убили

			if(scheduleStarted == false && deltaTime == 1)
				return;// пришло время schedule, но разрешение на него уже отменено
			
			// можно запускать новые schedule
			scheduleStarted = false;
			var keyResult:uint = this.keyResult & 0xF;// 1111b
			
			var standState:Boolean = _owner && _owner.getProperty(destinationRef) == null;// персонаж неподвижен
			// персонаж перемещается и "донажата" клавиша, которая заставит его двигаться по диагонали вместо прямой
			// т.е. если ранее была нажата только одна кнопка, а теперь "донажата" кнопка перпендикульярного направления
			var diagonalHook:Boolean = !standState &&
					(  		   (lastKeyResult == LEFT && (keyResult == (LEFT | UP) || keyResult == (LEFT | DOWN)))
							|| (lastKeyResult == RIGHT && (keyResult == (RIGHT | UP) || keyResult == (RIGHT | DOWN)))
							|| (lastKeyResult == UP && (keyResult == (UP | LEFT) || keyResult == (UP | RIGHT)))
							|| (lastKeyResult == DOWN && (keyResult == (DOWN | LEFT) || keyResult == (DOWN | RIGHT)))
					);
			
			if(keyResult && (standState || diagonalHook))
			{	
				// очистить расчет старого @Render.direction
				lastInputDirection = 0;

				var tile:Point;
				
				if(standState)
				{
					tile = owner.getProperty(tileRef).clone();

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
				}else if(diagonalHook)
				{
					tile = owner.getProperty(tileRef).clone();

					if(keyResult == (LEFT | UP))
					{
						tile.x -= 1;
						tile.y -= 1;
						lastInputDirection |= IsoRenderer.LEFT | IsoRenderer.TOP;
					}
					else if(keyResult == (RIGHT | UP))
					{
						tile.x += 1;
						tile.y -= 1;
						lastInputDirection |= IsoRenderer.RIGHT | IsoRenderer.TOP;
					}

					if(keyResult == (LEFT | DOWN))
					{

						tile.x -= 1;
						tile.y += 1;
						lastInputDirection |= IsoRenderer.LEFT | IsoRenderer.BOTTOM;
					}
					else if(keyResult == (RIGHT | DOWN))
					{
						tile.x += 1;
						tile.y += 1;
						lastInputDirection |= IsoRenderer.RIGHT | IsoRenderer.BOTTOM;
					}
				}

				if(!IsoSpatialManager.contain(tile))
				{
					// получившаяся координата лежит за пределами поля
					tile = null;
				}

				if(tile == null && clickResult)
				{
					tile = clickResult;
				}
				
				if(tile)
				{
					lastKeyResult = keyResult;
					//trace("input tile=" + tile + "	(dest=" + owner.getProperty(destinationRef) + ")");
					listenSuspended = true;
					owner.setProperty(destinationRef, tile);
					listenSuspended = false;
				}
				
				clickResult = null;
				//keyResult = 0;
			}
		}

		/**
		 * "отжать" нажатые кнопки
		 */
		public function clearKeys():void
		{
			keyResult = lastKeyResult = 0;
		}
	}
}