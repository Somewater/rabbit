package com.somewater.rabbit.application
{
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.windows.PauseMenuWindow;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.text.EmbededTextField;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class GameGUI extends Sprite implements IClear
	{
		private var playPauseButton:SimpleButton;
		private var statPanel:Sprite;
		private var timeTF:EmbededTextField;
		private var carrotTF:EmbededTextField;
		private var minutesArrowShelf:Shape;
		
		public function GameGUI()
		{
			super();
			
			playPauseButton = Lib.createMC("interface.PauseButton");
			playPauseButton.x = 15;
			playPauseButton.y = Config.HEIGHT - playPauseButton.width - 15;
			addChild(playPauseButton);
			playPauseButton.addEventListener(MouseEvent.CLICK, onPlayPauseClick);
			
			statPanel = Lib.createMC("interface.GameStatPanel");
			statPanel.x = Config.WIDTH - statPanel.width - 15;
			statPanel.y = 15;
			addChild(statPanel);
			var minutesArrowCircle:Shape = new Shape();
			minutesArrowShelf = new Shape();
			statPanel.addChildAt(minutesArrowCircle, statPanel.getChildIndex(statPanel.getChildByName("minutesArrow")));
			statPanel.addChildAt(minutesArrowShelf, statPanel.getChildIndex(statPanel.getChildByName("minutesArrow")));
			minutesArrowShelf.x = minutesArrowCircle.x = statPanel.getChildByName("minutesArrow").x;
			minutesArrowShelf.y = minutesArrowCircle.y = statPanel.getChildByName("minutesArrow").y;
			minutesArrowCircle.mask = minutesArrowShelf;
			minutesArrowCircle.graphics.beginFill(0xFFFFFF, 0.47);
			minutesArrowCircle.graphics.drawCircle(0, 0, 15);
			
			timeTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true);
			timeTF.width = 55;
			timeTF.x = 139;
			timeTF.y = 15;
			statPanel.addChild(timeTF);
			
			carrotTF = new EmbededTextField(Config.FONT_SECONDARY, 0xFFFFFF, 16, true);
			carrotTF.width = 35;
			carrotTF.x = 222;
			carrotTF.y = 15;
			statPanel.addChild(carrotTF);
			
			Config.memory["GameGUI"] = this;
			life = 0;
			time = 0;
			carrot = 0;
		}
		
		public function clear():void
		{
			playPauseButton.removeEventListener(MouseEvent.CLICK, onPlayPauseClick);
			delete Config.memory["GameGUI"];
		}
		
		private function onPlayPauseClick(e:Event):void
		{
			new PauseMenuWindow();
		}
		
		// 0..1
		public function set life(value:Number):void
		{
			statPanel.getChildByName("progressBar").scaleX = Math.max(0,Math.min(1, value));
		}
		
		/**
		 * Сколько максимально длится раунд, секунды
		 */
		public function set timeEnd(value:int):void
		{
			_timeEnd = value;
			_time = -1;
			time = _time;	
		}
		public var _timeEnd:int = 60;
		
		/**
		 * Сколько длится текущий раунд
		 */
		public function set time(value:int):void
		{
			if(_time != value)
			{
				if(value > _timeEnd)
					_timeEnd = value;
				_time = value;
				var timeLeft:int = _timeEnd - _time;
				
				var minLeft:int = timeLeft / 60;
				var secLeft:int = timeLeft - (minLeft * 60);
				
				timeTF.text = (minLeft > 9?minLeft:"0" + minLeft) 
													+ ":" + (secLeft > 9?secLeft:"0" + secLeft);
				
				var part:Number = value / _timeEnd;
				var t_part:Number = Math.PI * 2 * part;
				statPanel.getChildByName("minutesArrow").rotation = part * 360;
				
				var g:Graphics = minutesArrowShelf.graphics;
				g.clear();
				g.beginFill(0xFFFFFF, 0.47);
				if(part < 0.25)
				{
					g.moveTo(0,0);
					g.lineTo(0, -100);
				}
				else if(part < 0.50)
				{
					g.drawRect(0, -20,20,20);
					
					g.moveTo(0,0);
					g.lineTo(100, 0);
				}
				else if(part < 0.75)
				{
					g.drawRect(0, -20,20,40);
					
					g.moveTo(0,0);
					g.lineTo(0, 100);
				}
				else
				{
					g.drawRect(0, -20,20,40);
					g.drawRect(-20, 0,20,20);
					
					g.moveTo(0,0);
					g.lineTo(-100, 0);
				}
				
				g.lineTo(100 * Math.sin(t_part), -100 * Math.cos(t_part));
				g.endFill();
			}
		}
		private var _time:int;
		
		public function set carrot(value:int):void
		{
			carrotTF.text = value.toString();
		}
	}
}