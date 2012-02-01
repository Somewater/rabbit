package com.somewater.rabbit.managers {
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.entity.IEntity;
	import com.somewater.rabbit.components.HeroDataComponent;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;

	import flash.display.DisplayObject;

	import flash.geom.Point;

	public class GameTutorialModule implements IGameTutorialModule{

		private static var _instance:GameTutorialModule;

		public function GameTutorialModule() {
		}

		public static function get instance():GameTutorialModule {
			if(_instance == null)
				_instance = new GameTutorialModule();
			return _instance;
		}

		public function get rabbitEntity():*
		{
			return hero;
		}

		public function get heroPoint():Point
		{
			return (hero.lookupComponentByName('Spatial') as IsoSpatial).position;
		}

		public function get heroTile():Point
		{
			return (hero.lookupComponentByName('Spatial') as IsoSpatial).tile;
		}

		private function get hero():IEntity
		{
			return PBE.lookupEntity('Hero');
		}

		public function getDisplayObject(entity:*):DisplayObject {
			return (IEntity(entity).lookupComponentByName('Render') as IsoRenderer).displayObject;
		}

		public function get heroDisplayObject():DisplayObject {
			return getDisplayObject(hero);
		}

		public function get carrotHarvested():int {
			return HeroDataComponent.instance ? HeroDataComponent.instance.carrot : 0;
		}

		public function get health():Number {
			return HeroDataComponent.instance ? HeroDataComponent.instance.health : 0;
		}
	}
}
