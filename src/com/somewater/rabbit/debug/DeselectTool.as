package com.somewater.rabbit.debug {
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.rendering2D.DisplayObjectRenderer;

	import flash.filters.GlowFilter;

	public class DeselectTool extends EditorToolBase{

		public function DeselectTool(template:XML, objectReference:XML = null) {
			super(template, objectReference);

			var entity:IEntity = findEntityByHash(objectReference.@hash);
			if(entity)
				(entity.lookupComponentByName("Render") as DisplayObjectRenderer).displayObject.filters = [];

			clear();
		}
	}
}