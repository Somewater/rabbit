package com.somewater.rabbit.creature
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.components.DataComponent;
	import com.somewater.rabbit.components.SwitchableAttackComponent;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	
	import flash.geom.Point;
	
	/**
	 * После атаки на кролика, компонент уже не переводит персонаж в стейт "stand"
	 * т.к. атака морковки смертельна (торчат уши кролика)
	 */
	public class CarrotAttackComponent extends SwitchableAttackComponent
	{
		public function CarrotAttackComponent()
		{
			super();
		}
		
		override public function breakAction():void
		{
			victims = null;
			
			// в отличае от оригинальной функции, не только не переводим персонаж в стейт stand
			// но даже специально фиксируем его в стейте attack (анимация "уши кролика торчат из морковки")
			owner.setProperty(renderStateRef, States.ATTACK);
		}
		
		/**
		 * Откладываем "убийство" кролика, т.к. кролик должен исчезнуть не сейчас, 
		 * а когда морковка наклонится к нему
		 */
		override protected function processAttack(victim:IEntity, attack:Number):void
		{
			if(!victim) return;
			
			// повернуться лицом к жертве
			var victimPos:Point = victim.getProperty(positionRef);
			owner.setProperty(renderViewPointRef, victimPos);
			
			// и убить её
			var data:DataComponent = victim.getProperty(dataComponentRef);
			if(data)
			{
				PBE.processManager.schedule(1000, this, function(data:DataComponent, attack:Number):void{
					data.health -= attack;					
				}, data, attack);
			}
			
			// заодно выставим кролику скорость на 0, чтобы он не убежал :)
			IsoMover(victim.lookupComponentByType(IsoMover)).speed = 0.05;
		}
	}
}