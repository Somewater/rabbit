package com.somewater.rabbit.storage
{
	public class RewardLevelDef extends LevelDef
	{

		public static const WIDTH:int = 9;
		public static const HEIGHT:int = 10;

		private var uniqId:Number = Math.random();

		public var gameUser:GameUser;

		public function RewardLevelDef(gameUser:GameUser)
		{
			this.gameUser = gameUser;
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
			for each(var r:RewardInstanceDef in gameUser.rewards)
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
	}
}