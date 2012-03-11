package com.somewater.rabbit.storage {
	import com.somewater.storage.InfoDef;

	public class ItemDef extends InfoDef{

		protected static var itemsById:Array = [];
		protected static var itemsByName:Array = [];

		public var name:String;
		public var id:int;
		public var slug:String;
		public var cost:int;// цена в кругликах

		public function ItemDef(data:Object) {
			super(data);

			if(this.id == 0
					|| itemsById[this.id]
					|| this.name == null
					|| itemsByName[this.name])
				throw new Error('Dublicated or undefined item id=' + this.id + ' name=' + this.name);

			itemsById[this.id] = this;
			itemsByName[this.name] = this;
		}

		public function getTitle():String
		{
			return Config.application.translate('ITEM_NAME_' + this.name.toUpperCase());
		}

		public function getDescription():String
		{
			return Config.application.translate('ITEM_DESC_' + this.name.toUpperCase());
		}

		public static function byId(id:int):ItemDef
		{
			return itemsById[id];
		}

		public static function byName(name:String):ItemDef
		{
			return itemsByName[name];
		}

		public static function byClass(clazz:Class):Array
		{
			var array:Array = [];
			for each(var i:ItemDef in itemsById)
				if(i is clazz)
					array.push(i);
			return array;
		}
	}
}
