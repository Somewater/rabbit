package com.somewater.rabbit.iso.scene
{
	import com.pblabs.engine.debug.Profiler;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.pblabs.rendering2D.DisplayObjectSceneLayer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	public class IsoLayer extends DisplayObjectSceneLayer
	{
		public static var instance:IsoLayer;
		
		public const NUM_GROUNDS:int = 0;// учитывает присутствие фона

		/**
		 * Через сколько тиков произвести полную сортировку
		 */
		public var tickForGlobalSorting:int = 1;
		
		/**
		 * Массив объевтов на сортировки z-индексов, требующих простой сортировки 
		 */
		public var unsortedSimpleQueue:Array = [];
		
		public function IsoLayer()
		{
			super();
			
			if(instance)
			{
				throw new Error("Multi iso layer does not implemented");
			}else
				instance = this;
		}
		
		override public function onRender():void
		{
			if(needSort){
				//var l:int = rendererList.length;
				//for(var i:int = 0;i<l;i++)
				//	if(unsortedSimpleQueue.indexOf(rendererList[i]) != -1)
				//		unsortedSimpleQueue.push(rendererList[i]);
				//simpleSorting();
				if(tickForGlobalSorting == 0)
					tickForGlobalSorting = 15;// таким образом, делаем пересортировку не чаще 2 раз в секунду
				else
				{
					tickForGlobalSorting--;
					if(tickForGlobalSorting == 0)
						recursiveSorting();
					else if(unsortedSimpleQueue.length)
						simpleSorting();
				}
			}else if(unsortedSimpleQueue.length){
				simpleSorting();
			}
		}
		
		override public function updateOrder():void
		{
			recursiveSorting();
		}
		
		
		
		/**
		 * Сортировка из фреймворка isolib
		 * Применяется для наиболее сложных способов: когда был передвинут (или изменил размер) объект с ненулевым размером
		 * @see com.progrestar.common.new_iso.simpleSorting
		 */
		private function recursiveSorting ():void
		{
			CONFIG::debug
			{
				Profiler.enter("recursiveSorting");
			}
			//var startTime:uint = getTimer();6
			var depth:uint;6
			var visited:Dictionary = new Dictionary();
			var dependency:Dictionary;
			
			// TODO - cache dependencies between frames, only adjust invalidated objects, keeping old ordering as best as possible
			// IIsoDisplayObject -> [obj that should be behind the key]
			dependency = new Dictionary();
			
			// For now, use the non-rearranging display list so that the dependency sort will tend to create similar output each pass
			var children:Array = rendererList; rendererList = null;
			
			// Full naive cartesian scan, see what objects are behind child[i]
			// TODO - screen space subdivision to limit dependency scan
			var max:uint = children.length;
			for (var i:uint = 0; i < max; ++i)
			{
				var behind:Array = [];
				
				var objA:IsoRenderer = children[i];
				var posA:Point = objA._position;
				var sizeA:Point = objA._size;
				// TODO - direct access ("public var isoX" instead of "function get x") of the object's fields is a TON faster.
				//   Even "final function get" doesn't inline it to direct access, yielding the same speed as plain "function get".
				//   use namespaces to provide raw access?
				//   rename interface class = IsoDisplayObject, concrete class = IsoDisplayObject_impl with public fields?
				
				// TODO - getting bounds objects REALLY slows us down, too.  It creates a new one every time you ask for it!
				var xA:Number = posA.x + sizeA.x + objA.correctX;
				var yA:Number = posA.y + sizeA.y + objA.correctY;
				
				for (var j:uint = 0; j < max; ++j)
				{
					if(i == j) continue;
					var objB:IsoRenderer = children[j];
					
					// See if B should go behind A
					// simplest possible check, interpenetrations also count as "behind", which does do a bit more work later, but the inner loop tradeoff for a faster check makes up for it
					var posB:Point = objB._position;
					var sizeB:Point = objB._size;
					var frontB:Number = posB.y + sizeB.y + objB.correctY;
					if ((frontB < yA) ||
						(frontB == yA && (posB.x + sizeB.x + objB.correctX) < xA)
					)
					{
						behind.push(objB);
					}
				}
				
				dependency[objA] = behind;
			}			
			// TODO - set the invalidated children first, then do a rescan to make sure everything else is where it needs to be, too?  probably need to order the invalidated children sets from low to high index
			
			// вернуть массивы сортировки в исходное состояние, когда всё отсортировано
			unsortedSimpleQueue = [];
			rendererList = [];
			
			// Set the childrens' depth, using dependency ordering
			//Profiler.enter("place implementation");
			depth = 0;
			for each (var obj:IsoRenderer in children)
			if (true !== visited[obj])
				place(obj);
			
			needSort = false;
			CONFIG::debug
			{
				Profiler.exit("recursiveSorting");
			}
			/**
			 * Dependency-ordered depth placement of the given objects and its dependencies.
			 */
			function place(obj:IsoRenderer):void
			{
				visited[obj] = true;
				for each(var inner:IsoRenderer in dependency[obj])
				if(true !== visited[inner])
					place(inner);
				
				if (depth != getChildIndex(obj.displayObject))
				{
					setChildIndex(obj.displayObject, depth + NUM_GROUNDS);
				}
				rendererList.push(obj);
				obj.zIndexSorted = true;
				++depth;
			};
		}// end recursiveSorting
		
		
		override public function remove(dor:DisplayObjectRenderer):void
		{
			super.remove(dor);
			
			// а также удаляем из unsortedSimpleQueue
			var idx:int = unsortedSimpleQueue.indexOf(dor);
			if(idx != -1)
				unsortedSimpleQueue.splice(idx, 1);
		}
		
		
		
		
		/**
		 * Cортировка методом из "Actionscript for multiplier games and virtual worlds"
		 * Применяется, когда были передвинуты только безразмерные объекты (напр. персонажи)
		 * Алгоритм быстрее, чем recursiveSorting()
		 * @see com.progrestar.common.new_iso.recursiveSorting
		 */
		private function simpleSorting():void{	
			CONFIG::debug
			{
				Profiler.enter("simpleSorting");
			}
			var max:int = unsortedSimpleQueue.length;
			var i:int;
			var j:int;
			var posA:Point = new Point();
			var posB:Point = new Point();
			
			for(i = 0;i<max;i++){
				var objA:IsoRenderer = unsortedSimpleQueue[i];
				var sortedIndex:int = rendererList.indexOf(objA);
				var added:Boolean = false;
				posA.x = objA._position.x + objA.correctX;
				posA.y = objA._position.y + objA.correctY;
				//var sizeA:Point = objA.size;
				
				if(sortedIndex != -1)
					rendererList.splice(sortedIndex, 1);
				
				var sortedMax:int = rendererList.length;
				for(j = 0;j<sortedMax;j++){
					var objB:IsoRenderer = rendererList[j];
					posB.x = objB._position.x;
					posB.y = objB._position.y;
					var sizeB:Point = objB._size;
					var dx:Number = posA.x /*+ sizeA.x * 0.5*/ - posB.x - sizeB.x - objB.correctX;
					var dy:Number = posA.y /*+ sizeA.y * 0.5*/ - posB.y - sizeB.y - objB.correctY;
					if(dy < 0 || (dy == 0 && dx < 0)){// || (dx * dy == 0 && dx + dy < 0)){
						
						// если у объектов разные "высоты", проверяем, не пересекаются ли они в пространстве
						//if(objA.height > objB.height && posB.y < posA.y)
						//	continue;// objA все равно дожен быть выше
							
						added = true;
						rendererList.splice(j, 0, objA);
						break;
					}
				}
				if(!added)
					rendererList.push(objA);
			}
			
			unsortedSimpleQueue = [];
			
			for(i = 0;i<rendererList.length;i++)
				if(!IsoRenderer(rendererList[i]).zIndexSorted){// если объект не прикреплен к комнате (т.е. он был отсортирован)
					setChildIndex(rendererList[i].displayObject, i + NUM_GROUNDS);// numGrounds учитывает присутствие фона
					IsoRenderer(rendererList[i]).zIndexSorted = true;
				}
			CONFIG::debug
			{
				Profiler.exit("simpleSorting");
			}
		}
	}
}