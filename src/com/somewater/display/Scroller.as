package com.somewater.display
{
	import com.progrestar.city.SWFItem;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class Scroller extends Sprite
	{
		
		private var scroller:*;
		private var scroller_btn:*;
		private var _scrollListener:Sprite;
		private var _scrollerPosition:Number;
		private var _isActive:Boolean;
		
		public function Scroller(scrollListener:Sprite)
		{
			super();
			scroller = SWFItem.getLib().getExportedAsset("common.Scroll") as Sprite;
			addChild(scroller);
			scroller_btn = scroller.getChildByName("scroll_btn");
			
			_scrollListener = scrollListener;
			scroller_btn.addEventListener(MouseEvent.MOUSE_DOWN, scrollDown);
			scroller_btn.buttonMode = true;
			scroller_btn.y = 7;
			_scrollListener.addEventListener(MouseEvent.MOUSE_UP, scrollUp);
		}
		
		public function get scrollerPosition():Number{
			return _scrollerPosition;
		}
		
		public function set scrollerPosition(p:Number):void{
			_scrollerPosition = p;
			scroller_btn.y = 6+(303-6)*scrollerPosition;
		}
		
		public function get isActive():Boolean{
			return _isActive;
		}
		
		private var currentMouseY:Number;
		private function scrollDown(e:Event=null):void{
			currentMouseY = scroller.mouseY;
			_isActive =  true;
			_scrollListener.addEventListener(MouseEvent.MOUSE_MOVE,scrollMouseMove);
		}
		
		private function scrollUp(e:Event=null):void{
			_isActive = false;
			_scrollListener.removeEventListener(MouseEvent.MOUSE_MOVE,scrollMouseMove);
		}
		
		private function scrollMouseMove(e:Event):void{
			var scrolBtnPos:Number = scroller_btn.y + scroller.mouseY - currentMouseY; 
			if(scrolBtnPos > 303){
				scrolBtnPos = 303;
				//scrollUp();
			}
			if(scrolBtnPos < 6){
				scrolBtnPos = 6;
				//scrollUp();
			} 
			scroller_btn.y = scrolBtnPos;
			_scrollerPosition = (scrolBtnPos-6)/(303-6);
			currentMouseY = scroller.mouseY;
		}
		
	}
}