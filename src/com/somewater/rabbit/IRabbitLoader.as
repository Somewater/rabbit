package com.somewater.rabbit
{
	import com.somewater.control.IClear;
	import com.somewater.net.IServerHandler;
	import com.somewater.social.SocialUser;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	/**
	 * Главный лоадер
	 * Отвечает за загрузку всех флешек и ассетов (в т.ч. перед стартом игры)
	 */
	public interface IRabbitLoader extends IRabbitModule, IClear
	{
		/**
		 * Загрузить queue, заданный в формате {"name":String, "url":String}
		 * onComplete():void
		 * onError():void
		 * onProgress(value:Number = 0..1)
		 */
		function loadSwfs(queue:Array, onComplete:Function, onError:Function = null, onProgress:Function = null):void
			
		/**
		 * Загрузать xml-файлы, поместив результаты загрузки в массив xmls в соответствующие поля
		 * @param xmls - ассоциативный массив ["XmlName" => {"url":"http://..."}  ,  "SecondXmlName" => "http://..." ]
		 * @param onComplete(xmls:Hash of XML)
		 * @param onError():void
		 * @param onProgress(progress:Number = 0..1)
		 */
		function load(data:Object, onComplete:Function = null, onError:Function = null, onProgress:Function = null):void
			
		/**
		 * содержимое предварительно загруженного xml файла по его имени
		 * (имя без .xml)
		 */
		function getXML(name:String):XML
		
		/**
		 * Содержимое файла в виде текста
		 * (имя файла без расширения)
		 */
		function getData(name:String):String
		
		function setXML(name:String, data:XML):void
		function setData(name:String, data:String):void
			
		/**
		 * Путь загрузки файлов, для которых путь начинается не с http
		 * (если не задан, базовым считается путь до прелоадера)
		 */
		function set basePath(value:String):void
		
		/**
		 * Установить прогресс прелоадера
		 * 0 соц. сеть
		 * 1 свф-ки
		 * 2 статические данные
		 * 3 init запросы к серверу (динамические данные)
		 */
		function setProgress(type:int, value:Number):void
			
		function get flashVars():Object
			
		function get content():Sprite
			
		function get popups():Sprite
			
		function get tooltips():Sprite
			
		function get cursors():Sprite
			
		function get swfADs():Array

		function get serverHandler():IServerHandler
		
		/**
		 * ПОлучив идентификатор файла, возвращает путь, по которому этот файл можно загрузить
		 */
		function getFilePath(fileId:String):String
			
		function addChild(child:DisplayObject):DisplayObject
			
		function allocatePreloader():*
			
		function toString():String
			
		/**
		 * Социальные данные
		 */
		function get net():int

		function get hasUserApi():Boolean
		
		function get hasFriendsApi():Boolean
			
		function getFriends():Array
			
		function getAppFriends():Array
			
		function getUser():SocialUser

		function setUser(user:SocialUser):void
			
		function showInviteWindow():void
			
		function pay(quantity:Object, onSuccess:Function, onFailure:Function, params:Object = null):void
			
		function getUsers(uids:Array, onComplete:Function, onError:Function):void
	}
}