package com.somewater.storage {

	/**
	 * Умеет парсить xml-и из простых значений вида
	 * <xml>
	 *     <name>Иван<name>
	 *     <age>32</age>
	 *     <money>-6</money>
	 * </xml>
	 */
	public class XMLInfoDef extends InfoDef{
		public function XMLInfoDef(xml:XML = null) {
			super(xml);
		}

		override public function set data(value:Object):void {
			if(value == null)
				return;

			var xml:XML = value is XML ? value as XML : new XML(value);
			this._data = xml;

			for each(var xmlField:XML in xml.*)
			{
				if(xmlField.hasSimpleContent())
				{
					try{
						if(xmlField.toString().substr(0,2) == 'T_')
							this[xmlField.localName()] = translate(xmlField.toString());
						else
							this[xmlField.localName()] = xmlField.toString();
					}catch(err:Error){
						onError(err);
					}
				}
			}
		}

		public function get xml():XML
		{
			return _data as XML;
		}

		protected function translate(key:String):String
		{
			throw new Error('Must be overriden')
		}

		protected function onError(error:Error):void
		{

		}
	}
}
