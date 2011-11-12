package {
	import com.somewater.arrow.ArrowVK;
	import com.somewater.rabbit.loader.SocialRabbitLoader;

	[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
	public class VkRabbitLoader extends SocialRabbitLoader{
		public function VkRabbitLoader() {
		}

		override protected function netInitialize():void
		{
			arrow = new ArrowVK();
		}

		override protected function createSpecificPaths():void
		{
			swfs = {
						"Game":{priority:-1,preload:true,url:"RabbitGame.swf"}
						,
						"Application":{priority:int.MIN_VALUE,
							preload:true,url:"RabbitApplication.swf"}
						,"Interface":{preload:true, url:"assets/interface.swf"}
						,"Assets":{preload:true, url:"assets/rabbit_asset.swf"}
						,"Rewards":{preload:false, url:"assets/rabbit_reward.swf"}
						,"Lang":{priority:100, preload:true, url:"lang_ru.swf"}
						,"Editor":{priority:1, preload:true, url:"RabbitEditor.swf"}

						,"Font":{priority:100, preload:true, url:"assets/fonts_ru.swf"}
						//,"Font":{priority:1000, preload:true, url:"assets/fonts_ru.swf"}
					}

			filePaths = {
							 "Levels":"levels.xml"
							,"Managers":"Managers.xml"
							,"Description":"Description.xml"
							,"Rewards":"Rewards.xml"
						}
		}

		override public function get net():int { return 2; }
	}
}
