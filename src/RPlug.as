package
{
	import com.somewater.display.Window;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class RPlug extends Sprite
	{
		[Embed(source="./assets/swc/rplug.swf", symbol="preloader.PlugWindow")]
		private const windowCl:Class;
		
		public function RPlug()
		{
			if(stage)
				onAddedToStage(null);
			else
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void
		{
			var w:DisplayObject = new windowCl();
			w.x = ((stage.stageWidth > 1? stage.stageWidth : 810) - w.width) * 0.5;
			w.y = ((stage.stageHeight > 1 ? stage.stageHeight : 650) - w.height) * 0.5;
			stage.addChild(w);
		}
	}
}