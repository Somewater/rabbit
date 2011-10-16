package com.somewater.storage
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	final public class Lang
	{
		private static var instance:Lang;
		private var dictionry:Object;
		
		// для записи текстовых констант, которые будут доступны еще до выбора и загрузки языка
		// basic[0] содержит список всех доступных языков вида [{},{}...{label:название, data:путь загрузки файла или null}..]
		public static const basic:Array = [];
		
		public function Lang()
		{
			 
		}

		public static function getInstance():Lang{
			if(instance == null)
				instance = new Lang();
			return instance;
		}
		
		
		/**
		 * Получить слово по введенному ключу. Согласно текущему словарю
		 */
		public static function t(key:String, args:Object = null):String{
			var dict:Object = instance.dictionry;
			if (dict[key])
			{
				if(args == null)
				{
					return dict[key];
				}
				else
				{
					var result:String = dict[key];
					for (var name:String in args) {
						result.replace(new RegExp("\{" + name + "\}", "g"), args[name])
					}
					return result;
				}
			}
			else
				return key.length?key:"T_NULL";
		}
		
		public static function arr(key:String, separator:String = ","):Array{
			var dict:Object = instance.dictionry;
			if (dict.hasOwnProperty(key))
				if (dict[key] is Array)
					return dict[key];
				else
					{
						dict[key] = String(dict[key]).split(separator);
						return dict[key];
					}
			else
				throw new Error("Lang error. No array on specific key: "+key);
		}
		
		
		/**
		 * В файле должно быть менее 1'000'000 строк
		 * Если парсинг произведен успешно, диспатчится событие COMPLETE
		 * После парсинка в главном управляющем классе надо переопределить
		 * PersonalData.lng = Lang.t("LNG"); - чтобы знать строковое представление вновь загруженного языка
		 */
		public function parse(storage:String):void{
			var i:int = 0;
			var newDict:Boolean = false;// создается ли новый словарь, или замещаются поля старого (новым языковым файлом)
			if (dictionry == null) {
				dictionry = {};
				newDict = true;
			}
			
			storage = storage.replace("\r\n", "\n");
			var lines:Array = storage.split("\n");
			
			for each(var line:String in lines)
			{
				if(line.charAt() != "#")
				{
					var equalPos:int = line.indexOf("=");
					if(equalPos != -1)
						dictionry[line.substr(0, equalPos)] = line.substr(equalPos + 1).replace(/\\n/g,"\n");
				}
			}
		}	
		
		/**
		 * Согласно заданному числу выдает корректный стринг для слово (например 7 "дней", 1 "день"...)
		 * Абстрактная ф-ция для формирования общего алгоритма для минут, часов и дней
		 * 
		 * Правила задаются как _rule:array (готовые)
		 * либо как key_rule
		 */
		private static function abstractRule(value:int,_rule:Array,key_rule:String,key_default:String):String{
			if (_rule == null) _rule = Lang.arr(key_rule);
			var rules:Array = _rule;
			var i:int = 0;
			while((i+2)<rules.length){
				if (int(rules[i])<= value && int(rules[i+2])>=value)
					return rules[i+1];
				i += 3;
			}
			return Lang.t(key_default);
		} 
		
		private var _day_rule:Array;
		public static function day(value:int):String{
			return abstractRule(value,null,"DAY_RULE","DAY_DEFAULT");
		}
		
		private var _hour_rule:Array;
		public static function hour(value:int):String{
			return abstractRule(value,null,"HOUR_RULE","HOUR_DEFAULT");
		}
		
		private var _minute_rule:Array;
		public static function minute(value:int):String{
			return abstractRule(value,null,"MINUTE_RULE","MINUTE_DEFAULT");
		}
		 
	}
}