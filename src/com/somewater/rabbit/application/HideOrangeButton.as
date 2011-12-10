package com.somewater.rabbit.application
{
	import com.gskinner.geom.ColorMatrix;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.Sprite;

	import flash.filters.ColorMatrixFilter;

	/**
	 * Кнопак для соц сетей, которая должна присутствовать, но которую "не хочется нажимат"
	 */
	public class HideOrangeButton extends OrangeButton
	{
		public function HideOrangeButton()
		{
			super();
		}

		override protected function createGround(type:String):Sprite {
			return Lib.createMC("interface.ShadowOrangeButton_" + type);
		}
	}
}