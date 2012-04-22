package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.storage.LevelDef;

	public class TutorialLevelDef extends LevelDef{

		public static const TYPE:String = 'TutorialLevel';

		public static const WIDTH:int = 14;
		public static const HEIGHT:int = 10;

		private var uniqId:int = 1000 * Math.random();

		public function TutorialLevelDef() {
			var xml:XML =
			<level id="369" version="16">
				<description></description>
				<number>1</number>
				<author>dev</author>
				<width>{WIDTH}</width>
				<height>{HEIGHT}</height>
				<image>image.CursorKeys</image>
				<conditions>
					<time>150</time>
					<carrotMin>2</carrotMin>
					<carrotAll>10</carrotAll>
					<carrotMiddle>5</carrotMiddle>
					<carrotMax>10</carrotMax>
				</conditions>
				<group>
					<objectReference x="10" y="3" name="Bush" hash="07ni0b7eq8"/>
					<objectReference x="13" y="1" name="Bush" hash="0t5sphbnx1"/>
					<objectReference x="6" y="0" name="Bush" hash="23248rgtto"/>
					<objectReference x="5" y="0" name="Bush" hash="2foftdjpos"/>
					<objectReference x="12" y="9" name="Bush" hash="2ijueea1fn"/>
					<objectReference x="13" y="8" name="Bush" hash="2y0lfymkn3"/>
					<objectReference x="5" y="5" name="Bush" hash="3vxi0qs37u"/>
					<objectReference x="3" y="8" name="Bush" hash="3w6h3quv0n"/>
					<objectReference x="4" y="9" name="Bush" hash="5devjz5p02"/>
					<objectReference x="8" y="0" name="Bush" hash="5dmrikcvpu"/>
					<objectReference x="9" y="0" name="Bush" hash="5ds1wgraxa"/>
					<objectReference x="10" y="5" name="Bush" hash="71vy0o5l07"/>
					<objectReference x="3" y="9" name="Bush" hash="721kjyocg4"/>
					<objectReference x="13" y="9" name="Bush" hash="7bhu0n0j2n"/>
					<objectReference x="0" y="1" name="Bush" hash="8hg3e8l6vc"/>
					<objectReference x="9" y="4" name="Bush" hash="9a6cxz0dfm"/>
					<objectReference x="8" y="9" name="Bush" hash="9ge65kzohc"/>
					<objectReference x="3" y="7" name="Bush" hash="9zi3gss2ez"/>
					<objectReference x="7" y="4" name="Bush" hash="b3itv9d16b"/>
					<objectReference x="7" y="9" name="Bush" hash="bb2uaf53ew"/>
					<objectReference x="5" y="6" name="Bush" hash="djrju5e1a6"/>
					<objectReference x="7" y="0" name="Bush" hash="i26chsj45h"/>
					<objectReference x="9" y="9" name="Bush" hash="i7zjcb3smf"/>
					<objectReference x="4" y="0" name="Bush" hash="i89ok6gw4k"/>
					<objectReference x="10" y="9" name="Bush" hash="ijntdz3di1"/>
					<objectReference x="6" y="9" name="Bush" hash="jyfemomkae"/>
					<objectReference x="0" y="0" name="Bush" hash="k4sclavcaf"/>
					<objectReference x="11" y="4" name="Bush" hash="kmfn4ktyox"/>
					<objectReference x="5" y="2" name="Bush" hash="kppeqwov0a"/>
					<objectReference x="3" y="6" name="Bush" hash="ldz0bqazmw"/>
					<objectReference x="0" y="3" name="Bush" hash="mrbkciibp3"/>
					<objectReference x="12" y="5" name="Bush" hash="mzjh4ou0wb"/>
					<objectReference x="12" y="3" name="Bush" hash="ntcavuyaur"/>
					<objectReference x="1" y="0" name="Bush" hash="ohpba0cfcp"/>
					<objectReference x="13" y="2" name="Bush" hash="ozw6xxz0sn"/>
					<objectReference x="3" y="0" name="Bush" hash="q2fzqk90sg"/>
					<objectReference x="2" y="0" name="Bush" hash="qgnu63bcjg"/>
					<objectReference x="5" y="9" name="Bush" hash="qyrt9qawro"/>
					<objectReference x="11" y="9" name="Bush" hash="rsqqnsrabm"/>
					<objectReference x="8" y="5" name="Bush" hash="rv4zbir694"/>
					<objectReference x="0" y="4" name="Bush" hash="shgwnusvop"/>
					<objectReference x="5" y="3" name="Bush" hash="skc9jguodu"/>
					<objectReference x="13" y="5" name="Bush" hash="t3kqzkwxo0"/>
					<objectReference x="5" y="1" name="Bush" hash="t795iuffn9"/>
					<objectReference x="11" y="0" name="Bush" hash="tb1d7wposq"/>
					<objectReference x="13" y="3" name="Bush" hash="tro92g8pzr"/>
					<objectReference x="10" y="0" name="Bush" hash="ufq21euyr6"/>
					<objectReference x="13" y="4" name="Bush" hash="vrkeclvuta"/>
					<objectReference x="13" y="7" name="Bush" hash="vzhrnz5jdm"/>
					<objectReference x="0" y="2" name="Bush" hash="wrh7g66tkq"/>
					<objectReference x="13" y="0" name="Bush" hash="xi6hfajtv6"/>
					<objectReference x="12" y="0" name="Bush" hash="xxbdf79cbi"/>
					<objectReference x="8" y="3" name="Bush" hash="z85qhhqbgf"/>
					<objectReference x="5" y="4" name="Bush" hash="za8b2tuxrk"/>
					<objectReference x="13" y="6" name="Bush" hash="ze4cwxe6mw"/>
					<objectReference x="11" y="5" name="Carrot" hash="1qf5cgx2pk"/>
					<objectReference x="4" y="2" name="Carrot" hash="32gld2novo"/>
					<objectReference x="8" y="4" name="Carrot" hash="8sdnyhbq68"/>
					<objectReference x="7" y="5" name="Carrot" hash="bbts9fajt7"/>
					<objectReference x="4" y="3" name="Carrot" hash="eisi53ye5b"/>
					<objectReference x="12" y="4" name="Carrot" hash="g1imh3y3ft"/>
					<objectReference x="10" y="4" name="Carrot" hash="lw7x0fr0f0"/>
					<objectReference x="3" y="3" name="Carrot" hash="nlmvzeqx7d"/>
					<objectReference x="3" y="2" name="Carrot" hash="pynxmmz8zk"/>
					<objectReference x="9" y="5" name="Carrot" hash="ueu6xvjg1c"/>
					<objectReference x="7" y="1" name="Hedgehog" hash="hw4t1l27fn"/>
					<objectReference x="1" y="2" name="Hero" hash="y8sh1t9d1d"/>
					<objectReference x="0" y="5" name="Pool4" hash="jxeg5dpjos"/>
					<objectReference x="2" y="5" name="Pool4" hash="r9li0uclgc"/>
					<objectReference x="12" y="1" name="WeakWatchDog" hash="xj32xrmaa4"/>
				</group>
			</level>
			super(xml);
		}

		override public function get groupName():String
		{
			return "RewardLevelGroup_" + uniqId;
		}

		override public function get type():String
		{
			return TYPE;
		}
	}
}
