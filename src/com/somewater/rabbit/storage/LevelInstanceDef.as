package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	/**
	 * СИмволизирует пройденный уровень (и, соответственно, параметры его прохождения)
	 */
	public class LevelInstanceDef extends InfoDef
	{
		// констатны различных причин заверщения уровня
		public static const LEVEL_SUCCESS_FINISH:String = "LEVEL_SUCCESS_FINISH";// уровень пройден
		public static const LEVEL_FATAL_CARROT:String 	= "LEVEL_FATAL_CARROT";// кто-то украл все морковки
		public static const LEVEL_FATAL_LIFE:String 	= "LEVEL_FATAL_LIFE";// кролик погиб
		public static const LEVEL_FATAL_TIME:String 	= "LEVEL_FATAL_TIME";// время вышло

		private var _levelDef:LevelDef;

		///////////////////
		//
		//		ДАННЫЕ СОХРАНЯЮЩИЕСЯ В БАЗЕ
		//
		//////////////////
		public var timeSpended:uint;// число миллисекунд с момента старта игры
		public var carrotHarvested:int;// морковок собрано на уровне
		public var version:int;// версия уровня на момент прохождения

		private var _success:Boolean;
		public var finalFlag:String;// КОнстанта из класса LevelConditionsManager
		public var aliensPassed:int;// сколько врагов было на уровне (и, соответственно, пройдено)
		public var stars:int = 0;// Сколько звездочек получено за прохождение уровня (минимум 1, если уровень завершен успешно)
		public var rewards:Array = [];// бонусы за прохождение уровня (array of RewardInstanceDef)

		// Данные соответствующие конкретному прохождению (напр. timeSpended - лучшее время прохождения
		// а currentTimeSpended - прохождение для конкретного раза)
		public var currentTimeSpended:uint;
		public var currentCarrotHarvested:uint;
		public var currentStars:uint;
		
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
			{
				if(value.hasOwnProperty('c'))
					this.carrotHarvested = value['c'];
				if(value.hasOwnProperty('t'))
					this.timeSpended = value['t'];
				if(value.hasOwnProperty('v'))
					this.version = value['v'];
				if(value.hasOwnProperty('s'))
					this.stars = value['s'];
				super.data = value;
			}
		}


		public function get success():Boolean {
			return _success;
		}

		public function set success(value:Boolean):void {
			_success = value;
		}
		
		public static function get DUMMY_FATAL_LEVEL():LevelInstanceDef
		{
			var level:LevelInstanceDef = new LevelInstanceDef(new LevelDef(new XML()));
			level.success = false;
			return level;
		}

		public function get number():int
		{
			return levelDef.number;
		}
	}
}