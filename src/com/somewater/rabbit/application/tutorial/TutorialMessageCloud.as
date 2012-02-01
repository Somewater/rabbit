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

	/**
	 * Облачко с текстом (возможно с рисунком, возможно с кнопкой "Далее")
	 * Центрируется относительно центра кролика (его центральной точки на животе)
	 */
	public class TutorialMessageCloud extends Sprite implements ITutorialMessage{

		private var message:String;
		private var onAccept:Function;
		private var image:*;
		private var _toLeft:Boolean;

		private var cloud:DisplayObject;
		private var miniCloud:DisplayObject;
		private var contentHolder:Sprite;
		private var textField:EmbededTextField;
		private var photo:Photo;
		private var photoBorder:DisplayObjectContainer;
		private var buttonNext:OrangeButton;

		public function TutorialMessageCloud(message:String, onAccept:Function = null, image:* = null, toLeft:Boolean = false) {
			this.message = message;
			this.onAccept = onAccept;
			this.image = image;
			this._toLeft = toLeft;

			recreate();
		}

		private function recreate():void {
			miniCloud = Lib.createMC('tutorial.TutorialMiniCloud');
			miniCloud.y = -65;
			addChild(miniCloud);

			cloud = Lib.createMC('tutorial.TutorialCloud');
			addChild(cloud);

			contentHolder = new Sprite();
			addChild(contentHolder);

			textField = new EmbededTextField(null, null, 12, false, true);
			textField.width = 150;
			textField.x = 10;
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
				buttonNext.addEventListener(MouseEvent.CLICK, onAcceptClicked);
				buttonNext.x = ((photoBorder ? photoBorder.x + photoBorder.width : textField.x + textField.width) - buttonNext.width) * 0.5;
				buttonNext.y = (photoBorder ? Math.max(photoBorder.y + photoBorder.height, textField.y + textField.height) : textField.y + textField.height) + 10;
				contentHolder.addChild(buttonNext);

				buttonNext.height = 20;
			}

			// resize
			cloud.width = (photoBorder ? photoBorder.x + photoBorder.width - textField.x : textField.x + textField.width) + 30;
			cloud.height = buttonNext ? buttonNext.y + buttonNext.height + 25 : (photoBorder ? Math.max(photoBorder.y + photoBorder.height, textField.y + textField.height) : textField.height) + 25;
			cloud.y = -95 - cloud.height;

			_toLeft = !_toLeft;
			toLeft = !_toLeft;

			miniCloud.alpha = 0;
			cloud.alpha = 0;
			contentHolder.alpha = 0;
			TweenMax.to(miniCloud, 0.3, {alpha: 1, onComplete: onMiniCloudComplete, delay: 0.3});
		}

		private function onMiniCloudComplete():void {
			TweenMax.to(cloud, 0.3, {alpha: 1, onComplete: onCloudComplete});
		}

		private function onCloudComplete():void {
			TweenMax.to(contentHolder, 0.3, {alpha: 1});
		}

		private function onAcceptClicked(e:Event = null):void
		{
			onAccept();
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
				buttonNext.removeEventListener(MouseEvent.CLICK, onAcceptClicked);
			}
		}

		public function set toLeft(value:Boolean):void {
			if(value != _toLeft)
			{
				_toLeft = value;

				miniCloud.x = _toLeft ? -60 : 60;
				cloud.x = _toLeft ? -80 - cloud.width : 80;
				contentHolder.x = cloud.x + 10;
				contentHolder.y = cloud.y + 10;
			}
		}
	}
}
