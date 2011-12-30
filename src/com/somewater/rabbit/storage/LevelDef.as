package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	public class LevelDef extends InfoDef
	{
     	public var id:int;
		public var number:uint = 0;// нумерация с "1"
		public var description:String;
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
			if(id == 0)
				id = -Math.random() * 1000;
			
			for each(var xmlField:XML in xml.*)
			{
				if(xmlField.hasSimpleContent())
				{
					try{
						this[xmlField.localName()] = xmlField.toString();
						if(xmlField.toString().substr(0,2) == 'T_')
							this[xmlField.localName()] = Config.application.translate(xmlField.toString());
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
			return 'Level';
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
			var data:Array = this.description.split('--');
			if(data.length == 2)
				return data[0]
			else
				return this.description;
		}
		
		public function get shortDescription():String
		{
			var data:Array = this.description.split('--');
			if(data.length == 2)
				return data[1]
			else
				return this.description;	
		}
	}
}