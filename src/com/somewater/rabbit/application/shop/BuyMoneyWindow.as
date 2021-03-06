package com.somewater.rabbit.application.shop {
	import com.somewater.display.Window;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.AppServerHandler;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.application.windows.NeighboursWindow;
	import com.somewater.rabbit.storage.ConfManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.events.Event;

	import flash.events.MouseEvent;
	import flash.utils.getTimer;

	public class BuyMoneyWindow extends Window{

		private static const WIDTH:int = 550;
		private static const HEIGHT:int = 380;

		private static var lastClickTime:uint = 0;

		private var buyMoneyButtons:Array = [];
		private var addFriendsButton:OrangeButton;

		public function BuyMoneyWindow(need:int = 0) {
			super(null, null, null, []);
			setSize(WIDTH, HEIGHT);

			var buyTitle:EmbededTextField = new EmbededTextField(Config.FONT_PRIMARY, 0xDB661B, 20, true);
			buyTitle.text = Lang.t('BUY_MONEY_WINDOW_TITLE');
			buyTitle.x = (WIDTH - buyTitle.width) * 0.5;
			buyTitle.y = 18;
			addChild(buyTitle);

			var needMoneyText:EmbededTextField
			if(need)
			{
				needMoneyText = new EmbededTextField(null, 0xDB661B, 12, true, true, false, false, 'center');
				needMoneyText.width = this.width * 0.8;
				needMoneyText.text = Lang.t('NEED_MONEY_MESSAGE', {quantity: need})
				needMoneyText.x = (this.width - needMoneyText.width) * 0.5;
				needMoneyText.y = buyTitle.y + buyTitle.textHeight + 10;
				addChild(needMoneyText);
			}

			var rules:Object = ConfManager.instance.get('NETMONEY_TO_MONEY');
			var count:int;
			var key:String;
			var sortedRules:Array = [];
			if(Config.loader.hasPaymentApi)
				for(key in rules)
				{
					count++;
					sortedRules.push({money: int(rules[key]), netmoney: int(key)});
				}
			sortedRules.sortOn('money', Array.NUMERIC);

			var nextY:int = needMoneyText ? needMoneyText.y + needMoneyText.textHeight + 20 : buyTitle.y + buyTitle.textHeight + 20;
			var padding:int = BuyMoneyButton.HEIGHT + 10;
			var i:int = 0;
			for each(var data:Object in sortedRules)
			{
				var button:BuyMoneyButton = new BuyMoneyButton(data.netmoney, data.money);
				button.x = (WIDTH - BuyMoneyButton.WIDTH) * 0.5;
				button.y = nextY;
				nextY += padding;
				button.addEventListener(MouseEvent.CLICK, onClick);
				addChild(button);
				buyMoneyButtons.push(button);

				// кнопка кликабельна, если это просто окно (без need), если кнопка окупит всё или это последняя доступная кнопка (остальные заблочены)
				button.enabled = need == 0 || need <= data.money || i == sortedRules.length - 1;

				i++;
			}

			addFriendsButton = new OrangeButton();
			addFriendsButton.addEventListener(MouseEvent.CLICK, onAddNeighboursClicked);
			addFriendsButton.width = BuyMoneyButton.WIDTH;
			addFriendsButton.textField.size = 14;
			addFriendsButton.textField.multiline = true;
			addFriendsButton.textField.width = addFriendsButton.width * 0.8
			addFriendsButton.label = "Добавить соседей и собирать\nкруглики на их полянках каждый день";
			addFriendsButton.height = BuyMoneyButton.HEIGHT * 2;
			addFriendsButton.x = (this.width - addFriendsButton.width) * 0.5;
			addFriendsButton.y = nextY;
			addChild(addFriendsButton);

			if(count == 0)
			{
				// если нет воз-ти покупать кругилки
				var attentionTF:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20, true, true, false, false, 'center');
				attentionTF.width = this.width * 0.8;
				attentionTF.height = 200
				attentionTF.text = Lang.t('CANT_BUY_MONEY_MESSAGE')
				attentionTF.x = (this.width - attentionTF.width) * 0.5;
				attentionTF.y = 100;
				addChild(attentionTF);
			}

			open();

			Config.stat(Stat.WND_BUY_COINS);
		}


		override public function clear():void {
			super.clear();
			for each(var b:BuyMoneyButton in buyMoneyButtons)
			{
				b.removeEventListener(MouseEvent.CLICK, onClick);
				b.clear();
			}
			addFriendsButton.removeEventListener(MouseEvent.CLICK, onAddNeighboursClicked);
		}

		private function onClick(event:MouseEvent):void {
			var btn:BuyMoneyButton = event.currentTarget as BuyMoneyButton;
			if(!btn.enabled) return;
			BuyMoneyWindow.pay(btn.money, btn.netmoney, function():void{
				close();
			})
		}

		private function onAddNeighboursClicked(event:Event):void {
			close();
			new NeighboursWindow();
		}

		private static function pay(money:int, netmoney:int, onComplete:Function, onError:Function = null, silent:Boolean = true):void{
			var currentClickTime:uint = getTimer()
			if(currentClickTime - lastClickTime < 2000) return;// не реже раза в 2 секнуды
			lastClickTime = currentClickTime;
			Config.loader.pay(netmoney, function(...args):void{
				// success
				if(currentClickTime == lastClickTime)
					lastClickTime = 0;
				else
					return;// уже был другой запрос к апи, этот неактуален
				Config.application.showSlash(0);

				if(Config.loader.asyncPayment){
					AppServerHandler.instance.refreshMoney(onGameServerResponseSuccess, onGameServerResponseError);
				} else {
					AppServerHandler.instance.buyMoney(money, netmoney, onGameServerResponseSuccess, onGameServerResponseError);
				}
			}, function(...args):void{
				// error
				if(currentClickTime == lastClickTime)
					lastClickTime = 0;
				if(onError != null)
					onError();
			});

			function onGameServerResponseSuccess(response:Object):void{
				Config.application.hideSplash();
				if(!silent)
					Config.application.message(Lang.t('BUY_MONEY_SUCCESS_MESSAGE', {quantity: money}))
				if(onComplete != null)
					onComplete();
			}
			function onGameServerResponseError(response:Object):void{
				Config.application.hideSplash();
				if(!silent)
					Config.application.message(Lang.t('ERROR_BUY_MONEY', {error: Config.loader.serverHandler.toJson(response)}))
				if(onError != null)
					onError();
			}
		}

		public static function withMoney(fullPrice:int, onComplete:Function, onError:Function = null):void {
			if(UserProfile.instance.money >= fullPrice){
				onComplete();
			} else {
				var need:int = fullPrice - UserProfile.instance.money;

				var rules:Object = ConfManager.instance.get('NETMONEY_TO_MONEY');
				var sortedRules:Array = [];
				for(var key:String in rules){
					sortedRules.push({money: int(rules[key]), netmoney: int(key)});
				}
				sortedRules.sortOn('money', Array.NUMERIC);
				for each(var data:Object in sortedRules){
					if(data.money >= need){
						pay(data.money, data.netmoney, onComplete, onError);
						return;
					}
				}

				new BuyMoneyWindow(need).addEventListener(Window.EVENT_CLOSE, function(ev:Event):void{
					if(UserProfile.instance.money >= fullPrice)
						onComplete();
					else if(onError != null)
						onError();
				})
			}
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
		getTxt.y = 1;
		addChild(getTxt);

		var fromTxt:EmbededTextField = new EmbededTextField(null, 0xFFFFFF, 14);
		fromTxt.x = icon.x + icon.width + 20;
		fromTxt.y = 5;
		addChild(fromTxt);

		getTxt.htmlText = Lang.t('BUY_MONET_QUANTITY', {quantity: money});


		var netMoneyName:String = Lang.t('NET_MONEY');
		try
		{
			netMoneyName = Config.loader.customHash['NET_MONEY'](netmoney);
		}catch(err:Error){}

		fromTxt.text = Lang.t('BUY_MONEY_COST', {cost: netmoney, net_money: netMoneyName})
	}
}
