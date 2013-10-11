package com.somewater.effects {
import com.somewater.effects.Particle;

import flash.display.DisplayObject;
	import flash.geom.Point;

	public class FountainEffect extends ParticleEffectBase {
	

	public function FountainEffect(visualTypes:Array) {
		super(visualTypes);
	}

	override protected function filterParticle(p:Particle):Boolean {
		return p.x > 0 && p.x < this.width && p.y < height && p.alpha > 0;
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
		p.x = width * 0.5 + p.sign * x * p.arg2;
		p.y = height - (x - 0.01 * Math.pow(x, p.arg1)) * 12
		p.alpha = 1 - x * 2 / width;
		//trace("age " + x + " " + int(p.x) + "," + int(p.y))
	}


	override public function getRegistrationPoint():Point {
		return new Point(width * 0.5, height)
	}
}
}