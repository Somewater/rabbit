package
{
	import flash.display.Sprite;
	
	public class KrolikJO2 extends Sprite
	{
		[Embed(source="krolik_jo2.jpg")]
		private const IMAGE:Class;
	
		public function KrolikJO2()
		{
			addChild(new IMAGE());
		}
	}	
}
