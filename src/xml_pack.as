package
{
	import flash.display.Sprite;
	import flash.utils.getDefinitionByName;

	public class xml_pack extends Sprite
	{
		[Embed("./../bin-debug/Description.xml", mimeType="application/octet-stream")]
		private const Description:Class;
		
		[Embed("./../bin-debug/Levels.xml", mimeType="application/octet-stream")]
		private const Levels:Class;
		
		[Embed("./../bin-debug/Managers.xml", mimeType="application/octet-stream")]
		private const Managers:Class;
		
		[Embed("./../bin-debug/Rewards.xml", mimeType="application/octet-stream")]
		private const Rewards:Class;
		
		
		public function xml_pack()
		{
			// внимание, при рефакторинге методов Config, возможна неработоспособность (без compile time ошибок)
			var Config:Class = getDefinitionByName('com.somewater.rabbit.storage.Config') as Class;
			Config.loader.setData('Description', new Description());
			Config.loader.setData('Levels', new Levels());
			Config.loader.setData('Managers', new Managers());
			Config.loader.setData('Rewards', new Rewards());
		}
	}
}