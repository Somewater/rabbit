package com.somewater.rabbit.components
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.ThinkingComponent;
	import com.pblabs.engine.core.IQueuedObject;
	import com.pblabs.engine.entity.EntityComponent;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.Lib;
	import com.somewater.rabbit.storage.PowerupInfo;
	import com.somewater.rabbit.util.AnimationHelper;

	import flash.display.DisplayObject;

	import flash.display.Sprite;
	import flash.events.Event;

	final public class PowerupPanelRendererComponent extends ThinkingComponent
	{
		/**
		 * holder для значков паверапов, его центр совпадает с центром персонажа
		 * (т.е. значек с координатой 0,0 будет точно по центру персонажа)
		 */
		private var holder:Sprite = new Sprite();

		private var powerupControllerRef:PowerupControllerComponent;

		private var cachedIcons:Array = [];


		public function PowerupPanelRendererComponent()
		{
			super();
		}

		override protected function onAdd():void {
			think(refresh, Config.FRAME_RATE);
			owner.eventDispatcher.addEventListener(PowerupControllerComponent.POWERUPS_CHANGED, onPowerupsChanged);
			super.onAdd();
		}

		override protected function onRemove():void {
			owner.eventDispatcher.removeEventListener(PowerupControllerComponent.POWERUPS_CHANGED, onPowerupsChanged);
			super.onRemove();
			powerupControllerRef = null;
			cachedIcons = [];
		}

		override protected function onReset():void {
			super.onReset();
			if(powerupControllerRef == null)
				powerupControllerRef = owner.lookupComponentByName('PowerupController') as PowerupControllerComponent;
		}

		protected function createDisplayObject():void
		{
			var mainRender:ProxyIsoRenderer = owner.lookupComponentByName('Render') as ProxyIsoRenderer;
			if(mainRender.holder == null)
			{
				think(refresh, Config.FRAME_RATE);
				return;//  пока что не можем создать
			}

			mainRender.holder.addChild(holder);
			holder.y = -75;

			//holder.graphics.beginFill(0xFF0000);
			//holder.graphics.drawCircle(0,0,10);
		}

		private function refresh():void
		{
			if(holder.parent == null)
				createDisplayObject();
		}

		private function onPowerupsChanged(event:Event):void {
			while(holder.numChildren)
				holder.removeChildAt(0);

			const ICON_SIZE:int = 50;

			var powerups:Array = powerupControllerRef.temporaryPowerups;
			powerups.sortOn('timeRemain', Array.NUMERIC);
			var l:int = powerups.length;
			var startX:int = -ICON_SIZE * (l - 1) * 0.5;
			for (var i:int = 0; i < l; i++) {
				var powerup:PowerupInfo = powerups[i];
				var icon:DisplayObject = Lib.createMC(powerup.data.slug);
				icon.scaleX = icon.scaleY = 30 / (icon.width > icon.height ? icon.width : icon.height)
				holder.addChild(icon);
				icon.x = startX + ICON_SIZE * i;

				AnimationHelper.instance.blink(icon, powerup.timeRemain - 2);// когда останется 2 секунды до конца действия паверапа, он замигает
			}
		}
	}
}