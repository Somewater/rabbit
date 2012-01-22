package com.somewater.rabbit.storage {
	import com.somewater.storage.XMLInfoDef;

	/**
	 * Реализация XMLInfoDef для использования в игре
	 */
	public class RXmlInfoDef extends XMLInfoDef{
		public function RXmlInfoDef(xml:XML) {
			super(xml);
		}

		override protected function translate(key:String):String {
			return Config.application.translate(key);
		}
	}
}
