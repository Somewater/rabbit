/**
 * Обеспечивает работу подсказки
 * 
 * Возможно придется переписать 
 * 		- создание textField и цвет фона (строка ~124)
 * 		- ресайз textField (строки ~100,101)
 */
package com.somewater.text
{
	import com.greensock.TweenMax;
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;
	
	public class Hint extends Sprite
	{
		public static var PADDING:int = 5;// сколько пикселей от края есть всегда
		public static var HORIZONTAL_PADDING:int = 20;// отступ от мышки (чтобы курсор не загораживал подсказку)
		
		private static var _instance:Hint;
		private var ground:Sprite;
		private var application:DisplayObjectContainer;// относительно чего выводить и просчитывать подсказку
		
		private var timer:TweenMax;
		private var currentControl:Object;// ссылка на объект, для которого в данный момент выведена подсказка
		
		protected var textField:EmbededTextField;
		
		private var simpleControls:Dictionary;// коллекция объектов, подписанных на подсказки, которые не являются IHinted
		private var lastTextSize:Point = new Point();// если совпадают можно не менять положение текста
		
		public function Hint()
		{	
			if(_instance)
				throw new Error("Singletone class");
			else
				_instance = this;
			
			ground = Lib.createMC("interface.HintGround");
			addChild(ground);
			
			textField = new EmbededTextField(Config.FONT_SECONDARY,0x124D18,14,true,true,false,false,"center");
			textField.autoSize = TextFieldAutoSize.CENTER;
			addChild(textField);
			
			simpleControls = new Dictionary(true);
		}
		
		/**
		 * инициировать экземпляр класса
		 */
		public static function init(stage:DisplayObjectContainer):void{
			new Hint();
			_instance.application = stage;
		}
		
		/**
		 * создать подсказку для элемента, реализующего интерфейс IHinted (или не реализующего, но которому тоже очень нужна подсказка)
		 */
		public static function bind(target:*,text:*):void{
			if(target.hasOwnProperty("hint")){
				if (target.hint != text)
					target.hint = text;
			}else{
				_instance.simpleControls[target] = text;
			}
			target.removeEventListener(MouseEvent.ROLL_OVER,_instance.startHint);
			target.addEventListener(MouseEvent.ROLL_OVER,_instance.startHint,false,0,true);
		}
		
		public static function removeHint(target:*):void{
			delete _instance.simpleControls[target];
			target.removeEventListener(MouseEvent.ROLL_OVER,_instance.startHint);
		}
		
		public static function hideHint():void{
			_instance.stopHint();
		}
		
		private function startHint(e:MouseEvent):void{
			if(currentControl == e.currentTarget) return;
			var hint:String = (e.currentTarget.hasOwnProperty("hint")?e.currentTarget.hint: (simpleControls[e.currentTarget] is Function?simpleControls[e.currentTarget]():simpleControls[e.currentTarget]));
			if(hint == null || hint == "") return;
			if (!application.contains(this))
				application.addChild(this);
			textField.text = hint;	
			textField.width = Math.min(170,textField.text.length*10 + 20);
			moving();
			//resize();
			e.currentTarget.addEventListener(MouseEvent.ROLL_OUT, stopHint);
			e.currentTarget.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);//начинаем следить мышь
			// включаем таймер на автоскрытие
			if (timer != null) timer.kill();
			currentControl = e.currentTarget;
			timer = TweenMax.delayedCall(Math.max(2,hint.length * 0.2) + 1.8,stopHint);
			// обеспечить появление не сразу. а спустя "время удержания"
			alpha = 0;
			TweenMax.to(this,0.2,{alpha:1,delay:0.2})
		}
		
		private function stopHint(e:MouseEvent = null):void{
			if (e != null){
				if(e.relatedObject && (e.relatedObject == this || e.relatedObject == ground || e.relatedObject.parent == this)) {moving();return;}
				deleteListeners(e.currentTarget);
			}else
				if(currentControl)
					deleteListeners(currentControl);
			
			if (timer != null) timer.kill();		
			currentControl = null;
			
			if(application.contains(this))
				application.removeChild(this);
			function deleteListeners(obj:DisplayObject):void{
				obj.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				obj.removeEventListener(MouseEvent.ROLL_OUT, stopHint);	
			}
		}
		
		private function mouseMove(e:MouseEvent):void{
			moving();
		}
		
		private function moving():void
		{
			var w:int = textField.width;
			var h:int = textField.textHeight + 5; 
			
			resizeGround(w, h)
			textField.y = (ground.height - textField.height) * 0.5;
			
			var x:int = application.mouseX;
			var y:int = application.mouseY + HORIZONTAL_PADDING;
			
			if(x + w + PADDING > PopUpManager.WIDTH)
				x = x - w - PADDING;
			
			if(y + h + PADDING > PopUpManager.HEIGHT)
				y = y - ground.height - HORIZONTAL_PADDING - PADDING;
			
			this.x = x;
			this.y = y;
		}
		
		/**
		 * отресайзить фон согласно размерам текстового поля
		 */
		private function resizeGround(w:int, h:int):void{
			ground.width = w;
			ground.height = Math.max(28,h);
		}
		
	}
}