package com.somewater.rabbit.application {
	import com.somewater.rabbit.IUserLevel;
	import com.somewater.rabbit.application.shop.ICustomizable;
	import com.somewater.rabbit.application.shop.ShopModule;
	import com.somewater.rabbit.application.shop.ShopWindow;
	import com.somewater.rabbit.events.CustomizeEvent;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.CustomizeDef;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.IGameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardLevelDef;

	import flash.display.DisplayObjectContainer;

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;

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
												customizeHole(user, event.clip);
												break;
				case CustomizeEvent.TYPE_HOLE_CLICK:
												onHoleClicked(user,  event);
												break;
				default:
						throw new Error('Undefined CustomEvent type ' + event.customObjectType);
			}

			event.applyed = true;
		}

		private function onHoleClicked(user:GameUser, event:CustomizeEvent):void {
			if(user.itsMe())
			{
				Config.game.pause();
				new ShopWindow(ShopModule.CUSTOMIZE_DEFAULT_TAB).closeFunc = function(...args):Boolean{
					Config.game.start();
					customizeHole(user, event.clip);
					return true;
				};
			}
		}

		public function customizeHole(user:ICustomizable, holeClip:MovieClip):void {
			// добавить крышу, которую заслуживает этот юзер
			createByCustomize(CustomizeDef.TYPE_ROOF);
			createByCustomize(CustomizeDef.TYPE_DOOR);
			createByCustomize(CustomizeDef.TYPE_MAT);
			var titleClip:DisplayObjectContainer = createByCustomize(CustomizeDef.TYPE_TITLE);

			var titleClipTextField:TextField = titleClip.getChildByName('textField') as TextField;
			replaceTitleTextField(titleClipTextField);

			function getHolder(name:String):DisplayObjectContainer
			{
				return holeClip.getChildByName(name) as DisplayObjectContainer;
			}

			function createByCustomize(type:String):DisplayObjectContainer
			{
				var custom:CustomizeDef = user.getCustomize(type);
				if(custom == null) custom =	CustomizeDef.getDefault(type);
				var customClip:DisplayObjectContainer = Lib.createMC(custom.slug)
				var holder:DisplayObjectContainer = getHolder(type);
				while(holder.numChildren)
					holder.removeChildAt(0);
				holder.addChild(customClip);
				return customClip;
			}
		}

		public static function replaceTitleTextField(titleClipTextField:TextField):void {
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
			titleClipTextField.parent.addChildAt(holeTitle, titleClipTextField.parent.getChildIndex(titleClipTextField));
			titleClipTextField.parent.removeChild(titleClipTextField);
		}
	}
}
