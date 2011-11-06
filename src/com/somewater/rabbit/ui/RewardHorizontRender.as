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
			var randomTreesAll:int;
			var randomTrees:int = 15;
			var lastTreePos:int = 10;
			while(randomTrees >= 0)
			{
				var tree:DisplayObject = getTree();
				hill.addChild(tree);
				tree.x = lastTreePos;
				tree.y = -30 * Math.random() - 15;
				lastTreePos = lastTreePos + tree.width * 0.5 * (1.2 + Math.random() * 0.6);
				if(randomTrees == 0 || lastTreePos > HILL_WIDTH)
				{
					tree.x = HILL_WIDTH;
					break;
				}
				randomTrees--;
			}
			return hill

			function getTree():DisplayObject
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
}
