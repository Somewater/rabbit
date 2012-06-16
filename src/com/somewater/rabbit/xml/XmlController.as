package com.somewater.rabbit.xml {
	import com.somewater.rabbit.application.RewardManager;
	import com.somewater.rabbit.debug.EntityDef;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;

	import flash.geom.Point;

	import flash.utils.Dictionary;

	public class XmlController {

	private static var _instance:XmlController;

	private var description:Array;
	private var descriptionByName:Dictionary;
	private var calculateRewardSizeCache:Array = [];

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

	/**
	 * Сколько морковок требует уровень для завершения с 3-мя звездами (макс. результат)
	 * @param level
	 * @return
	 */
	public function calculateMaxCarrots(level:LevelDef):int
	{
		if(level.conditions['carrotMax'] == null || level.conditions['carrotMax'] == 0)
			level.conditions['carrotMax'] = calculateCarrots(level);
		return level.conditions['carrotMax'];
	}

	/**
	 * Сколько морковок требует уровень для завершения с 2-мя звездами
	 * @param level
	 * @return
	 */
	public function calculateMiddleCarrots(level:LevelDef):int
	{
		if(level.conditions['carrotMiddle'] == null|| level.conditions['carrotMiddle'] == 0)
			level.conditions['carrotMiddle'] = calculateCarrots(level) - 1;
		return level.conditions['carrotMiddle']
	}

	/**
	 * Сколько морковок требует уровень для завершения с 1-й звездой
	 * (т.е. минимульное число собранных морковок для прохождения уровня)
	 * @param level
	 * @return
	 */
	public function calculateMinCarrots(level:LevelDef):int
	{
		if(level.conditions['carrotMin'])
			return level.conditions['carrotMin'];
		else if(level.conditions['carrot'])
			return level.conditions['carrot'];
		else
			return calculateMiddleCarrots(level) - 1;
	}

	/**
	 * ПОсчитать время уровня в секундах
	 * @param level
	 * @return
	 */
	public function calculateLevelTime(level:LevelDef):int
	{
		return level.conditions ? level.conditions['time'] : 60;
	}

	/**
	 * Просчитать размер реварда, который он занимает на поле
	 * @param rewardId
	 * @return
	 */
	public function calculateRewardSize(rewardId:int):Point
	{
		if(calculateRewardSizeCache[rewardId] == null)
		{
			var template:XML = RewardManager.instance.getXMLById(rewardId);
			var result:Point = calculateRewardSizeCache[rewardId] = new Point(1,1);
			iterateComponents(template, function(component:XML):Boolean{
				if(String(component.@name) == 'Spatial')
				{
					var x:String = component.size.x.toString();
					var y:String = component.size.y.toString();
					if(x && x.length)
						result.x = parseInt(x);
					if(y && y.length)
						result.y = parseInt(y);
					return true;
				}
				return false;
			})
		}
		return	Point(calculateRewardSizeCache[rewardId]).clone();
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

	public function getLevelSlugs(level:LevelDef):Object
	{
		var slugs:Object = {};
		map(level, function(template:XML, objectReference:XML):Boolean{
			iterateComponents(template, function(component:XML):Boolean{
				if(String(component.@name) == "Render")
				{
					slugs[String(component.slug)] = null
					var slugsStr:String = String(component.slugs)
					if(slugsStr && slugsStr.length)
					{
						for each(var s:String in slugsStr.split(','))
							slugs[s] = null;
					}
					return true
				}
				return false;
			})
			return false;// на самоом деле нам нужен просто итератор а не map. Не заставляем делать модели EntityDef
		});
		return slugs;
	}

	/**
	 * Создает полное описание темплейтов и следующие дополнительные атрибуты:
	 * @templates = "RabbitBase,Animal,Iso" все темплейты, использованные в построении данного (заканчивая базовым)
	 */
	private function createDescription():void
	{
		description = [];
		descriptionByName = new Dictionary();
		createDescriptionXml(Config.loader.getXML("Description"));
		createDescriptionXml(Config.loader.getXML("Rewards"));
	}

	private function createDescriptionXml(xml:XML):void
	{
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

		for (name in allDescription) {
			var template:XML = allDescription[name];
			if(name.length > 4 && name.substr(name.length - 4).toLowerCase() == 'base') continue;
			if(name.length > 8 && name.substr(name.length - 8).toLowerCase() == 'template') continue;
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
