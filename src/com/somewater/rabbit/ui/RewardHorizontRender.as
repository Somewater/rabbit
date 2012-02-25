package com.somewater.rabbit.ui {
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public class RewardHorizontRender extends HorizontRender{
		public function RewardHorizontRender() {
		}

		override public function set darkness(value:Number):void {
			if(value != 0)
				throw new Error('Darkness = ' + value + ' not supported')
		}


		override protected function checkAndCreateBarriers(shift_x:int):void {
			// nothing
		}


		override protected function createHillDisplayObject():DisplayObject {
			var hill:DisplayObjectContainer = Lib.createMC("rabbit.Hill");
			createCompactTrees(hill);
			return hill;
		}

		override protected function createHillTreeDisplayObject():DisplayObject
		{
			return Lib.createMC(
								Math.random() > 0.7 ?
								"rabbit.HillTree_" + int(Math.random() * 2).toString()// лиственное
								:
								"rabbit.HillFir_" + int(Math.random() * 4).toString()// хвойное
							);
		}
	}
}
