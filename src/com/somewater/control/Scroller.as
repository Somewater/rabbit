package com.somewater.control{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * Скроллер вертикальный
	 */
	public class Scroller extends Sprite implements IClear
	{
		public var scrollSpeed:Number = 0.05;

		/**
		 * Размеры видимой части компонента (в т.ч. полоса прокрутки)
		 */
		private var _width:Number = 100;
		private var _height:Number = 100;
		
		private var contentMask:Shape;
		
		/**
		 * Ширина полосы прокрутки
		 * (ширина кнопок, бегунка, полоски)
		 */
		public var scrollWidth:Number = 20;
		
		/**
		 * Высота кнопок
		 */
		public var buttonsHeight:Number = 20;
		
		
		public function Scroller() 
		{
			contentMask = new Shape();
			addChild(contentMask);

			addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		}
		
		/**
		 * Нижняя прямоугольная подложка
		 */
		public function get background():DisplayObject
		{
			return _background;
		}		
		
		public function set background(value:DisplayObject):void
		{
			if (_background && _background.parent) 
				_background.parent.removeChild(_background);
			_background = value;
			draw();
		}
		
		private var _background:DisplayObject;
		
		
		
		/**
		 * Кнопка перемотки к началу (верхняя)
		 */
		public function get startButton():DisplayObject
		{
			return _startButton;
		}		
		
		public function set startButton(value:DisplayObject):void
		{
			if (_startButton && _startButton.parent) 
				_startButton.parent.removeChild(_startButton);
			_startButton = value;
			draw();
		}
		
		private var _startButton:DisplayObject;
		
		
		
		
		/**
		 * Кнопка перемотки в конец (нижняя)
		 */
		public function get endButton():DisplayObject
		{
			return _endButton;
		}		
		
		public function set endButton(value:DisplayObject):void
		{
			if (_endButton && _endButton.parent) 
				_endButton.parent.removeChild(_endButton);
			_endButton = value;
			draw();
		}
		
		private var _endButton:DisplayObject;
		
		/**
		 * Линия прокрутки
		 */
		public function get scrollLine():DisplayObject
		{
			return _scrollLine;
		}		
		
		public function set scrollLine(value:DisplayObject):void
		{
			_scrollLine = value;
			draw();
		}
		
		private var _scrollLine:DisplayObject;
		
		
		/**
		 * Бегунок
		 */
		public function get thumb():DisplayObject
		{
			return _thumb;
		}		
		
		public function set thumb(value:DisplayObject):void
		{
			if (_thumb && _thumb.parent) 
				_thumb.parent.removeChild(_thumb);
			if(value is Sprite)
				_thumb = value;
			else
			{
				// обертка на случай, если thumb не класса Sprite
				var s:Sprite =  new Sprite();
				s.addChild(value);
				_thumb = s;
			}
			draw();
		}
		
		private var _thumb:DisplayObject;
		
		
		public function setSize(w:Number, h:Number):void
		{
			_width = w;
			_height = h;
			draw();
		}
		
		
		/**
		 * Перерисовка компонента, согласно ранее заданным настройкам
		 */
		public function draw():void
		{
			// создаем заглушки для визуальных частей, которые не заданы напрямую
			createDefaultAssets();
			
			addChildAt(_background, 0);
			_background.width = _width - scrollWidth;
			_background.height = _height;
			
			addChildAt(_scrollLine, 1);
			_scrollLine.width = scrollWidth;
			_scrollLine.height = _height - 2 * buttonsHeight;
			_scrollLine.x = _width - scrollWidth;
			_scrollLine.y = buttonsHeight;
			
			addChild(_startButton);
			_startButton.width = scrollWidth;
			_startButton.height = buttonsHeight;
			_startButton.x = _width - scrollWidth;
			
			addChild(_endButton);
			_endButton.width = scrollWidth;
			_endButton.height = buttonsHeight;
			_endButton.x = _width - scrollWidth;
			_endButton.y = _height - buttonsHeight;
			
			addChild(thumb);
			setThumbSize(scrollWidth, _thumbHeight);
			thumb.x = _width - scrollWidth;
			thumb.y = buttonsHeight;
			
			if (_content)
			{
				_content.mask = contentMask;
				addChild(_content);
				
				contentMask.graphics.clear();
				contentMask.graphics.beginFill(0);
				contentMask.graphics.drawRect(0, 0, _width - scrollWidth, _height);
			}
			
			createListeners();
			
			updatePosition();
		}
		
		
		/**
		 * Заглушки для незаданных визуальных компонентов
		 */
		private function createDefaultAssets():void
		{
			if (!_background)
				_background = getRandomRect();
				
			if (!_startButton)
				_startButton = getRandomRect(0x00FF00);
				
			if (!_endButton)
				_endButton = getRandomRect(0x0000FF);
			
			if (!_scrollLine)
				_scrollLine = getRandomRect();
				
			if (!_thumb)
				_thumb = getRandomRect(0xFF0000);
			
			function getRandomRect(color:uint = 0):Sprite
			{
				var rect:Sprite = new Sprite();
				
				// рандомный цвет светлых тонов, если не задан color
				rect.graphics.beginFill(color?color:((0x66 * Math.random() + 0x88) << 16) 
						+ ((0x66 * Math.random() + 0x88) << 8) 
						+ (0x66 * Math.random() + 0x88));
				rect.graphics.drawRect(0, 0, 100, 100);
				return rect;
			}
		}
		
		
		/**
		 * 
		 * Визуальное наполнение компонента
		 */
		public function set content(value:DisplayObject):void
		{
			_content = value;
			
			draw();
			
			// пересчет размера ползунка
			var maxThumbSize:Number = _height - buttonsHeight * 2;
			setThumbSize(_thumb.width, Math.min(maxThumbSize, maxThumbSize * (_height / _content.height)));
			
			updatePosition();
		}
		
		public function get content():DisplayObject
		{
			return _content;
		}
		
		
		private var _content:DisplayObject;
		
		
		/**
		 * Проверяет наличие и вешает листенеры на кнопки компонента, управляющие пеермоткой
		 */
		private function createListeners():void
		{
			_startButton.removeEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
			_startButton.addEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
				
			_endButton.removeEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
			_endButton.addEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
				
			_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
			_thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);

			_thumb.removeEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);
			_thumb.addEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);

			_thumb.removeEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);
			_thumb.addEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);

				
			// пальчики
			if (_startButton is Sprite)
			{
				Sprite(_startButton).buttonMode = Sprite(_startButton).useHandCursor = true;
			}
			if (_endButton is Sprite)
			{
				Sprite(_endButton).buttonMode = Sprite(_endButton).useHandCursor = true;
			}
			if (_thumb is Sprite)
			{
				Sprite(_thumb).buttonMode = Sprite(_thumb).useHandCursor = true;
			}
		}
		
		
		
		private function onButtonClick(e:Event):void
		{
			if (e.currentTarget == _startButton)
			{
				// уменьшаем позицию прокрутки (прокрутка наверх, в начало)
				position -= scrollSpeed;
			}
			else
			{
				position += scrollSpeed;
			}
		}
		
		
		private function onThumbMouseDown(e:Event):void
		{
			if (stage)
			{
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onThumbMove);
				
				// если пользователь свел курсор с флешки, оборвать режим прокрутки
				stage.addEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);
				
				Sprite(_thumb).startDrag(false, new Rectangle(_width - scrollWidth, 
																buttonsHeight, 0, _height - 2 * buttonsHeight - _thumbHeight));
			}
		}
		
		
		private function onThumbMouseUp(e:Event):void
		{
			if (stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbMove);
				stage.removeEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);
			}
			
			Sprite(_thumb).stopDrag();
		}
		
		
		private function onThumbMove(e:Event):void
		{
			_position = (_thumb.y - buttonsHeight)/ (_height - buttonsHeight * 2 - _thumbHeight);
			updatePosition(false);
		}
		
		/**
		 * 
		 * Позиция прокрутки, переведенная в число в интервале 0 .. 1
		 */
		public function set position(value:Number):void
		{
			value = Math.max(0, Math.min(1, value));
			
			if (value != _position)
			{
				_position = value;
				updatePosition();
			}
		}
		
		public function get position():Number
		{
			return _position;
		}
		
		private var _position:Number = 0;
		
		
		private function updatePosition(updateThumb:Boolean = true):void
		{
			if(updateThumb)
				_thumb.y = buttonsHeight + (_height - buttonsHeight * 2 - _thumbHeight) * _position;

			// ползунок виден только при наличии контента внутри контрола, и если контент по высоте больше контрола
			// т.е. нуждается в прокрутке
			_thumb.visible = _content != null && _content.height > _height;
				
			if (_content)
			{
				if(_content.height > _height)
					_content.y = - (_content.height - _height) * _position;
				else
					_content.y = 0;
			}
		}
		
		
		/**
		 * Сложная ф-я на случай, если thumb это спрайт-обертка
		 * 
		 * @param	w
		 * @param	h
		 */
		private function setThumbSize(w:Number, h:Number):void
		{
			if (!(_thumb is DisplayObjectContainer) || DisplayObjectContainer(_thumb).numChildren == 0)
			{
				_thumb.width = w;
				_thumb.height = h;
			}
			else
			{
				var thumbContainer:DisplayObjectContainer = _thumb as DisplayObjectContainer;
				
				for (var i:int = 0; i < thumbContainer.numChildren; i++ )
				{
					var child:DisplayObject = thumbContainer.getChildAt(i);
					child.width = w;
					child.height = h;
				}
			}
			
			_thumbHeight = h;
		}
		
		
		private var _thumbHeight:Number;

		public function clear():void {
			if(_thumb is IClear)
				IClear(_thumb).clear();
			if(_startButton is IClear)
				IClear(_startButton).clear();
			if(_endButton is IClear)
				IClear(_endButton).clear();

			_startButton.removeEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
			_endButton.removeEventListener(MouseEvent.MOUSE_DOWN, onButtonClick);
			_thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
			_thumb.removeEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);
			_thumb.removeEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);

			if (stage)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbMove);
				stage.removeEventListener(MouseEvent.ROLL_OUT, onThumbMouseUp);
			}

			removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		}

		private function onWheel(event:MouseEvent):void {
			this.position -= event.delta * scrollSpeed;
		}
	}

}
