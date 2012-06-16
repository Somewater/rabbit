package com.somewater.display.blitting {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;

	/**
	 * Класс-заместитель для использования вместо MovieClip
	 */
	public interface IBlitted {

		/**
		 * Запрашивать анимацию у указанного мувика
		 * @param slug
		 */
		function initialize(slug:String):void

		/**
		 * Перевести анимацию на указанный стейт-дирекшн, в первый кадр
		 * @param state
		 * @param direction
		 */
		function goto(state:String, direction:int):void

		/**
		 * Передвинуть анимацию на указанное число кадров вперед
		 * (если анимация дошла до конца, то начать сначала и учесть оставшееся число кадров)
		 * @param frames
		 */
		function next(frames:int = 1):void

		/**
		 * для добавления в дисплей лист, как правило, возвращает Bitmap
		 */
		function get displayObject():DisplayObject;
	}
}
