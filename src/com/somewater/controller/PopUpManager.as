package com.somewater.controller
{
	import com.somewater.display.Window;
	import com.somewater.text.Hint;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filters.BlurFilter;

	public class PopUpManager
	{
		public var WIDTH:int;
		public var HEIGHT:int;
		public static var instance:PopUpManager;
		
		private var windowsStorage:Array;
		private var popUpGround:DisplayObject;// есть экран размытия (его надо впоследствии удалить)
		public var defaultParent:DisplayObjectContainer;// на что крепить popUp
		public var defaultContentRegion:DisplayObject;// чтоб подвергать размытию
		
		public static function Initialize(popupLayer:DisplayObjectContainer, contentLayer:DisplayObject, width:int, height:int, popUpGround:DisplayObject, splash:Sprite = null):void
		{
			instance = new PopUpManager();
			instance.defaultParent = popupLayer;
			instance.defaultContentRegion = contentLayer;
			instance.popUpGround = popUpGround;
			instance.splash = splash;
			instance.splashLogoInitialPosY = splash.getChildByName("logo").y;
			
			hideSplash();
			
			instance.WIDTH = width;
			instance.HEIGHT = height;
		}
		
		public function PopUpManager(target:IEventDispatcher=null)
		{
			super();
			init();
		}
		
		public function init():void
		{
			windowsStorage = [];
		}
		
		public static function getInstance():PopUpManager {
			if (!instance) 
				instance = new PopUpManager();
			return instance;
		}
		
		/**
		 * 
		 * @param windows Описание поп апа
		 * @param parent К чему добавить (если null то к корню приложения)
		 * @param modal Должны ли блокироваться ослаьные контролы полупрозрачной пеленой (не действует, если parent не сцена). 
		 * 			при modal = true автоматически выставляется individual = true
		 * @param individual Должны ли перед показом текущего попАпа быть удалены все остальные попАпы (не действует, если parent не сцена)
		 * @return показанный ПопАп
		 * 
		 */		
		public static function addPopUp(window:Window,modal:Boolean = false,individual:Boolean = false):DisplayObject{
			// идет прибавление к корню приложения, это обычный ПопАп, и он будет добавлен в массив всех ПопАпов и управляться из PopUpManager	
			var popup:Popup = new Popup(window, modal, individual);
			if (individual){// в тест моде текстовые сообщения не должны влиять на другие попАпы
				var i:int = 0;
				while (i<instance.windowsStorage.length){
					var popupClosed:Popup = Popup(instance.windowsStorage[i]);
					if(popupClosed.displayObject is Window)
						Window(popupClosed.displayObject).close();
					else
						removePopUp(popupClosed.displayObject);
					if(instance.windowsStorage.indexOf(popupClosed) != -1)
						instance.windowsStorage.splice(instance.windowsStorage.indexOf(popupClosed), 1);
				}
				Hint.hideHint();
			}
			if (modal){
				if (instance.popUpGround != null && instance.popUpGround.parent){
					instance.defaultParent.removeChild(instance.popUpGround);
					instance.defaultContentRegion.filters = [];
				}else{
					instance.popUpGround = new Shape();
					Shape(instance.popUpGround).graphics.beginFill(0xA498C5,0.3)
					Shape(instance.popUpGround).graphics.drawRect(0,0,instance.WIDTH,instance.HEIGHT);
				}
				instance.defaultContentRegion.filters = [new BlurFilter(5,5,1)];
				instance.defaultParent.addChild(instance.popUpGround);
			}
			instance.windowsStorage.push(popup);	
			return instance.defaultParent.addChild(window);
		}
		
		public static function message(text:String, title:String = null):Window{
			var window:Window = new Window(text.length > 300 ? text.substr(0,300) + "..." : text, title);
			window.width = (text.length < 300?400:500);
			addPopUp(window,true);
			centre(window);
			return window;
		}
		
		public static function centre(window:DisplayObject):void{
			window.x = 0.5*(instance.WIDTH - window.width);
			window.y = 0.5*(instance.HEIGHT - window.height);
		}
		

		/**
		 * @param window
		 * @return Было ли удалено окно. Если false, то видимо оно уже было удалено ранее 
		 */
		public static function removePopUp(window:Window):Boolean{
			if (window.parent != null)
				if (window.parent.contains(window)){
					window.parent.removeChild(window);
					var index:int;
					if (instance.popUpGround != null){
						index = instance.defaultParent.getChildIndex(instance.popUpGround);
						if (instance.defaultParent.numChildren == 1){// при закрытии любого окра, убирать сплаш
							if (instance.defaultParent.contains(instance.popUpGround))
								instance.defaultParent.removeChild(instance.popUpGround);
							instance.defaultContentRegion.filters = [];
							instance.popUpGround = null;
						}
						else
							if (instance.defaultParent.contains(instance.popUpGround))
								instance.defaultParent.setChildIndex(instance.popUpGround,Math.max(0,index - 1));
					}
					index = -1;
					for(var i:int = 0;i<instance.windowsStorage.length;i++)
						if(Popup(instance.windowsStorage[i]).displayObject == window){
							index = i;
							break;
						}
					if (index != -1){
						instance.windowsStorage.splice(index,1);
					}					
					return true;
				}
			return false;
		}
		
		public static function contain(window:DisplayObject):Boolean{
			for (var i:int = 0; i<instance.windowsStorage.length; i++)
				if (Popup(instance.windowsStorage[i]).displayObject == window)
					return true;
			return false;
		}
		
		
		public static function closeAll():void{
			while (instance.windowsStorage.length > 0){
				removePopUp(Popup(instance.windowsStorage[0]).displayObject);
			}
		}
		
		protected var splash:Sprite;
		private var splashLogoInitialPosY:int;
		
		/**
		 * @param progress если не -1, показывать прогресс бар с прогрессом 0..1
		 */
		public static function showSlash(progress:Number = -1):void{
			var splash:Sprite = instance.splash;
			if(splash)
			{
				splash.visible = true;
				if(progress >= 0)
				{
					var bar:MovieClip = splash.getChildByName("bar") as MovieClip;
					if(progress > 1) progress = 1;
					bar.visible = true;
					bar.textField.text = Math.round(progress * 100) + "%";
					bar.progressBar.scaleX = 1 - progress;
					splash.getChildByName("logo").y = instance.splashLogoInitialPosY;
				}
				else
				{
					splash.getChildByName("bar").visible = false;
					splash.getChildByName("logo").y = instance.splashLogoInitialPosY + 40;
				}
			}
		}
		
		public static function hideSplash():void{
			if(instance.splash) instance.splash.visible = false;
		}
		
		
		public static function get numWindows():int
		{
			return instance.windowsStorage.length;
		}
		
		public static function get activeWindow():Window
		{
			if(instance.windowsStorage.length)
				return Popup(instance.windowsStorage[instance.windowsStorage.length - 1]).displayObject;
			else
				return null;
		}
	}
}
	import com.somewater.display.Window;
	
	import flash.display.DisplayObject;
	
class Popup{
	public var displayObject:Window;
	public var modal:Boolean;
	public var individual:Boolean;
	
	public function Popup(displayObject:Window, modal:Boolean, individual:Boolean){
		this.displayObject = displayObject;
		this.modal = modal;
		this.individual = individual;
	}
}