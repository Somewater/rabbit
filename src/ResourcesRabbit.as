package
{
	import com.pblabs.engine.resource.ResourceBundle;

	public class ResourcesRabbit extends ResourceBundle
	{
		//[TypeHint(alias="description.xml")]// как alias можно задать путь до удаленного сервера
		//[Embed(source='com/somewater/rabbit/xml/Description.xml', mimeType='application/octet-stream' )]
		//public var description:Class;
		//public static function getDescription():*{return new instance.description();}
		
		
		
		//[TypeHint(alias="levelpack.xml")]
		//[Embed(source='com/somewater/rabbit/xml/LevelPack.xml', mimeType='application/octet-stream' )]
		//public var levelpack:Class;
		
		
		private static var _instance:ResourcesRabbit;
		public static function get instance():ResourcesRabbit
		{
			if(_instance == null)
				_instance = new ResourcesRabbit();
			return _instance;
		}
		
		public function ResourcesRabbit()
		{
			
		}
	}
}