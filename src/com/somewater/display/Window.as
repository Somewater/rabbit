package com.somewater.display
{
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.TruncatedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.Font;
	import flash.text.TextFormat;
	
	/**
	 * Всплывабщее окно в стиле грандж
	 * Описанное
	 */
	public class Window extends Sprite implements IClear
	{
		private const WIDTH:int = 400;
		private const HEIGHT:int = 150;
		
		public static var GROUND_CLASS:Class;
		public static var CLOSE_BTN_CLASS:Class;
		public static var BTN_CLASS:Class;
		
		protected var MIN_BUTTON_Y:int = 60;// выше данного уровня кнопка не встает никогда, даже в отсутсиве текста
		
		protected var modal:Boolean = true;
		protected var individual:Boolean = false;
		
		public var textField:EmbededTextField;
		public var titleField:TruncatedTextField;
		
		public var _buttons:Array;
		public var closeButton:DisplayObject;
		protected var ground:Sprite;
		
		public var closeFunc:Function;
		
		public function Window(text:String = null, title:String = null ,closeFunc:Function = null,_buttons:Array = null)
		{
			super();
			this.closeFunc = closeFunc;
			
			ground = new GROUND_CLASS();
			ground.name = 'ground';
			ground.width = WIDTH; ground.height = HEIGHT;
			//ground.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownOnGround_handler,false,0,true);
			//ground.addEventListener(MouseEvent.MOUSE_UP,onMouseUpOnGround_handler,false,0,true);
			addChild(ground);
			
			
			this._buttons = [];
			if (_buttons == null) 
			{
				var okBtn:* = new BTN_CLASS();
				if(okBtn.hasOwnProperty("label")) okBtn.label = "OK";
				okBtn.width = Math.max(okBtn.width, 100);
				_buttons =  [okBtn];
			}
			
			buttons = _buttons;
			
			closeButton = new CLOSE_BTN_CLASS();
			closeButton.name = 'closeButton';
			closeButton.addEventListener(MouseEvent.CLICK, onCloseBtnClick);
			addChild(closeButton);
					
			setSize(WIDTH,HEIGHT);
			
			if (text != null){				
				textField = new EmbededTextField(null,"b",24,false,true,false,false,"center");
				textField.name = 'textField';
				textField.y = 55;
				textField.mouseEnabled = false;
				addChild(textField);
				this.text = text;
			}
		}
		
		public function clear():void{
			closeButton.removeEventListener(MouseEvent.CLICK, onCloseBtnClick);
			if(_buttons)
				for(var i:int = 0;i<_buttons.length;i++)
				{
					_buttons[i].removeEventListener(MouseEvent.CLICK,onButtonClick_handler);
					if(_buttons[i] is IClear)
						IClear(_buttons[i]).clear();
				}
		}
		
		public function set htmlText(value:String):void{
			if (textField != null){
				textField.htmlText = value;
				resize(); 
			}
		}
		
		public function set text(value:String):void
		{
			if (textField != null){
				textField.text = value;
				if(textField.height < textField.textHeight + 10)
					textField.height = textField.textHeight + 10;
				resize(); 
			}
		}
		public function get text ():String
		{
			if (textField != null)
				return textField.text;
			else
				return "";
		}
		
		public function set title(value:String):void
		{
			if(value == null || value == "")
			{
				if(titleField) 
					removeChild(titleField);
				titleField = null;
			}else{
				if(titleField == null)
				{
					titleField = new TruncatedTextField(null, "b", 26,true);
					titleField.y = 5;
					addChild(titleField);
				}
				titleField.text = value;
				resize();
			}
		}
		
		public function get title():String
		{
			if(titleField)
				return titleField.text;
			else
				return "";
		}
		
		public function resize():void{
			if (textField != null)
			{				
				textField.width = _width - 20;
				textField.x = (_width - textField.width) * 0.5;
				if (textField.height > (_height - 100 - textField.y))
					_height = Math.min( PopUpManager.HEIGHT, textField.y + textField.textHeight + 100);
			}
			
			
			
			if(titleField)
			{
				titleField.maxWidth = _width - 100;
				titleField.x = (_width - titleField.width) * 0.5 + 10;
			}
			
			ground.width = _width;
			ground.height = _height;
			
			closeButton.x = _width - 10 - closeButton.width;
			closeButton.y = 12;

			resizeButtons();
			
			PopUpManager.centre(this);
		}
		
		protected function setSize(w:int,h:int):void{
			
			if(w != _width || h != _height)
			{
				_width = w;
				_height = h;
				resize();
			}
		}
		

		public function set buttons(value:Array):void
		{
			var i:int;
			// сначала удаляем все старые кнопки
			for (i = 0;i<_buttons.length;i++)
				if (_buttons[i] is DisplayObject)
					if (contains(_buttons[i]))
						removeChild(_buttons[i]);
			_buttons = [];
			for (i = 0;i<value.length;i++){				
				_buttons.push(createButton(value[i]));
				addChild(_buttons[i]);
			}
			resizeButtons();
		}
		
		protected function createButton(value:*):DisplayObject {
			var btn:DisplayObject;
			if(value is DisplayObject)
				btn = value;
			else if(value is Class) 
				btn = new value();
			else 
				btn = new BTN_CLASS();
			if(btn.hasOwnProperty("label") && (value is String))Object(btn).label = value;
			btn.addEventListener(MouseEvent.CLICK,onButtonClick_handler, true);
			return btn;
		}
		
		protected function resizeButtons():void{
			if(_buttons.length == 0) return;
			var btnY:int = _height - 45 - 25;// кнопки выравниваются по нижнему краю
			if (textField != null) 
				btnY = Math.max((textField.textHeight + textField.y + 15),btnY,MIN_BUTTON_Y) + _buttons[0].height * 0.5;// под размер текста, но не выше 60 и не ниже 80
			for (var i:int = 0;i<_buttons.length; i++){
				_buttons[i].x = width/_buttons.length*(0.5 + i) - _buttons[i].width*0.5;
				_buttons[i].y = btnY - _buttons[i].height * 0.5;
			}				
		}
		
		public function get buttons():Array
		{
			return _buttons;
		}
		
		private function onMouseDownOnGround_handler(e:MouseEvent):void{
			startDrag(false, new Rectangle(3, 3, stage.stageWidth - _width - 6, stage.stageHeight - _height - 6));
		}
		
		private function onMouseUpOnGround_handler(e:MouseEvent):void{
			stopDrag();
		}
		
		protected function onButtonClick_handler(e:MouseEvent):void{
			if (closeFunc != null)
			{
				if(closeFunc(e.currentTarget.hasOwnProperty("label")?e.currentTarget.label:e.currentTarget))
						close();
			}				
			else
				close()
		}
		
		public function simulateButtonPress(button:DisplayObject):void
		{
			if (closeFunc != null)
			{
				if(closeFunc(button.hasOwnProperty("label")?Object(button).label:button))
					close();
			}				
			else
				close()
		}

		public function defaultButtonPress():void
		{
			if(buttons
			   && buttons.length == 1
			   && buttons[0] is DisplayObject)
					simulateButtonPress(DisplayObject(buttons[0]));
		}
		
		protected function startBlur():void
		{
			//TweenMax.to(this,0.3,{blurFilter:{blurX:0},startAt:{blurFilter:{blurX:20}},onComplete:function():void{filters = [];}});
		}
		
		public function open():void{
			Config.application.play(Sounds.WINDOW_OPEN, SoundTrack.INTERFACE, true);
			startBlur();
			PopUpManager.addPopUp(this, modal, individual);
			PopUpManager.centre(this);
		}
		
		protected function onCloseBtnClick(e:MouseEvent):void{
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			if(closeButton.visible)
				close();
		}
		
		public function close():void{
			clear();
			PopUpManager.removePopUp(this);
		}
		
		private var _width:int;
		override public function set width(value:Number):void{
			setSize(value,_height);
		}
		
		override public function get width():Number{
			return _width;
		}
		
		private var _height:int;
		override public function set height(value:Number):void{
			setSize(_width,value);
		}
		
		override public function get height():Number{
			return _height;
		}
		
	}
}