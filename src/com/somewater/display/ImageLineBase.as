package com.progrestar.display
{
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	
	[Event(name="init",type="flash.events.Event")]
	[Event(name="open",type="flash.events.Event")]
	[Event(name="close",type="flash.events.Event")]
	
	/**
	 * Рисунки типа PhotoBazaar в виде линии, с возможностью перемотки туда сюда (сразу весь ряд)
	 * (не входящие в область просмотра скрываются. Потипу ImageLine для проекта ProgrestarSite)
	 */
	public class ImageLineBase extends Sprite implements IClear
	{
		public var SPEED:Number = 0.3;// за сколько секунд выполняется анимированное перемежение
		public var WIDTH:int = 600;
		public var HEIGHT:int = 200;
		public var IMG_NUMBER:int = 4;// количество рисунков. одновременно показываемых на экране
		public var IMG_WIDTH:int = 95;// ширина под 1 рисунок
		public var IMG_PADDING:int = 36;// отсутп рисунка от рисунка
		public var ARROW_WIDTH:int = 34;// ширина отступа под стрелочную кнопку (может быть больше фактичской ширины, чтобы создать отступ)
		public var MASK:Boolean = true;
		
		protected var _images:Array;// данные для построения элементов линии (после их построения - ссылки на сами объекты)
		protected var content:Sprite;
		protected var contentMask:Shape;
		
		protected var leftArrow:DisplayObject;
		protected var rightArrow:DisplayObject;
		//private var haveArrows:Boolean;// имеются ли стрелки
		
		public function ImageLineBase()
		{
			super();
			content = new Sprite();
			addChild(content);
		}
		
		public function clear():void{
			if (_images != null){
				for (var i:int = 0;i<_images.length;i++){
					if (_images[i] is IClear)
						_images[i].clear();
					TweenMax.killTweensOf(_images[i]);
				}					
				_images = null;	
			}
			if (leftArrow != null)
				leftArrow.removeEventListener(MouseEvent.CLICK, onArrowClick_handler);
			if (rightArrow != null)
				rightArrow.removeEventListener(MouseEvent.CLICK, onArrowClick_handler);
		}
		
		/**
		 * Добавить в ImageLine еще одно изображение (оно анимационно "выезжает" справа)
		 */
		public function addImage(source:*):void{addImageAt(source);}
		public function addImageAt(source:*, index:int = -1):void{
			var animation:int = 0;
			if (index > _images.length) throw new Error("Try add image in image line, index is out of range");
			if (index < 0 || index == _images.length){
				index = _images.length;
				animation = 2;
			}else{
				// "отпихнуть" картинки с большим индексом, т.к. поризводится добавление картинки не в самый конец
				for (var i:int = index;i<_images.length;i++){
					setImagePosition(_images[i],i+1,animation);
				}
			}
			var image:DisplayObject = (source is DisplayObject?source:createImage(index,source));
			images.splice(index, 0, image);
			content.addChild(image);
			setImagePosition(image,index, animation);
			if (animation == 0){
				startAddAnim(image);
			}
			refreshArrows();
			position = _images.length - IMG_NUMBER;// установить самую крайнюю справа в область видимости
		}
		
		/**
		 * Удаляет image под указанным индексом, стоящие правее сдвигаются, занимаю опустевшее место
		 */
		public function deleteImageAt(index:int):DisplayObject{
			if (index < 0 || index >= _images.length)	throw new Error("Try deleting image out of range");
			var item:DisplayObject = _images[index];
			if(item == null) throw new Error("Image deleting error. Image is empty");
			
			if (index < (_images.length)){
				// "придвинуть" картинки с большими индексами
				for(var i:int = index + 1;i<_images.length;i++){
					setImagePosition(_images[i],i-1, /*анимированно придвинуть только те, который окажутся в области видимости*/   (i < (_position + IMG_NUMBER)?1:0));
				}
			}
			_images.splice(index,1);
			startDelAnim(item);
			refreshArrows();
			if (_position > (_images.length - IMG_NUMBER))
				position = _images.length - IMG_NUMBER;// установить самую крайнюю справа в область видимости
			return item;
		}
		
		// провести "анимацию удаления" после которой удалить объект на самом деле
		protected function startDelAnim(item:DisplayObject):void{
			TweenMax.to(item,SPEED,{scaleX:0,scaleY:0,onComplete:startDelAnim_complete,onCompleteParams:[item]});
		}
		
		protected function startDelAnim_complete(e:DisplayObject):void{
			if (content.contains(e))
				content.removeChild(e);
			if (e is IClear)
				IClear(e).clear();
		}
		
		// провести анимацию появления
		protected function startAddAnim(item:DisplayObject):void{
			item.alpha = 0;
			TweenMax.to(item,SPEED,{alpha:1})
		}
		
		
		// построить картинки согласно данным, содержащимся в value
		public function set images(value:Array):void{
			if (value == null) return;
			_images = value;
			recreate();
			dispatchEvent(new Event(Event.INIT));
		}
		
		public function get images():Array{
			return _images;
		}
		
		
		/**
		 * Перестраивает images согласно заданым парамтерам
		 * Чтобы увидеть визуальрый результат необходимо вызвать метод show() после init()
		 */
		private function recreate():void
		{
			var _images:Array = this._images;
			this._images = [];
			content.x =  getContentNullPos();
			
			while(content.numChildren)
				content.removeChildAt(0);
			
			for (var i:int = 0;i<_images.length;i++)
			{
				var item:DisplayObject = (_images[i] is DisplayObject?_images[i]:createImage(i,_images[i]));
				content.addChild(item);
				this._images.push(item);
				if (i < IMG_NUMBER){
					// анимировать появление картинок
					setImagePosition(item,i);
					//item.x = WIDTH;
					//TweenMax.delayedCall(SPEED*i,setImagePosition,[item,i,2]);
				}else{
					// просто разместить картинки как надо
					setImagePosition(item,i);
				}
			}
			
			if (MASK){
				if (contentMask == null){
					contentMask = new Shape();
					contentMask.graphics.beginFill(0);
					contentMask.graphics.drawRect(ARROW_WIDTH,0,WIDTH - ARROW_WIDTH * 2,HEIGHT);
					addChild(contentMask);
					content.mask = contentMask;
				}
			}else{
				if (contentMask != null){
					if (contains(contentMask))
						removeChild(contentMask);
					contentMask = null;
				}
			}
			
			refreshArrows();
			
			_position = -1;
			position = 0;
		}
		
		
		
		/**
		 * Абстрактная функция создания элемента линии
		 */
		protected function createImage(index:int, source:*):DisplayObject{
			var item:Sprite = new Sprite();
			item.graphics.beginFill(0xFF00FF);
			item.graphics.drawRect(0,0,IMG_WIDTH, HEIGHT);
			return item;
		}
		
		/**
		 *  установить "x" картинки согласно индексу
		 * image:* индекс или сама картинка
		 * index её новый индекс
		 * animation сделать переход мгновенно или анимированно
		 * 		0 - моментально
		 * 		1 - анимационно, с текущего положения
		 * 		2 - анимационно сбоку
		 */
		protected function setImagePosition(image:*, index:int, animation:int = 0):void{
			var newPos:Number = (IMG_WIDTH + IMG_PADDING) * index;
			
			if (!(image is DisplayObject))
				image = _images[image];

			if (animation == 0)
				image.x = newPos;
			else{
				if (animation == 2)
					image.x = WIDTH - (MASK?ARROW_WIDTH * 2:0) + _position*(IMG_WIDTH + IMG_PADDING);
				TweenMax.to(image, SPEED, {x: newPos});
			}
			if (index >= _position && (index < (_position + IMG_NUMBER)))
				setVisible(image, true);
		}
		
		
		// установить стрелки
		protected function refreshArrows():void{			
			if (this._images.length>IMG_NUMBER)
			{	
				if (leftArrow == null){		
					leftArrow = createArrow(true);
					//leftArrow.scaleX = -1;
					leftArrow.x += 0//leftArrow.width;
					leftArrow.addEventListener(MouseEvent.CLICK,onArrowClick_handler);
					addChild(leftArrow);
				}
				if (rightArrow == null){
					rightArrow = createArrow(false);
					rightArrow.x += WIDTH - rightArrow.width;
					rightArrow.addEventListener(MouseEvent.CLICK,onArrowClick_handler);
					addChild(rightArrow);
				}
				if (leftArrow != null)
					setArrowEnabled(leftArrow, (_position != 0));
			
				if (rightArrow != null)
					setArrowEnabled(rightArrow, (_position != (_images.length - IMG_NUMBER)));
					
			}else{
				if (leftArrow != null){
					leftArrow.removeEventListener(MouseEvent.CLICK,onArrowClick_handler);
					if (contains(leftArrow))
						removeChild(leftArrow);
					leftArrow = null;
				}
				if (rightArrow != null){
					rightArrow.removeEventListener(MouseEvent.CLICK,onArrowClick_handler);
					if (contains(rightArrow))
						removeChild(rightArrow);
					rightArrow = null;
				}
			}
		}
		// создать одну стрелку
		protected function createArrow(left:Boolean):DisplayObject{
			var arrow:Sprite = new Sprite();
			arrow.buttonMode = true;	arrow.useHandCursor = true;
			arrow.graphics.beginFill(0);
			arrow.graphics.drawRect(0,0,ARROW_WIDTH,HEIGHT);
			return arrow;
		}
		
		protected function setArrowEnabled(arrow:DisplayObject, enabled:Boolean):void{
			if (arrow.hasOwnProperty("enabled"))
			 	Object(arrow)["enabled"] = enabled;
		}

		
		protected function onArrowClick_handler(e:MouseEvent):void{
			if (e.currentTarget.hasOwnProperty("enabled"))
				if (!e.currentTarget.enabled ) return;
			if (e.currentTarget == leftArrow)
				position -= IMG_NUMBER;
			else
				position += IMG_NUMBER;
		}
		
		/**
		 * помещяет элемент с индексом равным pos в левый край. Если же элемент находится в числе последних. то сдвигает область просмотра к краю
		 */
		protected var _position:int;
		public function set position(pos:int):void{
			if (pos > (_images.length - IMG_NUMBER)) pos = _images.length - IMG_NUMBER;
			if (pos<0) pos = 0;
			if (pos == _position) return;
			
			for (var i:int = Math.max(0,Math.min(pos,_position));i<Math.min(_images.length,(Math.max(pos,_position)+IMG_NUMBER));i++)
				setVisible(_images[i], true);
			
			var delta:int = Math.abs(pos - _position);
			_position = pos;	
			refreshArrows();
			
			TweenMax.to(content,0.8,{x:
				(   getContentNullPos() - pos*(IMG_WIDTH+IMG_PADDING)), 
				onComplete:setPos_onComplete});
		}
		
		// высичляется позиция спрайта content на которой расстояние картинок от обеих стрелок будет равным
		protected function getContentNullPos():Number{
			return (WIDTH - (IMG_WIDTH+IMG_PADDING)*IMG_NUMBER + IMG_PADDING)*0.5;
		}
		
		/**
		 * Включить или выключить видимость элемента,
		 * который в данный момент входит/не входит в видимую область
		 */
		protected function setVisible(image:DisplayObject, visibility:Boolean):void{
			image.visible = visibility
		}
		
		private function setPos_onComplete():void{
			if (_images == null) return;
			for (var i:int = 0;i<_images.length;i++)
				setVisible(_images[i],     Boolean((i >= _position   &&   i<(_position + IMG_NUMBER))?1:0)    );
		}
		
		public function get position():int{
			return _position;
		}
		
	}
}