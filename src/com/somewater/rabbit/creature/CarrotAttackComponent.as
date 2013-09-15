package com.somewater.rabbit.creature
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.components.DataComponent;
	import com.somewater.rabbit.components.HeroDataComponent;
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
		}
		
		/**
		 * Откладываем "убийство" кролика, т.к. кролик должен исчезнуть не сейчас, 
		 * а когда морковка наклонится к нему
		 */
		override protected function processAttack(victim:IEntity, attack:Number):Boolean
		{
			if(!victim) return false;

			var data:HeroDataComponent = victim.getProperty(dataComponentRef) as HeroDataComponent;
			var victimIsoMover:IsoMover = victim.lookupComponentByType(IsoMover) as IsoMover;
			if(data == null
					|| data.protectedFlag > 0 // жерта под защитой
					|| victimIsoMover.speed <= 0.05) // жетву уже кто-то замедлил (другая злая морковка)
				return false;
			
			// повернуться лицом к жертве
			var victimPos:Point = victim.getProperty(positionRef);
			owner.setProperty(renderViewPointRef, victimPos);
			
			// и убить её
			if(data)
			{
				PBE.processManager.schedule(1000, this, function(data:DataComponent, attack:Number):void{
					data.health -= attack;
				}, data, attack);
				HeroIsoMover(victim.lookupComponentByType(IsoMover)).pinHero();
			}

			return true;
		}
	}
}