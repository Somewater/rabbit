package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;

	public class RewardLevelDef extends LevelDef
	{

		private var uniqId:Number = Math.random();

		public function RewardLevelDef()
		{
			super(	<xml id="-1" number="0">
						<conditions>
							<time>2000000000</time>
						</conditions>
						<group>
							<objectReference x="3" y="2" name="Hero"/>
							<objectReference x="1" y="1" name="Award">
								<component name="Render" type="com.somewater.rabbit.awards.RabbitHoleRenderer">
									<slug>rabbit.RabbitHole</slug>
								</component>
								<component name="Spatial">
									<size>
										<x>2</x>
										<y>2</y>
									</size>
								</component>
							</objectReference>
						</group>
						<width>10</width>
						<height>10</height>
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