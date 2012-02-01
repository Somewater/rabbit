package com.somewater.rabbit.application.tutorial {
	import com.somewater.control.IClear;
	import com.somewater.rabbit.application.commands.ICommand;

	/**
	 * Абстрактный класс для шагов тьюториала
	 */
	public class TutorialStepBase implements ICommand, IClear{

		protected var cleared:Boolean = false;


		public function TutorialStepBase() {
		}

		/**
		 * Приступить к выполнению шага
		 */
		public function execute():void {
		}

		/**
		 * Проверять состояние игры и соверщать нужные действия
		 */
		public function tick():void
		{
		}

		/**
		 *
		 * @return
		 */
		public function completed():Boolean
		{
			throw new Error('Must be override')
		}

		/**
		 * Очистить "за собой" при удалении шага
		 */
		public function clear():void
		{
			cleared = true;
		}

		/**
		 * Номер шага в массиве TutorialManager#STEPS
		 */
		public function get index():int
		{
			var cl:Class = Object(this).constructor;
			return TutorialManager.instance.STEPS.indexOf(cl);
		}
	}
}
