package com.somewater.rabbit.application.shop {
	import com.somewater.rabbit.storage.CustomizeDef;

	public interface ICustomizable {
		function getCustomize(type:String):CustomizeDef
	}
}
