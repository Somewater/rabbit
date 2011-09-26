package com.somewater.common.util
{
	import com.somewater.common.GameObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	public class Indexer
	{
		private var mc:GameObject;
		private var dict:Dictionary;
		public function Indexer(_mc:GameObject)
		{
			mc = _mc;
			reindex();
		}
		
		public function reindex(){
			dict = new Dictionary();
			indexChildren(mc);
		}
		
		public function indexChildren(mc:DisplayObjectContainer){
			if( !mc ) mc = this.mc;
			var nc = mc.numChildren;
			for( var i=0;i<nc;i++ ){
				var c:DisplayObject = mc.getChildAt(i);
				if( c.name ){
					if(!dict[c.name]){
						dict[c.name] = [c];						
					}else{
						(dict[c.name] as Array).push(c);
					}
				}
				if( c is DisplayObjectContainer && !(c is GameObject) ) indexChildren(c as DisplayObjectContainer);
			}
		}
		
		public function getChildrenByName(name:String):Array{
			if( dict[name] )
				return dict[name];
			else
				return [];
		}
		
		public function getChildByName(name:String):DisplayObject{
			if( dict[name] )
				return dict[name][0];
			else
				return null;
		}
	}
}