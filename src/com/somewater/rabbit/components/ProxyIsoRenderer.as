package com.somewater.rabbit.components {
	import com.somewater.rabbit.iso.IsoRenderer;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;

	/**
	 * На слой добавляется спрайт, а сам ассет является чайлдом этого спрайта
	 * (в обычных условиях на слой добавляется сам ассет)
	 *
	 * Применяется для добавления объекту дополнительных визуальных элементов
	 * (которые становятся дополнительными чайлдами холдера)
	 */
	public class ProxyIsoRenderer extends IsoRenderer{

		public var holder:Sprite;
		public var asset:MovieClip;

		public function ProxyIsoRenderer() {
		}

		/**
		 * Если происходит попытка присвоения мувиклипа, создаем для него холдер
		 * @param value
		 */
		override public function set displayObject(value:DisplayObject):void {
			if(holder == null)
			{
				holder = new Sprite();
				asset = value as MovieClip;
				holder.addChild(value);
			}
			else
				throw new Error('Asset already added');

			super.displayObject = holder;
		}
	}
}
