package com.somewater.storage
{
	import com.somewater.control.IClear;
	
	import flash.utils.getQualifiedClassName;

	/**
	 * Базовый класс для создания типизированных классов данных, заполняющихся на основе объектов data, 
	 * приходящих с сервера, у которых к тому же поля совпадают (у серверных объектов и у классов, расширяющих InfoDef)
	 */
	public class InfoDef implements IClear
	{
		protected var _data:Object;
		protected var supressSerializationWarn:Boolean;
		
		public function InfoDef(data:Object = null)
		{
			if(data)
				this.data = data;
		}
		
		
		public function set data(value:Object):void
		{
			if(value)
				for(var s:String in value)
				{
					try
					{
						if(this.hasOwnProperty(s) && (!(value[s] === null)))
							this[s] =(isNaN(Number(value[s])) || value[s] == null?value[s]:
											(value[s] is String && value[s] != "0"?value[s]:Number(value[s])));
						continue;
					}catch(e:Error){
						// nothing
					}
					if(!supressSerializationWarn)
						trace("Unexpected field " + s + "=" + value[s] + " in " + getQualifiedClassName(this) + " " + value["id"]);
				}
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function clear():void
		{
			_data = null;
		}
	}
}