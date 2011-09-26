package com.somewater.rabbit.storage
{
	import com.somewater.storage.InfoDef;
	
	public class PathDef extends InfoDef
	{
		public var passMask:uint;// маска битов, оценивающая проходимость тайладля данного субъекта
		
		public var occupyMask:uint;// какие быти занимает в тайле этот субьект собой, если встает в тайл
		
		public function PathDef(data:Object=null)
		{
			super(data);
		}
	}
}