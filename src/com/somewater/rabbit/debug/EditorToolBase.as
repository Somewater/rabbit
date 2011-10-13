package com.somewater.rabbit.debug {
	import com.somewater.control.IClear;

	import flash.geom.Point;

	public class EditorToolBase implements IClear{

		public var cleared:Boolean = false;
		protected var template:XML;

		public function EditorToolBase(template:XML = null) {
			this.template = template;
		}

		public function onMove(tile:Point):void
		{

		}

		public function onClick(tile:Point):void
		{

		}

		public function clear():void
		{
			cleared = true;

			template = null;
			EditorModule.instance.setTemplateTool(null);
		}
	}
}
