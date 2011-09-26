package com.somewater.control.tree
{
	import com.greensock.TweenMax;
	import com.somewater.control.IClear;
	import com.progrestar.events.IndexedEvent;
	import com.somewater.text.LinkLabel;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.ColorTransform;
	
	[Event(name="resize",type="flash.events.Event")]
	[Event(name="clickIndexedItem",type="com.progrestar.events.IndexedEvent")]
	
	/**
	 * Создает 1 элемент дерева: заголовок и, если есть, его детей
	 */
	public class TreeBranch extends Sprite implements IClear
	{
		public var registration:Array = [];
		
		public var DEFAUL_LABEL_HEIGHT:int = 15;
		public var DEFAUL_CHILD_HEIGHT:int = 15;
		private const SPEED:Number = 0.3;// время сек. на появление/исчезновение контента
		private const RECT_SPEED:Number = 0.3;// время на выдвижение/задвижение прямоугольника
		
		public var labelField:String;
		public var dataField:String;
		public var oldHeight:int;
		
		public var label:LinkLabel;
		private var labelGround:Shape;
		private var box:TreeBox;
		private var content:Sprite;
		private var childs:int = 0;
		private var type:int;// тип визуального представления
		
		/**
		 * 
		 * @param data данные для построения ветви (см. описание в классе Tree)
		 * @param type тип визуального представления надписей
		 *			0 - как в "Выбор категории"
	 	 *			1 - как в "Мой кабинет" (менюшка)
	 	 * 			2 - как в "Мой кабинет" (страница)
		 * 
		 */
		public function TreeBranch(data:Object,type:int,registration:Array)
		{
			super();
			this.registration = registration;
			this.type = type;
			if (type == 1){
				DEFAUL_LABEL_HEIGHT = 20;
				DEFAUL_CHILD_HEIGHT = 20;
			}
			//box = new TreeBox();
			//box.useHandCursor = true;	box.buttonMode = true;
			//box.addEventListener(MouseEvent.CLICK,labelClick);
			//addChild(box);
			labelGround = new Shape();
			labelGround.graphics.beginFill(0xFF003D);
			
			label = new LinkLabel(null,"w",12,false);
			label.addEventListener(MouseEvent.ROLL_OVER,labelMouseOver_handler);
			label.addEventListener(MouseEvent.ROLL_OUT,labelMouseOut_handler);
			label.addEventListener(MouseEvent.CLICK,labelClick);
			label.text = data.title;
			label.data = [{id:data.id,title:data.title}];
			label.y = -1;
			labelGround.graphics.drawRect(0,0,label.width,label.height);
			labelGround.scaleX = 0;	labelGround.visible = false;
			addChild(labelGround);
			addChild(label);
			_height = DEFAUL_LABEL_HEIGHT;
			content = new Sprite();
			if (type != 2) content.visible = false;
			if (data.childs != null){
				if (data.childs.length>0)
				{					
					content.x = 10; content.y = 14;
					if (type != 2) content.alpha = 0;
					addChild(content);
					for(var i:int = 0;i<data.childs.length;i++){
						var subline:LinkLabel = new LinkLabel(null,"w",11,false);
						subline.text =data.childs[i].title;
						subline.data = [{id:data.id,title:data.title},{id:data.childs[i].id,title:data.childs[i].title}];
						subline.x = 10;	subline.y = i*DEFAUL_CHILD_HEIGHT;
						var mark:TreeMark = new TreeMark();
						mark.y = subline.y+7;
						content.addChild(mark);
						if (type == 1){
							mark.visible = false;
							mark.mark = true;
							mark.transform.colorTransform = new ColorTransform(0,0,0,1,0xff,0xff,0xff);
						}
							
						content.addChild(subline);
						subline.addEventListener(MouseEvent.ROLL_OVER,sublineMouseOver_handler);
						subline.addEventListener(MouseEvent.ROLL_OUT,sublineMouseOut_handler);
						subline.addEventListener(LinkLabel.LINK_CLICK,categoryClick);
					}
					childs = i;
					label.linked = false;
				}
			}else{
				label.addEventListener(LinkLabel.LINK_CLICK,categoryClick);
			}
			registration.push(this);
		}
		
		public function clear():void{
			registration = null;
		}
		
		private function categoryClick(e:TextEvent):void{
			//var str:String = "";
			//for (var i:int = 0;i<e.currentTarget.data.length;i++)
			//	str += "id="+e.currentTarget.data[i].id+" title="+e.currentTarget.data[i].title+"\n";
			var event:IndexedEvent = new IndexedEvent(IndexedEvent.CLICK_INDEXED_ITEM,e.currentTarget.data);
			dispatchEvent(event);
		}
		
		private function sublineMouseOver_handler(e:MouseEvent):void{
			var mark:TreeMark = (content.getChildAt(content.getChildIndex(e.currentTarget as DisplayObject) - 1) as TreeMark);
			if (type == 0 || type == 2){
				LinkLabel(e.currentTarget).color = 0x590000;
				mark.mark = true;
			}
			if (type == 1){
				mark.visible = true;
			}
		}
		
		private function sublineMouseOut_handler(e:MouseEvent):void{
			var mark:TreeMark = (content.getChildAt(content.getChildIndex(e.currentTarget as DisplayObject) - 1) as TreeMark);
			if (type == 0 || type == 2){
				LinkLabel(e.currentTarget).color = 0xffffff;
				mark.mark = false;
			}
			if (type == 1){
				mark.visible = false;
			}
		}
		
		private function labelMouseOver_handler(e:MouseEvent = null):void{
			if (content.visible && e != null && type != 2) return;
			label.color = 0x590000;
			labelGround.visible = true;
			TweenMax.to(labelGround,RECT_SPEED,{scaleX:1});
		}
		
		private function labelMouseOut_handler(e:MouseEvent = null):void{
			if (content.visible && e != null && type != 2) return;
			label.color = 0xFFFFFF;
			TweenMax.to(labelGround,RECT_SPEED,{scaleX:0,onComplete:function():void{labelGround.visible = false;}});
		}
		
		public function labelClick(e:MouseEvent = null):void{
			// закрыть открытую ветвь
			if (e != null)
				for (var i:int = 0;i<registration.length;i++)
					if (registration[i] != this)
						if (TreeBranch(registration[i]).content.visible){
							TreeBranch(registration[i]).labelClick();
						}
					
			if (childs == 0) {	
				if (content.visible)					
					labelMouseOut_handler();
				else
					labelMouseOver_handler();
				content.visible = !content.visible;
				return;	
			}
			
			if (type == 2) return;
			
			if (content.visible || e == null){
				TweenMax.to(content,SPEED,{alpha:0,onComplete:function():void{
					if (type != 2)content.visible = false;
					labelMouseOut_handler();
				}});
				oldHeight = _height;
				_height = DEFAUL_LABEL_HEIGHT;
			}else{
				labelMouseOver_handler();
				oldHeight = _height;
				_height = DEFAUL_LABEL_HEIGHT + DEFAUL_CHILD_HEIGHT * childs;
				content.visible = true;
				TweenMax.to(content,SPEED,{alpha:1});
			}
			var event:Event = new Event(Event.RESIZE);
			dispatchEvent(event);	
		}
		
		public function setSize(w:int,h:int):void{
			_width = w;
			_height = h;
		}
		
		private var _width:Number;
		override public function set width(value:Number):void{			
			_width = value;
			setSize(_width,_height);
		}
		override public function get width():Number{			
			return _width;
		}
		
		private var _height:Number;
		override public function set height(value:Number):void{			
			_height = value;
			setSize(_height,_height);
		}
		override public function get height():Number{			
			return _height;
		}		
		
	}
}