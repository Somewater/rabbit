package com.somewater.rabbit.creature {
	import com.somewater.rabbit.components.HeroContactComponent;
	import com.somewater.rabbit.decor.PopupEffectFactory;
	import com.somewater.rabbit.events.GameModuleEvent;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;

	/**
	 * Диспатчит событие сбора и самоуничтожается, при соприкосновении с героем
	 */
	public class MoneyRewardControllerComponent extends HeroContactComponent{
		public function MoneyRewardControllerComponent() {
		}

		override protected function onContact(heroSpatial:IsoSpatial):void {
			// диспатчить начисление еще одного оффера, передать событию координаты размещения оффера
			var spatial:IsoSpatial = owner.lookupComponentByName('Spatial') as IsoSpatial;
			Config.application.dispatchEvent(new GameModuleEvent(GameModuleEvent.FRIEND_VISIT_REWARD_HARVESTED, Config.game.level))

			// создать попап эффекта
			PopupEffectFactory.createEffect('rabbit.MoneyRewardAnimation', spatial.tile, this.owner);

			// и самоудалиться
			this.owner.destroy();
		}
	}
}
