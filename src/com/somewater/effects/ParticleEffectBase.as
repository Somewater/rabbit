package com.somewater.effects {
import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;

public class ParticleEffectBase extends EffectBase {
	
	protected var particles:Array;

	public var emitSpeed:Number = 0.01;// particles per ms
	public var particleMaximum:int = 50;
	protected var particleAccumulator:Number = 0;
	public var lifetime:int = 10000;

	protected var renderMatrix:Matrix;
	protected var renderColorTrans:ColorTransform;
	protected var clearBeforeRender:Boolean = true;
	protected var displayObjects:Array;
	protected var dataPartIndex:int = 0;
	protected var bitmapDataParts:Array;
	
	public function ParticleEffectBase(visualTypes:Array) {
		super();

		this.displayObjects = visualTypes;
		renderMatrix = new Matrix();
		renderColorTrans = new ColorTransform();
	}
	
	protected function emitParticle(data:BitmapDataPart):Particle {
		var p:Particle = new Particle()
		p.bitmapData = data.bitmapData;
		p.xOffset = data.xOffset;
		p.yOffset = data.yOffset;
		particles.push(p);
		return p;
	}

	protected function pickNewParticleBDPart():BitmapDataPart {
		return bitmapDataParts[dataPartIndex++ % bitmapDataParts.length];
	}
	
	protected function render():void {
		bitmapData.lock();
		if(clearBeforeRender)
			bitmapData.fillRect(bitmapData.rect, 0x88000000);
		for each(var p:Particle in particles){
			renderMatrix.tx = p.x + p.xOffset;
			renderMatrix.ty = p.y + p.yOffset;
			//bitmapData.copyPixels(p.bitmapData, p.bitmapData.rect, pos);
			renderColorTrans.alphaMultiplier = p.alpha;
			bitmapData.draw(p.bitmapData, renderMatrix,  renderColorTrans);
		}
		bitmapData.unlock();
	}

	override public function start():void {
		super.start();
		particles = [];
		bitmapDataParts = [];
		for each(var d:DisplayObject in displayObjects){
			bitmapDataParts.push(Utils.displayObjectToBitmapData(d));
		}
	}

	override public function clear():void {
		super.clear();
		particles = null;
		for each(var b:BitmapDataPart in bitmapDataParts){
			b.clear();
		}
	}

	override public function tick(msDelta:int):Boolean {
		var p:Particle
		var filteredParticles:Array = [];
		for each(p in particles){
			if(filterParticle(p))
				filteredParticles.push(p);
		}
		particles = filteredParticles;
		particleAccumulator += msDelta * emitSpeed;
		var emitCount:int = int(particleAccumulator);
		if(emitCount && lifetime > 0){
			particleAccumulator -= emitCount;
			for(var i:int = 0; i < emitCount; i++) {
				if(particles.length >= particleMaximum)
					break;
				var data:BitmapDataPart = pickNewParticleBDPart()
				p = emitParticle(data);
				setupParticleSpeed(p);
			}
		}
		for each(p in particles){
			p.age += msDelta;
			updateParticleSpeed(p);
		}
		render();

		lifetime -= msDelta;
		return lifetime > 0 || particles.length > 0;
	}

	protected function filterParticle(p:Particle):Boolean {
		return true;
	}

	protected function setupParticleSpeed(p:Particle):void {
	}

	protected function updateParticleSpeed(p:Particle):void {
	}
}
}