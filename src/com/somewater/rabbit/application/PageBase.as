package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class PageBase extends Sprite implements IClear
	{
		protected static var ground:DisplayObject;
		protected var logo:MovieClip;
		
		public function PageBase()
		{
			super();
			
			createGround();
		}
		
		public static function Initialize(preloader:*):void
		{
			ground = preloader.background;
		}
		
		public function clear():void
		{
			if(ground && ground.parent == this)
				ground.parent.removeChild(ground);
		}
		
		protected function createGround():void
		{
			if(!ground) return;
			ground.x = (Config.WIDTH - ground.width) * 0.5;
			ground.y = (Config.HEIGHT - ground.height) * 0.5;
			addChild(ground);
			
			logo = Lib.createMC("LogoRabbit");
			logo.scaleX = logo.scaleY = 0.625;
			logo.x = Config.WIDTH - logo.width - 15;
			logo.y = Config.HEIGHT - logo.height - 20;
			addChild(logo);
		}
		
		protected function getButton(label:String, parent:DisplayObjectContainer, 
								   x:int, y:int, onClick:Function = null, args:Array = null):Sprite
		{
			var button:Sprite = new Sprite();
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.mouseEnabled = false;
			tf.text = label;
			tf.background = true;
			tf.border = true;
			tf.backgroundColor = 0xEEEEEE;
			tf.borderColor = 0x777777;
			tf.selectable = false;
			button.addChild(tf);
			parent.addChild(button);
			button.buttonMode = button.useHandCursor  =true;
			button.x = x;
			button.y = y;
			button.addEventListener(MouseEvent.CLICK, function(e:Event):void{
				onClick && onClick.apply(null, args);
			});
			return button;
		}
	}
}