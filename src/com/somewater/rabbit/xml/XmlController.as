package com.somewater.rabbit.xml {
	import com.somewater.rabbit.debug.EntityDef;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;

	import flash.utils.Dictionary;

	public class XmlController {

	public static const EXCLUDED_TEMPLATES:Array = ["Animal","Iso","IsoMover","Kennel","Rabbit","RabbitBase"];

	private static var _instance:XmlController;

	private var description:Array;
	private var descriptionByName:Dictionary;

	public static function get instance():XmlController
	{
		if(!_instance)
		{
			_instance = new XmlController();
		}
		return _instance;
	}

	public function XmlController() {

	}


	/**
	 * Посчтитать, сколько на уровне предположительно врагов
	 * @param level
	 * @return
	 */
	public function calculateAliens(level:LevelDef):int
	{
		var aliens:int = 0;
		map(level, function(template:XML, objectReference:XML):Boolean{
			iterateComponents(template, function(component:XML):Boolean{
				if(String(component.@name) == "Attack" && String(component.victimName) == "Hero")
				{
					aliens++;
					return true
				}
				return false;
			})
			return false;// на самоом деле нам нужен просто итератор а не map. Не заставляем делать модели EntityDef
		});
		return aliens;
	}

	/**
	 * Посчитать, сколько морковки на уровне
	 * @param level
	 * @return
	 */
	public function calculateCarrots(level:LevelDef):int
	{
		var carrots:int = 0;
		map(level, function(template:XML, objectReference:XML):Boolean{
			if(String(template.@templates).split(",").indexOf("Carrot") != -1)
				carrots++;
			return false;// на самоом деле нам нужен просто итератор а не map. Не заставляем делать модели EntityDef
		});
		return carrots;
	}

	public function getNewLevel():LevelDef
	{
		return new LevelDef(<level id="0" number="1"><description>New Level</description><conditions><time>300</time></conditions></level>);
	}


	public function getDescription():Array
	{
		if(!description)
		{
			createDescription();
		}
		return description;
	}

	public function getDescriptionByName():Dictionary
	{
		if(!descriptionByName)
		{
			createDescription();
		}
		return descriptionByName;
	}

	/**
	 * Создает полное описание темплейтов и следующие дополнительные атрибуты:
	 * @templates = "RabbitBase,Animal,Iso" все темплейты, использованные в построении данного (заканчивая базовым)
	 */
	private function createDescription():void
	{
		var xml:XML = Config.loader.getXML("Description");
		var xmlArray:Array = [];
		var allDescription:Array = [];
		var child:XML;
		var name:String;
		for each(child in xml.*)
		{
			xmlArray[child.@name] = child;
		}
		// решаем зависимости
		for(name in xmlArray)
		{
			child = XML(xmlArray[name]);
			//trace("CHILD:" + child + "\n");
			allDescription[name] = initiateXML(new XML(<template></template>), name, xmlArray);
			allDescription[name].@name = name;
			//trace("TEMPLATE " + name + ":\n" + description[name] + "\n\n");
		}

		description = [];
		descriptionByName = new Dictionary();

		for (name in allDescription) {
			var template:XML = allDescription[name];
			if(EXCLUDED_TEMPLATES.indexOf(name) != -1) continue;
			description.push(template);
			descriptionByName[name] = template;
		}
	}

	private function initiateXML(processedXML:XML, templateName:String, descriptionRef:Array):XML
	{
		if(templateName)
		{
			var template:XML = descriptionRef[templateName];
			//trace("templ:\n" + template);
			if(template)
			{
				var nextTemplateName:String = template.@template;
				if(nextTemplateName && nextTemplateName.length)
				{
					var templates:String = processedXML.@templates
					processedXML.@templates = (templates && templates.length ? templates : templateName) + "," + nextTemplateName;
					initiateXML(processedXML, nextTemplateName, descriptionRef);
				}
				for each(var component:XML in template.*)
				{
					//trace("comp:\n" + component + "\n");
					var processedComponent:XML = null;
					for each(var component2:XML in processedXML.*)
					{
						//trace("component:\n" + component.@name.toString() + "\n");
						//trace("component2:\n" + component2.@name.toString() + "\n");
						if(String(component2.@name) == String(component.@name))
						{
							processedComponent = component2;
							break;
						}
					}
					if(processedComponent)
					{
						// TODO: слить свойства из component и processedComponent
						//trace("processedComponent (before)\n" + processedComponent + "\n");
						//trace("component (before)\n" + component + "\n");
						for each(var componentField:XML in component.*)
							addXMLField(processedComponent, componentField);
						//trace("processedComponent (after):\n" + processedComponent + "\n");
						addXMLField(processedXML, processedComponent, true);
					}
					else
						processedXML.appendChild(component.copy());
					//trace("processedXML:\n" + processedXML  + "\n");
				}
			}
		}
		return processedXML;
	}

	/**
	 * Добавляет в xml новое поле field или заменяет на него существующее
	 * @param xml
	 * @param field
	 * @param checkNameAttr поля сравниваются по аттрибуту @name, а не по собственному имени поля field.name()
	 */
	private function addXMLField(xml:XML, field:XML, checkNameAttr:Boolean = false):void
	{
		var name:String = field.name();
		if(checkNameAttr)
		{
			var index:int = 0;
			for each(var xmlFiled:XML in xml.*)
				if(String(xmlFiled.@name) == String(field.@name))
				{
					xml.replace(index, field)
					return;
				}
				else
					index++;
			xml.appendChild(field);
		}
		else
		{
			if(xml.hasOwnProperty(name))
				xml.replace(name, field);
			else
				xml.appendChild(field);
		}
	}

	/**
	 * Итератор по персонажам уровня
	 * @param level
	 * @param callback (template:XML, objectReference:XML):Boolean надо ли добавить entity в результирующий массив
	 * @return array of EntityDef
	 */
	private function map(level:LevelDef, callback:Function):Array
	{
		var arr:Array = [];
		var groupXML:XML = level.group;
		if(this.descriptionByName == null)
			getDescription();
		var descByName:Dictionary = descriptionByName;
		for each(var objectReference:XML in groupXML.*)
		{
			var template:XML = descByName[String(objectReference.@name)];
			if(callback(template, objectReference))
			{
				var ed:EntityDef = new EntityDef()
				ed.template = template;
				ed.objectReference = objectReference;
				arr.push(ed);
			}
		}
		return arr;
	}


	/**
	 * Итератор компонентов темплейта
	 * @param template
	 * @param callback (component:XML):Boolean - возвращает true, если надо закончить итерации
	 */
	private function iterateComponents(template:XML, callback:Function):void
	{
		for each(var component:XML in template.*)
		{
			if(callback(component))
				break;
		}
	}
}
}
