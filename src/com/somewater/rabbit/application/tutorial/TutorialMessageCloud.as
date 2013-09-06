package com.somewater.rabbit.application.tutorial {
	import com.greensock.TweenMax;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.application.OrangeButton;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;

	/**
	 * Облачко с текстом (возможно с рисунком, возможно с кнопкой "Далее")
	 * Центрируется относительно центра кролика (его центральной точки на животе)
	 */
	public class TutorialMessageCloud extends Sprite implements ITutorialMessage{

		private const PADDING:int = 10;

		private var message:String;
		private var onAccept:Function;
		private var image:*;
		private var _toLeft:Boolean;
		private var _top:Boolean = true;

		private var cloud:DisplayObject;
		private var miniCloud:DisplayObject;
		private var microCloud:DisplayObject;
		public var contentHolder:Sprite;
		private var textField:EmbededTextField;
		private var photo:Photo;
		private var photoBorder:DisplayObjectContainer;
		public var buttonNext:OrangeButton;

		public function TutorialMessageCloud(message:String, onAccept:Function = null, image:* = null, toLeft:Boolean = false) {
			this.message = message;
			this.onAccept = onAccept;
			this.image = image;
			this._toLeft = toLeft;

			recreate();
		}

		private function recreate():void {

			while(numChildren)
				removeChildAt(0);

			microCloud = Lib.createMC('tutorial.TutorialMiniCloud');
			microCloud.scaleX = microCloud.scaleY = 0.75;
			addChild(microCloud);

			miniCloud = Lib.createMC('tutorial.TutorialMiniCloud');
			addChild(miniCloud);

			cloud = Lib.createMC('tutorial.TutorialCloud');
			addChild(cloud);

			contentHolder = new Sprite();
			addChild(contentHolder);

			textField = new EmbededTextField(null, 0x565C12, 12, false, true, false, false, 'center');
			textField.autoSize = TextFieldAutoSize.CENTER;
			textField.width = 150;
			textField.x = PADDING;
			textField.text = message;
			contentHolder.addChild(textField);

			if(image)
			{
				photoBorder = Lib.createMC("interface.LevelSwitchImage");
				photoBorder.x = textField.x + textField.width + 5;
				contentHolder.addChild(photoBorder);

				photo = new Photo(null, Photo.ORIENTED_CENTER, 88, 67, 88/2, 67/2);
				photo.photoMask = photoBorder.getChildByName('photoMask');
				photo.source = PostingFactory.getImage(image);

				photoBorder.scaleX = photoBorder.scaleY = 0.6;
			}

			if(onAccept != null)
			{
				buttonNext = new OrangeButton()
				buttonNext.label = Lang.t('TUTORIAL_NEXT_BTN_LABEL');
				contentHolder.useHandCursor = contentHolder.buttonMode = true;
				addEventListener(MouseEvent.MOUSE_DOWN, onAcceptClicked);
				buttonNext.x = ((photoBorder ? photoBorder.x + photoBorder.width : textField.x + textField.width) - buttonNext.width) * 0.5;
				buttonNext.y = (photoBorder ? Math.max(photoBorder.y + photoBorder.height, textField.y + textField.height) : textField.y + textField.height) + 10;
				contentHolder.addChild(buttonNext);

				buttonNext.height = 20;
			}

			// resize
			cloud.width = (photoBorder ? photoBorder.x + photoBorder.width + 15 : textField.x + textField.width) + 10 + PADDING * 2;
			cloud.height = buttonNext ? buttonNext.y + buttonNext.height + 45 : (photoBorder ? Math.max(photoBorder.y + photoBorder.height, textField.y + textField.height) : textField.height) + 25 + PADDING * 2;

			_toLeft = !_toLeft;
			toLeft = !_toLeft;

			microCloud.alpha = 0;
			miniCloud.alpha = 0;
			cloud.alpha = 0;
			contentHolder.alpha = 0;
			TweenMax.to(microCloud, 0.1, {alpha: 1, onComplete: onMicroCloudComplete, delay: 0.1});
		}

		private function onMicroCloudComplete():void {
			TweenMax.to(miniCloud, 0.1, {alpha: 1, onComplete: onMiniCloudComplete, delay: 0.1});
		}

		private function onMiniCloudComplete():void {
			TweenMax.to(cloud, 0.1, {alpha: 1, onComplete: onCloudComplete});
		}

		private function onCloudComplete():void {
			TweenMax.to(contentHolder, 0.1, {alpha: 1});
		}

		private function onAcceptClicked(e:Event = null):void
		{
			onAccept();
			if(e)e.stopImmediatePropagation();
		}

		public function clear():void {
			onAccept = null;
			var idx:int = TutorialManager.instance.messages.indexOf(this);
			if(idx != -1)
				TutorialManager.instance.messages.splice(idx, 1);
			if(photo)
				photo.clear();
			if(buttonNext)
			{
				buttonNext.clear();
				removeEventListener(MouseEvent.MOUSE_DOWN, onAcceptClicked);
			}
		}

		public function set toLeft(value:Boolean):void {
			if(value != _toLeft)
			{
				_toLeft = value;

				refresh();
			}
		}

		public function set top(value:Boolean):void {
			if(value != _top)
			{
				_top = value;
				refresh();
			}
		}

		private function refresh():void {
			microCloud.x = _toLeft ? -45 : 45;
			miniCloud.x = _toLeft ? -65 : 65;
			cloud.x = _toLeft ? -40 - cloud.width : 40;
			contentHolder.x = cloud.x + PADDING;

			if(_top)
			{
				cloud.y = -90 - cloud.height;
				microCloud.y = -50;
				miniCloud.y = -75;
			}
			else
			{
				const BOTTOM_FIX:int = -25;
				cloud.y = 90 + BOTTOM_FIX;
				microCloud.y = 50 + BOTTOM_FIX;
				miniCloud.y = 75 + BOTTOM_FIX;
				//contentHolder.y = 90 + PADDING * 2 + BOTTOM_FIX;
			}

			contentHolder.y = cloud.y + PADDING + 10;
		}

		public function get heightIfBottom():int
		{
			return 90 + contentHolder.height + PADDING;
		}
	}
}
