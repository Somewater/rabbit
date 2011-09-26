package com.somewater.control.tree
{
	public class TreeMark extends Tree_mark
	{
		public function TreeMark()
		{
			super();
			stop();
		}
		
		private var _mark:Boolean = false;
		public function set mark(value:Boolean):void{
			if (value != _mark){
				_mark = value;
				gotoAndStop(_mark?2:1);
			}
		}
		
		public function get mark():Boolean{
			return _mark;
		}
		
	}
}