package com.somewater.control
{
	import com.somewater.text.LinkLabel;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.filters.GlowFilter;
	
	[Event(name="change",type="flash.events.Event")]
	
	/**
	 * Навигатор по страницам. Представляет из себя список номеров страниц 1 2 3 4 5...
	 * Если число страниц велико, появляются стрелки перемотки. Текущая страница выделена цветом
	 * Координация относительно начала координат, т.е. 0,0 является цеттром данного элемента
	 */
	public class PageNavigator extends Sprite implements IClear
	{		
		protected var ARROW_WIDTH:int = 14;
		protected var ITEM_WIDTH:int = 18;
		
		public var HEIGHT:int = 14;// настолько большое число. чтобы все элементы вмещались
		
		private var items:Array;
		private var leftArrow:DisplayObject;
		private var rightArrow:DisplayObject;
		
		public var leftArrowActive:Boolean;
		public var rightArrowActive:Boolean;
		
		public function PageNavigator()
		{
			super();
			leftArrowActive = rightArrowActive = false;
			_page = 1;
			_maxPages = 10;
			items = [];
		}
		
		public function clear():void{
			flushStage();
			for (var i:int = 0;i<items.length;i++){
				items[i].removeEventListener(MouseEvent.CLICK, pageClick_handler);
				if (items[i] is IClear)
					IClear(items[i]).clear();
			}
			
			items = null;
			
			if (leftArrow != null){
				leftArrow.removeEventListener(MouseEvent.CLICK, arrowClick_handler);
				if (leftArrow is IClear)
					IClear(leftArrow).clear();
			}
			
			if (rightArrow != null){
				rightArrow.removeEventListener(MouseEvent.CLICK, arrowClick_handler);
				if (rightArrow is IClear)
					IClear(rightArrow).clear();
			}
		}
		
		private function recreate():void{
			var i:int;
			flushStage();
				
			// лимиты страниц, т.е. номера страниц, которые видны
			var leftLimit:int = _page - Math.floor((_maxPages-1)*0.5);
			var rightLimit:int = _page + Math.ceil((_maxPages-1)*0.5);
			// если лимиты не равны maxPage, значит один из них можно расширить за счет другого
			if (leftLimit < 1){
				rightLimit += 1 - leftLimit;
			}
			if (rightLimit > _pageNumber){
				leftLimit -= rightLimit-_pageNumber;				
			}
			leftLimit = Math.max(1,leftLimit);
			rightLimit = Math.min(_pageNumber,rightLimit);
			// сигнализирует. что необходимо будет создать стрелки
			leftArrowActive = leftLimit>1;	
			rightArrowActive = rightLimit<pageNumber;
			// общая ширина элементов:
			var sumWidth:Number = (rightLimit - leftLimit + 1)*ITEM_WIDTH + int(leftArrowActive)*ARROW_WIDTH + int(rightArrowActive)*ARROW_WIDTH;
			sumWidth = - sumWidth * 0.5;// делим нацело, тперь каждый новый элемент должен x=sumWidth, sumWidth += width
			// создаем левую стрелку, если нужно
			if (leftArrowActive){
				if (leftArrow == null){
					leftArrow = createArrow(true);
				}
				addChild(leftArrow);
				leftArrow.x = sumWidth;
				sumWidth += ARROW_WIDTH;
			}
			for (i = leftLimit; i<= rightLimit; i++){
				var label:DisplayObject;
				if (items.length)
					label = items.pop();
				else
					label = createPageItem(i);
				
				setPageNumber(label,i);
				setSelectedPage(label,i == _page);
					
				addChild(label);
				label.x = sumWidth;
				sumWidth += ITEM_WIDTH;	
			}
			if (rightArrowActive){
				if (rightArrow == null){
					rightArrow = createArrow(false);
				}
				addChild(rightArrow);
				rightArrow.x = sumWidth;// выравнивается по правому краю габаритного прямоугольника
			}
			
		}
		
		/**
		 * Удаляет все элементы (стрелки и номера). Номера помещаются в массив items
		 */
		private function flushStage():void{
			var i:int;
			while(numChildren>0){
				var pageItem:Boolean = true;
				if (leftArrow != null)
					if (getChildAt(0) == leftArrow)
						pageItem = false;
				if (rightArrow != null)
					if (getChildAt(0) == rightArrow)
						pageItem = false;
				if (pageItem)
					items.push(removeChildAt(i));
				else
					removeChildAt(i);
			}
		}
		
		// создает стрелку
		protected function createArrow(left:Boolean):DisplayObject{
			var arrow:LinkLabel = new LinkLabel();
			arrow.text = (left?"&lt;":"&gt;");
			arrow.y = (HEIGHT - arrow.textHeight) * 0.5;
			arrow.addEventListener(MouseEvent.CLICK,arrowClick_handler);
			return arrow;
		}
		
		// создает элемент, отвечающий за нумерацию
		protected function createPageItem(index:int):DisplayObject{
			var label:LinkLabel = new LinkLabel(null,null,11,false,"center",true);
			//label.autoSize = TextFieldAutoSize.NONE;
			label.width = ITEM_WIDTH;
			label.addEventListener(LinkLabel.LINK_CLICK,pageClick_handler);
			label.y = (HEIGHT - label.textHeight)*0.5;
			return label;
		}
		
		// установить для данного элемента нумерации текст (номер страницы)
		protected function setPageNumber(item:DisplayObject,index:int):void{
			LinkLabel(item).text = index.toString();
		}
		
		// извлекает из заданного элемента нумерации, какой номер страницы в нем задан
		protected function getPageNumber(item:DisplayObject):int{
			return int(LinkLabel(item).text);
		}
		
		// устанавливает для заданного элемента нумерации, считать ли его текущим или нет (в соответствии с этим визуально отрисовать)
		protected function setSelectedPage(item:DisplayObject, selected:Boolean):void{
			if (selected){
				item.filters = [new GlowFilter(0xFFFFFF,0.5,8,8)];
			}else{
				item.filters = [];
			}
			LinkLabel(item).linked = !selected;
		}
		
		protected function arrowClick_handler(e:MouseEvent):void{
			var newPage:int = _page+(e.currentTarget == rightArrow?1:-1);
			var oldPage:int = _page;
			if (newPage == _page) return;
			_page = newPage;
			if (dispatchEvent(new Event(Event.CHANGE,false,true)))
				page = newPage;
			else
				_page = oldPage;
		}
		
		protected function pageClick_handler(e:TextEvent):void{
			var newPage:int = int(e.text);
			var oldPage:int = _page;
			if (newPage == _page) return;
			_page = newPage;
			if (dispatchEvent(new Event(Event.CHANGE,false,true)))
				page = newPage;
			else
				_page = oldPage;
		}
		
		// текущая страница
		private var _page:int;
		public function set page(value:int):void
		{
			if (value<1 || value>pageNumber) throw new Error("Wrong page number = "+value.toString()+". Pages quantity "+_pageNumber.toString());
			_page = value;
			recreate();
		}
		public function get page ():int
		{
			return _page;
		}
		
		
		// количество страниц		
		private var _pageNumber:int;
		public function set pageNumber(value:int):void
		{
			if (value == _pageNumber) return;
			_pageNumber = value;
			recreate();
		}
		public function get pageNumber ():int
		{
			return _pageNumber;
		}
		
		
		// максимальное количество отображаемых номерков страниц
		protected var _maxPages:int;
		public function set maxPages(value:int):void
		{
			if (_maxPages == _pageNumber) return;
			_maxPages = value;
			recreate();
		}
		public function get maxPages ():int
		{
			return _maxPages;
		}
		
		
		
	}
}