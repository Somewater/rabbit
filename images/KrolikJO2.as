package
{
	import flash.display.Sprite;
	import flash.system.Security;
	
	public class KrolikJO2 extends Sprite
	{
		[Embed(source="krolik_jo23f.jpg")]
		private const IMAGE:Class;
	
		public function KrolikJO2()
		{
			addChild(new IMAGE());
			Security.allowDomain('*');
			buttonMode = useHandCursor = true;
		}
	}	
}
