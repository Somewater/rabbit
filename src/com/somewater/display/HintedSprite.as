package com.somewater.display
{
	import com.somewater.text.Hint;
	import com.somewater.text.IHinted;
	
	import flash.display.Sprite;

	public class HintedSprite extends Sprite implements IHinted
	{
		public function HintedSprite()
		{
			super();
		}
		
		private var _hint:String;
		public function set hint(value:String):void
		{
			if (value != null && value != "")
			{
				if (_hint == null || _hint == "")
				{
					_hint = value;
					Hint.bind(this,value);
				}
			}else if(_hint != null && _hint != "")
				Hint.removeHint(this);
			_hint = value;
								
		}
		public function get hint ():String
		{
			return _hint;
		}
		
	}
}