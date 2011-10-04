package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	public class LevelDef extends InfoDef
	{
		public var id:int = -1;
		public var number:uint;// нумерация с "1"
		public var desc:String;
		
		public var file:String = "LevelPack";
		
		public var width:int = 12;
		public var height:int = 12;
		
		public var conditions:Array;
		
		public var group:*;

		private var _xml:XML;
		
		///////////////////////////////////
		//
		//		INSTANCE PROPERTIES
		//
		///////////////////////////////////
		
		public var completed:Boolean;
		
		public function LevelDef(xml:XML)
		{
			id = xml.attribute("id");
			
			for each(var xmlField:XML in xml.*)
			{
				if(xmlField.hasSimpleContent())
				{
					try{
						this[xmlField.localName()] = xmlField.toString();
					}catch(err:Error){}
				}
			}
			
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
			return Config.loader.getXML("Description");
		}

		/**
		 * Имя группы, из которой формируется и благодаря которой удаляется уровень
		 */
		public function get groupName():String
		{
			return "LevelCreatures_" + (id < 0 ? "_minus_" : "") + Math.abs(id).toString();
		}
	}
}