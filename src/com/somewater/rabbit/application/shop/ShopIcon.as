package com.somewater.rabbit.application.shop {
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.display.HintedSprite;
	import com.somewater.display.Photo;
	import com.somewater.display.SpriteAligner;
	import com.somewater.rabbit.application.CustomizeManager;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.ItemDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;

	import flash.display.MovieClip;

	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class ShopIcon extends HintedSprite implements IClear{

		public var itemDef:ItemDef;

		private var photo:Photo;
		private var core:Sprite;
		private var ground:DisplayObject;
		private var costTF:EmbededTextField;

		private var _selected:Boolean = false;

		public function ShopIcon(itemDef:ItemDef) {
			this.itemDef = itemDef;

			core = Lib.createMC('interface.ShopIcon');
			addChild(core);

			photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MIN);
			photo.maxScale = 1;
			photo.photoMask = core.getChildByName('photoMask');
			costTF = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 20, true);
			costTF.x = 60;
			costTF.y = 98;
			addChild(costTF);
			ground = core.getChildByName('ground');
			ground.alpha = 0

			useHandCursor = buttonMode = true;

			addEventListener(MouseEvent.ROLL_OVER, onOver);
			addEventListener(MouseEvent.MOUSE_OUT, onOut);
			addEventListener(MouseEvent.CLICK, onClick);

			// установка неизменных хар-к айтема
			var mc:Sprite = Lib.createMC(itemDef.shop_slug && itemDef.shop_slug.length > 0 ? itemDef.shop_slug : itemDef.slug);
			if(mc is MovieClip)
				MovieClipHelper.stopAll(mc as MovieClip);
			if(mc.getChildByName('textField') && mc.getChildByName('textField') is TextField)
				CustomizeManager.replaceTitleTextField(mc.getChildByName('textField') as TextField);
			mc = new SpriteAligner(mc)
			photo.source = mc;
			this.hint = itemDef.getTitle();

			mouseChildren = false;

			refresh();
		}

		private function onOut(event:MouseEvent):void {
			TweenMax.killTweensOf(ground);
			ground.alpha = 0
		}

		private function onOver(event:MouseEvent):void {
			TweenMax.killTweensOf(ground);
			ground.alpha = 1
		}

		public function clear():void {
			TweenMax.killTweensOf(ground);
			itemDef = null;
			hint = null;
			photo.clear();
			removeEventListener(MouseEvent.ROLL_OVER, onOver);
			removeEventListener(MouseEvent.MOUSE_OUT, onOut)
			removeEventListener(MouseEvent.CLICK, onClick);
		}

		private function onClick(event:MouseEvent):void {
			TweenMax.to(ground, 0.2, {reversed:true, alpha:0.3})
		}

		public function set selected(value:Boolean):void
		{
			if(_selected != value)
			{
				_selected = value;
				refresh();
			}
		}

		private function refresh():void {
			core.getChildByName('selection').visible = _selected;
			costTF.text = itemDef.cost.toString();
		}
	}
}
