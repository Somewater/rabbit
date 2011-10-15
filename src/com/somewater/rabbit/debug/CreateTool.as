package com.somewater.rabbit.debug {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.debug.EditorModule;
	import com.somewater.rabbit.events.EditorEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;

	import flash.geom.Point;

	public class CreateTool extends EditorToolBase{

		private static var _filter:ColorMatrixFilter;

		public function CreateTool(template:XML) {
			super(template);

			EditorModule.instance.setIcon(createIconFromSlug(template..slug));
		}

		override public function onMove(tile:Point):void {
			highlightObjects(tile);
		}


		override public function onClick(tile:Point):void {
			highlightObjects(tile);

			// создать ентити
			var newEntity:IEntity = PBE.templateManager.instantiateEntity(template.@name);
			newEntity.owningGroup = PBE.lookup(Config.game.level.groupName) as PBGroup;

			// остановить процессор (который включается больно умным TemplateManager)
			Config.game.pause();

			// потикать контрллеры нового entity
			EditorModule.instance.tickVisualComponents(newEntity);

			// отпозиционировать ентити в нужный тайл
			IsoSpatial(newEntity.lookupComponentByName("Spatial")).tile = tile.clone();

			// вызвать внутренний колбэк на создание нового ентити
			EditorModule.instance.onNewEntityCreated(newEntity);

			// убрать курсор и диспатчить конец процесса
			clear();
			EditorModule.instance.dispatchEvent(new EditorEvent(Event.CHANGE, newEntity));
		}

		override protected function get getHighlightFilter():* {
			if(!_filter)
			{
				var matrix:Array = new Array();
				matrix = matrix.concat([1, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, 0.2, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, 0.2, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				_filter = new ColorMatrixFilter(matrix);
			}
			return _filter;
		}
	}
}
