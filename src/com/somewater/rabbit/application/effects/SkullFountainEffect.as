package com.somewater.rabbit.application.effects {
	import com.somewater.effects.Particle;
	import com.somewater.rabbit.storage.Lib;

	import flash.geom.Point;

	public class SkullFountainEffect extends GameFountainEffect{

		private var died:Boolean = false;
		private var const1:Number = 0.02;
		private var handOffsetX:int = 0;
		private var handOffsetY:int = 0;
		private static const BOTTOM_OFFSET:int = 50;

		public function SkullFountainEffect(params:Object) {
			super([Lib.createMC('effect.RabbitSkull')]);
			if(params && params.health <= 0){
				lifetime = 1000;
				emitSpeed = 0.02;
				particleMaximum = 20;
				died = true;
				const1 = 0.01
				handOffsetX = 20;
				handOffsetY = 25;
			} else {
				lifetime = 600;
				emitSpeed = 0.005;
				particleMaximum = 15;
			}
			width = died ? 300 : 200
			height = (died ? 400 : 200);
		}

		override protected function setupParticleSpeed(p:Particle):void {
			p.x = width * 0.5;
			p.y = height;
			p.age = 0;
			p.sign = Math.random() > 0.5 ? 1 : -1;
			p.arg1 = 2 + Math.random() * 0.3;// степень функции
			p.arg2 = random(0.5, 2);
		}

		override protected function updateParticleSpeed(p:Particle):void {
			var x:Number = p.age * 0.1;
			var width:int = this.width * 0.8;
			var height:int = this.height * 0.8;
			p.x = handOffsetX + width * 0.5 + p.sign * x * p.arg2;
			p.y = -BOTTOM_OFFSET + handOffsetY + height - (x - const1 * Math.pow(x, p.arg1)) * 6
			p.alpha = 1 - x * 2 / width;
		}

		override public function getRegistrationPoint():Point {
			return new Point(width * 0.5, height - BOTTOM_OFFSET)
		}

		override protected function filterParticle(p:Particle):Boolean {
			return p.y > -BOTTOM_OFFSET;
		}
	}
}
