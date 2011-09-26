package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class LevelIcon extends HintedSprite implements IClear
	{
		private var ground:DisplayObject;
		private var lockedGround:DisplayObject;
		private var levelTF:EmbededTextField;
		private var scoreTF:TextField;
		private var _data:LevelDef
		
		public function LevelIcon()
		{
			ground = Lib.createMC("interface.LevelIcon");
			addChild(ground);
			
			levelTF = new EmbededTextField(null, 0xFFFFFF, 18, true, false, false, false, "center");
			levelTF.x = 30;
			levelTF.y = 17;
			levelTF.width = 33;
			addChild(levelTF);
			
			scoreTF = new EmbededTextField(null, 0x124D18, 14, true);
			scoreTF.x = 54;
			scoreTF.y = 54;
			scoreTF.width = 33;
			addChild(scoreTF);
			
			lockedGround = Lib.createMC("interface.LockedLevelIcon");
			addChild(lockedGround);
		}
		
		public function clear():void
		{
			_data = null;
			hint = null;
		}
		
		public function set data(value:LevelDef):void
		{
			_data = value;
			refresh();
		}
		
		public function get data():LevelDef
		{
			return _data;
		}
		
		private function refresh():void
		{
			var locked:Boolean = !UserProfile.instance.canPlayWithLevel(_data);
			lockedGround.visible = locked;
			levelTF.visible = scoreTF.visible = ground.visible = !locked;
			
			if(!locked)
			{
				levelTF.text = _data.number;
				scoreTF.text = "999";//TODO запросить, сколько очков у юзера по тому или иному уровню
				hint = _data.desc;
			}
			else
			{
				hint = Lang.t("ERROR_LOCKED_HINT");
			}
		}
	}
}