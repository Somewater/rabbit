package com.somewater.rabbit.application.tutorial {
	import com.somewater.control.IClear;

	/**
	 * Интерфейс как для сообщений в GUI, так и сообщений от кролика в игре
	 */
	public interface ITutorialMessage extends IClear{

		function set toLeft(value:Boolean):void

		function set top(value:Boolean):void
	}
}
