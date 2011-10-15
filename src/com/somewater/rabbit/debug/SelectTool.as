package com.somewater.rabbit.debug {
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.rendering2D.DisplayObjectRenderer;

	import flash.filters.GlowFilter;

	public class SelectTool extends EditorToolBase{

		public function SelectTool(template:XML, objectReference:XML = null) {
			super(template, objectReference);

			var entity:IEntity = findEntityByHash(objectReference.@hash);
			if(entity)
				(entity.lookupComponentByName("Render") as DisplayObjectRenderer).displayObject.filters = [getHighlightFilter];

			clear();
		}

		override protected function get getHighlightFilter():* {
			return new GlowFilter(0x5533FF, 1, 20,20, 5);
		}
	}
}