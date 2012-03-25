package
{
	import flash.display.Sprite;
	import flash.utils.getDefinitionByName;

	public class lang_ru extends Sprite
	{
		
		[Embed("locale/ru.txt", mimeType="application/octet-stream")]
		private static const data : Class;
		
		public function lang_ru()
		{
			var Config:Class = getDefinitionByName('com.somewater.rabbit.storage.Config') as Class;
			Config.memory['lang_pack'] = new data();
		}
	}
}