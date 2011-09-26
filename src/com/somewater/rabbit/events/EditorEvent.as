/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/24/11
 * Time: 6:02 PM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.rabbit.events {
	import flash.events.Event;

	public class EditorEvent extends Event{

		public var data:Object;

		public function EditorEvent(type:String, data:Object) {
			this.data = data;
			super(type);
		}
	}
}
