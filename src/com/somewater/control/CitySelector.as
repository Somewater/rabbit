package com.somewater.control
{
	import com.greensock.TweenMax;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.HintedSprite;
	import com.somewater.text.EmbededTextField;
	
	import fl.controls.Button;
	import fl.controls.ComboBox;
	import fl.events.ListEvent;
	import fl.managers.FocusManager;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	[Event(name="citySelector_Selected",type="com.progrestar.events.CitySelectorEvent")]
	
	public class CitySelector extends HintedSprite implements IClear
	{
		/**
		 * function (onComplete:Function,onError:Function = null, country:int = -1,region:int = -1);
		 * 
		 *  Умеет выдавать список географических объектов: 
		 * 				/	...			=>  e.country[i]==	{country_id,name}
		 * 	внутренний {	country=..	=>	e.region[i]	==	{region_id, name} или e.city[i]	==	{city_id, name}
		 * 	ответ		\	region=..	=>	e.city[i]	==	{city_id, name}
		 * 
		 *  внешний ответ: 	e.list[i] == {uid,name}
		 * 					e.type == "country" / "city" / "region"
		 */
		public static var remoteDataProvider:Function;
		
		private const SPEED:Number = 0.2;// скорость (секунды) открытия /закрытия popUp
		private const HEIGHT:int = 180;
		public static var DEFAULT_CITY:Array = []//[72,35,90];// индексы России, Моск. обл. и Москвы
		
		private const DEFAULT_AUTOCOMPL_WIDTH:int = 150;
		private const DEFAULT_AUTOCOMPL_HEIGHT:int = 18;
		private const BUTTON_SIZE:int = 18;
		
		private var countryInput:AutoComplet;
		private var countryInputCreated:Boolean = false;
		private var countryValue:Object;// объект, содержащий данные по последней выбранной стране (именно по ней построен текущий регион)
		private var countryOnSelected:Function; // передаем данной функции аргумент (чтобы избежать глюка с многовызываемостью)
		
		private var regionInput:AutoComplet;
		private var regionInputCreated:Boolean = false;
		private var regionValue:Object;// инфа по последнему выбранному региону {uid,name}
		private var regionOnSelected:Function;
		
		private var cityInput:AutoComplet;
		private var cityInputCreated:Boolean = false;
		private var cityValue:Object;
		private var cityOnSelected:Function;
		private var cityLabel:EmbededTextField;// чтобы иметь позможность легко добавлять/удалять лейбл "город"
		private var regionLabel:EmbededTextField;
		private var countryLabel:EmbededTextField;
		
		private var popUpHolder:Sprite;// держатель 3х полей страна, регион, город
		private var contentHolder:Sprite;// содержит всё полезное содержимое попапа (не включает в себя маску)
		private var sumbitButton:Button;
		private var canselButton:Button;
		
		public var textField:EmbededTextField;
		private var numberOfAutoComplete:int = 0;
		
		private var defaultSelects:Array = [-1,-1,-1];// используется во внутренней логике. Если правильно задать id, то они автоматически откроются при создании попАпа
		public var _value:CitySelectorEvent;
		private var defaultWidth:int;
		
		private var closeTimer:TweenMax;
		
		private var typeSelector:ComboBox;// поле выбора типа
		

		
		
		public function CitySelector(width:int = 130):void
		{	
			defaultWidth = width;
			// создаем "comboBox"
			var ground:Sprite = new TextInput_upSkin();
			ground.width = width-BUTTON_SIZE;
			ground.height = BUTTON_SIZE;
			ground.buttonMode = true; ground.useHandCursor = true;
			ground.addEventListener(MouseEvent.CLICK,createPopUp,false,0,true);
			addChild(ground);
			
			textField = new EmbededTextField();
			textField.mouseEnabled = false;
			textField.text =  Lang("CITY_SELECTOR_COMMON_PROMPT");
			textField.selectable = false;
			textField.x = 2;
			textField.y = -2;
			textField.width = width-BUTTON_SIZE;
			textField.color = 0x999999;
			addChild(textField);
			
			var textFieldMask:Shape = new Shape();
			textFieldMask.graphics.beginFill(0);
			textFieldMask.graphics.drawRect(0,0,width-BUTTON_SIZE-3,BUTTON_SIZE);
			textField.mask = textFieldMask;
			addChild(textFieldMask);
			
			var button:Button = new Button();
			button.width = 18;
			button.x = width-BUTTON_SIZE + 18;// 2 - рамка при фокусе поля
			button.rotation = 90;
			addChild(button);
			
			button.addEventListener(MouseEvent.CLICK,createPopUp,false,0,true);
			textField.addEventListener(MouseEvent.CLICK,createPopUp,false,0,true);

			_value = new CitySelectorEvent("init");
			
			//createCountryInput();		
		}
		
		public function clear():void{
			canselButton_handler();
			TweenMax.killTweensOf(contentHolder,true);
		}
		
		/**
		 * Зная строковое представление параметров местоположения, найти и установить их id
		 */
		public function set value(data:Array):void
		{
			if (data.length != 3) throw new Error("CitySelector value format request 3 id or string data. Input "+data.length);
			var dataField:String = (isNaN(data[0]))?"name":"uid";
			remoteDataProvider(-1,-1,countriesLoaded,null)
			function countriesLoaded(e:Object):void{
				countryValue = halfDivisionMethod(e.list,data[0],dataField);
				defaultSelects[0] = (e.list as Array).indexOf(countryValue);
				remoteDataProvider(countryValue.uid,-1,regionsLoaded,null)
			}
			function regionsLoaded(e:Object):void{
				regionValue = halfDivisionMethod(e.list,data[1],dataField);
				defaultSelects[1] = (e.list as Array).indexOf(regionValue);
				remoteDataProvider(-1,regionValue.uid,citesLoaded,null)
			}
			function citesLoaded(e:Object):void{
				cityValue = halfDivisionMethod(e.list,data[2],dataField);
				defaultSelects[2] = (e.list as Array).indexOf(cityValue);
				dispatchPlace(false);
			}
		}
		
		public function get value ():Array
		{
			if (_value == null) return [];
			var result:Array = [];
			
			if (_value.country_id != -1) result.push(_value.country_id);
			else result.push(0);
			
			if (_value.region_id != -1) result.push(_value.region_id);
			else result.push(0);
			
			if (_value.city_id != -1) result.push(_value.city_id);
			else result.push(0);
			
			return result;
		}
		
		private var popUpCreated:Boolean = false;
		public function createPopUp(e:MouseEvent = null):void{
			if (popUpCreated) 
					if (PopUpManager.contain(popUpHolder)) return;
					else{
						// был удален попАп менеждером, без вызова очистки
						canselButton_handler();
					}
			if (defaultSelects[0] == -1){
				defaultSelects = DEFAULT_CITY.slice();
			}
			popUpHolder = new Sprite();
			contentHolder = new Sprite();// чтобы содержать контент
			var contentMask:Shape = new Shape();
			contentHolder.mask = contentMask;
			var _width:Number = Math.max(DEFAULT_AUTOCOMPL_WIDTH+10,defaultWidth);//  хз почему но надо вычесть 1, иначе получается на 1 пиксель шире
			var _height:Number = HEIGHT;
			contentMask.graphics.beginFill(0);
			contentMask.graphics.drawRect(0,0,_width+1,HEIGHT+1);
			contentHolder.y = -HEIGHT;
			sumbitButton = new Button();
			sumbitButton.label = Lang("CITY_SUBMIT");
			sumbitButton.x = 10; sumbitButton.y = _height - sumbitButton.height - 5;
			sumbitButton.addEventListener(MouseEvent.CLICK,submitButton_handler,false,0,true);
			canselButton = new Button();
			canselButton.label = Lang("CITY_CANSEL");
			canselButton.x = _width - canselButton.width - 10; canselButton.y = sumbitButton.y;
			canselButton.addEventListener(MouseEvent.CLICK,canselButton_handler,false,0,true);
			popUpHolder.x = localToGlobal(new Point(0,0)).x + defaultWidth - _width - 1;
			popUpHolder.y = localToGlobal(new Point(0,0)).y + BUTTON_SIZE;
			contentHolder.addChild(sumbitButton);
			contentHolder.addChild(canselButton);
			popUpHolder.addChild(contentHolder);
			popUpHolder.addChild(contentMask);
			PopUpManager.addPopUp(popUpHolder);			
			popUpCreated = true;
			// создаем поля ввода
			numberOfAutoComplete = 0;
			
			// создаем typeSelector
			var lbl:EmbededTextField = new EmbededTextField(null,"w");
			lbl.text = Lang("CITY_SELECTOR_TYPE");
			lbl.x = 5;
			lbl.y = 5;
			contentHolder.addChild(lbl);
			
			typeSelector = new ComboBox();
			typeSelector.addEventListener(Event.CHANGE, onTypeChange_handler,false,0,true);
			var typeData:Array = Lang_arr("CITY_SELECTOR_TYPES");
			typeSelector.dataProvider.addItems([{label:typeData[0],data:0},{label:typeData[1],data:1},{label:typeData[2],data:2},{label:typeData[3],data:3}]); 
			typeSelector.setSize(Math.max(DEFAULT_AUTOCOMPL_WIDTH,defaultWidth-10),DEFAULT_AUTOCOMPL_HEIGHT);
			typeSelector.x = 5;
			typeSelector.y = lbl.y + DEFAULT_AUTOCOMPL_HEIGHT + 1;
			contentHolder.addChild(typeSelector);
			
			
			if (countryInput == null){
				countryInput = new AutoComplet();
				countryInput.setSize(Math.max(DEFAULT_AUTOCOMPL_WIDTH,defaultWidth-10),DEFAULT_AUTOCOMPL_HEIGHT);
				countryInput.addEventListener(AutoComplet.VALUE_COMPLETE,function(e:ListEvent):void{
					if (countryOnSelected != dispatchPlace) sumbitButton.enabled = false;
					else countryValue = e.item;
					if (countryOnSelected == dispatchPlace)
						dispatchPlace();
					else
						countryOnSelected(e);
				});
			}
			
			if (regionInput == null){
				regionInput =  new AutoComplet();
				regionInput.setSize(Math.max(DEFAULT_AUTOCOMPL_WIDTH,defaultWidth-10),DEFAULT_AUTOCOMPL_HEIGHT);
				regionInput.addEventListener(AutoComplet.VALUE_COMPLETE,function(e:ListEvent):void{
					if (regionOnSelected != dispatchPlace) sumbitButton.enabled = false;
					else regionValue = e.item;
					if (regionOnSelected == dispatchPlace)
						dispatchPlace();
					else
						regionOnSelected(e);
				});
			}
			
			if (cityInput == null){
				cityInput = new AutoComplet();
				cityInput.setSize(Math.max(DEFAULT_AUTOCOMPL_WIDTH,defaultWidth-10),DEFAULT_AUTOCOMPL_HEIGHT);
				cityInput.addEventListener(AutoComplet.VALUE_COMPLETE,function(e:ListEvent):void{
					if (cityOnSelected != dispatchPlace) sumbitButton.enabled = false;
					else cityValue = e.item;
					if (cityOnSelected == dispatchPlace)
						dispatchPlace();
					else
						cityOnSelected(e);
				});
			}
			
			TweenMax.to(contentHolder,SPEED,{y: 0});
			
			popUpHolder.addEventListener(MouseEvent.ROLL_OUT,onMouseRollOut_handler,false,0,true);
			popUpHolder.addEventListener(MouseEvent.ROLL_OVER,onMouseRollOver_handler,false,0,true);
			onMouseRollOut_handler();// чтоб закрыть, если пользоваель нажал и больше не двигаеть мышкой
			
			_placeType = placeType;
			if (_placeType == -1) _placeType = 0;
			typeSelector.selectedIndex = _placeType;
			onTypeChange_handler();
		}
		// согдать сомбобокс стран, начать загрузку списка стран
		private function createCountryInput():void{	
			if (_placeType<1) return;		
			if (!countryInputCreated){
				AddAutoComplet(countryInput,true,0);
				countryInputCreated = true;
			}			
			removeInput(1);
			removeInput(2);
			remoteDataProvider(-1,-1,countryComplete,countryError);
		}
		// закончить формирование комбобокса стран. Если выбрана страна, создать комбобокс региона и выполнить их загрузку
		private function countryComplete(e:Object):void{
			setData(countryInput,e.list,Lang("COUNTRY_PROMPT"),
				(_placeType == 1?dispatchPlace:createRegionInput),0);
		}
		private function countryError(e:Object):void{
			// TODO
			trace( Lang("ASK_PLACE_COUNRTY"));
		}
		/**
		 * Удалить комбобоксы города и региона, если есть
		 * Создает комбобокс регионов, загружает регионы. 
		 * Если загрузились города, то заменяется prompt и вешаются хандлеры от городов
		 * (иначе промпт и хандлеры регионов)
		 */
		private function createRegionInput(e:ListEvent):void{
			if (countryValue == e.item) return;
			countryValue = e.item;
			if (_placeType<2) return;						
			regionValue = null;
			cityValue = null;	
			remoteDataProvider(int(e.item.uid),-1,regionComplete,regionError);
			AddAutoComplet(regionInput,!regionInputCreated,1);
			regionInputCreated = true;
			removeInput(2);
			regionInput.prompt =  Lang("REGION_LOADING");
			regionInput.text = "";
		}
		private function regionComplete(e:Object):void{	
			if (e.type == "region"){
				// если регионы, то подготовиться для построения комбобоксов гоордов
				setData(regionInput,e.list, Lang("REGION_PROMPT"),
					(_placeType == 2? dispatchPlace:createCityInput),1);
			}else{
				// если города, то при вводе диспатчить событие городВыбран
				setData(regionInput,e.list, Lang("CITY_PROMPT"),citySuccess,2);
				cityValue = regionValue;
				regionValue = null;
			}				
		}
		private function regionError(e:Object):void{
			// TODO	
			trace( Lang("ASK_PLACE_REGION"));
		}
		private function createCityInput(e:ListEvent):void{
			if (regionValue == e.item) return;
			regionValue = e.item;
			if (_placeType<3) return;			
			regionValue = e.item;
			cityValue = null;
			remoteDataProvider(int(countryValue.uid),int(e.item.uid),cityComplete,cityError);
			AddAutoComplet(cityInput,!cityInputCreated,2);
			cityInputCreated = true;
		}
		private function cityComplete(e:Object):void{	
			setData(cityInput,e.list, Lang("CITY_PROMPT"),citySuccess,2);
		}
		private function cityError(e:Object):void{	
			// TODO
			trace( Lang("ASK_PLACE_CITY"));
		}
		/**
		 * Город успешно выбран, однако результат выбора еще не присвоен
		 */
		private function citySuccess(e:ListEvent):void{
			if (cityValue == e.item) return;
			cityValue = e.item;
			dispatchPlace();
		}
		
		private function submitButton_handler(e:MouseEvent):void{
			if (sumbitButton.enabled){
				dispatchPlace(true);
				canselButton_handler();
			}			
		}
		
		private function canselButton_handler(e:MouseEvent = null):void{
			if (countryInput != null) countryInput.clear();
			if (regionInput != null) regionInput.clear();
			if (cityInput != null) cityInput.clear();
			var clearAll:Function = function ():void{
				PopUpManager.removePopUp(popUpHolder);
				popUpHolder = null;
				contentHolder = null;
				countryValue = null;
				countryLabel = null;
				countryInput = null;
				countryInputCreated = false;
				regionValue = null;
				regionLabel = null;
				regionInput = null;
				regionInputCreated = false;
				cityValue = null;
				cityLabel = null;
				cityInput = null;
				cityInputCreated = false;
				sumbitButton.removeEventListener(MouseEvent.CLICK,submitButton_handler);
				canselButton.removeEventListener(MouseEvent.CLICK,canselButton_handler);
				sumbitButton = null;
				canselButton = null;
				popUpCreated = false;
			}
			stopCloseTimer();
			if (contentHolder != null)
				TweenMax.to(contentHolder,SPEED,{y: -HEIGHT,onComplete:clearAll});
				
			if (countryInput != null)
				countryInput.close(null,true);
				
			if (regionInput != null)
				regionInput.close(null,true);
				
			if (cityInput != null)
				cityInput.close(null,true);
			
			if (typeSelector != null)
				typeSelector.close();
				
			var m:FocusManager = new FocusManager(this);
			m.hideFocus();
		}
		
		/**
		 * closePopUp если false, то только выполнить необходимые присвоения переменных
		 * событие не диспатчить, попАп не закрывать (возможно он и не открыт)
		 */
		private function dispatchPlace(closePopUp:Boolean = false):void{
			//if (countryValue && regionValue && cityValue) DEFAULT_CITY = [countryValue.name,regionValue.name,cityValue.name];
			sumbitButton.enabled = true;
			var event:CitySelectorEvent = new CitySelectorEvent(CitySelectorEvent.SELECTED);
			textField.text = "";
			var _hint:String = "";
			textField.color = 0;
			textField.text = Lang_arr("CITY_SELECTOR_TYPES")[0];
			if (countryValue != null){
				if (_placeType > 0){
					event.country = countryValue.name;
					event.country_id = countryValue.uid;
					if (_placeType == 1)
						textField.text = countryValue.name;
					_hint += countryValue.name;
				}
				defaultSelects[0] = countryValue.name;
			}
			if (regionValue != null){				
				if (_placeType > 1){
					event.region = regionValue.name;
					event.region_id = regionValue.uid;
					if (_placeType == 2)
						textField.text = regionValue.name;
					_hint += "\n" + regionValue.name;
				}
				defaultSelects[1] = regionValue.name;
			}	
			if (cityValue != null){				
				if (_placeType == 3){
					event.city = cityValue.name;
					event.city_id = cityValue.uid;
					textField.text = cityValue.name;
					_hint += "\n" + cityValue.name;	
				}					
				
				defaultSelects[2] = cityValue.name;
			}
			_value = (event.clone() as CitySelectorEvent);
			hint = _hint;
			DEFAULT_CITY = defaultSelects.slice();
			
			if (closePopUp){
				DEFAULT_CITY = defaultSelects.slice();			
				dispatchEvent(event);	
				popUpHolder.removeEventListener(MouseEvent.ROLL_OUT,onMouseRollOut_handler);// чтобы не было создания таймера закрытия после того, как поп-ап исчезнет
				stopCloseTimer();
			}		
		}
		
		/**
		 * Установить "заполнение по умолчанию" согласно персональных данных пользователя или других даных
		 * @param ids массив id-шников [страна, регион, город]
		 * @param names массив названий [страна, регион, город]
		 * 
		 */
		public function setDefaultLocation(ids:Array,names:Array):void{
			if (DEFAULT_CITY.length == 0)
				value = names;
			var _hint:String = textField.text = names[0];
			textField.color = 0x000000;
			if (names[1] != null)
				if (names[1] != ""){
					_hint += "\n" + names[1];
					if (names[2] == null) textField.text += ". "+names[1];
						else
							if (names[2] == "")	textField.text += ". "+names[1];
				}
					
			if (names[2] != null)
				if (names[2] != ""){
					_hint += "\n" + names[2];
					textField.text += ". "+names[2];
				}					
			var event:CitySelectorEvent = new CitySelectorEvent("value");
			event.country = names[0];
			event.country_id = ids[0];
			event.region = names[1];
			event.region_id = ids[1];
			event.city = names[2];
			event.city_id = ids[2];
			_value = event;
			hint = _hint;
			defaultSelects = names.slice();
		}
		
		/**
		 * 
		 * @param cmpl ссылка на AutoComplet который нужно установиь
		 * @param add добавить ли на сцену, либо только поменять enable (т.к. он уже был добавлен)
		 * @param type тип автокомплита (страны=0, региона=1, города=2). Если add=true то вместе с ним добавить подпись
		 * 
		 */		
		private function AddAutoComplet(cmpl:AutoComplet,add:Boolean = true,index:int = 0):void{
			if (add) {
				var lbl:EmbededTextField = new EmbededTextField(null,"w");
				lbl.text = Lang_arr("CITY_SELECTOR_LABELS")[index];
				lbl.x = 5;
				lbl.y = numberOfAutoComplete*(DEFAULT_AUTOCOMPL_HEIGHT+18) + (DEFAULT_AUTOCOMPL_HEIGHT + 18) + 4;
				if (index == 0)countryLabel = lbl; else if (index == 1) regionLabel = lbl; else cityLabel = lbl;
				cmpl.x = 5;
				cmpl.y = lbl.y + DEFAULT_AUTOCOMPL_HEIGHT+1;
				cmpl.prompt = index == 0?Lang("COUNTRY_LOADING"):(index == 1?Lang("REGION_LOADING"):Lang("CITY_LOADING"));
				contentHolder.addChild(lbl);
				contentHolder.addChild(cmpl);
				cmpl.labelField = "name";
				cmpl.dataField = "uid";
				numberOfAutoComplete++;
			}			
			cmpl.enabled = false;
		}
		/**
		 * Абстрактная функиця-установкик данных для комбобоксов, когда данные успешно загружены
		 * index - обозначает поле ввода (0 - страна, 1 - регион, 2 - город), чтобы они обращались к массиву  defaultSelects
		 */
		private function setData(cmpl:AutoComplet,list:Array,prompt:String,onValue:Function,index:int):void{
			cmpl.dataProvider = list;
			cmpl.prompt = prompt;
			cmpl.text = "";
			cmpl.enabled = true;
			if (cmpl == countryInput)countryOnSelected = onValue;
			if (cmpl == regionInput)regionOnSelected = onValue;
			if (cmpl == cityInput)cityOnSelected = onValue;
			if (defaultSelects[index] != -1){
				if (defaultSelects[index] is String) 
					cmpl.selectIndex(-1,defaultSelects[index]);
				else 
					cmpl.selectIndex(defaultSelects[index]);
				//defaultSelects[index] = -1;
			}
		}
		
		private function onMouseRollOut_handler(e:MouseEvent = null):void{
			stopCloseTimer();
			closeTimer = TweenMax.delayedCall(4,canselButton_handler);
		}
		
		private function onMouseRollOver_handler(e:MouseEvent):void{
			stopCloseTimer();
		}
		
		private function stopCloseTimer():void{
			if (closeTimer != null) 
				closeTimer.kill();
		}
		
		// возвращает тип: 0 для мира, 1 для страны, 2 для региона, 3 для города
		public function get placeType():int{
			if (_value.type == "init") return -1;
			if (_value.country_id == -1) return 0;
			if (_value.region_id == -1) return 1;
			if (_value.city_id == -1) return 2;
			return 3;
		}
		
		private var _placeType:int = 0;
		private function onTypeChange_handler(e:Event = null):void{
			var type:int = (e == null? _placeType: int(ComboBox(e.target).value))
			if (_placeType != type || (e == null))
			{
				_placeType = type;
				if (type == 0){
					removeInput(0);
					removeInput(1);
					removeInput(2);
					dispatchPlace(false);
				}					
				else{
					sumbitButton.enabled = false
					createCountryInput();
				}
									
			}
		}
		
		// удалить поле ввода (0 - страны, 1 - региона, 2 - города)
		private function removeInput(index:int):void{
			var arr:Array = ["country","region","city"];
			if (this[arr[index] + "InputCreated"]){
				contentHolder.removeChild(this[arr[index] + "Input"]);			
				contentHolder.removeChild(this[arr[index] + "Label"]);	
				numberOfAutoComplete--;
				this[arr[index] + "InputCreated"] = false;
			}
		}
	}
}











import flash.events.Event;

class CitySelectorEvent extends Event
{
	public static var SELECTED:String = "citySelector_Selected";
	
	public var country:String = "";
	public var region:String = "";
	public var city:String = "";
	
	public var country_id:int = -1;
	public var region_id:int = -1;
	public var city_id:int = -1;
	
	
	public function CitySelectorEvent(type:String)
	{
		super(type);
	}
	
	override public function clone():Event{
		var event:CitySelectorEvent = new CitySelectorEvent(type);
		event.country = country;
		event.region = region;
		event.city = city;
		event.country_id = country_id;
		event.region_id = region_id;
		event.city_id = city_id;			
		return event;
	}
	
	// возвращает тип: 0 для мира, 1 для страны, 2 для региона, 3 для города
	public function get placeType():int
	{
		if (country_id == -1) return 0;
		if (region_id == -1) return 1;
		if (city_id == -1) return 2;
		return 3;
	}
}











/**
 * Находит среди элементов list объект. у когорого labelField=wish
 * Все элементы list должны быть в алфавитном порядке относительно labelField
 * Возвращает найденный объект
 */
function halfDivisionMethod(list:Array, wish:String,labelField:String = "title"):Object{
	var success:Boolean = false; 
	var iterator:int = 1000; 
	var minLimit:int = 0;						
	var maxLimit:int = list.length;
	var centerLimit:int;
	while (iterator>0){
		iterator--;
		centerLimit = minLimit+int((maxLimit-minLimit)/2);
		if (list[centerLimit][labelField]>wish) {maxLimit = centerLimit;continue;}
		if (list[centerLimit][labelField]<wish) {minLimit = centerLimit;continue;}
		if (list[centerLimit][labelField]==wish) {
			success = true;
			break;
		}
		if (list[maxLimit][labelField]==wish) {
			centerLimit = maxLimit;
			success = true;
			break;
		}
		if (minLimit == maxLimit) break;					
	}
	if (success){
		return list[centerLimit];
	}
	// если не был найден элемент, проводим полный перебор (видимо нарушен алфамитный порядок)
	for (var i:int = 0;i<list.length;i++)
		if (list[centerLimit][labelField]==wish)
			return list[i];
	
	return null;// если искомый элемент не найден
}




function Lang(msg:String):String
{
	return msg;
}




function Lang_arr(msg:String):Array
{
	if(msg == "CITY_SELECTOR_TYPES")
		return ["мир","страна","регион","город"];
	if(msg == "CITY_SELECTOR_LABELS")
		return ["страна","регион","город"];
	throw new Error("City selector unknown lang array");
}