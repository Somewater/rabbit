package com.somewater.common.new_iso
{
	import flash.display.MovieClip;
	
	/**
	 * Элементарный объект карты, имеющий размер и неподвижный (в отличае от IsoMover)
	 * @see com.progrestar.common.new_iso.IsoMover
	 */
	public class MapObjectBase extends MapObjectTiled
	{
		public function MapObjectBase(mc:MovieClip=null)
		{
			super(mc);
		}
		
		override public function set position(value:IsoPoint):void{
			
			if(value != null && !ghost)
				refreshRegistratin(value.x, value.y, value.right, value.bottom);

			super.position = value;
		}
	}
}