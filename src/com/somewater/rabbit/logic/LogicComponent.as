package com.somewater.rabbit.logic
{
	import com.pblabs.engine.components.ThinkingComponent;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.core.ITickedObject;
	
	/**
	 * Отвечает за логику персонажей, которые могут выбирать модель 
	 * поведения на основе указания нескольких компонентов.
	 * Данный класс руководит работой компонентов типа
	 */
	public class LogicComponent extends TickedComponent
	{
		
		/**
		 * Массив компонентов ISentientComponent
		 */
		public var sentients:Array = [];
		
		
		/**
		 * Компонент, который принят "за главного" на данный момент. Если null, 
		 * значит надо пройти по всем подобным компонентам и выбрать новый currentSentient
		 */ 
		public var currentSense:SenseEvent;
		
		/**
		 * Означает, что currentSentient не определен и производится выбор
		 * компонента на его роль
		 */
		protected var interviewFlag:Boolean = false;
		
		/**
		 * Запрос, который во время интервью считается наиболее приоритетным на данный момент
		 */
		private var interviewCandidate:SenseEvent;
		
		
		public function LogicComponent()
		{
			super();
		}
		
		
		override public function onTick(deltaTime:Number):void
		{
			if(currentSense)
			{
				// передать управление текущему компоненту чувства
				currentSense.creator.action();
			}else
			{
				// выбрать новый текущий
				interviewFlag = true;
				
				for(var i:int = 0;i<sentients.length;i++)
				{

					ISentientComponent(sentients[i]).analyze();
				}
				
				currentSense = interviewCandidate;
				
				interviewFlag = false;
				interviewCandidate = null;
				
				if(currentSense)
				{
					currentSense.creator.driven = true;
					currentSense.creator.startAction(currentSense);
				}
			}
		}
		
		
		/**
		 * Принимает события от компонентов
		 * Если sense == null, значит это событие от текущего компонента, который желает завершить свою работу
		 */
		public function port(sense:SenseEvent):void
		{
			if(interviewFlag)
			{
				// null означает ошибку и не несет никакого значения
				if(sense == null) return;
				
				// обработать как запрос во время интервью
				if(interviewCandidate == null || interviewCandidate.priority < sense.priority)
					interviewCandidate = sense;
				
			}else{
				// обработать незапланированный запрос
				
				if(sense == null)
				{
					// завершить текущее событие
					if(currentSense)
					{
						currentSense.creator.driven = false;
						currentSense.creator.breakAction();
					}
					
					currentSense = null;
					return;
				}
				
				if(currentSense == null || sense.priority >= currentSense.priority)
				{
					// поменять текущий управляющий компонент ан новый
					if(currentSense)
					{
						currentSense.creator.driven = false;
						currentSense.creator.breakAction();
					}
					
					currentSense = sense;
					currentSense.creator.driven = true;
					currentSense.creator.startAction(currentSense);
				}
			}
		}
		
		
		override protected function onReset():void
		{
			// при изменении набора компонентов у owner-а, обеспечить, чтобы все 
			// ISentientComponent имели ссылку на port и содержались в массиве sentients
			sentients = owner.lookupComponentsByType(ISentientComponent);
			
			for(var i:int = 0;i<sentients.length;i++)
			{
				ISentientComponent(sentients[i]).port = this.port;
			}
		}
	}
}