package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.text.Font;
	
	
	public class OrangeButton extends OrangeGround
	{

		public var textField:EmbededTextField;
		private const defaultHeight:int = 32;
		private var _enabled:Boolean = true;
		
		public function OrangeButton()
		{
			super();
			buttonMode = true;
			_height = defaultHeight;
			
			textField = new EmbededTextField(null, 0xFFFFFF, 12, true);
			textField.mouseEnabled = false;
			addChild(textField);
			
			useHandCursor = buttonMode = true;
		}
		
		override protected function resize():void
		{
			super.resize();
			
			textField.x = (_width - textField.width) * 0.5;
			textField.y = (_height - textField.height) * 0.5 - 0.5;// KLUDGE 0.5
		}
		
		public function set label(text:String):void
		{
			textField.text = text;
			setSize(Math.max(_width, textField.width + 20), defaultHeight);
		}
		
		public function get label():String
		{
			return textField.text;
		}
		
		override protected function onDown(e:MouseEvent):void
		{
			Config.application.play(Sounds.ORANGE_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			super.onDown(e);
			textField.color = 0xFF8A1B;
		}
		
		override protected function onOut(e:MouseEvent):void
		{
			super.onOut(e);
			textField.color = 0xFFFFFF;
		}
		
		override protected function onOver(e:MouseEvent):void
		{
			super.onOver(e);
			textField.color = 0xFFFFFF;
		}

		public function set enabled(value:Boolean):void
		{
			if(_enabled != value)
			{
				_enabled = value;
				recreateGrounds();
				addChildAt(down, 0);
				buttonMode = useHandCursor = value;
				resize();
			}
		}

		public function get enabled():Boolean
		{
			return _enabled;
		}

		override protected function createGround(type:String):Sprite {
			if(_enabled)
				return super.createGround(type)
			else
				return Lib.createMC("interface.ShadowOrangeButton_" + 'up');
		}
	}
}