package com.somewater.rabbit.iso {
	import com.somewater.display.blitting.PreparativeBlitManager;
	import com.somewater.rabbit.storage.Lib;

	public class RabbitBlitManager extends PreparativeBlitManager{
		public function RabbitBlitManager() {
		}

		override protected function onSlugNotFound(slug:String, state:String, direction:int, frame:int, callback:Function):void {
			var hash:Object = {};
			hash[slug] = Lib.createMC(slug);
			prepare(hash);
			getBlitData(slug, state, direction, frame, callback);
		}
	}
}
