package com.somewater.rabbit.application.shop {
	import com.somewater.control.IClear;

	import flash.display.Sprite;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	[Event(type="flash.events.Event", name="change")]
	public class ShopTabs extends Sprite implements IClear{

		public static const TAB_WIDTH:int = 90;
		public static const HEIGHT:int = 25;

		private var tabs:Array = [];

		public var selectedTab:String;

		public function ShopTabs(botShGround:Sprite, selectedTab:String = null) {
			var nextX:int = 0;
			var i:int = 0;
			for each(var data:ShopData in ShopModule.SHOP_TYPES)
			{
				var tab:Tab = new Tab(botShGround, data.name, i == 0, i);
				tab.selected = selectedTab ? selectedTab == data.name : i == 0;
				tab.x = nextX;
				nextX += TAB_WIDTH;
				addChild(tab);
				tab.addEventListener(MouseEvent.CLICK, onClick);
				tabs.push(tab);
				i++;
			}

			if(selectedTab == null)
				this.selectedTab = Tab(tabs[0]).tabName;
			else
				this.selectedTab = selectedTab;
		}

		public function clear():void {
			for each(var t:Tab in tabs)
			{
				t.clear();
				t.removeEventListener(MouseEvent.CLICK, onClick)
			}
		}

		private function onClick(event:MouseEvent):void {
			var tab:Tab = event.currentTarget as Tab;
			selectedTab = tab.tabName;
			for each(var t:Tab in tabs)
			{
				t.selected = t == tab;
			}
			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}

import com.greensock.TweenLite;
import com.somewater.control.IClear;
import com.somewater.rabbit.application.shop.ShopTabs;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.storage.Lang;
import com.somewater.text.EmbededTextField;

import flash.display.DisplayObject;
import flash.display.Sprite;

import flash.display.Sprite;
import flash.events.MouseEvent;

class Tab extends Sprite implements IClear
{


	public var tabName:String;

	private var background:Sprite;
	private var selectBack:DisplayObject;
	private var textField:EmbededTextField;

	private var _selected:Boolean = false;

	public function Tab(botShGround:Sprite, name:String, backTypeSelected:Boolean, index:int)
	{
		this.tabName = name;

		background = Lib.createMC(backTypeSelected ? 'interface.ShopTabElement_orange' : 'interface.ShopTabElement_green');
		selectBack = background.getChildByName('select');
		textField = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 12, true, false, false, false, 'center');
		textField.width = ShopTabs.TAB_WIDTH;
		textField.text = Lang.t('SHOP_TAB_' + name.toUpperCase());
		textField.y = 4;
		addChild(selectBack);
		addChild(textField);
		botShGround.addChild(background);
		background.x = index * ShopTabs.TAB_WIDTH;

		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onOut);

		onOut(null);
	}

	public function clear():void {
		removeEventListener(MouseEvent.ROLL_OVER, onOver);
		removeEventListener(MouseEvent.ROLL_OUT, onOut);
	}

	private function onOut(event:MouseEvent):void {
		selectBack.visible = _selected;
		TweenLite.to(background,  0.2, {y:-ShopTabs.HEIGHT});
	}

	private function onOver(event:MouseEvent):void {
		if(!_selected)
			TweenLite.to(background,  0.2, {y:-ShopTabs.HEIGHT-5});
	}

	public function set selected(value:Boolean):void
	{
		if(_selected != value)
		{
			_selected = value;
			onOut(null);
		}
	}

	public function get selected():Boolean
	{
		return _selected;
	}
}