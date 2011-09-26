package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;
	
	/**
	 * СИмволизирует пройденный уровень (и, соответственно, параметры его прохождения)
	 */
	public class LevelInstanceDef extends InfoDef
	{
		private var _levelDef:LevelDef;
		
		public function LevelInstanceDef(data:Object=null)
		{
			super(data);
		}
		
		public function get levelDef():LevelDef
		{
			return _levelDef;
		}
		
		override public function set data(value:Object):void
		{
			if(value is LevelDef)
			{
				_levelDef = value as LevelDef;
			}
			else
				super.data = value;
		}
	}
}