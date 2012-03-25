package com.somewater.rabbit.storage
{
	public class LevelDef extends RXmlInfoDef
	{
		public static const TYPE:String = 'Level';

     	public var id:int;
		public var number:uint = 0;// нумерация с "1"
		public var version:int;
		public var image:String;// идентификатор картинки уровня
		
		public var author:String = "nobody";
		
		public var width:int = 12;
		public var height:int = 12;
		
		public var conditions:Array;
		
		public var group:XML;
		
		///////////////////////////////////
		//
		//		INSTANCE PROPERTIES
		//
		///////////////////////////////////
		
		public function LevelDef(xml:XML)
		{
			id = xml.attribute("id");
			number = xml.attribute("number");
			version = xml.attribute("version");
			if(id == 0)
				id = -Math.random() * 1000;

			super(xml);

			conditions = [];
			for each(var condition:XML in xml.conditions.*)
			{
				conditions[condition.localName()] = condition.toString();
			}
			
			if(!this.group)
			{
				this.group = XML(<group></group>).appendChild(xml.group.*);
				this.group.@name = groupName;
			}
		}

		public function get toXML():XML
		{
			throw new Error("TODO");
		}

		/**
		 * Преобразовать conditions в XML (напримре, для отсылки на сервер)
		 */
		public function get conditionsToXML():XML
		{
			var xml:XML = XML(<conditions></conditions>);
			for(var name:String in conditions)
				xml.appendChild(new XML("<" + name + ">" + conditions[name] + "</" + name + ">"));
			return xml;
		}

		/**
		 * Имя группы, из которой формируется и благодаря которой удаляется уровень
		 */
		public function get groupName():String
		{
			return "LevelCreatures_" + (id < 0 ? "_minus_" : "") + Math.abs(id).toString();
		}

		/**
		 * Флаг для того, чтобы отличать обычные уровни от фиктивных заглушек
		 * (например, поляна наград)
		 */
		public function get type():String
		{
			return TYPE;
		}

		/**
		 * Список файлов и т.д., необходимый левелу для старта
		 */
		public function get additionSwfs():Array
		{
			return [{name:"Assets"}, {name:"Interface"}];
		}
		
		public function get name():String
		{
			return Config.application.translate('LEVEL_TITLE_' + this.number);
		}
		
		public function get shortDescription():String
		{
			return Config.application.translate('LEVEL_DESC_' + this.number);
		}

		public function get story():StoryDef
		{
			return StoryDef.byLevelNumber(this.number);
		}
	}
}