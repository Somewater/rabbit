package com.somewater.rabbit.application
{
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.somewater.controller.PopUpManager;
	import com.somewater.display.Photo;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.GameUser;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.storage.Lang;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextFieldAutoSize;
	
	public class FriendIcon extends Sprite implements IClear
	{
		private var core:*;
		private var starText:EmbededTextField;
		private var photo:Photo;
		private var scoreText:EmbededTextField;
		private var nameText:EmbededTextField;
		
		/**
		 * 0 invite
		 * 1 normal mode
		 * 2 big mode
		 */
		private var mode:int = -1;
		private var user:GameUser;
		
		public function FriendIcon()
		{
			super();
			
			core = Lib.createMC("interface.FriendIcon");
			addChild(core);
			
			var inviteText:EmbededTextField = new EmbededTextField(null, 0xFFFFFF, 12, true, true, false, false, "center");
			inviteText.width = 70;
			inviteText.y = 51;
			inviteText.text = Lang.t("INVITE_BUTTON_TEXT");
			inviteText.filters = [new DropShadowFilter(2,45,0xA2BA2A,1,0,0)];
			core.invite.addChild(inviteText);
			
			starText = new EmbededTextField(null, 0xFFFFFF, 12, true,false,false,false,"center");
			starText.width = 24;
			starText.x = 0.5;
			starText.y = 4.3;
			core.star.addChild(starText);
			
			photo = new Photo(null, Photo.ORIENTED_CENTER | Photo.SIZE_MAX);
			photo.animatedShowing = false;
			photo.photoMask = core.photoMask;
			
			nameText = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 10, true, true, false, false, "center");
			nameText.setAbstractFormatField("leading",-1);
			nameText.width = 72;
			nameText.x = 1;
			nameText.y = 18;
			nameText.height = 35;
			core.ground_big.addChild(nameText);
			
			scoreText = new EmbededTextField(Config.FONT_SECONDARY, 0x124D18, 14, true);
			scoreText.width = 40;
			scoreText.x = 28;
			scoreText.y = 48;
			core.ground_big.addChild(scoreText);
			
			setMode(0);
			buttonMode = useHandCursor = true;
			
			addEventListener(MouseEvent.CLICK, onClick);
			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		}
		
		public function clear():void
		{
			removeEventListener(MouseEvent.CLICK, onClick);
			removeEventListener(MouseEvent.ROLL_OVER, onRollOver);
			removeEventListener(MouseEvent.ROLL_OUT, onRollOut);
			user = null;
		}
		
		private function onClick(e:MouseEvent):void
		{
			if(mode == 0)
			{
				Config.loader.showInviteWindow();	
			}
			else if(mode == 1 || mode == 2)
			{
				PopUpManager.message("TODO: clicked user " + user.socialUser.name);
			}
		}
		
		private function onRollOver(e:Event):void
		{
			if(mode == 1 || mode == 2)
			{
				setMode(2);
			}
		}
		
		private function onRollOut(e:Event):void
		{
			if(mode == 1 || mode == 2)
			{
				setMode(1);
			}
		}
		
		private function setMode(newMode:int):void
		{
			if(newMode != mode)
			{
				mode = newMode;
				core.invite.visible = core.ground.visible = core.star.visible = core.photoGround.visible = core.ground_big.visible = false;
				
				if(mode == 0)
				{
					core.invite.visible = true;
				}
				else
				{
					core.ground.visible = core.star.visible = core.photoGround.visible = true;
					TweenMax.killTweensOf(core.ground_big);
					TweenMax.killTweensOf(core.ears);
					
					if(mode == 1)
					{
						TweenMax.to(core.ground_big, 0.1, {"autoAlpha":0});
						TweenMax.to(core.ears, 0.1, {"y":-17, "delay":0.15});
					}
					else if(mode == 2)
					{
						TweenMax.to(core.ground_big, 0.1, {"autoAlpha":1, "delay":0.15});
						TweenMax.to(core.ears, 0.1, {"y":-70});
					}
				}
			}
		}
		
		
		public function setUser(user:GameUser):void
		{
			this.user = user;
			if(user)
			{
				photo.source = user.socialUser.photoMedium;
				nameText.text = user.socialUser.name;
				nameText.y = 15 + (45 - nameText.height) * 0.5
				starText.text = user.levelNumber.toString();
				scoreText.text = user.score.toString();
				setMode(1);
			}
			else
			{
				setMode(0);	
			}
		}
	}
}