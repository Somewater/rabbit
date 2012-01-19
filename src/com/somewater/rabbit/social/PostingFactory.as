package com.somewater.rabbit.social {
	import com.somewater.display.Photo;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.RewardDef;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	import com.somewater.utils.MovieClipHelper;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public class PostingFactory {


		public static function createLevelPosting(levelDef:LevelDef):DisplayObject
		{
			var image:MovieClip = Lib.createMC('images.LevelPosting');
			var tf:EmbededTextField = new EmbededTextField(null,0xFFFFFF,20,true,false,false,false,'center');
			image.star.addChild(tf);
			tf.x = image.star.text_field.x + 1; // KLUDGE
			tf.y = image.star.text_field.y + 4; // KLUDGE
			tf.width = image.star.text_field.width;
			tf.height = image.star.text_field.height;
			tf.text = levelDef.number.toString();
			image.star.text_field.parent.removeChild(image.star.text_field);
			return new HolderWithConstSize(image,100,100);
		}

		public static function createRewardPosting(reward:RewardDef):DisplayObject
		{
			var image:MovieClip = Lib.createMC('images.LevelPosting');
			image.star.visible = false;
			var p:Photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MIN, 90, 90, 50, 50);
			p.animatedShowing = false;
			p.source = getImage(reward.slug);
			image.addChild(p);
			return new HolderWithConstSize(image,100,100);
		}

		public static function createFriendsInvitePosting():DisplayObject
		{
			var image:DisplayObject = Lib.createMC('images.InvitePosting');
			return new HolderWithConstSize(image,100,100);
		}

		public static function getImage(image:String):*
		{
			if(image == null || image.length == 0) return null;
			if(image.substr(0,7) == 'http://')
				return image;
			else if(image.substr(0,2) == 'T_' && Lang.t(image).substr(0,2) != 'T_')
				return getImage( Lang.t(image));
			else if(Lib.hasMC(image))
			{
				var mc:DisplayObject = Lib.createMC(image);
				if(mc is MovieClip)
					 MovieClipHelper.stopAll(mc as MovieClip);
				var wrapper:Sprite = new Sprite()
				wrapper.addChild(mc);
				var bounds:Rectangle = mc.getBounds(mc);
				mc.x = -bounds.x;
				mc.y = -bounds.y;
				return wrapper;
			}
			else
				return null;
		}
	}
}

import flash.display.DisplayObject;
import flash.display.Sprite;

class HolderWithConstSize extends Sprite
{
	private var _width:int;
	private var _height:int;

	public function HolderWithConstSize(image:DisplayObject, width:int, height:int)
	{
		_width = width;
		_height = height;
		addChild(image);
	}


	override public function get width():Number {
		return _width;
	}

	override public function get height():Number {
		return _height;
	}
}


