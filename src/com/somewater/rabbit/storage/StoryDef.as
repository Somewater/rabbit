package com.somewater.rabbit.storage {

	/**
	 * Модель историй
	 */
	public class StoryDef extends RXmlInfoDef{

		private static var storiesByNumber:Array = [];

		public var number:int;
		public var image:String;

		public var start_level:int;
		public var end_level:int;

		public var enabled:Boolean;

		public function StoryDef(xml:XML) {
			super(xml);

			if(storiesByNumber[this.number])
				throw new Error('Dublicate story entried with ' + this.number + ' number')
			else
				storiesByNumber[this.number] = this;
		}

		public static function byNumber(number:int):StoryDef
		{
			return storiesByNumber[number];
		}

		public static function byLevelNumber(level:int):StoryDef
		{
			for each(var s:StoryDef in storiesByNumber)
				if(s.start_level <= level && s.end_level >= level)
					return s;
			return null;
		}

		public static function all():Array
		{
			return storiesByNumber.slice();
		}

		public function get name():String
		{
			return Config.application.translate('STORY_NAME_' + this.number);
		}

		public function get description():String
		{
			return Config.application.translate('STORY_DESC_' + this.number);
		}
	}
}
