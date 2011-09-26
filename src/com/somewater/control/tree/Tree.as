package com.somewater.control.tree
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.progrestar.events.IndexedEvent;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * Создает дерево: состоящее из TreeBranch
	 * 
	 * Структура data:
	 * 
	 * [
	 * 		{id:0,title:Категория первого уровня},
	 * 		{id:1,title:Категория первого уровня, childs[
	 * 													{id:11,title:Пункт второго уровня},
	 * 													{id:12,title:Пункт второго уровня}
	 * 													]
	 * 		}
	 * ]
	 * 
	 * 
	 * Структура value:  (если выбран пункт id=11)
	 * [
	 * 		{id:1,title:Категория первого уровня},
	 * 		{id:11,title:Пункт второго уровня}
	 * ]
	 * 
	 * type - тип визуального представления надписей
	 * 	0 - как в "Выбор категории"
	 * 	1 - как в "Мой кабинет"
	 * 	2 - "Мой кабинет" в виде страницы
	 */
	[Event(name="change",type="flash.events.Event")]
	[Event(name="resize",type="flash.events.Event")] 
	 
	public class Tree extends Sprite implements IClear
	{
		public var value:Array;
		private var registration:Array;
		
		public function Tree(data:Array, type:int = 0,registration:Array = null)
		{
			super();
			if (registration == null)
				this.registration = [];
			else
				this.registration = registration;		
			
			for (var i:int = 0; i<data.length; i++){
				var branch:TreeBranch = new TreeBranch(data[i],type,this.registration);
				branch.y = i* branch.DEFAUL_LABEL_HEIGHT;
				branch.addEventListener(Event.RESIZE,resize);
				branch.addEventListener(IndexedEvent.CLICK_INDEXED_ITEM,branchCategorySelected);
				addChild(branch);
			}
		}
		
		public function clear():void{
			registration = null;
			for (var i:int = 0;i<numChildren;i++){
				var child:DisplayObject = getChildAt(i);
				if (child is IClear)
					IClear(child).clear();
			}				
		}
		
		private function branchCategorySelected(e:IndexedEvent):void{
			value = e.selectedIndexies;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function resize(e:Event):void{			
			var resized:TreeBranch = (e.currentTarget as TreeBranch);
			var delta:String = String(resized.height - resized.oldHeight);
			for (var i:int = getChildIndex(resized)+1; i<numChildren; i++){
					// сначала завершим все уже работающие твины
					var currentTweens:Array = TweenMax.getTweensOf(getChildAt(i))
					for (var j:int = 0;j<currentTweens.length;j++)
						TweenLite(currentTweens[j]).complete();
					TweenMax.to(getChildAt(i),0.2,{y:delta});
			}
			dispatchEvent(new Event(Event.RESIZE));
		}
		

		override public function get height():Number{			
			var h:int = 0;
			for (var i:int = 0; i<numChildren; i++)
				h += TreeBranch(getChildAt(i)).height;
			return h;
		}
		
	}
}