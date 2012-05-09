package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.buttons.GreenButton;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;

	public class ShopBasket extends Sprite implements IClear{

		private var titleTF:EmbededTextField;
		private var iconsHolder:Sprite;
		private var icons:Array = [];
		public var buyButton:GreenButton;
		private var buyButtonMoneyIcon:Sprite;

		public function ShopBasket() {
			titleTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 21, true);
			titleTF.y = 8;
			titleTF.text = Lang.t('SHOP_BASKET_MESSAGE_BUY');
			addChild(titleTF);

			iconsHolder = new Sprite();
			addChild(iconsHolder);

			buyButton = new GreenButton();
			buyButton.y = 5;
			buyButton.label = Lang.t('SHOP_BASKET_BTN_BUY', {quantity: 999});
			buyButton.width *= 1.5;
			buyButtonMoneyIcon = Lib.createMC('interface.MoneyIcon');
			buyButtonMoneyIcon.y = 6;
			buyButtonMoneyIcon.scaleX = buyButtonMoneyIcon.scaleY = 0.7;
			buyButtonMoneyIcon.mouseEnabled = buyButtonMoneyIcon.mouseChildren = false;
			buyButton.addChild(buyButtonMoneyIcon);
			addChild(buyButton);

			alignAndCalcCost();
		}

		public function clear():void {
			buyButton.clear();
			clearIcons();
		}

		private function clearIcons():void
		{
			for each(var i:ItemIcon in icons)
			{
				i.clear();
				iconsHolder.removeChild(i);
				i.removeEventListener(MouseEvent.CLICK, onItemClick);
			}
			icons = [];
		}

		private function onItemClick(event:MouseEvent):void {
			removeItem(ItemIcon(event.currentTarget).item);
		}

		public function addItem(item:ItemDef, quantity:int = 1):void
		{
			var icon:ItemIcon;

			if(item is CustomizeDef && itemToQuantity(item) > 0)
				return;// нельзя купить 2 крыши и т.д.

			// удаляем из айтемов все не кастомные объекты, а также кастомные с тем же типом что новенький
			var i:int = 0;
			while(i < icons.length)
			{
				icon = icons[i];
				if((item is CustomizeDef &&
						(
							!(icon.item is CustomizeDef)
							||
							CustomizeDef(icon.item).type == CustomizeDef(item).type)
						)
					||
					(item is PowerupDef && !(icon.item is PowerupDef))
				)
				{
					removeItem(icon.item);
				}
				else
					i++;
			}
			icon = null;
			for each(var ic:ItemIcon in icons)
				if(ic.item == item)
				{
					ic.quantity += quantity;
					icon = ic;
					break;
				}
			if(icon == null)
			{
				icon = new ItemIcon(item);
				icon.closeVisible = true;
				icon.quantity = quantity;
				icon.quantituColor = 0x124D18;
				icon.useHandCursor = icon.buttonMode = true;
				icon.addEventListener(MouseEvent.CLICK, onItemClick);
				icon.background = true;
				icons.push(icon);
				iconsHolder.addChild(icon);
			}
			alignAndCalcCost();
			dispatchChange();
		}

		public function removeItem(item:ItemDef):void
		{
			for each(var ic:ItemIcon in icons)
				if(ic.item == item)
				{
					if(ic.quantity > 1)
						ic.quantity--;
					else
					{
						ic.clear();
						iconsHolder.removeChild(ic);
						icons.splice(icons.indexOf(ic), 1);
						ic.removeEventListener(MouseEvent.CLICK, onItemClick);
					}
					alignAndCalcCost();
					dispatchChange();
					return;
				}
			throw new Error('Ha not item in basket')
		}

		/**
		 * Массив содержащихся в корзине товаров
		 * array of ItemDef
		 */
		public function get items():Array
		{
			var items:Array = [];
			for each(var ic:ItemIcon in icons)
				items.push(ic.item);
			return items;
		}

		public function itemToQuantity(item:ItemDef):int
		{
			for each(var ic:ItemIcon in icons)
				if(ic.item == item)
					return ic.quantity;
			return 0;
		}

		public function itemIdByQuantity():Array
		{
			var itemIdsToQuantity:Array = [];
			for each(var ic:ItemIcon in icons)
				itemIdsToQuantity[ic.item.id] = ic.quantity;
			return itemIdsToQuantity;
		}

		private function dispatchChange():void
		{
			dispatchEvent(new Event(Event.CHANGE));
		}

		private function alignAndCalcCost():void
		{
			var nextX:int = 0;
			for each(var ic:ItemIcon in icons)
			{
				ic.x = nextX;
				nextX += ic.width + 15;
			}

			// пересчитать и написать надпись на кнопке КУПИТЬ
			var sumPrice:int = this.sumPrice;
			buyButton.label = Lang.t('SHOP_BASKET_BTN_BUY', {quantity: sumPrice});
			buyButton.x = -buyButton.width;
			buyButtonMoneyIcon.x = buyButton.textField.x + buyButton.textField.width + 5;

			var iconsWidth:int = icons.length ? ItemIcon(icons[icons.length - 1]).x + ItemIcon(icons[icons.length - 1]).width : 0;
			iconsHolder.x = -buyButton.width - 20 - iconsWidth;
			titleTF.x = iconsHolder.x - titleTF.width - 15;

			this.visible = icons.length > 0;
		}

		public function get sumPrice():int
		{
			var price:int = 0;
			for each(var ic:ItemIcon in icons)
			{
				price += ic.item.cost * ic.quantity;
			}
			return price;
		}

		public function clearBasket():void {
			clearIcons();
			alignAndCalcCost();
			dispatchChange();
		}
	}
}
