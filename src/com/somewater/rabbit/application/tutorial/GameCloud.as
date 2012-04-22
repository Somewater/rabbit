package com.somewater.rabbit.application.tutorial {
	import com.somewater.controller.PopUpManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Point;

	public class GameCloud extends Sprite implements ITutorialMessage{

		private var cloud:TutorialMessageCloud;
		private var tmpPoint:Point = new Point();
		private var onAcceptArgiment:Function;

		public function GameCloud(msg:String, onAccept:Function = null, image:* = null) {
			onAcceptArgiment = onAccept;
			cloud = new TutorialMessageCloud(msg, onAccept != null ? onAcceptProxy : null, image);
			addChild(cloud);

			Config.loader.tutorial.addChild(this);
		}

		public function clear():void {
			cloud.clear();
			var idx:int = TutorialManager.instance.messages.indexOf(this);
			if(idx != -1)
				TutorialManager.instance.messages.splice(idx, 1);
			if(parent)
				parent.removeChild(this);
			idx = TutorialManager.instance.tickedClouds.indexOf(this);
			if(idx != -1)
				TutorialManager.instance.tickedClouds.splice(idx, 1);
		}

		private function onAcceptProxy():void
		{
			if(onAcceptArgiment != null)
				onAcceptArgiment();
			clear();
		}

		public function tick():void {
			// позиционируемся
			var personageDO:DisplayObject = TutorialManager.modile.heroDisplayObject;
			if(personageDO == null)
				return;
			tmpPoint.x = 0;
			tmpPoint.y = 0;
			tmpPoint = personageDO.localToGlobal(tmpPoint);
			tmpPoint = this.parent.globalToLocal(tmpPoint);

			this.x = tmpPoint.x;
			this.y = tmpPoint.y;

			this.toLeft =  tmpPoint.x > Config.WIDTH * 0.5;

			var canBottom:Boolean = tmpPoint.y + cloud.heightIfBottom < Config.HEIGHT;
			var needBottom:Boolean = PopUpManager.activeWindow != null || (tmpPoint.y - cloud.heightIfBottom - 100) < 0;
			this.top = !(canBottom && needBottom);
		}

		public function set toLeft(value:Boolean):void {
			cloud.toLeft = value;
		}

		public function set top(value:Boolean):void {
			cloud.top = value;
		}
	}
}
