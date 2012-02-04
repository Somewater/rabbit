package com.somewater.rabbit.application.tutorial {
	import com.somewater.rabbit.application.LevelsPage;
	import com.somewater.rabbit.application.RewardLevelGUI;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.RewardLevelDef;
	import com.somewater.storage.Lang;

	import flash.utils.getTimer;

	public class TutorialStep12 extends TutorialStepBase{

		/**
		 * Посмотреть на ТОП
		 */
		public function TutorialStep12() {
		}

		override public function completed():Boolean
		{
			return true;
		}
	}
}
