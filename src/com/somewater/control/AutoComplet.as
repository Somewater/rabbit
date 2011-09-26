package com.somewater.control
{
	import com.greensock.TweenMax;
	import com.somewater.controller.PopUpManager;
	import com.somewater.text.EmbededTextField;
	
	import fl.controls.List;
	import fl.data.DataProvider;
	import fl.events.ListEvent;
	import fl.managers.FocusManager;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	[Event(name="valueComplete", type="com.progrestar.display.bazaar.AutoComplet")]

	public class AutoComplet extends TextInputGrounded implements IClear
	{
		public static const VALUE_COMPLETE:String = "valueComplete";
		
		private const LIST_SPEED:Number = 0.2;// скорость (секунды) открытия /закрытия листа
		
		private var _list:List;
		private var listMask:Shape;
		private var _dataProvider:Array;
		public var labelField:String = "label";
		public var dataField:String = "data";
		
		// открывать лист при получении фокуса
		public var forceOpen:Boolean = true;
		// максимальное кол-во элементов в листе
		public var maxListItem:int = 7;
		
		// состояние листа (открыт/закрыт)
		private var listOpened:Boolean = false;
		
		// содержит выбранный объект, либо null (если объект, напрмер, уже некорректен в результате "дописки" пользователя)
		public var selectedValue:Object = null;
		public var selectedIndex:int = -1;
		
		private var self:AutoComplet;
		
		public function AutoComplet(font:String=null, color:*=null, size:int=12, bold:Boolean=false, align:String="left")
		{
			self = this;
			super(font, color, size, bold, align);
		}

		public function set list(value:List):void
		{
			_list = value;
		}
		public function get list ():List
		{
			if (_list == null){
					_list = new List();
					_list.addEventListener(ListEvent.ITEM_CLICK,listClick_handler);
					_list.setStyle("textFormat",EmbededTextField.getEmbededFormat(null,null,null,11,false));
					_list.verticalScrollBar.addEventListener(MouseEvent.ROLL_OVER,function(e:MouseEvent):void{
						preventScrollSudenClosure = false;
					});
					_list.verticalScrollBar.addEventListener(MouseEvent.ROLL_OUT,function(e:MouseEvent):void{
						preventScrollSudenClosure = true;
						var fm:FocusManager = new FocusManager(self);
						fm.setFocus(input);
					});
					listMask = new Shape();
					_list.mask = listMask;
				}				
			return _list;
		}
		
		public function clear():void{
			if (list != null)
				PopUpManager.removePopUp(list);
		}

		public function set dataProvider(value:Array):void
		{
			_dataProvider = value;
			if (_dataProvider != null)
				if (_dataProvider.length){
					input.addEventListener(FocusEvent.FOCUS_IN,focusInHandler);
					input.addEventListener(FocusEvent.FOCUS_OUT,focusOutHandler);
					input.addEventListener(Event.CHANGE,textInput_changeHandler);
					return;
				}
			input.removeEventListener(FocusEvent.FOCUS_IN,focusInHandler);
			input.removeEventListener(FocusEvent.FOCUS_OUT,focusOutHandler);
			input.removeEventListener(Event.CHANGE,textInput_changeHandler);
		}
		
		public function get dataProvider():Array
		{
			return _dataProvider;
		}
		
		public function sortDataProvider():void{
			if (_dataProvider != null){
				_dataProvider.sort(function (a:Object, b:Object):Number {			
				    if(String(a[labelField]).toLowerCase() > String(b[labelField]).toLowerCase()) {
				        return 1;
				    } else if(String(a[labelField]).toLowerCase() < String(b[labelField]).toLowerCase()) {
				        return -1;
				    } else  {
				        //a == b
				        return 0;
				    }
				});
			}
		}
		
		public function filteredDataProvider(focusIn:Boolean = false):Array{
			var success:Boolean = false; // вхождение найдено
			if (input.directText.length>0 && !focusIn){
				var iterator:int = 100; 
				var minLimit:int = 0;								
				var maxLimit:int = _dataProvider.length;
				while (iterator>0){
					iterator--;
					var centerLimit:int = minLimit+int((maxLimit-minLimit)/2);
					if (_dataProvider[centerLimit][labelField]>text) {maxLimit = centerLimit;continue;}
					if (_dataProvider[centerLimit][labelField]<text) {minLimit = centerLimit;continue;}
					if (_dataProvider[centerLimit][labelField]==text) {
						success = true;
						break;
					}
					if (_dataProvider[maxLimit][labelField]==text) {
						centerLimit = maxLimit;
						success = true;
						break;
					}
					if (minLimit == maxLimit) break;
				}
				if (success){
					// найден 1 точный элемент
					return [_dataProvider[centerLimit]];
				}else{
					// отфильтровать по алфавиту
					var filtered:Array = [];
					for (var i:int = 0;i<_dataProvider.length;i++)
						if (String(_dataProvider[i][labelField]).substr(0,input.directText.length).toLowerCase() == input.directText.toLowerCase())
							filtered.push(_dataProvider[i]);
					return filtered;
				}			
			}else{
				// введено слишком мало символов, просто показываем лист
				return _dataProvider;
			}
		}
		
		protected function focusInHandler(event:FocusEvent):void
		{
			preventGleams = true;
			if(forceOpen)
				open(true);
		}
		
		// избавиться от внезапного закрытия лста при попытке прокрутить его. Если prevent...=true значит мышь наведена не на скролл листа
		private var preventScrollSudenClosure:Boolean = true;
		protected function focusOutHandler(event:FocusEvent):void
		{
			if (preventScrollSudenClosure){
				var timer:Timer = new Timer(200,1);
				timer.addEventListener(TimerEvent.TIMER,close);
				timer.start();	
			}			
		}
		
		// избаиться от открытий/закрытий листа при вводе некорректного текста. Если открытие происходит из за ввода теката, то prev..=true 
		//(и новый ввод текста не может открыть лист, пока не будет введен корректный текст (отвечающий каким-то элементам датаПровайдера))
		private var preventGleams:Boolean = true;
		protected function textInput_changeHandler(event:Event):void
		{			
			open();
			preventGleams = false;
		}
		
		//private var focusOutTime:int = 0;
		protected function listClick_handler(e:ListEvent):void{		
			dispatchSelection(e.item,true);
			close(null,true);
		}

		/**
		 * Инициировать "выбор пользователем" какого-то члена dataProvider
		 * @param index в отличае от метода selectedIndex = 1, selectIndex(1) диспетчиризует событие выбора
		 * @param label ищет индекс согласно строке, если не находит, использует index. затем диспетчиризует выбор
		 */
		public function selectIndex(index:int,label:String = null):int{
			if (label != null){
				var success:Boolean = false; 
				var iterator:int = 100; 
				var minLimit:int = 0;						
				var maxLimit:int = _dataProvider.length;
				var centerLimit:int;
				while (iterator>0){
					iterator--;
					centerLimit = minLimit+int((maxLimit-minLimit)/2);
					if (_dataProvider[centerLimit][labelField]>label) {maxLimit = centerLimit;continue;}
					if (_dataProvider[centerLimit][labelField]<label) {minLimit = centerLimit;continue;}
					if (_dataProvider[centerLimit][labelField]==label) {
						success = true;
						break;
					}
					if (_dataProvider[maxLimit][labelField]==label) {
						centerLimit = maxLimit;
						success = true;
						break;
					}
					if (minLimit == maxLimit) break;					
				}
				if (success){
					index = centerLimit;
				}
			}
			selectedIndex = index;
			if (selectedIndex != -1)
				dispatchSelection(_dataProvider[selectedIndex],true);
			close();
			return index;
		}
		
		override public function set prompt(value:String):void
		{
			super.prompt = value;
		}
		override public function get prompt ():String
		{
			return super.prompt;
		}
		
		/**
		 * Диспетчиризация нового значния
		 * @param setText установка текста из нового значения в текстовое поле
		 * @param selectSuffix выделить прибавляемую часть текста
		 * @return было ли диспетчеризовано событие
		 */
		private function dispatchSelection(item:Object,setText:Boolean = true,selectSuffix:Boolean = false):Boolean{
			if (selectedValue == item)// запрет диспетчеризации при вводе/выводе фокуса
				if (setText && !selectSuffix)
					text = selectedValue[labelField];// но если клик по уже выбранному в листе значению, то просто заполнить инпут текст
				else
					return false;
			selectedValue = item;
			list.selectedItem = selectedValue;
			selectedIndex = _dataProvider.indexOf(selectedValue);
			dispatchEvent(new ListEvent(AutoComplet.VALUE_COMPLETE,false,false,-1,-1,selectedIndex,selectedValue));
			if (setText)if (selectSuffix){
					// выделить суффикс
					var startSelection:int = text.length;
					var stopSelection:int = selectedValue[labelField].length;
					text = selectedValue[labelField];
					input.setSelection(startSelection,stopSelection);
				}else{
					// поставить текст
					text = selectedValue[labelField];
				}
			return true;
		}
		
		/**
		 * Открыть лист
		 * (также вызывается для фильтрации уже открытого листа, когда текст поля ввода изменяется)
		 */
		protected function open(focusIn:Boolean = false):void{
			if (!enabled) return;
			var newDataSource:Array = filteredDataProvider(focusIn);
			if (newDataSource.length>1){
				// открыть список
				list.labelField = labelField;
				list.dataProvider = new DataProvider(newDataSource);
				list.selectedItem = selectedValue;
				list.height = list.rowHeight * Math.min(newDataSource.length,maxListItem);
				listMask.graphics.clear();
				listMask.graphics.beginFill(0);
				listMask.graphics.drawRect(0,0,width,list.height);
				preventGleams = true;
			}else if (newDataSource.length == 1){
				// список содержит лишь 1 подходящее значение, закрыть его и применить значение (выделить)
				if (dispatchSelection(newDataSource[0],true,true))
					close();// закрыть тольео если было диспетчеризовано событие
			}else{
				close();
			}
			if (!listOpened && preventGleams){
				close();// проверить не открыт ли, если открыт. сначала закрыть				
				list.x = localToGlobal(new Point(0,0)).x;
				var wishY:int = localToGlobal(new Point(0,0)).y+height;	
				list.y = wishY - list.height;			
				list.width = width;
				listMask.x = list.x;
				listMask.y = wishY;
				PopUpManager.addPopUp(list);
				PopUpManager.addPopUp(listMask);
				listOpened = true;
				TweenMax.to(list,LIST_SPEED,{y:wishY,overwrite:3});
			};			
		}
		
		/**
		 * Закрыть лист
		 * @param fast закрыть мгновенно (без эффекта)
		 */
		public function close(e:Event = null, fast:Boolean = false):void{
			if (list.parent != null)
				if (list.parent.contains(list))
					if (listOpened && !fast){						
						TweenMax.to(list,LIST_SPEED,{y:localToGlobal(new Point(0,0)).y-list.height+height,onComplete:function ():void{
							listOpened = false;
							//list.parent.removeChild(list);
							//listMask.parent.removeChild(listMask);	
							PopUpManager.removePopUp(list);
							PopUpManager.removePopUp(listMask);				
						},overwrite:3})
					}else if(fast){
						// лист анимационно убирается. Сделать это мгновенно
						TweenMax.killTweensOf(list, true);
					}
					
		}
	}//end class
}// end package