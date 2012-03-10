package com.somewater.rabbit.application.shop {
	import com.somewater.display.Window;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.storage.ConfManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.events.MouseEvent;

	public class BuyMoneyWindow extends Window{

		private static const WIDTH:int = 550;
		private static const HEIGHT:int = 350;

		private var buyMoneyButtons:Array = [];

		public function BuyMoneyWindow() {
			super(null, null, null, []);
			setSize(WIDTH, HEIGHT);

			var buyTitle:EmbededTextField = new EmbededTextField(Config.FONT_PRIMARY, 0xDB661B, 20, true);
			buyTitle.text = Lang.t('BUY_MONEY_WINDOW_TITLE');
			buyTitle.x = (WIDTH - buyTitle.width) * 0.5;
			buyTitle.y = 18;
			addChild(buyTitle);

			var rules:Object = ConfManager.instance.get('NETMONEY_TO_MONEY');
			CONFIG::debug
			{
				rules = {1 : 10, 3 : 35, 5 : 60, 10 : 140, 50 : 850}
			}
			var count:int;
			var key:String;
			for(key in rules)
				count++;

			var nextY:int = buyTitle.y + buyTitle.textHeight + 10;
			var padding:int = BuyMoneyButton.HEIGHT + 10;
			for(key in rules)
			{
				var netmoney:int = int(key);
				var money:int = int(rules[key]);
				var button:BuyMoneyButton = new BuyMoneyButton(netmoney, money);
				button.x = (WIDTH - BuyMoneyButton.WIDTH) * 0.5;
				button.y = nextY;
				nextY += padding;
				button.addEventListener(MouseEvent.CLICK, onClick);
				addChild(button);
				buyMoneyButtons.push(button);
			}

			open();
		}


		override public function clear():void {
			super.clear();
			for each(var b:BuyMoneyButton in buyMoneyButtons)
			{
				b.removeEventListener(MouseEvent.CLICK, onClick);
				b.clear();
			}
		}

		private function onClick(event:MouseEvent):void {
			var btn:BuyMoneyButton = event.currentTarget as BuyMoneyButton;
			Config.loader.pay(btn.netmoney, function(...args):void{
				// success
				Config.application.showSlash(0);
				AppServerHandler.instance.buyMoney(btn.money, btn.netmoney, function(response:Object):void{
					// SUCCESSSSS
					Config.application.hideSplash();
					close();
					Config.application.message(Lang.t('BUY_MONEY_SUCCESS_MESSAGE', {quantity: btn.money}))
				}, function(response:Object):void{
					// game server error
					Config.application.hideSplash();
					Config.application.message(Lang.t('ERROR_BUY_MONEY', {error: Config.loader.serverHandler.toJson(response)}))
				});
			}, function(...args):void{
				// error
			});
		}
	}
}

import com.somewater.rabbit.application.buttons.GreenButton;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.storage.Lang;
import com.somewater.text.EmbededTextField;

import flash.display.DisplayObject;

class BuyMoneyButton extends GreenButton
{
	public static const WIDTH:int = 350;
	public static const HEIGHT:int = 32;

	public var netmoney:int;
	public var money:int;

	public function BuyMoneyButton(netmoney:int, money:int)
	{
		this.netmoney = netmoney;
		this.money = money;
		setSize(WIDTH, HEIGHT);

		var icon:DisplayObject = Lib.createMC('interface.MoneyIcon')
		icon.x = (WIDTH - icon.width) * 0.5;
		icon.y = (HEIGHT - icon.height) * 0.5;
		addChild(icon);

		var getTxt:EmbededTextField = new EmbededTextField(null, 0xFFFFFF, 14, true, false, false, false, 'right');
		getTxt.x = icon.x - 20;
		addChild(getTxt);

		var fromTxt:EmbededTextField = new EmbededTextField(null, 0xFFFFFF, 14);
		fromTxt.x = icon.x + icon.width + 20;
		addChild(fromTxt);

		getTxt.htmlText = Lang.t('BUY_MONET_QUANTITY', {quantity: money});
		getTxt.y = (HEIGHT - getTxt.textHeight) * 0.5;


		var netMoneyName:String = Lang.t('NET_MONEY');
		try
		{
			netMoneyName = Config.loader.customHash['NET_MONEY'](netmoney);
		}catch(err:Error){}

		fromTxt.text = Lang.t('BUY_MONEY_COST', {cost: netmoney, net_money: netMoneyName})
		fromTxt.y = (HEIGHT - fromTxt.textHeight) * 0.5;
	}
}
