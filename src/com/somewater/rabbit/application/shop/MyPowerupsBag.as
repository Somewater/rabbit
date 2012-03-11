package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.rabbit.storage.UserProfile;

	import flash.display.DisplayObject;

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

		private var highlightPowerupButtons:Boolean;

		public function MyPowerupsBag(padding:int = 5, highlightPowerupButtons:Boolean = false) {

			this.padding = padding;
			this.highlightPowerupButtons = highlightPowerupButtons;

			UserProfile.bind(onUserDataChanged);
		}

		private function onUserDataChanged():void {
			clearIcons();
			var nextX:int = 0;
			var powerupDefs:Array = ItemDef.byClass(PowerupDef);
			powerupDefs.sortOn('cost', Array.NUMERIC);
			for each(var powerup:PowerupDef in powerupDefs)
			{
				var icon:ItemIcon = new ItemIcon(powerup);
				icon.quantity = int(UserProfile.instance.items[powerup.id]);
				icon.addEventListener(MouseEvent.CLICK, onIconClicked);
				if(highlightPowerupButtons)
				{
					icon.addEventListener(MouseEvent.ROLL_OVER, onIconOver);
					icon.addEventListener(MouseEvent.ROLL_OUT, onIconOut);
					icon.buttonMode = icon.useHandCursor = true;
				}
				addChild(icon)
				icon.x = nextX;
				nextX += padding + icon.width;
				icons.push(icon);
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
			for each(var icon:ItemIcon in icons)
			{
				icon.removeEventListener(MouseEvent.CLICK, onIconClicked);
				if(highlightPowerupButtons)
				{
					icon.removeEventListener(MouseEvent.ROLL_OVER, onIconOver);
					icon.removeEventListener(MouseEvent.ROLL_OUT, onIconOut);
				}
				icon.clear();
				this.removeChild(icon);
			}
			icons = [];
		}

		private function onIconOut(event:MouseEvent):void {
			var icon:ItemIcon = event.currentTarget as ItemIcon;
			icon.background = false;
		}

		private function onIconOver(event:MouseEvent):void {
			var icon:ItemIcon = event.currentTarget as ItemIcon;
			icon.background = true;
		}

		private function onIconClicked(event:MouseEvent):void {
			var icon:ItemIcon = event.currentTarget as ItemIcon;
			dispatchEvent(new PowerupEvent(icon.item as PowerupDef));
		}

		override public function get width():Number {
			return icons.length ? DisplayObject(icons[icons.length - 1]).x + DisplayObject(icons[icons.length - 1]).width : 0;
		}

		override public function get height():Number {
			return HEIGHT;
		}
	}
}