package
{
	import apparat.memory.Structure;

	public class MyStruct extends Structure
	{
		[Map(type='float', pos=0)]
		public var x:Number;
		
		[Map(type='float', pos=1)]
		public var y:Number;
	}
}