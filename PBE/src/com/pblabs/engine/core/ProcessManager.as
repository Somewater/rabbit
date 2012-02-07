/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 * 
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.core
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.PBUtil;
	import com.pblabs.engine.components.TickedComponent;
	import com.pblabs.engine.debug.*;
	import com.pblabs.engine.entity.Entity;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.serialization.TypeUtility;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.pblabs.rendering2D.SimpleSpatialComponent;
	import com.somewater.rabbit.events.ExceptionEvent;
	import com.somewater.rabbit.iso.IsoCameraController;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.iso.IsoSpatial;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.ui.HorizontRender;

	import flash.display.DisplayObject;

	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
    
    /**
     * The process manager manages all time related functionality in the engine.
     * It provides mechanisms for performing actions every frame, every tick, or
     * at a specific time in the future.
     * 
     * <p>A tick happens at a set interval defined by the TICKS_PER_SECOND constant.
     * Using ticks for various tasks that need to happen repeatedly instead of
     * performing those tasks every frame results in much more consistent output.
     * However, for animation related tasks, frame events should be used so the
     * display remains smooth.</p>
     * 
     * @see ITickedObject
     * @see IAnimatedObject
     */
    public class ProcessManager
    {
        /**
         * If true, disables warnings about losing ticks.
         */
        public static var disableSlowWarning:Boolean = true;
        
        /**
         * The number of ticks that will happen every second.
         */
        public static const TICKS_PER_SECOND:int = 30;
        
        /**
         * The rate at which ticks are fired, in seconds.
         */
        public static const TICK_RATE:Number = 1.0 / Number(TICKS_PER_SECOND);
        
        /**
         * The rate at which ticks are fired, in milliseconds.
         */
        public static const TICK_RATE_MS:Number = TICK_RATE * 1000;
        
        /**
         * The maximum number of ticks that can be processed in a frame.
         * 
         * <p>In some cases, a single frame can take an extremely long amount of
         * time. If several ticks then need to be processed, a game can
         * quickly get in a state where it has so many ticks to process
         * it can never catch up. This is known as a death spiral.</p>
         * 
         * <p>To prevent this we have a safety limit. Time is dropped so the
         * system can catch up in extraordinary cases. If your game is just
         * slow, then you will see that the ProcessManager can never catch up
         * and you will constantly get the "too many ticks per frame" warning,
         * if you have disableSlowWarning set to false.</p>
         */
        public static const MAX_TICKS_PER_FRAME:int = 5;

		/**
		 * Тикать всех подряд, не проводить оптимизацию
		 */
		public var optimizeModeCounter:int = -1;
		private function get optimizeMode():Boolean{return optimizeModeCounter > 2;}
        
        /**
         * The scale at which time advances. If this is set to 2, the game
         * will play twice as fast. A value of 0.5 will run the
         * game at half speed. A value of 1 is normal.
         */
        public function get timeScale():Number
        {
            return _timeScale;
        }
        
        /**
         * @private
         */
        public function set timeScale(value:Number):void
        {
            _timeScale = value;
        }
        
        /**
         * TweenMax uses timeScale as a config property, so by also having a
         * capitalized version, we can tween TimeScale instead and get along 
         * just fine.
         */
        public function set TimeScale(value:Number):void
        {
            timeScale = value;
        }
        
        /**
         * @private
         */ 
        public function get TimeScale():Number
        {
            return timeScale;
        }
        
        /**
         * Used to determine how far we are between ticks. 0.0 at the start of a tick, and
         * 1.0 at the end. Useful for smoothly interpolating visual elements.
         */
        public function get interpolationFactor():Number
        {
            return _interpolationFactor;
        }
        
        /**
         * The amount of time that has been processed by the process manager. This does
         * take the time scale into account. Time is in milliseconds.
         */
        public function get virtualTime():Number
        {
            return _virtualTime;
        }
        
        /**
         * Current time reported by getTimer(), updated every frame. Use this to avoid
         * costly calls to getTimer(), or if you want a unique number representing the
         * current frame.
         */
        public function get platformTime():Number
        {
            return _platformTime;
        }
        
        /**
         * Starts the process manager. This is automatically called when the first object
         * is added to the process manager. If the manager is stopped manually, then this
         * will have to be called to restart it.
         */
        public function start():void
        {
            if (started)
            {
                Logger.warn(this, "start", "The ProcessManager is already started.");
                return;
            }
            
            lastTime = -1.0;
            elapsed = 0.0;
            PBE.mainStage.addEventListener(Event.ENTER_FRAME, onFrame);
            started = true;
        }
        
        /**
         * Stops the process manager. This is automatically called when the last object
         * is removed from the process manager, but can also be called manually to, for
         * example, pause the game.
         */
        public function stop():void
        {
            if (!started)
            {
                Logger.warn(this, "stop", "The ProcessManager isn't started.");
                return;
            }
            
            started = false;
            PBE.mainStage.removeEventListener(Event.ENTER_FRAME, onFrame);
        }
		
		/**
		 * Удалить все shedule tasks
		 */
		public function clear():void
		{
			deferredMethodQueue = [];
			thinkHeap.clear();	
		}
        
        /**
         * Returns true if the process manager is advancing.
         */ 
        public function get isTicking():Boolean
        {
            return started;
        }
        
        /**
         * Schedules a function to be called at a specified time in the future.
         * 
         * @param delay The number of milliseconds in the future to call the function.
         * @param thisObject The object on which the function should be called. This
         * becomes the 'this' variable in the function.
         * @param callback The function to call.
         * @param arguments The arguments to pass to the function when it is called.
         */
        public function schedule(delay:Number, thisObject:Object, callback:Function, ...arguments):void
        {
            if (!started)
                start();
            
            var schedule:ScheduleObject = new ScheduleObject();
            schedule.dueTime = _virtualTime + delay;
            schedule.thisObject = thisObject;
            schedule.callback = callback;
            schedule.arguments = arguments;

            thinkHeap.enqueue(schedule);
        }
        
        /**
         * Registers an object to receive frame callbacks.
         * 
         * @param object The object to add.
         * @param priority The priority of the object. Objects added with higher priorities
         * will receive their callback before objects with lower priorities. The highest
         * (first-processed) priority is Number.MAX_VALUE. The lowest (last-processed) 
         * priority is -Number.MAX_VALUE.
         */
        public function addAnimatedObject(object:IAnimatedObject, priority:Number = 0.0):void
        {
            addObject(object, priority, animatedObjects, entityAnimatedObjects);
        }
        
        /**
         * Registers an object to receive tick callbacks.
         * 
         * @param object The object to add.
         * @param priority The priority of the object. Objects added with higher priorities
         * will receive their callback before objects with lower priorities. The highest
         * (first-processed) priority is Number.MAX_VALUE. The lowest (last-processed) 
         * priority is -Number.MAX_VALUE.
         */
        public function addTickedObject(object:ITickedObject, priority:Number = 0.0):void
        {
            addObject(object, priority, tickedObjects, entityTickedObjects);
        }
        
        /**
         * Queue an IQueuedObject for callback. This is a very cheap way to have a callback
         * happen on an object. If an object is queued when it is already in the queue, it
         * is removed, then added.
         */
        public function queueObject(object:IQueuedObject):void
        {
            // Assert if this is in the past.
            if(object.nextThinkTime < _virtualTime)
                throw new Error("Tried to queue something into the past, but no flux capacitor is present!");
            
            CONFIG::debug
			{
				Profiler.enter("queueObject");
			}
            
            if(object.nextThinkTime >= _virtualTime && thinkHeap.contains(object))
                thinkHeap.remove(object);
            
            thinkHeap.enqueue(object);
            
            CONFIG::debug
			{
				Profiler.exit("queueObject");
			}
        }
        
        /**
         * Unregisters an object from receiving frame callbacks.
         * 
         * @param object The object to remove.
         */
        public function removeAnimatedObject(object:IAnimatedObject):void
        {
            removeObject(object, animatedObjects, entityAnimatedObjects);
        }
        
        /**
         * Unregisters an object from receiving tick callbacks.
         * 
         * @param object The object to remove.
         */
        public function removeTickedObject(object:ITickedObject):void
        {
            removeObject(object, tickedObjects, entityTickedObjects);
        }
        
        /**
         * Forces the process manager to advance by the specified amount. This should
         * only be used for unit testing.
         * 
         * @param amount The amount of time to simulate.
         */
        public function testAdvance(amount:Number):void
        {
            advance(amount * _timeScale, true);
        }
        
        /**
         * Forces the process manager to seek its virtualTime by the specified amount.
         * This moves virtualTime without calling advance and without processing ticks or frames.
         * WARNING: USE WITH CAUTION AND ONLY IF YOU REALLY KNOW THE CONSEQUENCES!
         */
        public function seek(amount:Number):void
        {
            _virtualTime += amount;
        }
        
        /**
         * Deferred function callback - called back at start of processing for next frame. Useful
         * any time you are going to do setTimeout(someFunc, 1) - it's a lot cheaper to do it 
         * this way.
         * @param method Function to call.
         * @param args Any arguments.
         */
        public function callLater(method:Function, args:Array = null):void
        {
            var dm:DeferredMethod = new DeferredMethod();
            dm.method = method;
            dm.args = args;
            deferredMethodQueue.push(dm);
        }
        
        /**
         * @return How many objects are depending on the ProcessManager right now?
         */
        private function get listenerCount():int
        {
            return tickedObjects.length + animatedObjects.length;
        }
        
        /**
         * Internal function add an object to a list with a given priority.
         * @param object Object to add.
         * @param priority Priority; this is used to keep the list ordered.
         * @param list List to add to.
         */
        private function addObject(object:*, priority:Number, list:Array, entityList:Array):void
        {
            // If we are in a tick, defer the add.
            if(duringAdvance)
            {
                PBE.callLater(addObject, [ object, priority, list, entityList]);
                return;
            }
            
            if (!started)
                start();
            
            var position:int = -1;

			var entityComponent:Boolean = false;
			if(optimizeMode && isEntityComponent(object))
			{
				list = entityList;
				entityComponent = true;
			}

            for (var i:int = 0; i < list.length; i++)
            {
                if(!list[i])
                    continue;
                
                if (list[i].listener == object)
                {
                    Logger.warn(object, "AddProcessObject", "This object has already been added to the process manager.");
                    return;
                }
                
                if (list[i].priority < priority)
                {
                    position = i;
                    break;
                }
            }
            
            var processObject:ProcessObject = new ProcessObject();
            processObject.listener = object;
            processObject.priority = priority;
            processObject.profilerKey = TypeUtility.getObjectClassName(object);
            
            if (position < 0 || position >= list.length)
                list.push(processObject);
            else
                list.splice(position, 0, processObject);

			CONFIG::debug
			{
				if(entityComponent && object._owner == null)
					throw new Error('Can`t manipilate unbind component')
			}

			if(entityComponent && entities.indexOf(object._owner) == -1)
			{
				entities.push(object._owner);
			}

        }
        
        /**
         * Peer to addObject; removes an object from a list. 
         * @param object Object to remove.
         * @param list List from which to remove.
         */
        private function removeObject(object:*, list:Array, entityList:Array):void
        {
            if (listenerCount == 1 && thinkHeap.size == 0)
                stop();
            for(var k:int = 0; k<2; k++)
			{
				for (var i:int = 0; i < list.length; i++)
				{
					if(!list[i])
						continue;

					if (list[i].listener == object)
					{
						CONFIG::debug
						{
							if(object._owner == null && this.optimizeMode)
								throw new Error('Can`t manipilate unbind component')
						}
						if(k == 1 && object is IsoRenderer)
						{
							// если производится удаление рендера у ентити, очевидно, что ентити удаляется насовсем
							var idx:int = entities.indexOf(object._owner);
							CONFIG::debug
							{
								if(idx == -1)
									throw new Error('Some entity component hide our owner later');
							}
							entities.splice(idx, 1);
						}
						if(duringAdvance)
						{
							list[i] = null;
							needPurgeEmpty = true;
						}
						else
						{
							list.splice(i, 1);
						}

						return;
					}
				}
				list = entityList;
			}
            
            Logger.warn(object, "RemoveProcessObject", "This object has not been added to the process manager.");
        }
        
        /**
         * Main callback; this is called every frame and allows game logic to run. 
         */
        private function onFrame(event:Event):void
        {
            // This is called from a system event, so it had better be at the 
            // root of the profiler stack!
            CONFIG::debug
			{
				Profiler.ensureAtRoot();
			}
            
            // Track current time.
            var currentTime:Number = getTimer();
            if (lastTime < 0)
            {
                lastTime = currentTime;
                return;
            }
            
            // Calculate time since last frame and advance that much.
            var deltaTime:Number = Number(currentTime - lastTime) * _timeScale;

			CONFIG::debug
			{
				// не оборачиваем в try-catch, чтобы воочию видет environment ошибки
				advance(deltaTime);
				lastTime = currentTime;
				return;
			}
			// advance(deltaTime);
			try{
				advance(deltaTime);
			}catch(err:Error){
				PBE.levelManager.dispatchEvent(new ExceptionEvent(ExceptionEvent.TICK_EXCEPTION, err));
				throw err;	
			}
            
            // Note new last time.
            lastTime = currentTime;
        }
        
        protected function advance(deltaTime:Number, suppressSafety:Boolean = false):void
        {
			// FIX: 56.02.2012, check visibility of owner of ticked and animation component
			this.optimizeModeCounter++;
			if(optimizeModeCounter == 3)// т.е. если это первый тик с оптимизацией
				separateProcessObjects();
			var optimizeMode:Boolean = this.optimizeMode;

            // Update platform time, to avoid lots of costly calls to getTimer.
            _platformTime = getTimer();
            
            // Note virtual time we started advancing from.
            var startTime:Number = _virtualTime;
            
            // Add time to the accumulator.
            elapsed += deltaTime;

			var unvisibleEntities:Dictionary = new Dictionary();
			var untickedEntities:Dictionary = new Dictionary();
			if(optimizeMode)
			{
				CONFIG::debug
				{
					Profiler.enter("Check visible entities");
				}
				const PADDING:int = 2;
				var camera:IsoCameraController = IsoCameraController.getInstance();

				var minXPosVisible:int = camera.x;
				var minYPosVisible:int = camera.y;
				var maxXPosVisible:int = Math.ceil(camera.x + Config.T_WIDTH);
				var maxYPosVisible:int = Math.ceil(camera.y + Config.T_HEIGHT);
				var minXPos:int = minXPosVisible - PADDING;
				var minYPos:int = minYPosVisible - PADDING;
				var maxXPos:int = maxXPosVisible + PADDING;
				var maxYPos:int = maxYPosVisible + PADDING;

				// для удаленив визуальных артефактов
				minXPosVisible -= 1;
				maxXPosVisible += 1;
				maxYPosVisible += 1;

				var ticker:TickedComponent;
				var render:DisplayObjectRenderer;
				var own:Entity;

				for each(own in this.entities)
				{
					var spatialRef:SimpleSpatialComponent = own.spatialRef
					var pos:Point = spatialRef._position;
					var size:Point = spatialRef._size;
					var minX:int = pos.x;
					var minY:int = pos.y;
					var maxX:int = minX + size.x;
					var maxY:int = minY + size.y;
					if(!own.noSleep && (minX > maxXPos || minY > maxYPos || maxX < minXPos || maxY < minYPos))
					{
						// не тикается и невидим
						untickedEntities[own] = true;
						unvisibleEntities[own] = true;
						continue;
					}
					if(minX > maxXPosVisible || minY > maxYPosVisible || maxX < minXPosVisible || maxY < minYPosVisible)
					{
						// невидим (но тикается)
						unvisibleEntities[own] = true;
					}

					// тикается и видим
				}
				CONFIG::debug
				{
					Profiler.exit("Check visible entities");
				}
			}

            // Perform ticks, respecting tick caps.
            var tickCount:int = 0;
			var object:ProcessObject;
			var j:int;
            while (elapsed >= TICK_RATE_MS && (suppressSafety || tickCount < MAX_TICKS_PER_FRAME))
            {
                // Ticks always happen on interpolation boundary.
                _interpolationFactor = 0.0;
                
                // Process pending events at this tick.
                // This is done in the loop to ensure the correct order of events.
                processScheduledObjects();
                
                // Do the onTick callbacks, noting time in profiler appropriately.
                CONFIG::debug
				{
					Profiler.enter("Tick");
				}
                
                duringAdvance = true;
                for(j=0; j<tickedObjects.length; j++)
                {
                    object = tickedObjects[j] as ProcessObject;
                    if(!object)
                        continue;

                    CONFIG::debug
					{
						Profiler.enter(object.profilerKey);
					}
                    (object.listener as ITickedObject).onTick(TICK_RATE);
                    CONFIG::debug
					{
						Profiler.exit(object.profilerKey);
					}
                }

				for(j=0; j<entityTickedObjects.length; j++)
				{
					object = entityTickedObjects[j] as ProcessObject;
					if(!object)
						continue;

					ticker = object.listener;

					if(untickedEntities[ticker._owner])
						continue;

					CONFIG::debug
					{
						Profiler.enter(object.profilerKey);
					}
					ticker.onTick(TICK_RATE);
					CONFIG::debug
					{
						Profiler.exit(object.profilerKey);
					}
				}
                duringAdvance = false;
                
                CONFIG::debug
				{
					Profiler.exit("Tick");
				}
                
                // Update virtual time by subtracting from accumulator.
                _virtualTime += TICK_RATE_MS;
                elapsed -= TICK_RATE_MS;
                tickCount++;
            }
            
            // Safety net - don't do more than a few ticks per frame to avoid death spirals.
            if (tickCount >= MAX_TICKS_PER_FRAME && !suppressSafety && !disableSlowWarning)
            {
                // By default, only show when profiling.
                Logger.warn(this, "advance", "Exceeded maximum number of ticks for frame (" + elapsed.toFixed() + "ms dropped) .");
                elapsed = 0;
            }
            
            // Make sure that we don't fall behind too far. This helps correct
            // for short-term drops in framerate as well as the scenario where
            // we are consistently running behind.
            elapsed = PBUtil.clamp(elapsed, 0, 300);      
            
            // Make sure we don't lose time to accumulation error.
            // Not sure this gains us anything, so disabling -- BJG
            //_virtualTime = startTime + deltaTime;
            
            // We process scheduled items again after tick processing to ensure between-tick schedules are hit
            // Commenting this out because it can cause too-often calling of callLater methods. -- BJG
            // processScheduledObjects();
            
            // Update objects wanting OnFrame callbacks.
            CONFIG::debug
			{
				Profiler.enter("frame");
			}
            duringAdvance = true;
            _interpolationFactor = elapsed / TICK_RATE_MS;
            for(j = 0; j<animatedObjects.length; j++)
            {
                object = animatedObjects[j] as ProcessObject;
                if(!object)
                    continue;

                CONFIG::debug
				{
					Profiler.enter(object.profilerKey);
				}
                (object.listener as IAnimatedObject).onFrame(deltaTime / 1000);
                CONFIG::debug
				{
					Profiler.exit(object.profilerKey);
				}
            }
			for(j = 0; j<entityAnimatedObjects.length; j++)
            {
                object = entityAnimatedObjects[j] as ProcessObject;
                if(!object)
                    continue;

				render = object.listener;
				var dor:DisplayObject = render._displayObject;
				if(unvisibleEntities[render._owner])
				{
					CONFIG::debug
					{
						continue;
					}
					if(dor)
						dor.visible = false;
					continue;
				}

                CONFIG::debug
				{
					Profiler.enter(object.profilerKey);
				}
				if(dor)
					dor.visible = true;
                render.onFrame(deltaTime / 1000);
                CONFIG::debug
				{
					Profiler.exit(object.profilerKey);
				}
            }
            duringAdvance = false;
            CONFIG::debug
			{
				Profiler.exit("frame");
			}

            // Purge the lists if needed.
            if(needPurgeEmpty)
            {
                needPurgeEmpty = false;
                
                CONFIG::debug
				{
					Profiler.enter("purgeEmpty");
				}
                
                for(j=0; j<animatedObjects.length; j++)
                {
                    if(animatedObjects[j])
                        continue;
                    
                    animatedObjects.splice(j, 1);
                    j--;
                }
                
                for(var k:int=0; k<tickedObjects.length; k++)
                {                    
                    if(tickedObjects[k])
                        continue;
                    
                    tickedObjects.splice(k, 1);
                    k--;
                }

                CONFIG::debug
				{
					Profiler.exit("purgeEmpty");
				}
            }
            
            CONFIG::debug
			{
				Profiler.ensureAtRoot();
			}
        }
        
        private function processScheduledObjects():void
        {
            // Do any deferred methods.
            var oldDeferredMethodQueue:Array = deferredMethodQueue;
            if(oldDeferredMethodQueue.length)
            {
                CONFIG::debug
				{
					Profiler.enter("callLater");
				}

                // Put a new array in the queue to avoid getting into corrupted
                // state due to more calls being added.
                deferredMethodQueue = [];
                
                for(var j:int=0; j<oldDeferredMethodQueue.length; j++)
                {
                    var curDM:DeferredMethod = oldDeferredMethodQueue[j] as DeferredMethod;
                    curDM.method.apply(null, curDM.args);
                }
                
                // Wipe the old array now we're done with it.
                oldDeferredMethodQueue.length = 0;

                CONFIG::debug
				{
					Profiler.exit("callLater");
				}
            }

            // Process any queued items.
            if(thinkHeap.size)
            {
                CONFIG::debug
				{
					Profiler.enter("Queue");
				}
                
                while(thinkHeap.front && thinkHeap.front.priority >= -_virtualTime)
                {
                    var itemRaw:IPrioritizable = thinkHeap.dequeue();
                    var qItem:IQueuedObject = itemRaw as IQueuedObject;
                    var sItem:ScheduleObject = itemRaw as ScheduleObject;
                    
                    var type:String = TypeUtility.getObjectClassName(itemRaw);
                    
                    CONFIG::debug
					{
						Profiler.enter(type);
					}
                    if(qItem)
                    {
                        // Check here to avoid else block that throws an error - empty callback
                        // means it unregistered.
                        if(qItem.nextThinkCallback != null)
                            qItem.nextThinkCallback();
                    }
                    else if(sItem && sItem.callback != null)
                    {
                        sItem.callback.apply(sItem.thisObject, sItem.arguments);                    
                    }
                    else
                    {
                        throw new Error("Unknown type found in thinkHeap.");
                    }
                    CONFIG::debug
					{
						Profiler.exit(type);
					}
                    
                }
                
                CONFIG::debug
				{
					Profiler.exit("Queue");
				}
            }
        }

		private function isEntityComponent(component:*):Boolean
		{
			var own:Entity;
			if(component is TickedComponent)
			{
				own = component.owner;
				if(own.noSleep)
					return false;
			}
			else if(component is DisplayObjectRenderer)
				own = component.owner;

			if(own && own.spatialRef)
				return true;

			return false;
		}

		private function separateProcessObjects():void
		{
			var i:int = 0;
			var owner:Entity;
			var object:ProcessObject;
			while(i < tickedObjects.length)
			{
				object = tickedObjects[i];
				if(isEntityComponent(object.listener))
				{
					entityTickedObjects.push(object)

					owner = object.listener._owner;
					CONFIG::debug
					{
						if(owner == null)
							throw new Error('Entity component without owner')
					}
					if(entities.indexOf(owner) == -1)
						entities.push(owner);

					tickedObjects.splice(i, 1)
				}
				else
					i++
			}
			i = 0;
			while(i < animatedObjects.length)
			{
				object = animatedObjects[i]
				if(isEntityComponent(object.listener))
				{
					entityAnimatedObjects.push(object)

					owner = object.listener._owner;
					CONFIG::debug
					{
						if(owner == null)
							throw new Error('Entity component without owner')
					}
					if(entities.indexOf(owner) == -1)
						entities.push(owner);

					animatedObjects.splice(i, 1)
				}
				else
					i++
			}
		}
        
        protected var deferredMethodQueue:Array = [];
        protected var started:Boolean = false;
        protected var _virtualTime:int = 0.0;
        protected var _interpolationFactor:Number = 0.0;
        protected var _timeScale:Number = 1.0;
        protected var lastTime:int = -1.0;
        protected var elapsed:Number = 0.0;
        protected var animatedObjects:Array = new Array();
        protected var tickedObjects:Array = new Array();
        protected var needPurgeEmpty:Boolean = false;

        protected var _platformTime:int = 0;
        
        protected var duringAdvance:Boolean = false;
        
        protected var thinkHeap:SimplePriorityQueue = new SimplePriorityQueue(1024);

		/**
		 * Очередь компонентов, которые принадлежат обычным игровым Entity, снабженными SpatialComponent и которые могут "спать"
		 */
		protected var entityAnimatedObjects:Array = new Array();
        protected var entityTickedObjects:Array = new Array();
		protected var entities:Array = [];
    }
}

final class ProcessObject
{
    public var profilerKey:String = null;
    public var listener:* = null;
    public var priority:Number = 0.0;
}

final class DeferredMethod
{
    public var method:Function = null;;
    public var args:Array = null;
}