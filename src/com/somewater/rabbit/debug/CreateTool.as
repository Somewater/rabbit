package com.somewater.rabbit.debug {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.PBGroup;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.debug.EditorModule;
	import com.somewater.rabbit.events.EditorEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	import flash.events.Event;

	import flash.geom.Point;

	public class CreateTool extends EditorToolBase{

		public function CreateTool(template:XML) {
			super(template);

			EditorModule.instance.setIcon(createIconFromSlug(template..slug));
		}


		override public function onClick(tile:Point):void {
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
	}
}
