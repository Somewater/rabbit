package com.somewater.rabbit.application.effects {
	import com.somewater.effects.BitmapDataPart;
	import com.somewater.effects.Particle;
	import com.somewater.effects.ParticleEffectBase;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;

	public class GameStreamEffect extends ParticleEffectBase{

		public var renderActive:Boolean = false;

		public function GameStreamEffect(w:int, h:int) {
			var symbols:Array = ['effects.SuccessStreamStar_0','effects.SuccessStreamStar_1'];
			var visTypes:Array = [];
			for each(var symbol:String in symbols){
				for (var i:int = 0; i < 6; i++){
				    var mc:MovieClip = Lib.createMC(symbol);
					mc.gotoAndStop(i + 1);
					mc.scaleX = random(0.7, 1.3);
					mc.scaleY = random(0.7, 1.3);
					var ch:DisplayObjectContainer = new Sprite();
					ch.addChild(mc)
					visTypes.push(ch);
				}
			}
			super(visTypes);
			this.width = w;
			this.height = h;
			lifetime = int.MAX_VALUE;
			particleMaximumAll = int.MAX_VALUE;
			emitSpeed = 0.023;
		}


		override protected function render():void {
			if(renderActive)
				super.render();
		}

		override protected function pickNewParticleBDPart():BitmapDataPart {
			if(Math.random() < 0.8)
				return null;
			return super.pickNewParticleBDPart();
		}

		override protected function filterParticle(p:Particle):Boolean {
			return p.x < width + 10;
		}

		override protected function setupParticleSpeed(p:Particle):void {
			p.x = 0;
			p.y = height - 40;
			p.arg1 = Math.PI * Math.random();
			p.arg2 = random(0.001, 0.005);
			p.arg3 = random(30, 50);
		}

		override protected function updateParticleSpeed(p:Particle):void {
			var x:Number = p.age * 0.1;
			p.x = x;
			p.y = height + Math.sin(p.arg1 + p.age * p.arg2) * p.arg3 - 20 - Math.pow(x / width, 0.5) * (height - 40);
		}
	}
}
