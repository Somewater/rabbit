package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	public class LevelDef extends InfoDef
	{
		public var id:int = -1;
		public var name:String;
		public var desc:String;
		
		public var file:String = "LevelPack";
		public var group:String;
		
		public var width:int = 12;
		public var height:int = 12;
		
		public var conditions:Array;

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
		}
		
		public function get number():String
		{
			return (id + 1).toString();
		}

		public function get toXML():XML
		{
			return Config.loader.getXML("Description");
		}
	}
}