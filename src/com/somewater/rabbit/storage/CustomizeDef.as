package com.somewater.rabbit.storage {
	import com.somewater.storage.InfoDef;

	public class CustomizeDef extends InfoDef{

		public static const CUSTOMIZES:String = 'CUSTOMIZES';

		public static const TYPE_ROOF:String = 'roof';
		public static const TYPE_DOOR:String = 'door';

		private static var itemsById:Array = [];
		private static var itemsByName:Array = [];

		public var name:String;
		public var id:int;
		public var slug:String;
		public var cost:int;
		public var type:String;
		public var start:Boolean = false;

		public function CustomizeDef(data:Object) {
			super(data);

			itemsById[this.id] = this;
			itemsByName[this.name] = this;
		}

		public static function byId(id:int):CustomizeDef
		{
			return itemsById[id];
		}

		public static function byName(name:String):CustomizeDef
		{
			return itemsByName[name];
		}

		public static function getDefault(type:String):CustomizeDef
		{
			var finded:Boolean = false;
			var custom:CustomizeDef;
			for each(custom in itemsById)
				if(custom.type == type && custom.start)
				{
					finded = true;
					break;
				}

			if(finded == false)
				throw new Error('Can`t find required custom by type=' + type);

			return custom;
		}

}
}
