package com.somewater.rabbit.ui {
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;

	/**
	 * Рендер для заднего фона обычных уровней. В зависимости от история уровня создает тот или иной задний фон
	 */
	public class LevelHorizontRender extends HorizontRender{

		private const configByStory:Array =
		[
			// 0 (1 огород)
			{
				barrier: "rabbit.Barrier",
				trees: ["rabbit.HillTree_0", "rabbit.HillTree_1"],
				treeFactory: createRareTrees
			}
			,
			// 1 (2 огород)
			{
				barrier: "rabbit.BirchBarrier",
				trees: ["rabbit.HillFir_0","rabbit.HillFir_1","rabbit.HillFir_2","rabbit.HillFir_3"],
				treeFactory: createCompactTrees
			}
		];

		public function LevelHorizontRender() {
		}

		override protected function createHillDisplayObject():DisplayObject
		{
			var hill:DisplayObjectContainer = Lib.createMC("rabbit.Hill");
			var func:Function = config['treeFactory'];
			func(hill);
			return hill
		}

		override protected function createBarrierDisplayObject():DisplayObject
		{
			var barrier:DisplayObjectContainer = Lib.createMC(config['barrier']);
			return barrier;
		}

		override protected function createHillTreeDisplayObject():DisplayObject
		{
			var treeVariants:Array = config['trees'];
			var tree:DisplayObject = Lib.createMC(treeVariants[int(treeVariants.length * Math.random())]);
			return tree;
		}

		// 0..
		private function get config():Object
		{
			return configByStory[Math.min(configByStory.length - 1, Config.game.level.story ? Config.game.level.story.number : int.MAX_VALUE)];
		}
	}
}
