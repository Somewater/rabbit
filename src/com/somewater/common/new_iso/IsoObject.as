package com.somewater.common.new_iso
{

	import com.somewater.common.GameObject;
	import com.somewater.common.StateGameObject;
	import com.somewater.common.factory.McFactory;
	import com.somewater.common.global.Env;
	import com.somewater.common.global.IconConfig;
	import com.somewater.common.managers.LayerManager;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	/**
	 * Реализует работу с изометрическими координатами в составе с классом IsoContainer
	 * 
	 * Обеспечивает перемещение объекта в нужную область 
	 * путём установки как экранных, так и изометрических (и тайловых) координат.
	 * Возвращает координаты объекта в разных системах отсчета:
	 * <li>screen привычная всем флешерам система экранных координат типа x, y</li>
	 * <li>iso система координат при виде сверху (измеряется в пикселях)</li>
	 * <li>tile система координат при виде сверху (измеряется в тайлах!). Отличается от iso координат делением на размер тайла</li>
	 * <listing>
	 * // пример использования
	 * var item:IsoObject = new IsoObject();
	 * item.tilePos = new Point(5,5);// поместить в тайл {5, 5}
	 * var p:Point = item.screenPos;// получили экранные координаты объекта
	 * p.x += 1;
	 * item.screenPos = p;// фактически передвинули объект на 1 пиксель вправо
	 * p = item.tilePos;
	 * trace(p);// [5.04, 4.96] - т.е. передвинули объект на некоторую величину и в тайловых координатах
	 * p.x = 6;
	 * p.y = 5;
	 * item.tilePos = p;// передвинули объект ровно в {6, 4} тайл
	 * p = item.isoPos;
	 * p.x += TILE_SIZE/2;
	 * item.isoPos = p;// передвинули объект на пол тайла вправо, в {6.5, 4} тайл
	 * </listing>
	 * @author mister
	 */
	public class IsoObject extends StateGameObject
	{
		/**
		 *	Высота объекта.
		 * 	Может быть и отрицательной. 
		 * 	При отрицательной высоте будет добавлять в отдельные "нижние уровни".
		 */		
		public var objectZ:int = 0;
		
		/**
		 *	Физические ширина и высота 
		 */		
		protected var _pWidth:Number = 1;
		
		/**
		 * Переменная, переопределяемая в конструкторе класса
		 * если true, значит контейнер объекта должен добавлять его в
		 * tickObjects при добавлении в себя
		 */
		public function get needTicking():Boolean
		{
			return _needTicking;
		}

		/**
		 * @private
		 */
		public function set needTicking(value:Boolean):void
		{
			_needTicking = value;
			
			if(!parentGameObject)
				return;
			
			if(value)
				parentGameObject.addToTick(this);
			else
				parentGameObject.removeFromTick(this);
		}

		public function get pWidth():Number
		{
			return _pWidth;
		}
		
		public function set pWidth(value:Number):void
		{
			_pWidth = value;
		}
		
		protected var _pHeight:Number = 1;
		
		public function get pHeight():Number
		{
			return _pHeight;
		}
		
		public function set pHeight(value:Number):void
		{
			_pHeight = value;
		}
				
		protected var _pTopLeft:Point = new Point(); 
		
		/**
		 * Верхняя левая физическая точка. Менять не получиться. 
		 * Новый объект не создается.
		 */		
		public function get pTopLeft():Point
		{
			if(!_position)
				return null;
			
			// если _pWidth и _pHeight == 0, то это ни на что не влияет
			
			var w1:Number = _position.width/2 - _pWidth/2;
			var h1:Number = _position.height/2 - _pHeight/2;
			
			if(w1 != _pTopLeft.x)
				_pTopLeft.x = w1;
			
			if(h1 != _pTopLeft.y)
				_pTopLeft.y = h1;
			
			return _pTopLeft;
		}
		
		protected var _pBottomRight:Point = new Point(); 
		
		/**
		 * Нижняя правая точка. Менять не получиться.		 
		 * Новый объект не создается.
		 * Для многотайлового объекта берем остаток.
		 * Два многотайловых объекта заползают своими углами (один ниж.-прав., второй верх.-левый) 
		 * на один тайл. Это единственная возможная ситуация, так как во всех остальных случаях один из объектов
		 * пометит тайл как занятый  - для этого и берем остаток - 
		 * чтобы учитывался не весь тайл, а только нижний правый из всех.
		 */		
		public function get pBottomRight():Point
		{
			if(!_position)
				return null;
			
			var w1:Number, h1:Number;
			
			// имеет смысл, если объект обладает физ. шириной и высотой
			if(_pWidth > 0 && _pHeight > 0)
			{
				w1 = _position.width/2 + _pWidth/2;
				h1 = _position.height/2 + _pHeight/2;
			}
			else
				w1 = h1 = 0;
			
			if(w1 != int(w1))
				w1 = w1 - int(w1);
			
			if(h1 != int(h1))
				h1 = h1 - int(h1);	
			
			if(w1 != _pBottomRight.x)
				_pBottomRight.x = w1;
			
			if(h1 != _pBottomRight.y)
				_pBottomRight.y = h1;
			
			return _pBottomRight;
		}
		
		/**
		 * Отсортирован ли данный объект. Если нет и производится изменение координаты/положения, 
		 * то не производится повторной постановки объекта в очередь на пересортировку
		 * Устанавливается в true в классе IsoContainer после пересортировки
		 */
		internal var _sorted:Boolean = false;
		
		/**
		 * Ссылка на объект, хранящий пространственные свойтсва объекта, в том числе размер
		 */
		internal var _position:IsoPoint;
		
		
		private var _needTicking:Boolean = false;

		// сколько времени должно пройти до того, как 
		// иконка будет выгружена после ухода мышки
		public static const MOUSE_ICON_TIMEOUT:int = 2000;
		
		protected var mouseIconTimeValue:int;
		protected var iconTimeValue:int;
		
		protected var _hideIcon:Boolean = false;
		/**
		 *	Непосредственно сама иконка. 
		 */		
		protected var iconMovieClip:*;
		/**
		 *	Массив имеющий вид "название иконки" -> "номер кадра"
		 * 	 Должно быть настроено в createIcons (в наследниках).
		 */		
		protected var iconStates:Object = {};
		
		/**
		 *	Настройки иконок. 
		 * 	"ключ" = объект IconConfig 
		 * 	Должен настраиваться в createIcons (в наследниках).
		 */		
		protected var iconConfig:Object = {};
		
		/**
		 * slug для иконок.
		 * Должно быть настроено в createIcons (в наследниках).
		 */		
		protected var iconSlug:String = "";
		
		/**
		 *	Активная иконка 
		 */		
		protected var activeIcon:String = "";
		
		/**
		 * Значение скейла иконки
		 */ 
		protected var iconScale:Number = 0;
		
		/**
		 * Отображаем необходимую иконку над объектом. 
		 */		
		public function showIcon(icon:String, ...params):void
		{
			if(!iconStates[icon])// || iconSlug == "")
				return;
						
			iconTimeValue = 0;
			
			hideIcon();

			if(iconConfig[icon])
			{
				if((iconConfig[icon] as IconConfig).onMouse)
					if(!selected) return;
				
				if((iconConfig[icon] as IconConfig).delay)
					iconTimeValue = getTimer();
			}
			
			if(icon == activeIcon)
			{
				resumeIcon();
				return;
			}
			else
				iconScale = 0;
			
			createIconObject(icon, params);
			
			(iconMovieClip as MovieClip).visible = (iconTimeValue == 0);
			
			activeIcon = icon;
		}
		
		protected function createIconObject(icon:String, params:Array=null):void
		{
			// если пред. иконка была gameObject, то анлоадим её
			if(iconMovieClip is GameObject)
				removeIcon();
			
			if(!iconMovieClip)
			{
				iconMovieClip = getIconMovieClip(iconSlug, Env.iconAssetKey);
				addChild(iconMovieClip);
			}
			
			(iconMovieClip as MovieClip).gotoAndStop(iconStates[icon]);
		}
		
		protected function getIconMovieClip(slug:String, key:String):MovieClip
		{
			var clip:MovieClip = McFactory.createMc(slug, key);
			clip.cacheAsBitmap = true;
			
			updateIconScale(clip);

			return clip;
		}
				
		public function hideIcon():void
		{
			if((iconMovieClip as MovieClip) && (iconMovieClip as MovieClip).visible)
			{
				mouseIconTimeValue = getTimer();
				(iconMovieClip as MovieClip).visible = false;
//				_hideIcon = true;
			}
		}
		
		protected function iconEvents():void
		{
			updateIconScale(iconMovieClip);
			
			// заданное поведение иконок
			if(iconConfig[activeIcon])
			{
				if(!_hideIcon && (iconConfig[activeIcon] as IconConfig).delay)
					resumeIcon();
				
				if((iconConfig[activeIcon] as IconConfig).onMouse)
				{
					if(selected)
					{
						resumeIcon();
						iconTimeValue = 0;
						return;
					}
					
					if(!(iconMovieClip as MovieClip).visible)
					{
						if((getTimer() - mouseIconTimeValue) >= MOUSE_ICON_TIMEOUT)
							removeIcon();
					}
					else
					{
						if((iconConfig[activeIcon] as IconConfig).onMouseOutDelay)
						{
							if(!iconTimeValue)
								iconTimeValue = getTimer();
							
							if((getTimer() - iconTimeValue) <= (iconConfig[activeIcon] as IconConfig).onMouseOutDelay)
								return;
						}
						
						hideIcon();
						_hideIcon = true;
					}
				}
			}
		}
		
		public function resumeIcon():void
		{			
			if((iconMovieClip as MovieClip) && !(iconMovieClip as MovieClip).visible)
			{
				if((iconConfig[activeIcon] as IconConfig) && (iconConfig[activeIcon] as IconConfig).delay && iconTimeValue)
				{
					if(!iconTimeValue)
						iconTimeValue = getTimer();
					
					if((getTimer() - iconTimeValue) > (iconConfig[activeIcon] as IconConfig).delay)
					{
						iconTimeValue = 0;
						updateIconScale(iconMovieClip);
						(iconMovieClip as MovieClip).visible = true;
					}
				}
				else
				{
					updateIconScale(iconMovieClip);
					(iconMovieClip as MovieClip).visible = true;
				}
			}
		}
		
		public function removeIcon():void
		{
			if(activeIcon != "")
			{
				if(iconMovieClip is GameObject)
				{
					removeTickObject((iconMovieClip as GameObject));
					(iconMovieClip as GameObject).unLoad();
				}
				
				if(iconMovieClip is MovieClip)
				{
					if(contains(iconMovieClip as MovieClip))
						removeChild((iconMovieClip as MovieClip));
					
					iconMovieClip = null;
				}
				
				trace("remove icon ",activeIcon);
				
				activeIcon = "";
				_hideIcon = false;
			}
		}
		
		
		protected function updateIconScale(iconClip:MovieClip):void
		{
			if(iconClip && 
				iconScale != 
				((1/LayerManager.GAME_LAYER.scaleX) > Env.iconMaxScale ? Env.iconMaxScale : (1/LayerManager.GAME_LAYER.scaleX)))
			{
				var localMc:MovieClip = (iconClip is GameObject) ? iconClip.mc : iconClip;
				
				iconScale = 
					((1/LayerManager.GAME_LAYER.scaleX) > Env.iconMaxScale ? Env.iconMaxScale : (1/LayerManager.GAME_LAYER.scaleX));	
				
				localMc.scaleX = localMc.scaleY = iconScale;
				
				updateIconPosition(iconClip);
			}
		}
		
		protected function updateIconPosition(iconClip:MovieClip):void
		{			
			var localMc:MovieClip = (iconClip is GameObject) ? iconClip.mc : iconClip;
			
			var exists:Boolean = contains(iconClip);

			if(exists)
				removeChild(iconClip);
			
			var localScale:Number = iconScale<1?1:iconScale;
			
			var rect:Rectangle = getBounds(this);
			
			localMc.x = -localMc.width/2;
			localMc.y = Math.max(-230 * localScale, rect.top - localMc.height - 20 * localScale);
			
			trace("update icon - ",activeIcon);
			
			if(exists)
				addChild(iconClip);
		}
		
		protected function createIcons():void
		{
			
		}
		
		private var _selected:Boolean;
		
		public function get selected():Boolean
		{
			return this._selected;
		}
		
		public function set selected(value:Boolean):void
		{
			this._selected = value;
			
			// обновляем иконки
			updateState();
			// и сразу проверяем состояние иконки
			iconEvents();
		}
		
		public function IsoObject(mc:MovieClip = null)
		{
			super(mc);
			
			// присваиваем им всем 1-ну ссылку, потому что при изменении они все корректно перезапишутся. А 0 - он во всех системах отсчета 0
			// теперь так - нельзя добавлятьэлемент на карту пока у него не будет выставлен position
			//_position = new IsoPoint();

			// TODO: в целях тестирования рисуем IsoObject как прямоугольник, который он занимает
			
			createIcons();
		}
		
		
		/**
		 * Получить пространственные свойства объекта
		 * Внимание: изменение объекта position не повлечет изменений IsoObject
		 * пока не будет вызвана функция set position
		 */
		public function get position():IsoPoint{
			return _position;	
		}
		
		/**
		 * Установить пространственные свойсова объекта
		 */
		public function set position(value:IsoPoint):void{
			// TODO можно убрать в релизе проверку на parentGameObject
			//if(!parentGameObject) throw new Error("You must be insert object in parent object before position definition: IsoContainer.addObject(object)");
			_position = value;
			if( _position ) refreshSpatial();
		}
		
		/**
		 * Рисует прямоугольник, заданный в iso-координатах
		 * (предварительно устанавливать параметры рисования)
		 * Функция сделана для дебага и не несет художественной ценности
		 */		
		public function drawIsoRect(isoRect:Rectangle):void{
			// получили 4-ре уловые точки прямоугольника
			var p1:Point = isoRect.topLeft.clone();
			var p2:Point = new Point(isoRect.right, isoRect.y);
			var p3:Point = isoRect.bottomRight.clone();
			var p4:Point = new Point(isoRect.x, isoRect.bottom);
			// преобразовали в iso-координаты (вид сверху)
			IsoPoint.isoToScreen(p1);
			IsoPoint.isoToScreen(p2);
			IsoPoint.isoToScreen(p3);
			IsoPoint.isoToScreen(p4);
			// нарисовали (параметры цвета и т.д. должны выставляться перед вызовом функции)
			graphics.moveTo(p1.x, p1.y);
			graphics.lineTo(p2.x, p2.y);
			graphics.lineTo(p3.x, p3.y);
			graphics.lineTo(p4.x, p4.y);
		}
		
		
		/**
		 * Возвратить позицию объекта относительно другой комнаты
		 * (в "тайловых" координатах)
		 */
		public function convertTilePos(newContainer:DisplayObjectContainer):Point{
			// TODO: подумать, как это сделать для разных степеней вложенности контейнеров
			return null
		}
		
		
		
		/**
		 * Обеспечивает корректную замену текущих координат, при смене контейнера
		 * (при последовательном вызове oldCont.removeObject(this); newCont.addObject(this); 
		 * не произойдет корректной замены координат)
		 */
		public function changeContainer(newContainer:IsoContainer):void{
			if(parentGameObject == null)
				newContainer.addChild(this);
			else
				throw new Error("TODO");
		}
		
		/**
		 * Удалить ссылки на объект для корректной работы GC
		 */
		override protected function unLoadComplete():void{
			if(parentGameObject is IsoContainer)
				IsoContainer(parentGameObject).removeObject(this);
			super.unLoadComplete();
		}
		
		
		override public function tick(arg1:int=0):void
		{
			super.tick(arg1);
			iconEvents();
		}
		
		override public function unLoad():void
		{
			removeIcon();
			super.unLoad();
		}
		
		
		/**
		 * Обновляет экранное положение объекта, вызывает пересортировку
		 * Можно вызывать данный метод, не прибегая к set position
		 * <listing>
		 * obj.position.offset(10, 10);
		 * obj.refreshSpatial();
		 * </listing>
		 */
		protected function refreshSpatial():void{
			// устанавливаем корректное положение при прорисовке
			var newPos:Point = _position.topLeft.clone();
			newPos.x += _position.size.x * 0.5;
			newPos.y += _position.size.y * 0.5;
			IsoPoint.isoToScreen(newPos);
			var empty:Boolean = (this is IsoMover);
			x = newPos.x;
			y = newPos.y;
			// если на данный момент считается правильно отсортированным, запросить пересортировку у контейнера
			if(_sorted){
				
				if(parentGameObject)
				{
					if(!empty)
						IsoContainer(parentGameObject).needGlobalSorting = true;
					IsoContainer(parentGameObject).unsortedQueue.push(this);
				}
				
				_sorted = false;
			}
		}
	}
}