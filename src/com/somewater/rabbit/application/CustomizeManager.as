package com.somewater.rabbit.application {
	import com.somewater.rabbit.IUserLevel;
	import com.somewater.rabbit.events.CustomizeEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.IGameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardLevelDef;

	import flash.display.DisplayObjectContainer;

	import flash.display.DisplayObjectContainer;

	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * Отвечает за кастомизацию будки согласно покупок гейм-юзера
	 */
	public class CustomizeManager {

		private static var _instance:CustomizeManager;

		public static function get instance():CustomizeManager
		{
			if(_instance == null)
				_instance = new CustomizeManager();
			return _instance;
		}

		public function CustomizeManager() {
		}

		/**
		 * Найти (или дождаться) рендер будки и выставить его визуальное представление согласно покупок пользователя
		 * @param user
		 * @param level
		 */
		public function customize():void
		{
			// поставить на обработку кастомизации норы
			Config.application.addEventListener(CustomizeEvent.CUSTOMIZE_EVENT, onHoleCreated);
		}

		private function onHoleCreated(event:CustomizeEvent):void {
			if(!(Config.game.level is IUserLevel)) return;

			var user:GameUser = IUserLevel(Config.game.level).gameUser as GameUser;

			switch(event.customObjectType)
			{
				case CustomizeEvent.TYPE_HOLE:
												customizeHole(user, event);
												break;
				default:
						throw new Error('Undefined CustomEvent type ' + event.customObjectType);
			}

			event.applyed = true;
		}

		private function customizeHole(user:GameUser, event:CustomizeEvent):void {
			// добавить крышу, которую заслуживает этот юзер
			createByCustomize(CustomizeDef.TYPE_ROOF);
			createByCustomize(CustomizeDef.TYPE_DOOR);
			var titleClip:DisplayObjectContainer = createByCustomize(CustomizeDef.TYPE_TITLE);

			var titleClipTextField:TextField = titleClip.getChildByName('textField') as TextField;

			var holeTitle:TextField = Config.application.createTextField(null,null,12,false,false,false,false, titleClipTextField.defaultTextFormat.align);
			holeTitle.width = titleClipTextField.width;
			holeTitle.height = titleClipTextField.height;
			holeTitle.defaultTextFormat = titleClipTextField.defaultTextFormat;
			holeTitle.embedFonts = true;
			holeTitle.text = Config.game.level is IUserLevel ? IUserLevel(Config.game.level).gameUser.socialUser.firstName
					: (Config.loader.getUser().firstName && Config.loader.getUser().firstName.length ? Config.loader.getUser().firstName :
									(Config.loader.getUser().lastName ? Config.loader.getUser().lastName : ''));
			var tf:TextFormat = titleClipTextField.getTextFormat();
			holeTitle.setTextFormat(tf);
			holeTitle.selectable = false;
			holeTitle.x = titleClipTextField.x;
			holeTitle.y = titleClipTextField.y;
			titleClip.addChildAt(holeTitle, titleClip.getChildIndex(titleClipTextField));
			titleClipTextField.parent.removeChild(titleClipTextField);

			function getHolder(name:String):DisplayObjectContainer
			{
				return event.clip.getChildByName(name) as DisplayObjectContainer;
			}

			function createByCustomize(type:String):DisplayObjectContainer
			{
				var custom:CustomizeDef = user.getCustomize(type);
				if(custom == null) custom =	CustomizeDef.getDefault(type);
				var customClip:DisplayObjectContainer = Lib.createMC(custom.slug)
				getHolder(type).addChild(customClip);
				return customClip;
			}
		}
	}
}
