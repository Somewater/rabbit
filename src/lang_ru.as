package
{
	import com.somewater.storage.Lang;
	
	import flash.display.Sprite;

	public class lang_ru extends Sprite
	{
		
		[Embed("locale/ru.txt", mimeType="application/octet-stream")]
		private static const data : Class;
		
		public function lang_ru()
		{
			Lang.getInstance().parse(new data());
		}
	}
}