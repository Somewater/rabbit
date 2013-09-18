package com.somewater.rabbit.application
{
	import com.gskinner.geom.ColorMatrix;
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
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.text.Font;
	
	
	public class OrangeButton extends OrangeGround
	{

		public var ICON_PADDING:int = 50;

		public var textField:EmbededTextField;
		private const defaultHeight:int = 32;
		private var _enabled:Boolean = true;
		protected var _icon:DisplayObject;
		private var _color:uint = 0xFFFFFF;

		private var downFilter:ColorMatrixFilter;
		
		public function OrangeButton()
		{
			super();
			buttonMode = true;
			_height = defaultHeight;
			
			textField = new EmbededTextField(null, _color, 12, true);
			textField.mouseEnabled = false;
			addChild(textField);
			
			useHandCursor = buttonMode = true;

			var cm:ColorMatrix = new ColorMatrix([]);
			cm.colorize(0xFF8A1B);
			downFilter = new ColorMatrixFilter(cm.toArray());
		}
		
		override protected function resize():void
		{
			super.resize();

			if(_icon)
			{
				_icon.x = ICON_PADDING * 0.5;
				_icon.y = _height * 0.5;
			}

			if(_icon)
			{
				var iconRight:int = _icon ? _icon.x + _icon.width + ICON_PADDING : 0
				textField.x = ICON_PADDING;
			}
			else
			{
				textField.x = (_width - textField.width) * 0.5;
			}
			textField.y = (_height - textField.height) * 0.5 - 0.5;// KLUDGE 0.5
		}
		
		public function set label(text:String):void
		{
			textField.text = text;
			setSize(Math.max(_width, textField.width + 20), defaultHeight);
		}

		public function set htmlLabel(text:String):void
		{
			textField.htmlText = text;
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
			if(icon)
				icon.filters = [downFilter];
		}
		
		override protected function onOut(e:MouseEvent):void
		{
			super.onOut(e);
			textField.color = _color;
			if(icon)
				icon.filters = [];
		}
		
		override protected function onOver(e:MouseEvent):void
		{
			super.onOver(e);
			textField.color = _color;
			if(icon)
				icon.filters = [];
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

		public function get icon():DisplayObject {
			return _icon;
		}

		public function set icon(value:DisplayObject):void {
			if(value != _icon)
			{
				if(_icon && _icon.parent)
				{
					_icon.parent.removeChild(_icon);
				}
				_icon = value;
				if(_icon)
				{
					addChild(_icon);
					resize();
				}
			}
		}

		public function set color(value:uint):void {
			_color = value;
			textField.color = _color;
		}
	}
}