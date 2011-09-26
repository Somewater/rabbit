package com.somewater.common.util
{
	import flash.display.MovieClip;
	
	public class CopyMovieClipProps
	{
		
		//public static var props : Array = ['transform', 'alpha', 'visible', 'blendMode', 'scale9Grid', 'rotation'];
		public static var props : Array = ['width', 'height', 'x', 'y', 'alpha', 'visible', 'blendMode', 'scale9Grid', 'rotation'];
		
		public static function copyProps(mcFrom:MovieClip, mcTo:MovieClip) : void
		{
			for each (var prop : String in props) {
				mcTo[prop] = mcFrom[prop];
			}
		}
	}
}