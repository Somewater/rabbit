package com.somewater.rabbit.iso
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.core.ITickedObject;
	import com.pblabs.engine.core.PBObject;
	import com.pblabs.engine.debug.Logger;
	import com.somewater.rabbit.events.HeroHealthEvent;
	import com.somewater.rabbit.iso.scene.IsoSpatialManager;
	import com.somewater.rabbit.managers.InitializeManager;
	import com.somewater.rabbit.storage.Config;

	import flash.events.Event;

	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * Содержит общедоступные из всех точек программы методы для управления камерой
	 */
	public class IsoCameraController extends PBObject implements ITickedObject
	{

		private static const DISALLOW_MAP_MOVE_MS:int = 5;
		private static const HERO_SHOW_DELAY_MS:int = 60;
		public static const DEFAULT_SPEED:Number = 0.5;
		private static const HERO_SHOW_SPEED_COEF:Number = 0.5;
		private static const MOVING_HERO_SHOW_SPEED_COEF:Number = 0.5;
		private static const HERO_FIRST_SHOW_SPEED_COEF:Number = 1;
		public static const MAX_SPEED:Number = 0.3;
		public static const MAX_ACCELERATION:Number = 0.02;
		private static const MAP_MOVE_PADDING:int = 180;
		private static const TRACK_OBJECT_MOVING_DELAY:int = 10;

		private static var instance:IsoCameraController;

		/**
		 * Сколько тайлов должно остаться объекту слежки до края,
		 * чтобы сцена начала передвигаться
		 */
		public var PADDING:int = 3;
		
		/**
		 * На сколько тайлов "сверху" передвинется камера, при необходимости передвинуться
		 * (для того, чтобы экран "не скакал", когда trackObject постоянно идет в его край)
		 */
		public var RESERVE:int = 2;

		/**
		 * Объекь, за которым передвигается экран
		 */
		public var trackObject:IsoSpatial;
		
		/**
		 * Листенеры на изменение позиции сцены (движение камеры)
		 */
		private var cameraMoveListeners:Array = [];

		/**
		 * Мышка в пределах игрового поля
		 */
		private var mouseOnScreen:Boolean = false;

		/**
		 * Вначала навести каму на героя, чтобы продемострировать игроку его положение на уровне
		 */
		public var centreOnHero:Boolean = false;

		private var trackObjectIsMoved:Boolean = false;
		private var trackObjectIsMovedDelayTimer:int = 0;

		private var trackTileRules:Vector.<TrackTileRule>;
		private var trackTileRulesEmptyTime:int = 0;
		private var disallowMapMoveTime:int = 0;
		
		public function IsoCameraController()
		{
			// пересчитываем константы в зависимости от размера сцены
			var T_SIZE:int = Math.min(Config.T_WIDTH, Config.T_HEIGHT);
			if(PADDING * 2 + RESERVE >= T_SIZE)
			{
				RESERVE = Math.max(0, T_SIZE - PADDING * 2 - 1)
				if(RESERVE == 0)
				{
					RESERVE = 1;
					PADDING = (T_SIZE - RESERVE - 1) / 2
				}
			}

			initialize("Camera");
			
			PBE.processManager.addTickedObject(this, 1);

			PBE.inputManager.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			PBE.mainStage.addEventListener(Event.MOUSE_LEAVE, onMouseOut);
			InitializeManager.bindRestartLevel(onLevelRestarted);

			trackTileRules = new Vector.<TrackTileRule>();
		}
		
		private function onMouseOut(e:Event):void
		{
			if(mouseOnScreen){
				mouseOnScreen = false;
				removeTrackRule(TrackTileRule.MAP_MOVING)
			}
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			mouseOnScreen = true;
		}
		
		public function onTick(deltaTime:Number):void
		{
			var gameIsTicking:Boolean = Config.game.isTicking;
			CONFIG::debug
			{
				if(Config.editor)
					gameIsTicking = gameIsTicking || PBE.mainStage != null;
			}
			if(!gameIsTicking)
				return;

			applyTrackRules();

			// трекинг на перемотку карты
			if(mouseOnScreen && !this.trackObjectIsMoved && disallowMapMoveTime-- <= 0)
				checkMapMoveTracking();

			if(centreOnHero){
				addHeroTracking(1);
				centreOnHero = false;
			}

			// трекинг на героя
			var trackOnlyHeroShow:Boolean = trackTileRules.length == 1 && trackTileRules[0].type == TrackTileRule.HERO_SHOWING;
			var trackObjectIsMoved:Boolean = this.trackObjectIsMoved && this.trackObjectIsMovedDelayTimer-- < 0;
			if(trackOnlyHeroShow || trackTileRules.length == 0){
				if(trackOnlyHeroShow || trackObjectIsMoved || trackTileRulesEmptyTime++ > HERO_SHOW_DELAY_MS){
					addHeroTracking(trackObjectIsMoved ? 3 : 2);
				}
			} else {
				trackTileRulesEmptyTime = 0;
			}
		}

		private function applyTrackRules():void {
			var scenePos:Point = position;
			while(trackTileRules.length > 0){
				var tileRule:TrackTileRule = trackTileRules[0];
				var tile:Point = tileRule.tile;
				if(scenePos.equals(tile)){
					trackTileRules.shift();
					continue;
				}
				var dx:Number = tile.x - scenePos.x;
				var dy:Number = tile.y - scenePos.y;
				if(tileRule.speedXY){
					if(dx)
						scenePos.x += (dx < 0 ? -dx : dx) > (tileRule.speedX < 0 ? -tileRule.speedX : tileRule.speedX) ?
								tileRule.speedX : dx;
					if(dy)
						scenePos.y += (dy < 0 ? -dy : dy) > (tileRule.speedY < 0 ? -tileRule.speedY : tileRule.speedY) ?
								tileRule.speedY : dy;
					tileRule.updateSpeed();
				} else {
					var speed:Number = tileRule.speed;
					if(dx)
						scenePos.x += (dx < 0 ? -dx : dx) > speed ? speed * (dx < 0 ? -1 : 1) : dx;
					if(dy)
						scenePos.y += (dy < 0 ? -dy : dy) > speed ? speed * (dy < 0 ? -1 : 1) : dy;
				}
				this.position = scenePos;
				break;
			}
		}

		private function addTrackRule(tileRule:TrackTileRule):void {
			var i:int;
			var r:TrackTileRule;
			if(tileRule.type){
				for(i = 0; i < trackTileRules.length; i++){
					if(trackTileRules[i].type == tileRule.type){
						if(trackTileRules[i].canChange(tileRule))
							trackTileRules[i] = tileRule;
						return;
					}
				}
			}
			for(i = 0; i < trackTileRules.length; i++){
				r = trackTileRules[i];
				if(r.priority < tileRule.priority){
					trackTileRules.splice(i, 0, tileRule);
					return;
				}
			}
			trackTileRules.push(tileRule);
		}

		private function removeTrackRule(type:int):void {
			for(var i:int = 0; i < trackTileRules.length; i++){
				if(trackTileRules[i].type == type){
					trackTileRules.splice(i, 1);
					return;
				}
			}
		}

		private function removeAllTrackRules():void {
			trackTileRules = new Vector.<TrackTileRule>();
		}

		private function onLevelRestarted():void {
			centreOnHero = true;
			trackObjectIsMoved = false;
			trackObjectIsMovedDelayTimer = 0;
			disallowMapMoveTime = 0;
			trackObject._owner.eventDispatcher.addEventListener(HeroHealthEvent.HERO_DAMAGE_EVENT, onHeroDamage, false, 0, true);
			trackObject._owner.eventDispatcher.addEventListener(IsoMover.MOVING_STARTED, onHeroMovingStarted, false, 0, true);
			trackObject._owner.eventDispatcher.addEventListener(IsoMover.DESTINATION_CHANGED, onHeroMovingStopped, false, 0, true);
			removeAllTrackRules();
		}

		private function onHeroDamage(event:HeroHealthEvent):void {
			if(event.isDamage){
				var trackingObjectPoint:Point = trackObjectCameraPos();
				if(trackingObjectPoint){
					removeAllTrackRules();
					var tileRule:TrackTileRule = new TrackTileRule(TrackTileRule.HERO_DAMAGE, trackingObjectPoint);
					addTrackRule(tileRule);
					disallowMapMoveTime = DISALLOW_MAP_MOVE_MS;
				}
			}
		}

		private function onHeroMovingStarted(event:Event):void {
			if(!trackObjectIsMoved && !Config.memory.disableCameraTracking){
				trackObjectIsMoved = true;
				trackObjectIsMovedDelayTimer = TRACK_OBJECT_MOVING_DELAY;
				removeTrackRule(TrackTileRule.MAP_MOVING);
			}
		}

		private function onHeroMovingStopped(event:Event):void {
			if(trackObjectIsMoved){
				trackObjectIsMoved = false;
			}
		}

		private function checkMapMoveTracking():void {
			var mouseX:int = PBE.mainStage.mouseX;
			var mouseY:int = PBE.mainStage.mouseY;
			var speedX:Number;
			var speedY:Number;

			speedX = speedByValues(mouseX, 0, MAP_MOVE_PADDING);
			if(speedX == 0) speedX = speedByValues(mouseX, Config.WIDTH, Config.WIDTH - MAP_MOVE_PADDING);

			speedY = speedByValues(mouseY, 0, MAP_MOVE_PADDING);
			if(speedY == 0) speedY = speedByValues(mouseY, Config.HEIGHT, Config.HEIGHT - MAP_MOVE_PADDING);

			if(speedX != 0 || speedY != 0){
				var scenePos:Point = position.clone();
				const MAX_LEVEL_SIZE = 10000;
				scenePos.x += (speedX > 0 ? MAX_LEVEL_SIZE : (speedX < 0 ? -MAX_LEVEL_SIZE : 0));
				scenePos.y += (speedY > 0 ? MAX_LEVEL_SIZE : (speedY < 0 ? -MAX_LEVEL_SIZE : 0));
				roundLevelSize(scenePos);
				var tileRule:TrackTileRule = new TrackTileRule(TrackTileRule.MAP_MOVING, scenePos);
				tileRule.accX = sign(speedX) * IsoCameraController.MAX_ACCELERATION;
				tileRule.accY = sign(speedY) * IsoCameraController.MAX_ACCELERATION;
				tileRule.speedX = 0;
				tileRule.speedY = 0;
				tileRule.speedXY = true;
				removeTrackRule(TrackTileRule.HERO_SHOWING);
				addTrackRule(tileRule);
			} else {
				removeTrackRule(TrackTileRule.MAP_MOVING);
			}
		}

		/**
		 * @param type
		 *        1 TrackTileRule.FIRST_HERO_SHOWING
		 *        2 TrackTileRule.HERO_SHOWING, при длительном отсутствии движений камеры
		 *        3 TrackTileRule.HERO_SHOWING, при перемещении персонажа
		 */
		private function addHeroTracking(type:int):void {
			var trackingObjectPoint:Point = trackObjectCameraPos();
			if(trackingObjectPoint){
				var tileRule:TrackTileRule = new TrackTileRule(type == 1 ? 	TrackTileRule.FIRST_HERO_SHOWING :
																		TrackTileRule.HERO_SHOWING,
																		trackingObjectPoint);
				if(type == 1)
					tileRule.speed *= HERO_FIRST_SHOW_SPEED_COEF;
				else if(type == 2)
					tileRule.speed *= HERO_SHOW_SPEED_COEF;
				else
					tileRule.speed *= MOVING_HERO_SHOW_SPEED_COEF;
				addTrackRule(tileRule);
			}
		}

		/**
		 * Позиция камеры, в тайлах, чтобы отслеживаемый объект был в области видимости
		 * (с минимальным передвижением камеры относительно текущего состояния)
		 * @return null, если центровка на персонажа не требуется (персонажа нет или он в поле зрения)
		 */
		private function trackObjectCameraPos():Point {
			if(!trackObject) return null;
			var objPos:Point = trackObject.tile;
			var movePos:Point = position;
			var scenePos:Point = movePos.clone();

			const USE_RESERVE:int = 1;
			if(objPos.x - scenePos.x < PADDING)
				movePos.x = objPos.x - PADDING - USE_RESERVE * RESERVE;
			else if((scenePos.x + Config.T_WIDTH) - objPos.x < PADDING + 1)
				movePos.x = objPos.x - Config.T_WIDTH + PADDING + 1 + USE_RESERVE * RESERVE;

			if(objPos.y - scenePos.y < PADDING)
				movePos.y = objPos.y - PADDING - USE_RESERVE * RESERVE;
			else if((scenePos.y + Config.T_HEIGHT) - objPos.y < PADDING + 1)
				movePos.y = objPos.y - Config.T_HEIGHT + PADDING + 1 + USE_RESERVE * RESERVE;

			roundLevelSize(movePos);

			return movePos.equals(scenePos) ? null : movePos;
		}

		private function roundLevelSize(tilePos:Point):void {
			// обеспечить, чтобы экран не сдвинулся за пределы границ карты
			if(tilePos.x < 0)
				tilePos.x = 0;
			else if(tilePos.x > IsoSpatialManager.instance.width - Config.T_WIDTH)
				tilePos.x = IsoSpatialManager.instance.width - Config.T_WIDTH;
			if(tilePos.y < -Config.HORIZONT_HEIGHT)
				tilePos.y = -Config.HORIZONT_HEIGHT;
			else if(tilePos.y > IsoSpatialManager.instance.height - Config.T_HEIGHT)
				tilePos.y = IsoSpatialManager.instance.height - Config.T_HEIGHT;
		}

		private var tempPos:Point = new Point();
		public function get x():Number
		{
			tempPos.x = -PBE.scene.position.x / Config.TILE_WIDTH;
			return tempPos.x;
		}
		public function set x(value:Number):void
		{
			tempPos.x = -value * Config.TILE_WIDTH;
			PBE.scene.position = tempPos;
			
			dispatchCameraMoving(tempPos)
		}
		public function get y():Number
		{
			tempPos.y = -PBE.scene.position.y / Config.TILE_HEIGHT;
			return tempPos.y;
		}
		public function set y(value:Number):void
		{
			tempPos.y = -value * Config.TILE_HEIGHT;
			PBE.scene.position = tempPos;
			dispatchCameraMoving(tempPos);
		}
		
		
		
		/**
		 * Позиция (смещение) сцены, только не в пикселах, а в тайлах
		 */
		public function set position(value:Point):void
		{
			value.x = -value.x * Config.TILE_WIDTH;
			value.y = -value.y * Config.TILE_HEIGHT;
			PBE.scene.position = value;
			dispatchCameraMoving(value);
		}
		
		public function get position():Point
		{
			var value:Point = PBE.scene.position;
			value.x = -value.x / Config.TILE_WIDTH;
			value.y = -value.y / Config.TILE_HEIGHT;
			return value;
		}
		
		
		public static function getInstance():IsoCameraController
		{
			if(instance == null)
				instance = new IsoCameraController();
			
			return instance;
		}
		
		/**
		 * Добавить слушателя на изменение позиции сцены
		 * callback(point:Point)  где point - смещение сцены в пикселях
		 */
		public function addCallback(callback:Function):void
		{
			if(cameraMoveListeners.indexOf(callback) == -1)
				cameraMoveListeners.push(callback);
		}
		
		/**
		 * Удалить слушателя на изменение позиции сцены
		 */
		public function removeCallback(callback:Function):void
		{
			var idx:int = cameraMoveListeners.indexOf(callback);
			if(idx != -1)
				cameraMoveListeners.splice(idx, 1);
		}
		
		private function dispatchCameraMoving(shift:Point):void
		{
			for(var i:int = 0;i<cameraMoveListeners.length;i++)
				cameraMoveListeners[i](shift);	
		}

		public function isoSpatialInViewArea(isoSpatial:IsoSpatial):Boolean
		{
			var pos:Point = isoSpatial._position;
			var x:int = this.x;
			var y:int = this.y;
			return pos.x >= x && pos.x <= x + Config.T_WIDTH && pos.y >= y && pos.y <= y + Config.T_HEIGHT;
		}

		private static function speedByValues(value:int, limit:int, startTracking:int):Number{
			if(limit < startTracking){
				if(value < startTracking){
					if(value < limit) value = limit;
					return - (startTracking - value) / (startTracking - limit);
				}
			}else{
				if(value > startTracking){
					if(value > limit) value = limit;
					return (value - startTracking) / (limit - startTracking);
				}
			}
			return 0;
		}

		private static function sign(value:Number):int {
			return value > 0 ? 1 : (value < 0 ? -1 : 0);
		}
	}
}

import com.somewater.rabbit.iso.IsoCameraController;

import flash.geom.Point;

class TrackTileRule{
	public static const HERO_DAMAGE:int = 10;
	public static const MAP_MOVING:int = 5;
	public static const HERO_SHOWING:int = 1;
	public static const FIRST_HERO_SHOWING:int = 30;

	public var type:int;
	public var tile:Point;
	public var speed:Number;
	public var accX:Number;
	public var accY:Number;
	public var speedX:Number;
	public var speedY:Number;
	public var speedXY:Boolean = false;
	public var priority:int = 1;

	public function TrackTileRule(type:int, tile:Point){
		this.speed = IsoCameraController.DEFAULT_SPEED;
		this.type = type;
		this.tile = tile;
		this.priority = this.type;
	}

	public function canChange(t:TrackTileRule):Boolean {
		if(type == TrackTileRule.MAP_MOVING){
			if(
					(this.accX > 0 ? 1 : (this.accX < 0 ? -1 : 0 )) == (t.accX > 0 ? 1 : (t.accX < 0 ? -1 : 0 ))
					&&
					(this.accY > 0 ? 1 : (this.accY < 0 ? -1 : 0 )) == (t.accY > 0 ? 1 : (t.accY < 0 ? -1 : 0 ))
					)
				return false;
		}
		return true;
	}

	public function updateSpeed():void {
		if(accX){
			speedX += accX;
			if(speedX > 0){
				if(speedX > IsoCameraController.MAX_SPEED) speedX = IsoCameraController.MAX_SPEED;
			}else{
				if(-speedX > IsoCameraController.MAX_SPEED) speedX = -IsoCameraController.MAX_SPEED;
			}
		}
		if(accY){
			speedY += accY;
			if(speedY > 0){
				if(speedY > IsoCameraController.MAX_SPEED) speedY = IsoCameraController.MAX_SPEED;
			}else{
				if(-speedY > IsoCameraController.MAX_SPEED) speedY = -IsoCameraController.MAX_SPEED;
			}
		}
	}
}