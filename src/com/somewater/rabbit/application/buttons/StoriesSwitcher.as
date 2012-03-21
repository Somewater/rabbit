package com.somewater.rabbit.application.buttons {
	import com.somewater.control.IClear;
	import com.somewater.control.IClear;
	import com.somewater.control.Scroller;
	import com.somewater.rabbit.application.RScroller;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.StoryDef;

	import flash.display.Sprite;
	import flash.events.Event;

	/**
	 * Переключалка историй для заданного юзера
	 */
	public class StoriesSwitcher extends Sprite implements IClear{

		public static const ON_STORY_CHANGED:String = 'onStoryChanged';

		private var items:Array = [];
		private var _position:int = 0;
		private var _selectedStory:StoryDef;

		private var scroller:RScroller = new RScroller();

		public function StoriesSwitcher(user:GameUser) {

			var stories:Array = StoryDef.all();

			// ищем маскимальную историю, открытую для пльзователя
			for each(var s:StoryDef in stories)
			{
				if(s.start_level <= user.levelNumber && s.enabled)// история доступна
				{
					if(_selectedStory == null || _selectedStory.number < s.number)
						_selectedStory = s;
				}
			}

			var contentHolder:Sprite = new Sprite();

			for (var i:int = 0; i < stories.length; i++)
			{
				var story:StoryDef = stories[i];
				var item:StoryItem = new StoryItem(story);
				items.push(item);
				item.x = i * (StoryItem.WIDTH + 16);
				item.y = 0;
				contentHolder.addChild(item);

				item.enabled = story.start_level <= user.levelNumber && story.enabled || Config.memory['portfolioMode'];
				item.selected = story.number == _selectedStory.number;
				item.addEventListener(StoryItem.STORY_ITEM_CLICKED, onItemClicked)
			}

			scroller = new RScroller();
			scroller.orientation = Scroller.HORIZONTAL;
			scroller.setSize(this.width, this.height);
			scroller.content = contentHolder;
			addChild(scroller);
		}

		private function onItemClicked(event:Event):void {
			var item:StoryItem = event.currentTarget as StoryItem;
			_selectedStory = item.story;
			for each(var item2:StoryItem in items)
			{
				item2.selected = item2 == item;
			}
			dispatchEvent(new Event(ON_STORY_CHANGED));
		}

		public function clear():void {
			for (var i:int = 0; i < items.length; i++)
			{
				IClear(items[i]).clear();
				StoryItem(items[i]).removeEventListener(StoryItem.STORY_ITEM_CLICKED, onItemClicked);
			}
		}

		public function get selectedStory():StoryDef
		{
			return _selectedStory;
		}

		override public function get height():Number {
			return 115;
		}

		override public function get width():Number {
			return 116 * 5;
		}
	}
}

import com.gskinner.geom.ColorMatrix;
import com.somewater.control.IClear;
import com.somewater.display.HintedSprite;
import com.somewater.display.Photo;
import com.somewater.rabbit.storage.Lib;
import com.somewater.rabbit.storage.StoryDef;
import com.somewater.storage.Lang;
import com.somewater.text.EmbededTextField;

import flash.display.DisplayObject;
import flash.display.MovieClip;

import flash.display.Shape;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;

class StoryItem extends HintedSprite implements IClear
{
	public static const WIDTH:int = 100;

	public static const STORY_ITEM_CLICKED:String = 'storyItemCLicked';

	private var _enabled:Boolean = true;
	private var topField:EmbededTextField;
	private var nameField:EmbededTextField;
	public var story:StoryDef;
	private var _selected:Boolean = false;

	private var imageHolder:Photo;
	private var lock:DisplayObject;
	private var imageBorder:Shape;
	private var arrow:DisplayObject;

	private var colormatrixFilter:ColorMatrix = new ColorMatrix([]);

	public function StoryItem(story:StoryDef)
	{
		this.story = story;

		topField = new EmbededTextField(null, 0x6F771A, 12, false, false, false, false, 'center');
		topField.width = this.width;
		topField.mouseEnabled = false;
		addChild(topField);
		topField.htmlText = Lang.t('VEGETABLE_GARDEN', {number: (story.number + 1)});


		var image:MovieClip = Lib.createMC('interface.StoryImages');
		image.gotoAndStop(story.number + 1);
		imageHolder = new Photo(null, 0, 300 ,300);
		imageHolder.animatedShowing = false;
		imageHolder.source = image;
		imageHolder.y = 25;
		addChild(imageHolder);

		var imageMask:Shape = new Shape();
		imageMask.graphics.beginFill(0xFF0000);
		imageMask.graphics.drawRoundRectComplex(0, 25, WIDTH, this.height - 25, 10,10,10,10);
		addChild(imageMask);
		imageHolder.mask = imageMask;

		imageBorder = new Shape();
		addChild(imageBorder);

		nameField = new EmbededTextField(null, 0xFFFFFF, 12, false, true, false, false, 'center');
		nameField.text = story.name.toUpperCase();
		nameField.x = 0;
		nameField.width = WIDTH;
		nameField.y = 25 + (WIDTH - 25 - nameField.textHeight) * 0.5;
		addChild(nameField);
		nameField.mouseEnabled = false;

		lock = Lib.createMC('interface.Lock');
		lock.scaleX = lock.scaleY = 0.7;
		lock.x = WIDTH - lock.width - 5;
		lock.y = 25 + 5;
		addChild(lock);

		arrow = Lib.createMC('interface.LiteFatArrow');
		arrow.x = WIDTH * 0.5;
		arrow.y = 2;
		addChild(arrow);

		addEventListener(MouseEvent.CLICK, onClick);
		_selected = true;
		this.selected = false;

		this.hint = story.description;

		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onUp);
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(MouseEvent.MOUSE_UP, onOver);
	}

	private function onClick(event:MouseEvent):void {
		if(_enabled)
			dispatchEvent(new Event(STORY_ITEM_CLICKED))
	}

	public function set enabled(value:Boolean):void
	{
		_enabled = value;
		refresh();

	}

	public function set selected(value:Boolean):void
	{
		if(_selected != value)
		{
			_selected = value;
			refresh();
		}
	}

	private function refresh():void
	{
		this.buttonMode = this.useHandCursor = _enabled;
		topField.color = _selected ? 0xFF8A1B : 0x6F771A;
		nameField.color = _enabled ? 0xFFFFFF : 0xAFBF29;
		lock.visible = !_enabled;
		arrow.visible = _selected;

		imageBorder.graphics.clear();
		if(!_enabled)
			imageBorder.graphics.beginFill(0x677D0B, 0.6);
		imageBorder.graphics.lineStyle(_selected && _enabled ? 4 : 2, _selected && _enabled ? 0xFF8A1B : 0x96B80C);
		imageBorder.graphics.drawRoundRectComplex(0, 25, WIDTH, this.height - 25, 10, 10, 10, 10);

		onUp(null);
	}

	public function clear():void {
		removeEventListener(MouseEvent.CLICK, onClick)
		imageHolder.clear();
		story = null;
		this.hint = null;

		removeEventListener(MouseEvent.ROLL_OVER, onOver);
		removeEventListener(MouseEvent.ROLL_OUT, onUp);
		removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
		removeEventListener(MouseEvent.MOUSE_UP, onOver);
	}

	private function onUp(event:MouseEvent):void {
		if(_enabled)
			imageHolder.filters = [];
	}

	private function onDown(event:MouseEvent):void {
		if(_enabled)
		{
			colormatrixFilter = new ColorMatrix([]);
			colormatrixFilter.adjustBrightness(-30);
			colormatrixFilter.adjustSaturation(-30);
			imageHolder.filters = [new ColorMatrixFilter(colormatrixFilter.toArray())];
		}
	}

	private function onOver(event:MouseEvent):void {
		if(_enabled)
		{
			colormatrixFilter = new ColorMatrix([]);
			colormatrixFilter.adjustBrightness(20);
			colormatrixFilter.adjustSaturation(5);
			imageHolder.filters = [new ColorMatrixFilter(colormatrixFilter.toArray())];
		}
	}

	override public function get height():Number {
		return 100;
	}

	override public function get width():Number {
		return WIDTH;
	}
}
