package com.somewater.common.new_iso
{
	import com.somewater.utils.Profiler;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import com.somewater.rabbit.iso.IsoObject;

	/**
	 * 
	 * @author mister
	 * 
	 */
	public class IsoContainer extends IsoObject
	{
		/**
		 * Очередь БЕЗРАЗМЕРНЫХ (человечки и т.д.) элементов, требующих пересортировки
		 */
		internal var unsortedQueue:Array;
		
		
		/**
		 * На следующем тике необходимо провести полную сортировку (рекурсивно)
		 */
		internal var needGlobalSorting:Boolean = false;
		
		/**
		 * Содержит все IsoObject-ты, содержащиеся в контейнере
		 * (в произвольном порядке)
		 */
		public var isoObjects:Array; //public нужно для использования в WorldController
		
		/**
		 * Содержит всех муверсов, содержащихся в контейнере 
		 * (по этому массиву осуществляется проверка наличия существ в тайле)
		 */
		protected var emptyObjects:Array;
		
		
		/**
		 * Содержит только  IsoObject-ты, которые на данны момент правильно отсортированы,
		 * в порядке их сортировки
		 */
		protected var sortedObjects:Array;
		
		/**
		 * Число фоновых "детей", которые не являются IsoObject. (например нижний фон)
		 * Данный параметр должен устанавливаться вручную в каждом конкретном случае
		 */
		protected var numGrounds:int;
		
		public function IsoContainer(mc:MovieClip = null)
		{
			blitting=false;
			_position = new IsoPoint();
			
			// mc будет служить фоном, не подверженным сортировкам IsoObject-ов
			numGrounds = (mc?1:0);
			needTicking = true;
			super(mc);
			isoObjects = [];
			sortedObjects = [];
			unsortedQueue = [];
			emptyObjects = [];
		}
		
		override public function tick(time:int=0):void{	
			Profiler.enter("IsoContainer.tick");
			Profiler.enter("IsoContainer.super.tick");
			super.tick(time);
			Profiler.exit("IsoContainer.super.tick");
			if(needGlobalSorting){
				recursiveSorting();
			}else if(unsortedQueue.length){
				simpleSorting();
			}
			Profiler.exit("IsoContainer.tick");
		}
		
		/**
		 * Добавляет IsoObject в контейнер
		 * 
		 * Нельзя добавлять на карту
		 * элемент, если он не имеет позиции. 
		 * 
		 * @return объект был успешно добавлен в контейнер
		 */
		public function addObject(object:IsoObject):Boolean{
			// добавляем на карту, только если есть position

			if(object.position != null && isoObjects.indexOf(object) == -1)
			{
				// удалить из старого контейнера
				if(object.parentGameObject)
					IsoContainer(object.parentGameObject).removeChild(object);
				
				isoObjects.push(object);
				
				addChild(object);
				// поставить в очереь на стортировку. Муверсов поместить в особый массив
				if(object is IsoMover){
					unsortedQueue.push(object);
					emptyObjects.push(object);
				}else
					needGlobalSorting = true;
				
				// если это IsoContainer, добавить в tickObject для сортировки
				if(object.needTicking)
					addTickObject(object);
				
				object.parentGameObject = this;
				return true
			}
			trace('addObject - position is null!');
			return false;
		}
		
		/**
		 * Удаляет IsoObject  в контейнер и чистит все ссылки на него (в пределах текущего контейнера)
		 */
		public function removeObject(object:IsoObject):void{
			// удалить из всех массивов
			var index:int = isoObjects.indexOf(object);
			if(index != -1)
				isoObjects.splice(index, 1);
			if(object is IsoMover){
				var emptyIndex:int = emptyObjects.indexOf(object);
				if(emptyIndex != -1)
					emptyObjects.splice(emptyIndex, 1);
			}
			var sortedIndex:int = sortedObjects.indexOf(object);
			var unsortedIndex:int = unsortedQueue.indexOf(object);
			var tickIndex:int = tickObjects.indexOf(object);
			if(sortedIndex != -1)
				sortedObjects.splice(sortedIndex, 1);
			if(unsortedIndex != -1)
				unsortedQueue.splice(unsortedIndex, 1);
			if(tickIndex != -1)
				tickObjects.splice(tickIndex, 1);
			if(contains(object))
				removeChild(object);				
			object.parentGameObject = null;
		}
		
		/**
		 * @param isoPoint тестируемая точка в "тайловых" координатах
		 * @param exclude объект, который в процессе проверке не будет учтен, как занимающий место 
		 * (применяется для проверки возможности перемещения именно для этого объекта)
		 * @return Определяет, занята ли точка каким-либо объектом в iso координатах
		 */
		public function pointIsFree(isoPoint:Point, exclude:IsoObject = null):Boolean{
			if(!_position.containsPoint(isoPoint)) return false;
			for(var i:int = 0;i<isoObjects.length;i++)
				if(IsoObject(isoObjects[i])._position.containsPoint(isoPoint))
					return false;
			return true;
		}
		
		/**
		 * @param isoRect тестируемый прямоугольник в "тайловых" координатах (можно задлавать функции IsoPoint)
		 * @param exclude объект, который в процессе проверке не будет учтен, как занимающий место 
		 * (применяется для проверки возможности перемещения именно для этого объекта)
		 * @return Определяет, занят ли прямоугольник каким-либо объектом в iso координатах
		 */
		public function isoPointIsFree(isoRect:Rectangle, exclude:IsoObject = null):Boolean{
			if(!_position.containsRect(isoRect)) return false;
			if(isoRect.isEmpty()) return pointIsFree(isoRect.topLeft, exclude)
			for(var i:int = 0;i<isoObjects.length;i++)
				if(IsoObject(isoObjects[i])._position.intersects(isoRect) && exclude != isoObjects[i])
					return false;
			return true;
		}
		
		/**
		 * @return содержится ли в прямоугольнике какой либо мувер (как правило - живое существо)
		 * Аналогична функции isoPointIsFree, однако не проверяет коллизии с объектами, имеющими размеры
		 */
		public function isoPointUninhabited(isoRect:Rectangle, exclude:IsoObject = null):Boolean{
//			return true;
			
			if(!_position.containsRect(isoRect)) return false;
			for(var i:int = 0;i<emptyObjects.length;i++){
				var obj:IsoObject = emptyObjects[i];
				if(obj != exclude){
					var tile:Point = obj._position.tile;
					if(tile.x == int(isoRect.x) && tile.y == int(isoRect.y))
						return false;
				}
			}
			return true;
		}
		
		
		
		/**
		 * Позиция мыши в "тайловых" координатах объекта
		 * (округленная до ближайшего тайла)
		 */
		public function get mouseTilePos():Point{
			var mp:Point = new Point(this.mouseX, this.mouseY);
			IsoPoint.screenToIso(mp);
			// для правильного округления отриц координат, иначе будет так: int(-0.8) = 0;
			if (mp.x < 0) mp.x--;
			if (mp.y < 0) mp.y--;
			// привели координаты к тайловым (отсечение остатка от деления)
			mp.x = int(mp.x);
			mp.y = int(mp.y);
			return mp;
		}
		
		
		/**
		 * Позиция мыши абсолютная (неокругленная)
		 */
		public function get mousePos():Point{
			var mp:Point = new Point(this.mouseX, this.mouseY);
			IsoPoint.screenToIso(mp);
			return mp;
		}
		

		
		/**
		 * Сортировка из фреймворка isolib
		 * Применяется для наиболее сложных способов: когда был передвинут (или изменил размер) объект с ненулевым размером
		 * @see com.progrestar.common.new_iso.simpleSorting
		 */
		private function recursiveSorting ():void
		{
			Profiler.enter("recursiveSorting");
			//var startTime:uint = getTimer();
			var depth:uint;
			var visited:Dictionary = new Dictionary();
			var dependency:Dictionary;

			// TODO - cache dependencies between frames, only adjust invalidated objects, keeping old ordering as best as possible
			// IIsoDisplayObject -> [obj that should be behind the key]
			dependency = new Dictionary();
			
			// For now, use the non-rearranging display list so that the dependency sort will tend to create similar output each pass
			var children:Array = isoObjects;
			
			// Full naive cartesian scan, see what objects are behind child[i]
			// TODO - screen space subdivision to limit dependency scan
			var max:uint = children.length;
			for (var i:uint = 0; i < max; ++i)
			{
				var behind:Array = [];
				
				var objA:IsoObject = children[i];
				// TODO - direct access ("public var isoX" instead of "function get x") of the object's fields is a TON faster.
				//   Even "final function get" doesn't inline it to direct access, yielding the same speed as plain "function get".
				//   use namespaces to provide raw access?
				//   rename interface class = IsoDisplayObject, concrete class = IsoDisplayObject_impl with public fields?
				
				// TODO - getting bounds objects REALLY slows us down, too.  It creates a new one every time you ask for it!
				var rightA:Number = objA._position.right;
				var frontA:Number = objA._position.bottom;
				
				for (var j:uint = 0; j < max; ++j)
				{
					if(i == j) continue;
					var objB:IsoObject = children[j];
					
					// See if B should go behind A
					// simplest possible check, interpenetrations also count as "behind", which does do a bit more work later, but the inner loop tradeoff for a faster check makes up for it
					if ((objB._position.x < rightA) &&
						(objB._position.y < frontA)
					)
					{
						behind.push(objB);
					}
				}
				
				dependency[objA] = behind;
			}			
			// TODO - set the invalidated children first, then do a rescan to make sure everything else is where it needs to be, too?  probably need to order the invalidated children sets from low to high index
			
			// вернуть массивы сортировки в исходное состояние, когда всё отсортировано
			sortedObjects = [];
			unsortedQueue = [];
			
			// Set the childrens' depth, using dependency ordering
			//Profiler.enter("place implementation");
			depth = 0;
			for each (var obj:IsoObject in children)
			if (true !== visited[obj])
				place(obj);
			
			needGlobalSorting = false;
			Profiler.exit("recursiveSorting");
			//trace("time = " + (getTimer() - startTime) + "	[recursive algorithm, numObjects=" + sortedObjects.length + "]");
			/**
			 * Dependency-ordered depth placement of the given objects and its dependencies.
			 */
			function place(obj:IsoObject):void
			{
				visited[obj] = true;
				for each(var inner:IsoObject in dependency[obj])
				if(true !== visited[inner])
					place(inner);
				
				if (depth != getChildIndex(obj))
				{
					setChildIndex(obj, depth + numGrounds);// numGrounds учитывает присутствие фона
				}
				sortedObjects.push(obj);
				obj._sorted = true;
				++depth;
			};
		}// end recursiveSorting
		
		
		
		
		private function recursiveSorting2():void
		{
			var startTime:uint = getTimer();
			var children:Array = isoObjects;
			var max:uint = children.length;
			var shadedArray:Array = new Array();
			var hash:Array=new Array();
			for (var i:uint = 0; i < max; ++i)
			{
				var objA:IsoObject = children[i];
				var rightA:Number = objA._position.right;
				var frontA:Number = objA._position.bottom;
				shadedArray[i]= new Array();
				hash[i]=1;
				for (var j:uint = 0; j < max; ++j)
				{
					if(i == j) continue;
					var objB:IsoObject = children[j];
					
					if ((objB._position.x < rightA) &&
						(objB._position.y < frontA))
					{
						shadedArray[i][j]= 1;
					}else{shadedArray[i][j]= 0;}
				}
			}
			var unsorted:uint=max-1;
			var count:uint;
			var shadeCount:Array=new Array();
			var depth:uint=0;
			sortedObjects=[];
			unsortedQueue=[];
			while(unsorted)
			{
				for ( i = 0; i < max; ++i)
				{
					count=0;
					for (j = 0; j < max; ++j)
					{
						if(i == j) continue;
						count+=shadedArray[i][j];
					}
					shadeCount[i]=count;
				}
				for ( i =0;i<max;++i)
				{
					if(shadeCount[i]==0 && hash[i]==1)
					{
						for(j = 0; j < max; ++j)
						{
							if(i == j) continue;
							shadedArray[j][i]=0;
						}
						//depth=(max-unsorted-1);
						if ( depth!= getChildIndex(children[i]))
						{
							setChildIndex(children[i], depth + numGrounds);// numGrounds учитывает присутствие фона
						}
						sortedObjects.push(children[i]);
						children[i]._sorted=true;
						unsorted-=1;
						hash[i]=0;
						depth++;
					}
				}
			}
			trace("time = " + (getTimer() - startTime) + "	[matrix algorithm, numObjects=" + sortedObjects.length + "]");
		}
		
		
		
		
		/**
		 * Cортировка методом из "Actionscript for multiplier games and virtual worlds"
		 * Применяется, когда были передвинуты только безразмерные объекты (напр. персонажи)
		 * Алгоритм быстрее, чем recursiveSorting()
		 * @see com.progrestar.common.new_iso.recursiveSorting
		 */
		protected function simpleSorting():void{	
			Profiler.enter("simpleSorting");
			//var startTime:uint = getTimer();
			var max:int = unsortedQueue.length;
			var i:int;
			var j:int;
			
			for(i = 0;i<max;i++){
				var objA:IsoObject = unsortedQueue[i];
				var sortedIndex:int = sortedObjects.indexOf(objA);
				var added:Boolean = false;
				var posA:Point = objA._position.topLeft;
				var sizeA:Point = objA._position.size;
				
				if(sortedIndex != -1)
					sortedObjects.splice(sortedIndex, 1);
				
				var sortedMax:int = sortedObjects.length;
				for(j = 0;j<sortedMax;j++){
					var objB:IsoObject = sortedObjects[j];
					var posB:Point = objB._position.topLeft;
					var sizeB:Point = objB._position.size;
					var dx:Number = posA.x + sizeA.x * 0.5 - posB.x - sizeB.x;
					var dy:Number = posA.y + sizeA.y * 0.5 - posB.y - sizeB.y;
					if(dx < 0 && dy < 0){// || (dx * dy == 0 && dx + dy < 0)){
						added = true;
						sortedObjects.splice(j, 0, objA);
						break;
					}
				}
				if(!added)
					sortedObjects.push(objA);
				
//				var start:int = 0;
//				var stop:int = sortedObjects.length - 1;stop = (stop>0?stop:0);// stop всегда неотрицательно
//				var center:int = 0;
//				while(stop - start > 1){
//					center = (start + stop) * 0.5;
//					if(check(sortedObjects[center]))
//						stop = center;
//					else
//						start = center;
//				}
//				// если center=stop проверить stop (т.к. его в этом случае никак не мог проверить цикл)
//				if(stop && stop == isoObjects.length && !check(isoObjects[stop]))
//					stop += 1;
//				sortedObjects.splice(stop, 0, objA);
			}
			
			unsortedQueue = [];
			
			for(i = 0;i<sortedObjects.length;i++)
				if(!IsoObject(sortedObjects[i])._sorted){// если объект не прикреплен к комнате (т.е. он был отсортирован)
					setChildIndex(sortedObjects[i], i + numGrounds);// numGrounds учитывает присутствие фона
					IsoObject(sortedObjects[i])._sorted = true;
				}
			Profiler.exit("simpleSorting");
			//trace("time = " + (getTimer() - startTime) + "	[simple algorithm, numObjects=" + sortedObjects.length + "]");
			
			function check(objB:IsoObject):Boolean{
				var posB:Point = objB._position.topLeft;
				var sizeB:Point = objB._position.size;
				return (posA.x < posB.x + sizeB.x && posA.y < posB.y + sizeB.y );
			}
		}
		
	}
}