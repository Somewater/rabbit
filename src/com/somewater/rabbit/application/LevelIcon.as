package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.LevelInstanceDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.UserProfile;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class LevelIcon extends HintedSprite implements IClear
	{
		private var ground:DisplayObject;
		private var carrotsThree:Sprite;
		private var lockedGround:DisplayObject;
		private var levelTF:EmbededTextField;
		private var scoreTF:TextField;
		private var _data:LevelDef
		
		public function LevelIcon()
		{
			ground = Lib.createMC("interface.LevelIcon");
			addChild(ground);

			carrotsThree = Lib.createMC("interface.CarrotsThree");
			carrotsThree.x = 17;
			carrotsThree.y = 51.5;
			addChild(carrotsThree);
			
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
			var levelInstance:LevelInstanceDef = locked ? null : UserProfile.instance.getLevelInsanceByNumber(_data.number);
			lockedGround.visible = locked;
			levelTF.visible = scoreTF.visible = ground.visible = !locked;
			
			if(levelInstance != null)
			{
				levelTF.text = _data.number.toString();
				scoreTF.text = levelInstance.carrotHarvested.toString();
				hint = _data.name;
				stars = levelInstance.stars;
			}
			else if(!locked)
			{
				levelTF.text = _data.number.toString();
				scoreTF.text = "";//TODO запросить, сколько очков у юзера по тому или иному уровню
				hint = _data.name;
				stars = 0;
			}
			else
			{
				hint = Lang.t("ERROR_LOCKED_HINT");
				stars = 0;
			}
		}

		private function set stars(value:int):void
		{
			carrotsThree.getChildByName('c1').alpha = value > 0 ? 1 : 0.1;
			carrotsThree.getChildByName('c2').alpha = value > 1 ? 1 : 0.1;
			carrotsThree.getChildByName('c3').alpha = value > 2 ? 1 : 0.1;
		}
	}
}