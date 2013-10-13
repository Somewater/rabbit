package com.somewater.rabbit.application.effects {
	import com.somewater.effects.Particle;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.MovieClip;

	public class ShineEffect extends GameFountainEffect{
		public function ShineEffect(params:Object) {
			var visObjects:Array = [];
			for (var i:int = 0; i < 3; i++) {
				var o:MovieClip = Lib.createMC('effect.ShineStar');
				o.gotoAndStop(i + 1);
				visObjects.push(o);
			}
			super(visObjects)
			lifetime = 1000;
			emitSpeed = 0.01;
			particleMaximum = 40;
			width = 200
			height = 200;
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
			p.x = width * 0.5 + p.sign * x * p.arg2;
			p.y = height - (x - 0.02 * Math.pow(x, p.arg1)) * 6
			p.alpha = 1 - x * 2 / width;
		}
	}
}
