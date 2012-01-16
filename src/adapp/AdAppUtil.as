package adapp
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import utils.MD5;

	public class AdAppUtil
	{
		private var _platform_id:String = "";
		private var _api_id:String = "";
		private var _auth_key:String = "";
		private var _api_key:String = "";
		private var _api_url:String = "";
		private var _uid:String = ""
		private var _count_standart:Number = 0;
		private var _count_vertical:Number = 0;
		private var _count_horizontal:Number = 0;
		public var _callBack:Function;
		public var _format:String = "XML";
		public function AdAppUtil(platform_id:String, api_id:String = null, auth_key:String = null, api_url:String = null, uid:String = null, key:String = null)
		{
			_platform_id = platform_id;
			
			if(api_id&&auth_key&&api_url&&uid&&key)
			{
				_api_key = key;
				_api_url = api_url;
				_auth_key = auth_key;
				_api_id = api_id;
				_uid = uid;
			}

		}
		public function getAds(callBack:Function, format:String = "XML", count_standart:Number = 0, count_vertical:Number = 0, count_horizontal:Number = 0):void
		{
			_count_standart = count_standart;
			_count_vertical = count_vertical;
			_count_horizontal = count_horizontal;
			_callBack = callBack;
			_format = format;
			if(_auth_key&&_api_url&&_uid&&_api_key)	
			{
			    var urlRequest:URLRequest = new URLRequest( _api_url );
			    urlRequest.method = URLRequestMethod.POST;
				
				var obj:Object = new Object;
				obj.nam = "method";
				obj.val = "getProfiles";
				
				var obj1:Object = new Object;
				obj1.nam = "uids";
				obj1.val = _uid;
				
				var obj2:Object = new Object;
				obj2.nam = "format";
				obj2.val = "XML";
				
				var obj3:Object = new Object;
				obj3.nam = "fields";
				obj3.val = "sex,bdate,city,country";

				var obj4:Object = new Object;
				obj4.nam = "api_id";
				obj4.val = this._api_id;
				
				
				var params:Array = new Array;
				params.push(obj); params.push(obj1); params.push(obj2); params.push(obj3); params.push(obj4);
				params.sortOn(["nam"]);
				var param_str:String = "";
				var url_vars:URLVariables = new URLVariables;
				
					for each(var param:* in params)
					{
						param_str+=param.nam+"="+param.val;
						url_vars[param.nam] = param.val;
					}
				url_vars["sig"] = MD5.encrypt(_uid+param_str+_api_key);
				
			    urlRequest.data = url_vars;  
			    var ldr:URLLoader = new URLLoader();
			    ldr.addEventListener( Event.COMPLETE, handler_);
			    ldr.load( urlRequest );
			}	
			else
			{
				adAppRequest(new Array());
			}		
		}
		private function adAppRequest(data:Array):void
		{
			 var url_vars:URLVariables = new URLVariables;

			for each(var it:* in data)
			{
				url_vars[it.nam] = it.val;
			}
			 url_vars['platform_id'] = this._platform_id;
			 url_vars['count_standart'] = this._count_standart;
			 url_vars['count_vertical'] = this._count_vertical;
			 url_vars['count_horizontal'] = this._count_horizontal;
			 url_vars['format'] = this._format;
		      var urlRequest:URLRequest = new URLRequest("http://adapp.ru/ad_getad.php");
		      urlRequest.method = URLRequestMethod.POST;			
		      var ldr:URLLoader = new URLLoader();
		      ldr.addEventListener(Event.COMPLETE, _callBack);
		      urlRequest.data = url_vars;
		      ldr.load( urlRequest );			
		}
		public function handler_(e:Event, dataXML:XML = null):void
		{
			var obj:Array = new Array;
			var data:XML = dataXML ? dataXML : XML(e.currentTarget.data);
			trace(data);
			if(data.user)
			{
				var ob1:Object = new Object;
				ob1.nam = 'uid';
				ob1.val = data.user.uid;
				var ob2:Object = new Object;
				ob2.nam = 'sex';
				ob2.val = data.user.sex;			
				var ob3:Object = new Object;
				ob3.nam = 'bdate';
				ob3.val = data.user.bdate;	
				var ob4:Object = new Object;
				ob4.nam = 'city';
				ob4.val = data.user.city;		
				var ob5:Object = new Object;
				ob5.nam = 'country';
				ob5.val = data.user.country;		
				var arr:Array = new Array(ob1, ob2, ob3, ob4, ob5);
				adAppRequest(arr);
			}
			else
			{
				adAppRequest(new Array);
			}
			
		}		

	}
}