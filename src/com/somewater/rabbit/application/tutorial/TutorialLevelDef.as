package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;

	public class TutorialLevelDef extends LevelDef{

		public static const TYPE:String = 'TutorialLevel';

		public static const WIDTH:int = 14;
		public static const HEIGHT:int = 10;

		private var uniqId:int = 1000 * Math.random();

		public function TutorialLevelDef() {
			var l:LevelDef = Config.application.getLevelByNumber(1);
			super(l.xml);
		}

		override public function get groupName():String
		{
			return "RewardLevelGroup_" + uniqId;
		}

		override public function get type():String
		{
			return TYPE;
		}
	}
}
