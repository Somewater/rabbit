package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class ShopModule extends Sprite implements IClear{

		public static var SHOP_TYPES:Array =
		[
			new ShopData('powerups', PowerupDef)
		]

		public static const WIDTH:int = 655;
		public static const HEIGHT:int = 600;

		private const TOP_PANEL_Y:int = 40;
		private const CONTENT_HEIGHT:int = HEIGHT - 200;
		private const CONTENT_Y:int = 120;
		private const BOTTOM_PANEL_Y:int = HEIGHT - 40;


		private var myPowerups:MyPowerupsBag;
		private var myMoney:MyMoneyBag;
		private var shopGround:DisplayObject;
		private var shopTabs:ShopTabs;
		public var basket:ShopBasket = new ShopBasket();

		private var shopIcons:Array = [];
		private var shopIconsHolder:Sprite;

		private var itemDescription:ItemDescriptionPanel;

		public function ShopModule() {
			var title:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20);
			title.text = Lang.t('SHOP').toUpperCase();
			title.x = (WIDTH - title.width) * 0.5;
			addChild(title);

			var myPowerupsGround:DisplayObject = Lib.createMC('interface.OpaqueBackground');
			myPowerupsGround.x = 0;
			myPowerupsGround.y = TOP_PANEL_Y;
			myPowerupsGround.height = MyPowerupsBag.HEIGHT;
			myPowerupsGround.width = MyPowerupsBag.MAX_WIDTH;
			addChild(myPowerupsGround);

			myPowerups = new MyPowerupsBag(18);
			myPowerups.x = 10;
			myPowerups.y = TOP_PANEL_Y + 2;
			addChild(myPowerups);
			myPowerupsGround.width = myPowerups.width + 20;
			Hint.bind(myPowerups, Lang.t('MY_POWERUPS_PANEL'))

			myMoney = new MyMoneyBag();
			myMoney.y = TOP_PANEL_Y;
			myMoney.x = WIDTH - MyMoneyBag.WIDTH;
			addChild(myMoney);

			shopGround = Lib.createMC('interface.ShopBackground');
			shopGround.x = 0;
			shopGround.y = CONTENT_Y;
			var botShGround:Sprite = new Sprite();
			addChild(botShGround);
			botShGround.x = shopGround.x;
			botShGround.y = shopGround.y;
			addChild(shopGround);
			shopTabs = new ShopTabs(botShGround);
			shopTabs.x = 0;
			shopTabs.y = CONTENT_Y - ShopTabs.HEIGHT;
			addChild(shopTabs);

			shopIconsHolder = new Sprite();
			shopIconsHolder.x = shopGround.x + 245;
			shopIconsHolder.y = shopGround.y + 7;
			addChild(shopIconsHolder)

			basket = new ShopBasket();
			basket.y = BOTTOM_PANEL_Y;
			basket.x = WIDTH;
			basket.addEventListener(Event.CHANGE, onBasketChanged);
			basket.buyButton.addEventListener(MouseEvent.CLICK, onBuyAllClicked);
			addChild(basket);

			itemDescription = new ItemDescriptionPanel();
			itemDescription.x = shopGround.x + 25;
			itemDescription.y = shopGround.y + 40;
			addChild(itemDescription)

			recreateIcons();
		}

		public function clear():void {
			myPowerups.clear();
			myMoney.clear();
			shopTabs.clear();
			itemDescription.clear();
			basket.clear();
			basket.buyButton.removeEventListener(MouseEvent.CLICK, onBuyAllClicked);
			basket.removeEventListener(Event.CHANGE, onBasketChanged);
			clearIcons();
			Hint.removeHint(myPowerups);
		}

		private function recreateIcons():void
		{
			clearIcons();
			var selectedShopData:ShopData;
			for each(selectedShopData in SHOP_TYPES)
				if(selectedShopData.name == shopTabs.selectedTab)
					break;

			var items:Array = ItemDef.byClass(selectedShopData.clazz);
			items.sortOn('cost', Array.NUMERIC);
			for (var i:int = 0; i < items.length; i++) {
				var item:ItemDef = items[i];
				var icon:ShopIcon = new ShopIcon(item);
				icon.addEventListener(MouseEvent.CLICK, onIconClick);
				icon.addEventListener(MouseEvent.ROLL_OVER, onIconOver);
				icon.addEventListener(MouseEvent.ROLL_OUT, onIconOut);
				icon.x = (i % 3) * 140;
				icon.y = int(i / 3) * 140;
				shopIcons.push(icon);
				shopIconsHolder.addChild(icon);
			}
		}

		private function clearIcons():void {
			for each(var icon:ShopIcon in shopIcons)
			{
				icon.clear();
				icon.removeEventListener(MouseEvent.CLICK, onIconClick);
				icon.removeEventListener(MouseEvent.ROLL_OVER, onIconOver);
				icon.removeEventListener(MouseEvent.ROLL_OUT, onIconOut);
				shopIconsHolder.removeChild(icon);
			}
			shopIcons = [];
		}

		private function onIconOut(event:MouseEvent):void {
			var icon:ShopIcon = event.currentTarget as ShopIcon;
			itemDescription.visible = false;
		}

		private function onIconOver(event:MouseEvent):void {
			var icon:ShopIcon = event.currentTarget as ShopIcon;
			if(icon.itemDef is PowerupDef)
			{
				itemDescription.visible = true;
				itemDescription.show(icon.itemDef as PowerupDef)
			}
		}

		private function onIconClick(event:MouseEvent):void {
			var icon:ShopIcon = event.currentTarget as ShopIcon;
			basket.addItem(icon.itemDef)
		}

		private function onBasketChanged(event:Event):void {
			var shopIcon:ShopIcon;
			for each(shopIcon in shopIcons)
				shopIcon.selected = false;
			for each(var item:ItemDef in basket.items)
			{
				// ищем соответствующий ему значек
				for each(shopIcon in shopIcons)
					if(shopIcon.itemDef == item)
					{
						shopIcon.selected = true
					}
			}
		}

		private function onBuyAllClicked(event:MouseEvent):void {
			var sumPrice:int = basket.sumPrice;
			if(sumPrice > UserProfile.instance.money)
			{
				// попросить докупиь бабла
				new BuyMoneyWindow(sumPrice - UserProfile.instance.money);
			}
			else
			{
				// произвести покупу
				var itemIdsToQuantity:Array = [];
				for each(var item:ItemDef in basket.items)
					itemIdsToQuantity[item.id] = basket.itemToQuantity(item);
				AppServerHandler.instance.purchaseItems(itemIdsToQuantity, function(response:Object):void{
					// success
					Config.application.message('SHOP_TRANSACTION_SUCCESS_MSG');
					basket.clearBasket();
				}, function(response:Object):void{
					// error
					Config.application.message(Lang.t('SHOP_TRANSACTION_ERROR_MSG', {error:Config.loader.serverHandler.toJson(response)}));
				})
			}
		}
	}
}