package com.somewater.rabbit
{
	import flash.events.IEventDispatcher;

	/**
	 * Для того, чтобы отличать модульные флешки (лоадер, приложение, игру)
	 * от простых флешек с ассетами
	 */
	public interface IRabbitModule extends IEventDispatcher
	{
		
	}
}