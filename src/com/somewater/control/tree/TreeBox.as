package com.somewater.control.tree
{
	public class TreeBox extends Tree_box
	{
		public function TreeBox()
		{
			super();
			stop();
		}
		
		private var _plus:Boolean = true;
		public function set plus(value:Boolean):void{
			if (value != _plus){
				_plus = value;
				gotoAndStop(_plus?1:2);
			}
		}
		
		public function get plus():Boolean{
			return _plus;
		}
		
	}
}