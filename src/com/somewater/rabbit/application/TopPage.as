package com.somewater.rabbit.application {
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.CorrectSizeDefinerSprite;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.TopUser;
	import com.somewater.social.SocialUser;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;
	import com.somewater.text.LinkLabel;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;

	public class TopPage extends PageBase{

		public static var TABLE_WIDTH:int;

		private var selectorButtonsHolder:Sprite;
		private var selectorButtons:Array = [];
		private var tableHolder:CorrectSizeDefinerSprite;
		private var scroller:RScroller;
		private var rows:Array = [];
		private var leftButton:DisplayObject;

		public function TopPage() {

			TABLE_WIDTH = Config.WIDTH * 0.8;

			logo.visible = false;

			var title:EmbededTextField = new EmbededTextField(null, 0xDB661B, 20, false, false, false, false, 'center');
			title.text = Lang.t('TOP_PAGE_TITLE');
			title.width = Config.WIDTH;
			title.y =  30;
			addChild(title);

			selectorButtonsHolder = new Sprite();
			selectorButtonsHolder.x = (Config.WIDTH - TABLE_WIDTH) * 0.5;
			selectorButtonsHolder.y = title.y + 50;
			addChild(selectorButtonsHolder);

			var topTypes:Array = [TopManager.TYPE_STARS, TopManager.TYPE_LEVEL];
			var selectorButtonsByCenter:Boolean = topTypes.length < 4;

			var selectorBtnStr:String;
			var selectorBtn:TopSelectorBtn;
			var selectorButtonWidthSum:Number = 0;
			for each(selectorBtnStr in topTypes)
			{
				selectorBtn = new TopSelectorBtn();
				if(selectorButtonsByCenter)
				{
					selectorBtn.align = 'center';
					selectorBtn.autoSize = TextFieldAutoSize.NONE;
				}
				selectorBtn.topType = selectorBtnStr;
				selectorBtn.text = Lang.t('TOP_TYPE_' + selectorBtnStr.toLocaleUpperCase());
				selectorBtn.addEventListener(LinkLabel.LINK_CLICK, onSelectorBtnClicked);
				selectorButtons.push(selectorBtn);

				selectorButtonsHolder.addChild(selectorBtn);
				selectorBtn.width = TABLE_WIDTH / topTypes.length;
				selectorButtonWidthSum += selectorBtn.width;
			}

			// а теперь позиционируем кнопки
			var selectorButtonSpace:Number = (TABLE_WIDTH - selectorButtonWidthSum) / ((topTypes.length - 1) * 2);
			var nextX:Number = 0;
			var i:int = 0;
			for each(selectorBtn in selectorButtons)
			{
				selectorBtn.x = nextX;
				nextX += selectorBtn.width;

				nextX += selectorButtonSpace;

				if(++i >= selectorButtons.length)
					break;

				var line:DisplayObject = getLine();
				line.height = 20;
				line.x = nextX;
				selectorButtonsHolder.addChild(line);

				nextX += selectorButtonSpace;
			}

			scroller = new RScroller();
			scroller.x = selectorButtonsHolder.x;
			scroller.y = selectorButtonsHolder.y + 20/*text height*/ + 10;
			scroller.setSize(TABLE_WIDTH + scroller.scrollWidth + 1, int((Config.HEIGHT - scroller.y - 30)/ Row.HEIGHT) * Row.HEIGHT);
			addChild(scroller)

			tableHolder = new CorrectSizeDefinerSprite(0, 1);

			if(TopManager.instance.dataLoaded)
				selectButtonIndex = 0;
			else
			{
				PopUpManager.showSlash();
				AppServerHandler.instance.topIndex(onTopIndexInfoLoadedComplete, onTopIndexInfoLoadedError);
			}

			leftButton = Lib.createMC("interface.LeftButton");
			leftButton.x = 20;
			leftButton.y = Config.HEIGHT - leftButton.height - 20;
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);
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
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
		}

		private function onLeftButtonClick(event:MouseEvent):void {
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.application.startPage("main_menu");
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
			var i:int;
			for (i = 0; i < selectorButtons.length; i++) {
				btn = selectorButtons[i];
				btn.selected = i == index;
				if(i == index)
					selectedTopType =  btn.topType;
			}

			// отрефрешить таблицу согласно выбранному типу топа
			clearRows();
			var nextY:int;
			var uidsToApi:Array = [];
			i = 0;
			for each(var user:TopUser in TopManager.instance.getUsersByTopType(selectedTopType))
			{
				var row:Row = new Row(user, i + 1);
				row.y = nextY;
				row.color = i % 2 == 0 ? 0xF7F7F7 : 0;
				nextY += row.height;
				tableHolder.addChild(row);
				rows.push(row);

				uidsToApi.push(user.uid);
				i++;
			}

			scroller.content = tableHolder;
			scroller.position = 0;
			scroller.scrollSpeed = Row.HEIGHT / tableHolder.height;

			// запрос к апи соц. сети
			if(Config.loader.hasUsersApi)
			{
				Config.loader.getUsers(uidsToApi, onUsersSocialInfoReceived, onUsersSocialInfoReceiveError);
			}
		}

		private function onUsersSocialInfoReceived(users:*):void {
			for each(var user:SocialUser in users)
			{
				// ищем строку таблицы, готовую принять инфу по юзеру
				for each(var btn:Row in rows)
					if(btn.user.uid == user.id)
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
import flash.display.Shape;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

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
	public static const HEIGHT:int = 63;

	public var user:TopUser;

	private var photoSprite:Sprite;
	private var photo:Photo;
	private var nameTF:EmbededTextField;
	private var valueTF:EmbededTextField;
	private var counterTF:EmbededTextField;

	private var _selected:Boolean = false;
	private var _color:int;

	public function Row(user:TopUser, count:int)
	{
		this.user = user;

		const DIVISION:Number = 0.7;// в каком соотношении делятся стобцы

		var topLine:Shape = new Shape();
		topLine.graphics.lineStyle(1, 0x89B93A);
		topLine.graphics.moveTo(0,0);
		topLine.graphics.lineTo(width, 0);
		addChild(topLine)

		var line:DisplayObject = TopPage.getLine();
		addChild(line);

		line = TopPage.getLine();
		line.x = 40;
		addChild(line);

		line = TopPage.getLine();
		line.x = this.width * DIVISION;
		addChild(line);

		line = TopPage.getLine();
		line.x = this.width;
		addChild(line);

		photoSprite = Lib.createMC('interface.TopUserPhoto');
		photo = new Photo();
		photo.photoMask = photoSprite.getChildByName('photoMask');
		photoSprite.x = 60;
		photoSprite.y = (height - photoSprite.height) * 0.5
		addChild(photoSprite);

		counterTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 21, false, false, false, false, 'right');
		counterTF.width = 30;
		counterTF.x = 30;
		counterTF.y = 19;
		counterTF.text = count.toString();
		addChild(counterTF);

		if(Config.loader.hasNavigateToHomepage)
		{
			nameTF = new LinkLabel(Config.FONT_SECONDARY, 0x31B1E8, 16, true);
			nameTF.addEventListener(LinkLabel.LINK_CLICK, onLinkClick);
		}
		else
		{
			nameTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 16, true);
		}
		nameTF.multiline = true;
		nameTF.autoSize = TextFieldAutoSize.LEFT
		nameTF.width = this.width * DIVISION - nameTF.x;
		nameTF.x = 150;
		nameTF.y = 14;
		nameTF.text = '---\n---'
		addChild(nameTF);

		valueTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 21, true, false, false, false, 'center');
		valueTF.width = this.width * (1 - DIVISION);
		valueTF.x = this.width * DIVISION;
		valueTF.y = 19;
		addChild(valueTF);

		valueTF.text = int(user.value).toString();

		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onOut);
	}

	private function onLinkClick(event:Event):void {
		Config.loader.navigateToHomePage(user.uid);
	}

	private function onOut(event:MouseEvent):void {
		selected = false;
	}

	private function onOver(event:MouseEvent):void {
		selected = true;

	}

	public function set color(value:int):void
	{
		_color = value;
		refreshGround();
	}

	public function set selected(value:Boolean):void
	{
		if(_selected != value)
		{
			_selected = value;
			refreshGround();
		}
	}

	private function refreshGround():void
	{
		graphics.clear();
		graphics.beginFill(_selected ? 0x78D0FE : _color, _color || _selected ? 0.2 : 0);
		graphics.drawRect(0,0,this.width, this.height);
	}

	public function clear():void
	{
		user = null;
		removeEventListener(MouseEvent.ROLL_OVER, onOver);
		removeEventListener(MouseEvent.ROLL_OUT, onOut);
		nameTF.removeEventListener(LinkLabel.LINK_CLICK, onLinkClick);
		photo.clear();
	}


	override public function get width():Number {
		return TopPage.TABLE_WIDTH;
	}


	override public function get height():Number {
		return HEIGHT;
	}

	public function setData(user:SocialUser):void {
		nameTF.text = user.firstName + '\n' + user.lastName;
		photo.source = user.photoSmall;
	}
}
