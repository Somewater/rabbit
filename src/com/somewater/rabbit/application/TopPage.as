package com.somewater.rabbit.application {
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.TopUser;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.LinkLabel;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;

	public class TopPage extends PageBase{

		public static var TABLE_WIDTH:int;

		private var selectorButtonsHolder:Sprite;
		private var selectorButtons:Array = [];
		private var tableHolder:Sprite;
		private var scroller:RScroller;
		private var rows:Array = [];

		public function TopPage() {

			TABLE_WIDTH = Config.WIDTH * 0.8;

			logo.visible = false;

			var title:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20, false, false, false, false, 'center');
			title.text = Lang.t('TOP_PAGE_TITLE');
			title.width = Config.WIDTH;
			title.y =  16;
			addChild(title);

			selectorButtonsHolder = new Sprite();
			selectorButtonsHolder.x = (Config.WIDTH - TABLE_WIDTH) * 0.5;
			selectorButtonsHolder.y = title.y + title.height + 10;
			addChild(selectorButtonsHolder);

			var topTypes:Array = [TopManager.TYPE_STARS];
			topTypes = topTypes.concat(topTypes,topTypes,topTypes,topTypes,topTypes,topTypes);

			var selectorBtnStr:String;
			var selectorBtn:TopSelectorBtn;
			var selectorButtonWidthSum:Number = 0;
			for each(selectorBtnStr in topTypes)
			{
				selectorBtn = new TopSelectorBtn();
				selectorBtn.topType = selectorBtnStr;
				selectorBtn.text = Lang.t('TOP_TYPE_' + selectorBtnStr.toLocaleUpperCase());
				selectorBtn.addEventListener(LinkLabel.LINK_CLICK, onSelectorBtnClicked);
				selectorButtons.push(selectorBtn);

				selectorButtonsHolder.addChild(selectorBtn);
				selectorButtonWidthSum += selectorBtn.width;
			}

			// а теперь позиционируем кнопки
			var selectorButtonSpace:Number = (TABLE_WIDTH - selectorButtonWidthSum) / ((topTypes.length - 1) * 2);
			var nextX:Number = 0;
			for each(selectorBtn in selectorButtons)
			{
				selectorBtn.x = nextX;
				nextX += selectorBtn.width;

				nextX += selectorButtonSpace;

				if(nextX > TABLE_WIDTH)
					break;

				var line:DisplayObject = getLine();
				line.height = 20;
				line.x = nextX;
				selectorButtonsHolder.addChild(line);

				nextX += selectorButtonSpace;
			}

			scroller = new RScroller();
			scroller.x = selectorButtonsHolder.x;
			scroller.y = selectorButtonsHolder.y + selectorButtonsHolder.height + 10;
			scroller.setSize(TABLE_WIDTH + scroller.scrollWidth, Config.HEIGHT - scroller.y - 30);
			addChild(scroller)

			tableHolder = new Sprite();

			if(TopManager.instance.dataLoaded)
				selectButtonIndex = 0;
			else
			{
				PopUpManager.showSlash();
				AppServerHandler.instance.topIndex(onTopIndexInfoLoadedComplete, onTopIndexInfoLoadedError);
			}
		}

		private function onTopIndexInfoLoadedComplete(data:Object):void {
			PopUpManager.hideSplash();
			selectButtonIndex = 0;
		}

		private function onTopIndexInfoLoadedError(data:Object):void {
			PopUpManager.hideSplash();
			PopUpManager.message(Lang.t('ERROR_GET_TOP_INDEX'));
		}

		public static function getLine():DisplayObject
		{
			return Lib.createMC('interface.GradientLine');
		}

		override public function clear():void {
			super.clear();

			for each(var selectorBtn:TopSelectorBtn in selectorButtons)
			{
				selectorBtn.removeEventListener(LinkLabel.LINK_CLICK, onSelectorBtnClicked);
				selectorBtn.clear();
			}

			clearRows();

			scroller.clear();
		}

		private function clearRows():void
		{
			for each(var r:Row in rows)
			{
				r.clear();
				if(r.parent)
					r.parent.removeChild(r);
			}
			rows = [];
		}

		private function onSelectorBtnClicked(event:Event):void {
			var btn:TopSelectorBtn = event.currentTarget as TopSelectorBtn;
			if(!btn.selected)
				selectButtonIndex = selectorButtons.indexOf(btn);
		}

		private function set selectButtonIndex(index:int):void
		{
			var btn:TopSelectorBtn;
			var selectedTopType:String;
			for (var i:int = 0; i < selectorButtons.length; i++) {
				btn = selectorButtons[i];
				btn.selected = i == index;
				if(i == index)
					selectedTopType =  btn.topType;
			}

			// отрефрешить таблицу согласно выбранному типу топа
			clearRows();
			var nextY:int;
			var uidsToApi:Array = [];
			for each(var user:TopUser in TopManager.instance.getUsersByTopType(selectedTopType))
			{
				var row:Row = new Row(user);
				row.y = nextY;
				nextY += row.height;
				tableHolder.addChild(row);
				rows.push(row);

				uidsToApi.push(user.uid);
			}

			scroller.content = tableHolder;

			// запрос к апи соц. сети
			if(Config.loader.hasUsersApi)
			{
				Config.loader.getUsers(uidsToApi, onUsersSocialInfoReceived, onUsersSocialInfoReceiveError);
			}
		}

		private function onUsersSocialInfoReceived(users:Array):void {
			for each(var user:SocialUser in users)
			{
				// ищем строку таблицы, готовую принять инфу по юзеру
				for each(var btn:Row in rows)
					if(btn.uid == user.id)
					{
						btn.setData(user);
						break;
					}
			}
		}

		private function onUsersSocialInfoReceiveError(...params):void {

		}
	}
}

import com.somewater.control.IClear;
import com.somewater.display.Photo;
import com.somewater.rabbit.application.RScroller;
import com.somewater.rabbit.application.TopPage;
import com.somewater.rabbit.storage.Config;
import com.somewater.rabbit.storage.Lib;
import com.somewater.rabbit.storage.TopUser;
import com.somewater.social.SocialUser;
import com.somewater.text.EmbededTextField;
import com.somewater.text.LinkLabel;

import flash.display.DisplayObject;

import flash.display.Sprite;

class TopSelectorBtn extends LinkLabel
{
	private var _selected:Boolean;

	public var topType:String;

	public function TopSelectorBtn()
	{
		super(Config.FONT_SECONDARY, 0x124D18, 12, true);

		_selected = true;
		selected = false;
	}

	public function set selected(value:Boolean):void
	{
		if(_selected != value)
		{
			_selected = value;
			linked = !value;
			color = value ? 0x9F4A13 : 0x124D18;
		}
	}

	public function get selected():Boolean
	{
		return _selected;
	}
}

class Row extends Sprite implements IClear
{
	public var uid:String;

	private var user:TopUser;

	private var photoSprite:Sprite;
	private var photo:Photo;
	private var nameTF:EmbededTextField;
	private var valueTF:EmbededTextField;

	public function Row(user:TopUser)
	{
		this.user = user;

		graphics.lineStyle(1, 0x89B93A);
		graphics.moveTo(0,0);
		graphics.lineTo(0, width);

		var line:DisplayObject = TopPage.getLine();
		line.height = this.height;
		addChild(line);

		line = TopPage.getLine();
		line.height = this.height;
		line.x = 300;
		addChild(line);

		line = TopPage.getLine();
		line.height = this.height;
		line.x = 460;
		addChild(line);

		photoSprite = Lib.createMC('interface.TopUserPhoto');
		photo = new Photo();
		photo.photoMask = photoSprite.getChildByName('photoMask');
		photoSprite.x = 27;
		photoSprite.y = (height - photoSprite.height) * 0.5

		nameTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 16, true, true)
		nameTF.x = 120;
		nameTF.y = 14;
		addChild(nameTF);

		valueTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 21, true, false, false, false, 'center');
		valueTF.width = 110;
		valueTF.x = 330;
		valueTF.y = 19;
		addChild(valueTF);

		valueTF.text = user.value.toString();
	}

	public function clear():void
	{
		user = null;
	}


	override public function get width():Number {
		return TopPage.TABLE_WIDTH - RScroller.SCROLL_WIDTH;
	}


	override public function get height():Number {
		return 63;
	}

	public function setData(user:SocialUser):void {
		nameTF.text = user.firstName + '\n' + user.lastName;
	}
}
