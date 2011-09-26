/*************
 *
 *	Когда нибудь будет использован
 *
 *************/
package com.somewater.social
{
	import com.progrestar.common.util.JSON;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import flash.utils.Timer;

	/**
	 * @author Forticom Ltd.
	 * @date 18/02/2010 15:34
	 * @description Forticom API interface for applications;
	 */
	public class ForticomAPI extends EventDispatcher
	{
		public static const CONNECTED : String = "connection established";
		public static const SEND_ERROR : String = "send failed";
		public static const DEBUG : Boolean = true;
		public static const CALL_BACK : String = "call_back_event";
		
		private static var _instance : ForticomAPI;
		
		private var _timer : Timer = new Timer(200);
		private var _connectedSelf : Boolean = false;
		
		private var _wasRetry : Boolean = false;
		private var _connection : LocalConnection = new LocalConnection;
		private var _connectionName : String;
		private var _eventsPool : Array = [];
		private var _connected : Boolean = false;
		public static function get connected():Boolean{return (_instance && _instance._connected)}
		
		public function ForticomAPI(key : SingleTonKey) 
		{
			super();
			
			this._timer.addEventListener(TimerEvent.TIMER, this.tryToCreateConnection);
			
			this._connection.allowDomain("*");
			this._connection.addEventListener(StatusEvent.STATUS, this.handleOutStatus);
			this._connection.client = this;
			
		}
		
		private function handleOutStatus(event : StatusEvent) : void
		{
			if(DEBUG) trace("ForticomAPI handleOutStatus " + event);
			if (event.level != StatusEvent.STATUS)
			{
				this.dispatchEvent(new Event(ForticomAPI.SEND_ERROR));
			}
		}
		
		public function tryToCreateConnection(event : TimerEvent = null) : void
		{
			try
			{
				if(!this._connectedSelf)
				{
					/*
					  If client connection, does not exists, try to create new one. 
					  If fails to create client connection, we assume that client connection with the same name already exists.
					  Probably this is an old connection from the previous session (possible with HTML applications)
					*/
					trace("Trying to create new client connection ", this._connectionName);
					this._connection.connect("_api_" + this._connectionName);
					this._connectedSelf = true;
				}
			}
			catch (e : Error)
			{
				trace("Client connection already exists!");
				
				//Try to close existing client connection in previous session
				var cc2 : LocalConnection = new LocalConnection();
				cc.addEventListener(StatusEvent.STATUS, this.handleOutStatusConcurrent, false, 0 , true);
				cc2.send("_api_" + this._connectionName, "closeConnection");
				//Start timer, which will retry creation of client connection
				this._timer.start();
				return;
			}	
			
			/**
			 * If client connection created succesfully, but not proxy not yet connected to this client, we will start timer to monitor, that succefull connection.
			 * 
			 */
			if (!this._connected) {
				if(event)
				{
					//if timer, that we assume that, proxy was connected to another client (previous session) and ask it to reconnect to this client instance
					this._timer.stop();
					this._timer.reset();
					trace("Telling proxy to make reconnect...");
					var cc : LocalConnection = new LocalConnection();
					cc.addEventListener(StatusEvent.STATUS, this.handleOutStatusReconnect, false, 0 , true);
					cc.send("_proxy_" + this._connectionName, "makeReconnect");
					
				}
				else
				{
					//start timer on first iteration 
					this._timer.start();
				}
			}
			
		}
		
		private function handleOutStatusReconnect(event : StatusEvent) : void
		{
			if(DEBUG) trace("ForticomAPI handleOutStatusReconnect " + event);
			if (event.level != StatusEvent.STATUS)
			{
				trace("Proxy not responding!");
				tryToCreateConnection();
			}
		}
		
		private function handleOutStatusConcurrent(event : StatusEvent) : void
		{
			if(DEBUG) trace("ForticomAPI handleOutStatusConcurrent " + event);
			if (event.level != StatusEvent.STATUS)
			{
				trace("Concurrent client not responding!");
			}
		}
		public function closeConnection() : void
		{
			this._connection.close();
		}
		
		public function establishConnection() : void
		{
			if (DEBUG)	trace('Client connection established');
			
			this._timer.stop();
			this._timer.reset();
			
			if (!this._connected)
			{
				this._connected = true;
				this.dispatchEvent(new Event(ForticomAPI.CONNECTED));
				
				while (this._eventsPool.length)
				{
					var item : PoolItem = this._eventsPool.shift() as PoolItem;
					this.doSend.apply(this, [item.method].concat(item.args))
				}
			}
		}
		
		public function apiCallBack(methodName : String, result : String, params : String) : void
		{
			this.dispatchEvent(new ApiCallbackEvent(ApiCallbackEvent.CALL_BACK, false, false, methodName, result, params));
		}
		
		private function doSend(method : String, ... rest) : void
		{
			if (this._connected)
			{
				if (rest.length) {
					this._connection.send.apply(this._connection, ["_proxy_" + ForticomAPI.instance._connectionName, method].concat(rest));
				}else {
					this._connection.send.apply(this._connection, ["_proxy_" + ForticomAPI.instance._connectionName, method]);
				}
			}
			else {
				this._eventsPool.push(new PoolItem(method, rest));
			}
		}
		
		private static function get instance() : ForticomAPI
		{
			ForticomAPI._instance = ForticomAPI._instance ? ForticomAPI._instance : new ForticomAPI(new SingleTonKey);
			return ForticomAPI._instance;
		}
		
		public static function showPermissions(... permissions ) : void
		{
			ForticomAPI.instance.doSend("showPermissions", JSON.encode(permissions));
		}
		
		public static function showInvite(text : String = null, params : String = null) : void
		{
			ForticomAPI.instance.doSend("showInvite", text, params);
		}
		
		public static function showNotification(text : String, params : String = null) : void
		{
			ForticomAPI.instance.doSend("showNotification", text, params);
		}
		
		public static function showPayment(name : String, description : String, code : String, price : int = -1, options : String = null, attributes : String = null, currency: String = null, callback : String = 'false') : void
		{
			ForticomAPI.instance.doSend("showPayment", name, description, code, price, options, attributes, currency, callback);
		}
		
		public static function showConfirmation(method : String, userText : String, signature : String) : void
		{
			ForticomAPI.instance.doSend("showConfirmation", method, userText, signature);
		}
		
		public static function set connection(name : String) : void
		{
			ForticomAPI.instance._connectionName = name;
			ForticomAPI.instance.tryToCreateConnection();
		}
		
		public static function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void
		{
			ForticomAPI.instance.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public static function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void
		{
			ForticomAPI.instance.removeEventListener(type, listener, useCapture);
		}
		
		public static function send(method : String, ... rest) : void
		{
			if (DEBUG)	trace('CLI: Method '+method+", arguments "+rest);
			ForticomAPI.instance.doSend.apply(ForticomAPI.instance, [method].concat(rest))
		}
		
	}

}
	import flash.events.Event;
	

internal class SingleTonKey { public function SingleTonKey() { } }
internal class PoolItem
{
	public var method : String;
	public var args : Array;
	
	public function PoolItem($method : String, ... $args)
	{
		this.method = $method;
		this.args = $args;
	}
}
internal class ApiCallbackEvent extends Event
{
	public static const CALL_BACK : String = "call_back_event";
	
	protected var _method : String;
	protected var _result : String;
	protected var _data : String;
	
	public function ApiCallbackEvent($type : String, $bubbles : Boolean=false, $cancelable : Boolean=false, $method : String = "null", $result: String = "", $data : String = "")
	{
		super($type, $bubbles, $cancelable);
		
		this._method = $method;
		this._result = $result;
		this._data = $data;
	}
	
	public function get method() : String
	{
		return this._method;
	}
	
	public function get result() : String
	{
		return this._result;
	}
	
	public function get data() : String
	{
		return this._data;
	}
	
	override public function clone() : Event
	{
		return new ApiCallbackEvent(this.type, this.bubbles, this.cancelable, this.method, this.result, this.data);
	}
	
}