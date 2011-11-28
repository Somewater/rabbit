package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	public class RewardLevelDef extends LevelDef
	{

		public static const WIDTH:int = 10;
		public static const HEIGHT:int = 10;

		private var uniqId:Number = Math.random();

		public function RewardLevelDef()
		{
			super(	<xml id="-1" number="0">
						<conditions>
							<time>2000000000</time>
						</conditions>
						<group>
							<objectReference x="3" y="2" name="Hero"/>
							<objectReference x="1" y="1" name="reward.RewardRabbitHole"/>
						</group>
						<width>{WIDTH}</width>
						<height>{HEIGHT}</height>
					</xml>);
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