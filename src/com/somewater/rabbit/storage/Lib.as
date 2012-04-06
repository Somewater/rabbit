package com.somewater.rabbit.storage
{
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import flash.utils.getDefinitionByName;

	public class Lib
	{
		/**
		 * Идентификатор библиотеки интерфейса
		 */
		public static const UI:String = "Interface";
		
		/**
		 * Идентификатор библиотеки ассетов
		 */
		public static const ASSETS:String = "Assets";

		private static var classCache:Array = [];
		
		
		public function Lib()
		{
			throw new Error("Use only static methods");
		}
		
		private static var inited:Boolean = false;
		public static var data:Object;
		
		public static function Initialize(_swfAds:Array):void
		{
			inited = true;
			swfADs = _swfAds;
			
			var i:int;
			var s:String;
			var o:Object;
			
			
		}
		
		
		////////////////////////////////////////////////////////////////
		//															  //
		//					U S E R		M E T H O D S				  //
		//															  //
		////////////////////////////////////////////////////////////////
		
		private static var swfADs:Array = [];
		
		public static function createMC(className:String, library:String = null, instance:Boolean = true):*
		{
			var cl:Class = classCache[className]
			if(cl == null)
			{
				for each(var _ad:* in swfADs)
				{
					var ad:ApplicationDomain = _ad as ApplicationDomain;
					if(ad)
					{
						try
						{
							cl = ad.getDefinition(className) as Class;
							if(cl != null)
								break;
						}catch(e:Error){}
					}
				}

				if(cl == null)
					cl = Config.loader.getClassByName(className);

				if(cl == null)
				{
					Config.game.logError(Lib, "createMC", "Mc \"" + className + "\" not loaded");
					trace("[ERROR] MC " + className + " not created");
					return null;
				}

				classCache[className] = cl;
			}

			if(instance)
				return new cl();
			else
				return cl;
		}

		public static function hasMC(className:String, library:String = null):Boolean
		{
			var cl:Class;
			try
			{
				cl = createMC(className, null, false) as Class;
			}catch(e:Error){}
			return cl != null;
		}
		
	}
}