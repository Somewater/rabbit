package com.somewater.rabbit.application.buttons {
	import com.somewater.control.IClear;
	import com.somewater.control.IClear;
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

		public function StoriesSwitcher(user:GameUser) {

			var stories:Array = StoryDef.all();

			// ищем маскимальную историю, открытую для пльзователя
			for each(var s:StoryDef in stories)
			{
				if(s.start_level <= user.levelNumber)// история доступна
				{
					if(_selectedStory == null || _selectedStory.number < s.number)
						_selectedStory = s;
				}
			}

			for (var i:int = 0; i < stories.length; i++)
			{
				var story:StoryDef = stories[i];
				var item:StoryItem = new StoryItem(story);
				items.push(item);
				item.x = 0;
				item.y = i * 50;
				addChild(item);

				item.enabled = story.start_level <= user.levelNumber;
				item.selected = story.number == _selectedStory.number;
				item.addEventListener(StoryItem.STORY_ITEM_CLICKED, onItemClicked)
			}
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
	}
}

import com.somewater.control.IClear;
import com.somewater.rabbit.storage.StoryDef;
import com.somewater.text.EmbededTextField;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

class StoryItem extends Sprite implements IClear
{
	public static const STORY_ITEM_CLICKED:String = 'storyItemCLicked';

	private var _enabled:Boolean = true;
	private var textField:EmbededTextField;
	public var story:StoryDef;
	private var _selected:Boolean = false;

	public function StoryItem(story:StoryDef)
	{
		this.story = story;

		textField = new EmbededTextField(null, 0xFFFFFF, 12, false, true);
		textField.width = 100;
		textField.mouseEnabled = false;
		addChild(textField);

		graphics.beginFill(0);
		graphics.drawRect(0,0,100,40);

		textField.text = story.name;

		addEventListener(MouseEvent.CLICK, onClick);
		_selected = true;
		this.selected = false;
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
		textField.color = _enabled ? (_selected ? 0xFF8877 : 0xFFFFFF) : 0x333333;
	}

	public function clear():void {
		removeEventListener(MouseEvent.CLICK, onClick)
		story = null;
	}
}
