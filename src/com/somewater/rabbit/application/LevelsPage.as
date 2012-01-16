package com.somewater.rabbit.application
{
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.SoundTrack;
	import com.somewater.rabbit.Sounds;
	import com.somewater.rabbit.Stat;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.rabbit.xml.XmlController;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.text.Hint;
	
	import flash.display.DisplayObject;
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
			
			var levels:Array = Config.application.levels;
			for (var i:int = 0;i<levels.length;i++)
			{
				var level:LevelDef = levels[i];
				
				if(i >= MAX_LEVEL_ICONS) continue;
				
				var icon:LevelIcon = new LevelIcon();
				icon.data = level;
				icon.addEventListener(MouseEvent.CLICK, onLevelClick);
				icon.x = (i % 5) * 116 + 120;
				icon.y = int(i / 5) * 90 + 20;
				if((i % 5) > 2 && icon.y + icon.height + 10 > logo.y) logo.visible = false;
				levelIcons.push(icon);
				addChild(icon);
			}
			
			leftButton = Lib.createMC("interface.LeftButton");
			if(friendBar == null || 40 + (Math.ceil(levelIcons.length / 5)) * 90 + 50 < friendBar.y)
			{
				leftButton.x = 120;
				leftButton.y = 40 + (Math.ceil(levelIcons.length / 5)) * 90;
			}
			else
			{
				leftButton.x = 100 - leftButton.width;
				leftButton.y = 20;
			}
			leftButton.addEventListener(MouseEvent.CLICK, onLeftButtonClick);
			Hint.bind(leftButton, Lang.t("BACK_TO_MAIN_MENU"));
			addChild(leftButton);
			
			globalScoreCarrot = Lib.createMC("interface.Carrot");
			globalScoreCarrot.x = 740;
			globalScoreCarrot.y = 30;
			addChild(globalScoreCarrot);
			
			globalScoreCounterTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true, false, false, false, "center");
			globalScoreCounterTF.width = 100;
			globalScoreCounterTF.x = globalScoreCarrot.x + globalScoreCarrot.width * 0.5 - 50 - 3;
			globalScoreCounterTF.y = globalScoreCarrot.y + globalScoreCarrot.height + 5;
			addChild(globalScoreCounterTF);

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
			
			Config.stat(Stat.LEVELS_PAGE_OPENED);
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
	}
}