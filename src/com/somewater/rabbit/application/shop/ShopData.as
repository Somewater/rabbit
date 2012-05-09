package com.somewater.rabbit.application.shop {
	internal class ShopData {

		public var clazz:Class;
		public var type:String;// подтип в пределах класса
		public var name:String;
		public var basketId:int;


		public function ShopData(name:String, clazz:Class, type:String, basketId:int) {
			this.name = name;
			this.clazz = clazz;
			this.type = type;
			this.basketId = basketId;
		}
	}
}
