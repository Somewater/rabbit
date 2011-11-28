package com.somewater.rabbit.application {
	import com.somewater.rabbit.storage.RewardDef;

	public class RewardManager {

		private static var _instance:RewardManager;

		private var rewardsByType:Array;
		private var rewardsById:Array;
		private var rewards:Array;
		private var xmlById:Array;

		public function RewardManager() {
			if(_instance)
				throw new Error('Singletone')
			_instance = this;
		}

		public static function get instance():RewardManager
		{
			if(_instance == null)
				new RewardManager();
			return _instance;
		}

		public function initialize(rewards_xml:XML):void
		{
			rewardsByType = [];
			rewardsById = [];
			rewards = [];
			xmlById = [];

			for each(var template:XML in rewards_xml.*)
			{
				var reward:RewardDef = new RewardDef(	template.@id,
														template.@type,
														template.hasOwnProperty('@degree') ? template.@degree : 0
													);
				reward.template = template;
				if(rewardsByType[reward.type] == null)
					rewardsByType[reward.type] = [];
				rewardsByType[reward.type].push(reward);
				if(rewardsById[reward.id] != null)
					throw new Error('Double reward id #' + reward.id)
				rewardsById[reward.id] = reward;
				xmlById[reward.id] = template.copy();
				rewards.push(reward)
			}

			rewards.sortOn('id', Array.NUMERIC);
			for each(var typeRewards:Array in rewardsByType)
			{
				typeRewards.sortOn(['degree', 'id'], Array.NUMERIC);
			}
		}

		public function getByType(type:String):Array
		{
			if(rewardsByType[type])
				return rewardsByType[type];
			else
				return [];
		}

		public function getById(id:int):RewardDef
		{
			return rewardsById[id];
		}

		public function getXMLById(id:int):XML
		{
			return xmlById[id];
		}

		public function getRewards():Array
		{
			return rewards
		}
	}
}
