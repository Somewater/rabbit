package clickozavr
{
	/**
	 * @author jvirkovskiy
	 * Класс-контейнер информации о размещаемом контейнере
	 */
	
	public class ContainerInfo
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public static const WIDE:String = "wide";				// Контейнер 560x90
		public static const VERTICAL:String = "vertical";		// Контейнер 150x500
		public static const USUAL:String = "usual";				// Контейнер 420x180
		public static const WIDE_EX:String = "wide_ex";			// Контейнер 560x90w
		public static const VERTICAL_EX:String = "vertical_ex";	// Контейнер 150x500w
		public static const USUAL_EX:String = "usual_ex";		// Контейнер 420x180w
		public static const BOTTOM_BAR:String = "wide_ex_b";	// Контейнер 560x90wb
		public static const WIDE600x150_BAR:String = "wide600x150_bar";	// Контейнер 600x150
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		// Адреса контейнеров
		private static const _420x180wUrl:String = "http://s1.stat.clickozavr.com/c/420x180w.swf";
		private static const _560x90wbUrl:String = "http://s1.stat.clickozavr.com/c/560x90wb.swf";
		private static const _420x180Url:String = "http://s1.stat.clickozavr.com/c/420x180.swf";
		private static const _560x90Url:String = "http://s1.stat.clickozavr.com/c/560x90.swf";
		private static const _560x90wUrl:String = "http://s1.stat.clickozavr.com/c/560x90w.swf";
		private static const _150x500wUrl:String = "http://s1.stat.clickozavr.com/c/150x500w.swf";
		private static const _150x500Url:String = "http://s1.stat.clickozavr.com/c/150x500.swf";
		private static const _600x150Url:String = "http://s1.stat.clickozavr.com/c/600x150.swf";
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _type:String;
		private var _url:String;
		private var _x:int;
		private var _y:int;
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public function ContainerInfo(type:String, x:int = 0, y:int = 0)
		{
			switch (type)
			{
				case WIDE: _url = _560x90Url; break;				// Контейнер 560x90
				case VERTICAL: _url = _150x500Url; break;			// Контейнер 150x500
				case USUAL: _url = _420x180Url; break;				// Контейнер 420x180
				case WIDE_EX: _url = _560x90wUrl; break;			// Контейнер 560x90w
				case VERTICAL_EX: _url = _150x500wUrl; break;		// Контейнер 150x500w
				case USUAL_EX: _url = _420x180wUrl; break;			// Контейнер 420x180w
				case BOTTOM_BAR: _url = _560x90wbUrl; break;		// Контейнер 560x90wb
				case WIDE600x150_BAR: _url = _600x150Url; break;		// Контейнер 560x90wb
				default: throw Error("Wrong Clickozavr container type");
			}
			
			_type = type;
			_x = x;
			_y = y;
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function get url():String
		{
			return _url;
		}
		
		public function get x():int
		{
			return _x;
		}
		
		public function get y():int
		{
			return _y;
		}
	}
}