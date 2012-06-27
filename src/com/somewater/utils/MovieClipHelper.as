/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/24/11
 * Time: 1:26 AM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.utils {
	import flash.display.MovieClip;

	public class MovieClipHelper {
		public function MovieClipHelper() {
		}

		public static function stopAll(mc:MovieClip):void
		{
			mc.stop();
			for (var i:int = 0; i < mc.numChildren; i++) {
				var child:MovieClip = mc.getChildAt(i) as MovieClip;
				if (child)
					stopAll(child);
			}
		}
	}
}
