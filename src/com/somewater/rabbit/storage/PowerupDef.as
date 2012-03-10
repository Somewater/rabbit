package com.somewater.rabbit.storage {
	public class PowerupDef extends ItemDef{

		public var template:String;

		public function PowerupDef(data:Object) {
			super(data);

			try
			{
				if(slug == null)
					slug = Config.loader.getXML('Description').template.(@name==this.template).component.(@name=='Render').slug;
			}
			catch(err:Error)
			{

			}
		}
	}
}
