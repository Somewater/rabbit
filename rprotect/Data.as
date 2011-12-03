package
{
	import flash.display.Sprite;
	
	public class Data extends Sprite
	{
		public function Data()
		{
			graphics.beginFill(0xFF00FF);
			graphics.drawRect(30,30,30,30);
			
			trace("Data starged: " + foo());
		}
	
		public function foo():String
		{
			return 'bar';
		}
	}
}
