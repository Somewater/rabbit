package com.somewater.rabbit.creature
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.core.PBSet;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.ObjectMask;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.components.RandomActComponent;
	import com.somewater.rabbit.util.RandomizeUtil;
	
	/**
	 * Переводит коспонент в "злое"-"нормальное" состояние через состояние "think"
	 * специально для морковок
	 */
	public class CarrotAngryComponent extends RandomActComponent
	{
		/**
		 * Стейт персонажа:
		 */
		private var angryState:Boolean = false;
		
		private var renderstateRef:PropertyReference;
		
		/**
		 * Как долго персонаж может быть злым, минимум (ms)
		 */
		public var minAngryTime:int = 3000;
		
		/**
		 * Как долго персонаж может быть злым, максимум (ms)
		 */
		public var maxAngryTime:int = 5000;

		/**
		 * Кол-во миллисекунд перед тем как стать злой
		 */
		public var transformationDuration:int = 2000;
		
		private var switchAttackComponentRef:PropertyReference; 
		private var drivingAttackComponentRef:PropertyReference; 
		private var harvestableFlag:PropertyReference;
		
		public function CarrotAngryComponent()
		{
			super();
			
			switchAttackComponentRef = new PropertyReference("@Attack.enabled");
			drivingAttackComponentRef = new PropertyReference("@Attack.driving");
			renderstateRef = new PropertyReference("@Render.state");
			harvestableFlag = new PropertyReference("@Harvestable.harvestableFlag");
		}
		
		override protected function randomAct():void
		{
			if(!_owner || angryState) return;

			owner.setProperty(renderstateRef,States.PRETHINK);
			think(prethinkComplete, transformationDuration)
		}

		/**
		 * Уже отбыл достаточное время в состоянии превращения в злую, можно стать по настоящему злой
		 */
		private function prethinkComplete():void {
			if(!_owner || angryState) return;

			// переход в состояния злости
			setAngryState(true);
			planeAngryStateExit();
		}
		
		/**
		 * Запланировать выход из состояния злости
		 */
		private function planeAngryStateExit():void
		{
			think(exitAngryState, minAngryTime + RandomizeUtil.rnd * (maxAngryTime - minAngryTime));
		}
		
		/**
		 * Выйти из состояния злости
		 */
		private function exitAngryState():void
		{
			if(!_owner || !angryState) return;
			
			// определяем, что морковка кого-то атакует
			var attackState:Boolean = owner.getProperty(drivingAttackComponentRef, false);
			
			if(attackState)
			{
				// не делаем ничего, чтио фактически значит, что морковка навсегда останется в стейте атаки
				//planeAngryStateExit();
			}
			else
			{
				setAngryState(false);
				planeRandomAct();
			}
		}
		
		private function setAngryState(angry:Boolean):void
		{
			if(angryState == angry) return;
			
			angryState = angry;
			owner.setProperty(switchAttackComponentRef, angry);
			owner.setProperty(harvestableFlag, !angry);
			owner.setProperty(renderstateRef, angry ? States.THINK : States.STAND);
		}
	}
}