package com.somewater.display
{
	import flash.display.Sprite;
	
	/**
	 * Отличается от обыкновенного спрайта тем, что определяет свои свойства width,height
	 * согласно опросу аналогичных свойств своих child. Удобен для добавления на него
	 * элементов UI с переопределенными width,height
	 */
	public class CorrectSizeDefinerSprite extends Sprite
	{
		private var paddingX:Number;
		private var paddingY:Number;
		
		public function CorrectSizeDefinerSprite(paddingX:Number = 0, paddingY:Number = 0)
		{
			super();
			this.paddingX = paddingX;
			this.paddingY = paddingY;
		}
		
		override public function get width():Number{
			var value:Number = 0;
			for (var i:int = 0;i<numChildren;i++){
				var newValue:int = getChildAt(i).x + getChildAt(i).width;
				if (newValue > value)
					value = newValue;
			}
			return value + paddingX// + 0.000001;// KLUDGE
		}
		
		override public function get height():Number{
			var value:Number = 0;
			for (var i:int = 0;i<numChildren;i++){
				var newValue:int = getChildAt(i).y + getChildAt(i).height;
				if (newValue > value)
					value = newValue;
			}
			return value + paddingY// + 0.000001;// KLUDGE
		}
	}
}