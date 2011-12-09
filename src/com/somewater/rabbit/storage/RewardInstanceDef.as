package com.somewater.rabbit.storage {
	import com.somewater.rabbit.application.RewardManager;
	import com.somewater.storage.InfoDef;
	
	import flash.geom.Point;

	public class RewardInstanceDef extends InfoDef{

		public var x:int;
		public var y:int;
		public var levelNumber:int;  // необязательный параметр, прохождение какого уровня дало ревард

		protected var _rewardDef:RewardDef;

		public function RewardInstanceDef(data:RewardDef) {
			super(data)
		}


		override public function set data(value:Object):void {
			if(value is RewardDef)
				_rewardDef = value as RewardDef;
			else
			{
				if(value.hasOwnProperty('id'))
					_rewardDef = RewardManager.instance.getById(value['id']);
				if(value.hasOwnProperty('n'))
					levelNumber = value['n'];
				delete(value['id']);
				delete(value['n']);
				super.data = value;
			}
		}
		
		public function get id():int
		{
			return rewardDef.id;	
		}
		
		public function get type():String
		{
			return rewardDef.type;	
		}
		
		public function get degree():int
		{
			return rewardDef.degree;	
		}

		public function get rewardDef():RewardDef
		{
			return _rewardDef;
		}

		public function get size():Point
		{
			return rewardDef.size;
		}

		public function get width():int
		{
			return rewardDef.size.x;
		}

		public function get height():int
		{
			return rewardDef.size.y;
		}
	}
}
