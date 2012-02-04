package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.application.buttons.StoriesSwitcher;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.StoryDef;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;

	public class LevelsPage extends PageBase
	{
		private const MAX_LEVEL_ICONS:int = 20;
		private const HIDE_LOGO_ICON:int = 14;
		
		private var friendBar:FriendBar;
		private var levelIcons:Array = [];
		private var leftButton:DisplayObject;
		private var globalScoreCarrot:DisplayObject;
		private var globalScoreCounterTF:EmbededTextField;
		private var globalScoreHolder:Sprite;

		private var storiesSwitcher:StoriesSwitcher;
		private var iconsHolder:Sprite;
		
		public function LevelsPage()
		{
			super();
			
			if(Config.loader.hasFriendsApi)
			{
				friendBar = new FriendBar();
				friendBar.x = 35;
				friendBar.y = Config.HEIGHT -  FriendBar.HEIGHT - 40;
				addChild(friendBar);
			}

			iconsHolder = new Sprite();
			iconsHolder.x = (Config.WIDTH - (6 * 116)) * 0.5 + 70;
			iconsHolder.y = 20;
			addChild(iconsHolder);

			globalScoreHolder = new Sprite();
			globalScoreHolder.x = Config.WIDTH > 800 ? 740 : Config.WIDTH - 100 - 10;
			globalScoreHolder.y = Config.WIDTH > 800 ? 30 : (friendBar ? friendBar.y + (FriendBar.HEIGHT - 80) * 0.5 : Config.HEIGHT - 100);
			addChild(globalScoreHolder)

			globalScoreCarrot = Lib.createMC("interface.Carrot");
			globalScoreCarrot.x = 0;
			globalScoreCarrot.y = 0;
			globalScoreHolder.addChild(globalScoreCarrot);
			
			globalScoreCounterTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true, false, false, false, "center");
			globalScoreCounterTF.width = 100;
			globalScoreCounterTF.x = globalScoreCarrot.x + globalScoreCarrot.width * 0.5 - 50 - 3;
			globalScoreCounterTF.y = globalScoreCarrot.y + globalScoreCarrot.height + 5;
			globalScoreHolder.addChild(globalScoreCounterTF);

			var sumScore:int = 0;
			var maxScores:int = 0;
			for each(var levelInst:LevelInstanceDef in UserProfile.instance.levelInstances)
			{
				sumScore += levelInst.carrotHarvested;
				maxScores += XmlController.instance.calculateCarrots(levelInst.levelDef);
			}
			globalScoreCounterTF.text = intToFourChar(sumScore) + " / " + intToFourChar(maxScores);
			
			Hint.bind(globalScoreCarrot, Lang.t("GLOBAL_SCORE_COUNTER_HINT"));
			Hint.bind(globalScoreCounterTF, Lang.t("GLOBAL_SCORE_COUNTER_HINT"));

			if(Config.WIDTH < globalScoreCounterTF.x + globalScoreCounterTF.width)
			{
				globalScoreCounterTF.visible = false;
				globalScoreCarrot.visible = false;
			}

			storiesSwitcher = new StoriesSwitcher(UserProfile.instance);
			storiesSwitcher.addEventListener(StoriesSwitcher.ON_STORY_CHANGED, onStoryChanged);
			addChild(storiesSwitcher);

			// HARDCODE START
			storiesSwitcher.visible = (Config.memory['testers'] && (Config.memory['testers'] as Array).indexOf(Config.loader.getUser().id) != -1);
			// HARDCODE END
			
			Config.stat(Stat.LEVELS_PAGE_OPENED);

			leftButton = Lib.createMC("interface.LeftButton");

			onStoryChanged();

			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);
		}

		private function onStoryChanged(e:Event = null):void {
			var icon:LevelIcon;
			var levels:Array = Config.application.levels;
			var story:StoryDef = storiesSwitcher.selectedStory;

			if(logo.visible)
				logo.visible = globalScoreHolder.y < Config.WIDTH * 0.5 &&(friendBar == null || (friendBar.x + FriendBar.WIDTH + 10 < logo.x));
			levelIcons = [];
			while(iconsHolder.numChildren)
			{
				icon = iconsHolder.removeChildAt(0) as LevelIcon;
				icon.clear();
				icon.removeEventListener(MouseEvent.CLICK, onLevelClick);
			}

			// TODO: START
			if(story.number == 1)
			{
				var buf:Array = levels.slice();
				levels = [];
				while(buf.length)
					levels.push(buf.splice(int(Math.random() * buf.length), 1)[0])
			}
			// TODO: END

			var i:int = 0;
			for each(var level:LevelDef in levels)
			{
				if(story.start_level > level.number || story.end_level < level.number) continue;
				if(i >= MAX_LEVEL_ICONS) break;

				icon = new LevelIcon();
				icon.data = level;
				icon.addEventListener(MouseEvent.CLICK, onLevelClick);
				icon.x = (i % 5) * 116;
				icon.y = int(i / 5) * 90;
				if((i % 5) > 2 && icon.y + icon.height + 10 > logo.y) logo.visible = false;
				levelIcons.push(icon);
				iconsHolder.addChild(icon);
				i++;
			}

			if(friendBar == null || 40 + (Math.ceil(levelIcons.length / 5)) * 90 + 50 < friendBar.y)
			{
				leftButton.x = iconsHolder.x;
				leftButton.y = 40 + (Math.ceil(levelIcons.length / 5)) * 90;
			}
			else
			{
				leftButton.x = iconsHolder.x - leftButton.width - 10;
				leftButton.y = 20;
			}
		}
		
		override public function clear():void
		{
			super.clear();
			if(friendBar)
				friendBar.clear();
			for(var i:int = 0;i<levelIcons.length;i++)
			{
				LevelIcon(levelIcons[i]).clear();
				LevelIcon(levelIcons[i]).removeEventListener(MouseEvent.CLICK, onLevelClick);
			}
			leftButton.removeEventListener(MouseEvent.CLICK, onLeftButtonClick);
			
			Hint.removeHint(leftButton);
			Hint.removeHint(globalScoreCarrot);
			Hint.removeHint(globalScoreCounterTF);

			storiesSwitcher.clear();
			storiesSwitcher.removeEventListener(StoriesSwitcher.ON_STORY_CHANGED, onStoryChanged);
		}
		
		private function onLevelClick(e:Event):void
		{
			var level:LevelDef = (e.currentTarget as LevelIcon).data;
			if(UserProfile.instance.canPlayWithLevel(level))
				Config.application.startGame(level);
		}
		
		private function onLeftButtonClick(e:Event):void
		{
			Config.application.play(Sounds.ALPHA_BUTTON_CLICK, SoundTrack.INTERFACE, true);
			Config.application.startPage("main_menu");
		}

		private function intToFourChar(value:int):String
		{
			var result:String = value.toString();
			while(result.length < 4)
				result = '0' + result;
			return result;
		}

		// для тьюториала
		public function get backButton():DisplayObject
		{
			return leftButton;
		}
	}
}