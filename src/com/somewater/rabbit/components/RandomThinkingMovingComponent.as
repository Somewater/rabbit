package com.somewater.rabbit.components
{
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.util.RandomizeUtil;

	/**
	 * Аналогично RandomMovingComponent, однако перед началом движения переводит персонаж
	 * в стейт "think"
	 */
	public class RandomThinkingMovingComponent extends RandomMovingComponent
	{
		private var renderstateRef:PropertyReference;
		
		/**
		 * Как долго персонаж "думает" перед началом движения, минимум (ms)
		 */
		public var minThinkTime:int = 1000;
		
		/**
		 * Как долго персонаж "думает" перед началом движения, максимум (ms)
		 */
		public var maxThinkTime:int = 2000;
		
		public function RandomThinkingMovingComponent()
		{
			super();
			
			renderstateRef = new PropertyReference("@Render.state");
		}
		
		override protected function randomAct():void
		{
			if(!_owner) return;
			
			think(onThinkStateComplete, minThinkTime + RandomizeUtil.rnd * (maxThinkTime - minThinkTime));
			owner.setProperty(renderstateRef, States.THINK);
		}
		
		
		public function onThinkStateComplete():void
		{
			if(!_owner) return;
			
			// передать управление расширяемому методу, который выберет точку и пошлет в неё персонажа
			super.randomAct();
		}
		
		override protected function planeRandomAct():void
		{
			owner.setProperty(renderstateRef, States.STAND);
			
			super.planeRandomAct();
		}
	}
}