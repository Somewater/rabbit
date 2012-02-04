package com.somewater.rabbit.application.tutorial {
	import com.greensock.TweenMax;
	import com.somewater.rabbit.application.PageBase;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;

	public class GuiCloud extends Sprite implements ITutorialMessage{

		private var rabbitActor:MovieClip;
		private var shadow:Sprite;
		private var cloud:TutorialMessageCloud;
		private var onAcceptArgiment:Function;

		public function GuiCloud(msg:String, x:int,  y:int, onAccept:Function = null, image:* = null, toLeft:Boolean = false) {
			onAcceptArgiment = onAccept;

			shadow = Lib.createMC('tutorial.TutorialShadow')
			shadow.mouseEnabled = shadow.mouseChildren = false;
			addChild(shadow);

			rabbitActor = Lib.createMC('rabbit.RabbitActor');
			rabbitActor.gotoAndStop(toLeft ? 2 : 1);
			addChild(rabbitActor);

			cloud = new TutorialMessageCloud(msg, onAccept != null ? onAcceptProxy : null, image, toLeft);
			addChild(cloud);

			Config.loader.tutorial.addChild(this);
			this.x = x;
			this.y = y;

			/*if((Config.application as RabbitApplication).currentPage
				&& (Config.application as RabbitApplication).currentPage is PageBase
				&& PageBase((Config.application as RabbitApplication).currentPage).logo)
			{
				TweenMax.to(PageBase((Config.application as RabbitApplication).currentPage).logo, 0.3, {autoAlpha: 0});
			}*/
		}

		private function onAcceptProxy():void
		{
			if(onAcceptArgiment != null)
				onAcceptArgiment();
			clear();
		}

		public function clear():void {
			cloud.clear();
			var idx:int = TutorialManager.instance.messages.indexOf(this);
			if(idx != -1)
				TutorialManager.instance.messages.splice(idx, 1);
			if(parent)
				parent.removeChild(this);
		}

		public function set toLeft(value:Boolean):void {
			cloud.toLeft = value;
			rabbitActor.gotoAndStop(value ? 2 : 1);
		}
	}
}
