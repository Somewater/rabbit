package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.rabbit.storage.UserProfile;

	import flash.display.Sprite;
	import flash.events.Event;

	import flash.events.MouseEvent;

	/**
	 * Показывает и своевременно обновляет панель паверапов
	 */
	public class MyPowerupsBag extends Sprite implements IClear{

		public static const HEIGHT:int = 48;
		public static const ITEM_WIDTH:int = 55;
		public static const MAX_WIDTH:int = 5 * ITEM_WIDTH;

		public static const POWERUP_ICON_CLICKED:String = 'powerupIconClicked';

		private var icons:Array = [];

		public var padding:int

		public function MyPowerupsBag(padding:int = 5) {

			this.padding = padding;

			UserProfile.bind(onUserDataChanged);
		}

		private function onUserDataChanged():void {
			clearIcons();
			var nextX:int = 0;
			for(var id:String in UserProfile.instance.items)
			{
				var powerupDef:PowerupDef = ItemDef.byId(int(id)) as PowerupDef;
				if(powerupDef)
				{
					var icon:PowerupIcon = new PowerupIcon(powerupDef, UserProfile.instance.items[id]);
					icon.addEventListener(MouseEvent.CLICK, onIconClicked);
					addChild(icon)
					icon.x = nextX;
					nextX += ITEM_WIDTH + padding;
					icons.push(icon);
				}
			}
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function clear():void
		{
			clearIcons();
			UserProfile.unbind(onUserDataChanged);
		}

		private function clearIcons():void
		{
			for each(var icon:PowerupIcon in icons)
			{
				icon.removeEventListener(MouseEvent.CLICK, onIconClicked);
				icon.clear();
				this.removeChild(icon);
			}
			icons = [];
		}

		private function onIconClicked(event:MouseEvent):void {
			var icon:PowerupIcon = event.currentTarget as PowerupIcon;
			dispatchEvent(new PowerupEvent(icon.powerup));
		}

		override public function get width():Number {
			return icons.length * ITEM_WIDTH + Math.max(0, icons.length - 1) * padding;
		}

		override public function get height():Number {
			return HEIGHT;
		}
	}
}

import com.somewater.control.IClear;
import com.somewater.rabbit.application.shop.MyPowerupsBag;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.rabbit.storage.PowerupDef;
import com.somewater.text.EmbededTextField;
import com.somewater.utils.MovieClipHelper;

import flash.display.MovieClip;

import flash.display.Sprite;
import flash.geom.Rectangle;

class PowerupIcon extends Sprite implements IClear
{
	public var powerup:PowerupDef;

	private var image:MovieClip;
	private var quantityTF:EmbededTextField;

	public function PowerupIcon(powerup:PowerupDef, quantity:int)
	{
		this.powerup = powerup;

		const imageScale:Number = 0.5;

		image = Lib.createMC(powerup.slug);
		image.scaleX = image.scaleY = imageScale;
		MovieClipHelper.stopAll(image);
		addChild(image);

		var bounds:Rectangle = image.getBounds(image);
		image.x = -bounds.x * imageScale;
		image.y = -bounds.y * imageScale;

		quantityTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true, false, false, false, 'right');
		quantityTF.x = MyPowerupsBag.ITEM_WIDTH;
		addChild(quantityTF);

		quantityTF.text = quantity.toString();
	}

	public function clear():void {
	}
}
