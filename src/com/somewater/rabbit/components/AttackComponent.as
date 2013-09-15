package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.core.PBSet;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.somewater.rabbit.States;
	import com.somewater.rabbit.iso.IsoMover;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.logic.SenseEvent;
	import com.somewater.rabbit.logic.SentientComponent;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * Производит атаку на определенные объекты
	 * (но при условии, что LogicComponent позволяет атаковать,
	 * например могут быть задачи важнее, чем атаковать)
	 * 
	 */
	public class AttackComponent extends FinderComponentBase
	{		
		/**
		 * Сила атаки
		 * (Для персонажей, атакующих недискретно, кол-во жизни, отнимаемое за секунду)
		 */
		public var attackRange:Number = 1;
		
		/**
		 * Интервал времени между атаками (в миллисекундах)
		 */
		public var attackInterval:int = 1000;
		
		/**
		 * Сколько времени макисмально персонаж может атаковать (мс)
		 * По прошествию этого промежутка, атака прекращается (персонаж "устает")
		 * Если равно 0, персонаж атакует 1 раз
		 */
		public var attackDuration:int = 1;
		
		private var startAttackTime:int;
		
		/**
		 * Время последней атаки. Компонент не может атаковать непрерывно
		 * в миллисекундах, считая от старта флешки
		 */
		private var lastAttackTime:Number = Number.MIN_VALUE;
		
		/**
		 * Хранит ссылки на атакуемые объекты
		 */
		protected var victims:Dictionary;
		
		/**
		 * Повешен ли листенер на @Mover
		 */
		private var moverListenerEnabled:Boolean = false;
		
		/**
		 * На сколько мс задержаться на анимационном стейте "attack"
		 * если персонаж атакует дискретно
		 */
		public var attackRendererDuration:int = 200;

		
		protected var renderStateRef:PropertyReference = new PropertyReference("@Render.state");
		
		protected var renderViewPointRef:PropertyReference = new PropertyReference("@Render.viewPoint");
		
		protected var dataComponentRef:PropertyReference = new PropertyReference("@Data");
		
		protected var positionRef:PropertyReference = new PropertyReference("@Spatial.position");
		
		public function AttackComponent()
		{
			super();
			initialize();
		}

		public function initialize():void {
			registerForTicks = true;
		}
		
		override protected function onAdd():void
		{
			owner.eventDispatcher.addEventListener(IsoMover.TILE_CHANGED, onTileChanged);
			super.onAdd();
		}
		
		override protected function onRemove():void
		{
			owner.eventDispatcher.removeEventListener(IsoMover.TILE_CHANGED, onTileChanged);
			super.onRemove();
		}
		
		private function onTileChanged(e:Event):void
		{
			analyze();
		}
		
		/**
		 * Анализировать, не располагается ли victim в пределах радиуса атаки
		 */
		override public function analyze():void
		{
			if(PBE.processManager.virtualTime - lastAttackTime < attackInterval)
				return;// недавно была атака, нельзя атаковать так часто
			
			var victims:Array = searchVictims();
			if(victims.length)
			{
				_port(getSense({"victims":victims}, "attack"));
			}
		}
		
		
		/**
		 * Атаковать атакуемого(ых)
		 */
		override public function startAction(sense:SenseEvent):void
		{
			var victioms:Array = sense.data.victims;
			this.victims = new Dictionary();
			var victimsLength:int = 0;
			var victim:IEntity;
			var victimAttacked:Boolean = false;
			if(victioms)
			{
				var l:int = victioms.length;
				for(var i:int = 0;i<l;i++)
					if(IsoSpatial(victioms[i]).isRegistered)
					{
						victim = IsoSpatial(victioms[i]).owner;
						if(attackDuration == 0)
						{
							if(processAttack(victim, attackRange))
								victimAttacked = true;
						}
						else
						{
							this.victims["victim_" + victimsLength] = victim;
							victimsLength++;
						}
					}
			}
			
			startAttackTime = lastAttackTime = PBE.processManager.virtualTime;
			if(victimAttacked)
				owner.setProperty(renderStateRef, States.ATTACK);
			
			// закончить процесс атаки
			if(attackDuration == 0)
			{
				_port(null);
			}
		}
		
		
		override public function action():void
		{
			var virtTime:Number = PBE.processManager.virtualTime;
			var attack:Number = (virtTime - lastAttackTime) * 0.001 * attackRange;
			var position:Point = owner.getProperty(positionRef);
			var sqrRadius:Number = searchRadius * searchRadius;
			var hasVictims:Boolean = false;
			lastAttackTime = virtTime;
			
			for(var key:String in victims)
			{
				var victim:IEntity = victims[key];
				var victimPos:Point = victim.getProperty(positionRef);
				if (!victimPos || (Math.pow(victimPos.x - position.x, 2) + Math.pow(victimPos.y - position.y, 2)) > sqrRadius)
				{
					// персонаж убежал
					delete victims[key];
				}
				else
				{
					if(processAttack(victim, attack))
						hasVictims = true;
				}
			}
			
			if(!hasVictims)
			{
				// заканчиваем атаковать жертву (жертв)
				victims = null;
				_port(null);
			}
			else
			{
				owner.setProperty(renderStateRef, States.ATTACK);
			}
		}
		
		
		override public function breakAction():void
		{
			victims = null;
			
			// если персонаж атакует дискретно, вызываем смену стейта атаки на stand с задержкой, 
			// чтобы хотя бы некоторое время демонстрировать анимацию attack
			if(attackDuration == 0)
				PBE.processManager.schedule(attackRendererDuration, this, revertState);
			else
				revertState();
			
			function revertState():void
			{
				if(!_owner) return;
				if(owner.getProperty(renderStateRef) == States.ATTACK)
					owner.setProperty(renderStateRef, States.STAND);
			}
		}

		/**
		 * @param victim
		 * @param attack
		 * @return жертву получилось атаковать (жертва в данный момент не защищена особой магией и подвержена атаке
		 */
		protected function processAttack(victim:IEntity, attack:Number):Boolean
		{
			if(!victim) return false;
			
			// повернуться лицом к жертве
			var victimPos:Point = victim.getProperty(positionRef);
			owner.setProperty(renderViewPointRef, victimPos);
			
			// и убить её
			var data:DataComponent = victim.getProperty(dataComponentRef);

			// если это кролик и он под защитой, мы не можем атаковать
			if(data is HeroDataComponent && HeroDataComponent(data).protectedFlag > 0)
				return false;

			if(data)
			{
				data.health -= attack;
				return true;
			}
			else
				return false;
		}
	}
}