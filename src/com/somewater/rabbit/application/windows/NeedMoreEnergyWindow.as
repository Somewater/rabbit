package com.somewater.rabbit.application.windows {
import com.somewater.display.Window;
import com.somewater.rabbit.application.AppServerHandler;
import com.somewater.rabbit.application.EnergyIndicator;
import com.somewater.rabbit.application.buttons.BuyButton;
import com.somewater.rabbit.storage.ConfManager;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.UserProfile;
import com.somewater.storage.Lang;

import flash.events.Event;

import flash.events.MouseEvent;

public class NeedMoreEnergyWindow extends Window{

	private var energyIndicator:EnergyIndicator;
	private var buyButton:BuyButton;

	private var onBuyed:Function;
	private var onCancel:Function;

	public function NeedMoreEnergyWindow(onBuyed:Function, onCancel:Function = null, otherTitle:String = null) {
		super(otherTitle ? otherTitle : Lang.t('NEED_MORE_ENERGY_WND_TITLE'), null, null, []);

		setSize(400, 350);

		this.onBuyed = onBuyed;
		this.onCancel = onCancel;

		energyIndicator = new EnergyIndicator();
		energyIndicator.x = (this.width - energyIndicator.width) * 0.5;
		energyIndicator.y = this.textField.y + this.textField.textHeight + 40;
		addChild(energyIndicator);

		buyButton = new BuyButton();
		buyButton.width = 200;
		buyButton.label = Lang.t('BUY_ENERGY_BY', {money: ConfManager.instance.getNumber('ENERGY_COST')});
		buyButton.enabled = UserProfile.instance.money >= ConfManager.instance.getNumber('ENERGY_COST');
		buyButton.addEventListener(MouseEvent.CLICK, onBuyClick);
		buyButton.x = (this.width - buyButton.width) * 0.5;
		buyButton.y = energyIndicator.y + energyIndicator.height + 40;
		addChild(buyButton);

		open();
	}


	override protected function onCloseBtnClick(e:MouseEvent):void {
		onCancel && onCancel();
		super.onCloseBtnClick(e);
	}

	override public function clear():void {
		super.clear();
		energyIndicator.clear();
		buyButton.clear();
		buyButton.removeEventListener(MouseEvent.CLICK, onBuyClick);
		onBuyed = null;
		onCancel = null;
	}

	private function onBuyClick(event:Event):void {
		var diff:int = UserProfile.instance.money - ConfManager.instance.getNumber('ENERGY_COST');
		if(diff >= 0){
			Config.application.showSlash(0);
			AppServerHandler.instance.purchaseEnergy(function(response:Object){
				Config.application.hideSplash();
				onBuyed && onBuyed();
				close();
			}, function(response:Object){
				Config.application.hideSplash();
				onCancel && onCancel();
				close();
				Config.application.message(Lang.t('ENERGY_PURCHASE_ERROR'))
			})
		} else {
			Config.application.message(Lang.t('NEED_MONEY_MESSAGE', {quantity: -diff}));
		}
	}
}
}
