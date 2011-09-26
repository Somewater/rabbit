package
{
	import com.somewater.rabbit.util.GeomUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	[SWF(width=800, height=600)]
	public class Test extends Sprite
	{
		private static var tff:TextField;
		private static var tf:TextField;
		private var p1:Point = new Point(20,20);
		public function Test()
		{
			super();
			
			tf = new TextField();
			tf.multiline = tf.wordWrap = true;
			tf.width = 300;
			tf.x = 300;
			addChild(tf);
			tff = new TextField();
			tff.multiline = tff.wordWrap = true;
			tff.width = 300;
			tff.x = 300;
			tff.y = 300;
			addChild(tff);
			
			
			
			
			
			addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void{
				tff.text = int(stage.mouseX) + ":" + int(stage.mouseY);
				
				
				ggg(p1, new Point(int(stage.mouseX),int(stage.mouseY)));
			});
			
			addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void{
				tff.text = int(stage.mouseX) + ":" + int(stage.mouseY);
				
				p1 = new Point(int(stage.mouseX),int(stage.mouseY));
				
				ggg(p1, new Point(int(stage.mouseX),int(stage.mouseY)));
			});
			
			var s:Sprite = new Sprite();
			s.graphics.beginFill(0 ,0);
			s.graphics.drawRect(0, 0, 800, 600);
			addChild(s);
			
		}
		
		
		public static function t(msg:*):void
			{
				tf.text += String(msg) + "\n";
			}
		
		
		function ggg(p1, p2):void
		{
			tf.text = "";
			var c:Point = new Point(50,80);
			var r:Number = 20;
			
			var inters:Array = GeomUtil.circlePartInrersections(c, r, p1, p2);
			
			var g:Graphics = this.graphics;
			g.clear();
			g.lineStyle(1, 0xFF0000);
			g.drawCircle(c.x, c.y, r);
			g.beginFill(0x00FF00);
			g.drawCircle(p1.x, p1.y, 2);
			g.drawCircle(p2.x, p2.y, 2);
			g.endFill();
			g.moveTo(p1.x, p1.y);
			g.lineTo(p2.x, p2.y);
			
			g.lineStyle(2, 0x0000FF);
			g.beginFill(0);
			
			t("c=" + c + ", r=" + r);
			t("p1=" + p1 + ", p2=" + p2);
			
			if(inters)
				for(var i:int = 0;i<inters.length;i++)
				{
					var inter:Point = inters[i];
					g.drawCircle(inter.x, inter.y, 2);
					
					t("i" + i + "=" + inter)
				}
			
			
			g.endFill();
			g.lineStyle(3, 0xFFFFFF);
			g.moveTo(c.x, c.y);
			g.curveTo(p1.x,p1.y,p2.x, p2.y);
		}
	}
}