package com.somewater.rabbit.storage {
	import com.somewater.storage.XMLInfoDef;

	public class OfferDef extends XMLInfoDef{

		public var x:int;
		public var y:int;
		public var level:int;

		private var _id:int = -1;

		public function OfferDef(xml:XML) {
			super(xml);
		}

		public function get id():int
		{
			return _id;
		}

		public function set id(value:int):void
		{
			if(_id == -1)
				_id = value;
			else
				throw new Error('Offer id already specified as ' + _id);
		}
	}
}
