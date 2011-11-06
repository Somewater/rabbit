package com.somewater.rabbit.iso
{
	import com.astar.Astar;
	import com.astar.Map;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.scene.IsoLayer;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	import flash.geom.Point;
	
	public class IsoSpatial extends SimpleSpatialComponent
	{	

		private var tempTilePos:Point = new Point();// для свойства get tile
		protected var _renderer:IsoRenderer;// для быстрого доступа, ссылка на @Render
		protected var _renderLayer:IsoLayer;// для быстрого доступа
		protected var _nullSize:Boolean = true;// объект имеет нулевой размер 0х0
		private var tempCenterPositionPoint:Point = new Point();
		
		/**
		 * Битовая маска, которую занимает под себя объект, становясь на тайл
		 * ВНИМАНИЕ: должна быть устнановлена перед вызовом метода set tile
		 */
		public var occupyMask:uint = 0;
		
		/**
		 * Биты, которые должны быть выставлены (не заняты другими), чтобы объект мог стать на тайл
		 * ВНИМАНИЕ: должна быть устнановлена перед вызовом метода set tile
		 */
		public var passMask:uint = 0;
		
		
		
		/**
		 * Флаг, задающий особые правила, при вычислении занятости/незанятости тайлов данным объектом
		 * Обеспечивает хуки, направленные на создание особых типов поведения (например, бревно)
		 * 
		 * биты:
		 * 	1 	при вычислении нового бита проходимости тайла, вызывать
		 * 		ф-ю getOccupyMask(tileIndex:uint):int вместо occupyMask
		 *  2	все вычисления должны производиться через функцию IThinkWall().getOccupyMask
		 * 		причем наличие других объектов в тайле игнорируется
		 */
		public var occupyMaskRule:uint;
		
		
		public function IsoSpatial()
		{
			super();
		}
		
		
		/**
		 * ПОместить объект в заданный тайл карты
		 * Сладующие свойства УЖЕ должны быть установлены:
		 * 	- size
		 *  - occupyMask
		 *  - passMask
		 */
		public function set tile(value:Point):void
		{
			tempTilePos.x = int(value.x);
			tempTilePos.y = int(value.y);
			position = IsoSpatialManager.centrePosition(tempTilePos, _size);
			IsoSpatialManager.instance.refreshPathTile(tempTilePos.x + (tempTilePos.y << 16));
		}
		
		public function get tile():Point
		{
			tempTilePos.x = int(_position.x);
			tempTilePos.y = int(_position.y);
			return tempTilePos;
		}
		
		override public function set position(value:Point):void
		{
			CONFIG::debug
			{
				if(_size.x < 0 || _size.y < 0)
					throw new Error("Size must be assigned before position");
			}
			// обновить регистрационные массивы
			var esp:Number = 0.000001;// применяется чтобы координата правого нижнего угла "9"считалась как лежащая в тайле "8"
			if(int(_position.x) != int(value.x) || // если меняется тайл точки регистрации
				int(_position.y) != int(value.y) || (_size.length && 
					// или если меняется тайл "удаленной от 0" крайней точки
				(int(_position.x + _size.x - esp) != int(value.x + _size.x - esp) || 
					int(_position.y + _size.y - esp) != int(value.y + _size.y - esp))))
				IsoSpatialManager(spatialManager).refreshRegistration(this, _position.x, _position.y, _size.x, _size.y, value.x, value.y,  _size.x, _size.y);
			
			super.position = value;
			
			if(createRenderLink())
				_renderer.position = value;
		}
		
		
		/**
		 * ВОзвращает координату центра масс персонажа
		 * (для персонажей, имеющих ненулевой размер, такая точка отличается от position)
		 */
		public function get centerPosition():Point
		{
			tempCenterPositionPoint.x = _position.x;
			tempCenterPositionPoint.y = _position.y;
			if(!_nullSize)
			{
				tempCenterPositionPoint.x += _size.x * 0.5;
				tempCenterPositionPoint.y += _size.y * 0.5;
			}
			return tempCenterPositionPoint;
		}
		
		
		override public function set size(value:Point):void
		{			
			CONFIG::debug
			{
				if(occupyMask == 0 && passMask == 0)
					throw new Error("Must be initialized before size property");
			}
			// обновить регистрационные массивы
			if(value.x != _size.x || value.y != _size.y || value == _size)// если value,_size один объект Point, на всякий случай применяем изменения (например, они сделаны в TemplateManager)
				IsoSpatialManager.instance.refreshRegistration(this, _position.x, _position.y, _size.x, _size.y, _position.x, _position.y, value.x, value.y);
			
			_size.x = value.x;
			_size.y = value.y;
			_nullSize = _size.x == 0 && _size.y == 0;
			
			if(createRenderLink())
				_renderer.size = value;
		}
		
		
		
		override protected function onRemove():void
		{
			super.onRemove();
			
			IsoSpatialManager.instance.refreshRegistration(this, _position.x, _position.y, _size.x, _size.y, 0, 0, 0, 0, 0x1);
			
			_position.x = int.MIN_VALUE;
			_position.y = int.MIN_VALUE;
			
			_size.x = -1;
			_size.y = -1;
		}
		
		
		
		/**
		 * Осуществить инициализацию ссылок на @Render и layer,
		 * а также вызвать пересортировку z-индексов
		 * @return инициализация произведела
		 */
		protected function createRenderLink():Boolean
		{
			if(_renderer == null)
				_renderer = owner.lookupComponentByType(IsoRenderer) as IsoRenderer;
			if(_renderer == null) return false;
			
			if(_renderLayer == null)
				_renderLayer = PBE.scene.getLayer(_renderer.layerIndex, true) as IsoLayer;
				// KLUDGE: еще невозможно знать layerIndex
			
			if(_renderer.zIndexSorted)
			{
				if(_size && (_size.x || _size.y))
					_renderLayer.markDirty();
				else{
					_renderLayer.unsortedSimpleQueue.push(_renderer);
				}
				_renderer.zIndexSorted = false;
			}
			
			return true;
		}
		
		/**
		 * Дает координату объекта в "экранном" представлении
		 */
		public function get screenPosition():Point
		{
			return IsoRenderer.isoToScreen(_position.clone());
		}
	}
}