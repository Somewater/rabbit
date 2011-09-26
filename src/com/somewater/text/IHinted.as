package com.somewater.text
{
	import flash.events.IEventDispatcher;
	
	public interface IHinted extends IEventDispatcher
	{
		function get hint():String;
		function set hint(value:String):void;
	}
	
	/*
	
	import com.progrestar.text.Hint;
	
	
	
	private var _hint:String;
	public function set hint(value:String):void
	{
		if (value != null && value != "")
			if (_hint == null || _hint == ""){
				_hint = value;
				Hint.bind(this,value);
				return;
			}
		_hint = value;
							
	}
	public function get hint ():String
	{
		return _hint;
	}
	
	*/
}