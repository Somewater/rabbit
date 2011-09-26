package com.somewater.rabbit.logic
{
	import com.pblabs.engine.core.IPrioritizable;
	import com.pblabs.engine.entity.IEntityComponent;
	
	/**
	 * Компоненты, отвечающие за "чувствование" чего-либо
	 * При необходимости (или по запросу) отправляют команду в LogicController
	 */
	public interface ISentientComponent extends IEntityComponent, IPrioritizable
	{
		/**
		 * Установить callback, в который направляется результат работы контроллера 
		 * (команда для LogicController)
		 * 
		 * portCallback:Function == function()
		 */
		function set port(portCallback:Function):void
			
		/**
		 * Осуществить действие, которое контроллер считает нужным выполнить на основе его восприятия
		 * @param sense Событие, которое задиспатчил компонент и которое, в конечном счете, привело 
		 * к вызову кем-то функци startAction
		 */
		function startAction(sense:SenseEvent):void
			
		
		/**
		 * Продолжить действие, согласно чувству
		 */
		function action():void

		
		
		/**
		 * Прервать действие (т.к. управление пеердается другому контроллеру)
		 */
		function breakAction():void


			
		/**
		 * Заставить контроллер "прочувствовать". После этого контроллер, 
		 * если счтиает нужным, выдает ответ в callback port и (или) диспатчит событие SenseEvent
		 */
		function analyze():void
			
		function set driven(value:Boolean):void
	}
}