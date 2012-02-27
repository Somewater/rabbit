package com.somewater.text
{
	import com.somewater.control.IClear;
	
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	[Event(name="linkClick",type="com.somewater.text.LinkLabel")]
	
	public class LinkLabel extends EmbededTextField implements IClear
	{
		public static const LINK_CLICK:String = "linkClick";
		
		protected var _linked:Boolean;
		public var linkClick:Function;
		public var data:Object;
		
		public function LinkLabel(font:String=null, color:*=null, size:int=12, bold:Boolean=false, align:String="left",bitmapText:Boolean = false)
		{
			super(font, color, size, bold, false, false, false, align,bitmapText);
			_linked = false;// иначе не сработает linked = true;
			linked = true;
		}
		
		public function clear():void{
			removeAllListeners();
			hint = null;
		}
		
		public function set linked(flag:Boolean):void{
			if (flag == _linked) return;
			mouseEnabled = underline = _linked = flag;
			if (flag){
				addEventListener(MouseEvent.MOUSE_OVER,headerLabelMouseOverEvent,false,0,true);
				addEventListener(MouseEvent.MOUSE_OUT,headerLabelMouseOutEvent,false,0,true);
				addEventListener(MouseEvent.CLICK,headerLabelMouseClick,false,0,true);
				if (super.text.length) text = super.text;
			}else{
				removeAllListeners();
				if (underline) underline = false;
				if (super.text.length) super.htmlText = super.text;
			}			
		}
		
		private function removeAllListeners():void{
			removeEventListener(MouseEvent.MOUSE_OVER,headerLabelMouseOverEvent);
			removeEventListener(MouseEvent.MOUSE_OUT,headerLabelMouseOutEvent);
			removeEventListener(MouseEvent.MOUSE_OUT,headerLabelMouseClick);
		}
		
		override public function set text(value:String):void{
			if (_linked)
				super.htmlText = "<a href='event:'>"+value+"</a>";
			else
				super.text = value;
		}
		
		public function get linked():Boolean{
			return _linked;
		}
		
		private function headerLabelMouseOverEvent(e:MouseEvent):void{
			underline = false;
		}
		
		private function headerLabelMouseOutEvent(e:MouseEvent):void{
			underline = true;
		}
		
		private function headerLabelMouseClick(e:MouseEvent):void{
			if (linkClick != null) 
				linkClick(data?data: text);
			else{
				var event:TextEvent = new TextEvent(LinkLabel.LINK_CLICK,false,false,text);
				dispatchEvent(event);	
			}
			
		}
		
	}
}