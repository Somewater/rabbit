package com.somewater.rabbit.storage {

	public class CustomizeDef extends ItemDef{

		public static const TYPE_ROOF:String = 'roof';
		public static const TYPE_DOOR:String = 'door';

		public var type:String;
		public var start:Boolean = false;

		public function CustomizeDef(data:Object) {
			super(data);
		}

		public static function getDefault(type:String):CustomizeDef
		{
			var finded:Boolean = false;
			var custom:CustomizeDef;
			for each(custom in ItemDef.byClass(CustomizeDef))
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
