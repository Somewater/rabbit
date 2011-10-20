package
{
	import apparat.asm.*;

	import flash.display.Sprite;

	[SWF(width=800, height=600)]
	public class RProtector extends Sprite
	{
		private var seed:Number = 7;

		public function RProtector()
		{
			super();

			graphics.beginFill(0);
			graphics.drawRect(0,0,10,10);

			trace("start")
			for (var i:int = 0; i < 10; i++) {
				trace(i + ") " + byte());
			}
			loop();
		}

		//[trace] 0) 0.00005263322966761572
		//[trace] 1) 0.849868759442991
		//[trace] 2) 0.8308587259756675
		//[trace] 3) 0.8758483291025498
		//[trace] 4) 0.3229700188725116
		//[trace] 5) 0.9968947344445134
		//[trace] 6) 0.8592770755567015
		//[trace] 7) 0.7469390140599287
		//[trace] 8) 0.8242600256690104
		//[trace] 9) 0.32663447751041247
		private function byte():Number
		{
			//seed;
			seed = seed * 16147 % 2147483647;
			//return seed / 2147483647;
			__maxStack(3)
			__asm(
		  /*+1|-0  */
					//FindProperty(AbcQName('seed',AbcNamespace(NamespaceKind.PRIVATE,'RProtector'))),
					//__as3(seed),
					//GetProperty(seed),PushScope,
		  /*+1|-0  */ //PushShort(16147),
		  /*+1|-2  */ //Multiply,
		  /*+1|-0  */ //PushInt(2147483647),
		  /*+1|-2  */ //Modulo,
		  /*+0|-2  */ //InitProperty(AbcQName('seed',AbcNamespace(NamespaceKind.PRIVATE,'RProtector'))),
		  /*+0|-0  */ //DebugLine(28),
		  /*+1|-0  */  //GetProperty(AbcQName('seed',AbcNamespace(NamespaceKind.PRIVATE,'RProtector'))),
					//GetProperty(seed),PushScope,
						__as3(seed),
		  /*+1|-0  */ PushInt(2147483647),
		  /*+1|-2  */ Divide,
		  /*+0|-1  */ ReturnValue
			 	);		return 0;
		}

		function loop():void
		{
			var i:int = 0;
			__asm('l1:')

			trace('i=' + i);
			i++
			__asm(Jump('l2'))

			graphics.beginFill(0xFF0000);
			graphics.drawRect(0,0,40,40);
			__asm(ReturnVoid)
			__asm('l2:');
			graphics.beginFill(0x00FF00);
			graphics.drawRect(0,0,10,10);
		}
	}
}