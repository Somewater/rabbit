package com.somewater.rabbit.application.buttons
{
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.application.OrangeGround;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	
	public class SoundSwitchButton extends OrangeGround
	{
		private var _enabled:Boolean = true;
		
		private var icon:Sprite;
		private var alert:DisplayObject;
		private var waves:DisplayObject;
		
		private var _mode:String;
		
		public function SoundSwitchButton(mode:String)
		{
			super();
			buttonMode = useHandCursor = true;
			
			if(mode == "sound")
			{
				icon = Lib.createMC("interface.SoundIcon");
				waves = icon["waves"];
			}
			else if(mode == "music")
			{
				icon = Lib.createMC("interface.MusicIcon");
			}
			else
				throw new Error("Unsupported mode: " + mode);
			
			_mode = mode;
			
			alert = Lib.createMC("interface.AlertSymbolIcon");
			addChild(icon);
			addChild(alert);
			
			icon.mouseEnabled = icon.mouseChildren = false;
			
			setSize(32, 32);
		}
		
		public function get mode():String
		{
			return _mode;
		}
		
		public function set enabled(value:Boolean):void
		{
			if(value != _enabled)
			{
				_enabled = value;
				refreshIcons();
			}
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		override protected function resize():void
		{
			super.resize();
			icon.x = (_width - icon.width) * 0.5;
			icon.y = (_height - icon.height) * 0.5;
			
			alert.x = _width - 15;
			alert.y = _height - 15;
			
			refreshIcons();			
		}
		
		override protected function onMouse(event:MouseEvent):void
		{
			refreshIcons();
		}
		
		private function refreshIcons():void
		{
			if(waves)
				waves.visible = _enabled;
			
			alert.visible = !_enabled;
			
			if(_mouseMode == 2)
			{
				icon.transform.colorTransform = new ColorTransform(0,0,0,1,0xFF,0x8A,0x1B);
			}
			else
			{
				icon.transform.colorTransform = new ColorTransform();
			}
		}

		override protected function onDown(e:MouseEvent):void {
			Config.application.play(Sounds.ORANGE_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			super.onDown(e);
		}
	}
}