/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/23/11
 * Time: 3:14 AM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.rabbit.editor.events {
	import flash.events.Event;

	public class EntitySelectedEvent extends Event{

		public static const ENTITY_SELECTED_EVENT:String = "entitySelectedEvent";

		public var template:XML;
		public var objectReference:XML;

		public var data:Object;

		public function EntitySelectedEvent(template:XML, objectReference:XML = null) {
			this.template = template;
			this.objectReference = objectReference;
			super(ENTITY_SELECTED_EVENT);
		}
	}
}
