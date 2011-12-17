package com.somewater.rabbit.storage
{
	import com.somewater.rabbit.IUserLevel;

	public class RewardLevelDef extends LevelDef implements IUserLevel
	{

		public static const WIDTH:int = 9;
		public static const HEIGHT:int = 10;

		private var uniqId:Number = Math.random();

		private var _gameUser:GameUser;

		public function RewardLevelDef(gameUser:GameUser)
		{
			this._gameUser = gameUser;
			var xml:XML = <xml id="-1" number="0">
								<conditions>
									<time>2000000000</time>
								</conditions>
								<group>
									<objectReference x="3" y="2" name="Hero"/>
									<objectReference x="1" y="1" name="reward.RewardRabbitHole"/>
								</group>
								<width>{WIDTH}</width>
								<height>{HEIGHT}</height>
							</xml>;
			for each(var r:RewardInstanceDef in _gameUser.rewards)
			{
				var name:String = r.rewardDef.template.@name
				XML(xml.group).appendChild(<objectReference x={r.x} y={r.y} name={name}/>)
			}
			super(xml);
		}

		override public function get groupName():String
		{
			return "RewardLevelGroup_" + uniqId;
		}

		override public function get type():String
		{
			return 'RewardLevel';
		}


		override public function get additionSwfs():Array {
			return super.additionSwfs.concat({name:"Rewards"});
		}

		public function get gameUser():GameUser
		{
			return _gameUser;
		}
	}
}