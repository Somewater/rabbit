package com.somewater.rabbit.application.effects {
	import com.somewater.effects.ParticleEffectBase;
	import com.somewater.rabbit.storage.Lib;

	import flash.display.DisplayObject;

	public class GameStreamEffect extends ParticleEffectBase{
		public function GameStreamEffect() {
			var symbols:Array = [Lib.createMC('effects.SuccessStreamStar_0'), Lib.createMC('effects.SuccessStreamStar_0');
			var visTypes:Array = [];
			for each(var symbol:DisplayObject in symbols){
				visTypes.push(symbol);
			}
			super(visTypes);
		}
	}
}
